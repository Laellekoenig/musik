import type { Artwork, EngineState, MusicEngine, RepeatMode, Song } from "@musik/core";
import type { MKArtwork, MKGlobal, MKInstance, MKMediaItem, MKSongResource } from "./musickit";

const scriptUrl = "https://js-cdn.music.apple.com/musickit/v3/musickit.js";

/** Every event that can change `EngineState`. */
const stateEvents = [
  "authorizationStatusDidChange",
  "playbackStateDidChange",
  "nowPlayingItemDidChange",
  "queueItemsDidChange",
  "queuePositionDidChange",
  "shuffleModeDidChange",
  "repeatModeDidChange",
];

export interface MusicKitEngineOptions {
  /** A MusicKit developer token (a JWT signed with your MusicKit key). Called once, at startup. */
  developerToken: () => Promise<string>;
  /** Shown to the user when they authorize. */
  app: { name: string; build: string };
}

/** A `MusicEngine` backed by MusicKit JS, for browsers and Electron. */
export function createMusicKitEngine(options: MusicKitEngineOptions): MusicEngine {
  return new MusicKitEngine(options);
}

class MusicKitEngine implements MusicEngine {
  private state: EngineState = {
    auth: "pending",
    setupError: null,
    nowPlaying: null,
    isPlaying: false,
    queuePosition: -1,
    queueLength: 0,
    shuffle: false,
    repeat: "none",
  };
  private readonly listeners = new Set<() => void>();
  private readonly ready: Promise<{ music: MKInstance; MusicKit: MKGlobal }>;
  /** Set once `ready` resolves, for the synchronous methods. */
  private loaded: { music: MKInstance; MusicKit: MKGlobal } | null = null;
  /** Where a seek in flight is headed; reported as the playback time until it lands. */
  private seekTarget: number | null = null;

  constructor(options: MusicKitEngineOptions) {
    this.ready = this.setup(options);
    this.ready.catch((error: unknown) => this.setState({ auth: "unauthorized", setupError: toError(error).message }));
  }

  getState = (): EngineState => this.state;

  subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };

  getPlaybackTime = (): number => this.seekTarget ?? this.loaded?.music.currentPlaybackTime ?? 0;

  authorize = (): Promise<void> => this.call(async (music) => void (await music.authorize()));

  searchSongs = (term: string, { limit, signal }: { limit: number; signal?: AbortSignal }): Promise<Song[]> =>
    this.call(async (music) => {
      const response = await music.api.music(
        "/v1/catalog/{{storefrontId}}/search",
        { term, types: "songs", limit },
        { fetchOptions: { signal } },
      );
      const results = (response.data as { results: { songs?: { data: MKSongResource[] } } }).results;
      return (results.songs?.data ?? []).map(songFromResource);
    });

  playQueue = (songs: Song[], startIndex: number): Promise<void> =>
    this.call(async (music) => {
      await music.setQueue({ songs: songs.map((song) => song.id), startWith: startIndex, startPlaying: true });
    });

  play = (): Promise<void> => this.call((music) => music.play());

  pause = (): void => this.loaded?.music.pause();

  skipToNext = (): Promise<void> => this.call((music) => music.skipToNextItem());

  skipToPrevious = (): Promise<void> => this.call((music) => music.skipToPreviousItem());

  seek = async (seconds: number): Promise<void> => {
    this.seekTarget = seconds;
    try {
      await this.call((music) => music.seekToTime(seconds));
    } finally {
      this.seekTarget = null;
    }
  };

  setShuffle = (on: boolean): void => {
    if (!this.loaded) return;
    const { music, MusicKit } = this.loaded;
    music.shuffleMode = on ? MusicKit.PlayerShuffleMode.songs : MusicKit.PlayerShuffleMode.off;
  };

  setRepeat = (mode: RepeatMode): void => {
    if (!this.loaded) return;
    const { music, MusicKit } = this.loaded;
    music.repeatMode = MusicKit.PlayerRepeatMode[mode];
  };

  private async setup({ developerToken, app }: MusicKitEngineOptions) {
    const [token, MusicKit] = await Promise.all([developerToken(), loadMusicKit()]);
    const music = await MusicKit.configure({ developerToken: token, app });
    this.loaded = { music, MusicKit };
    for (const event of stateEvents) music.addEventListener(event, this.sync);
    this.sync();
    return this.loaded;
  }

  /** Runs `operation` once MusicKit is ready, with MusicKit's errors turned into readable `Error`s. */
  private async call<T>(operation: (music: MKInstance) => Promise<T>): Promise<T> {
    const { music } = await this.ready;
    try {
      return await operation(music);
    } catch (error) {
      throw toError(error);
    } finally {
      this.sync();
    }
  }

  private sync = (): void => {
    if (!this.loaded) return;
    const { music, MusicKit } = this.loaded;
    const item = music.nowPlayingItem;
    const previous = this.state.nowPlaying;
    const song = item ? songFromMediaItem(item) : null;

    this.setState({
      auth: music.isAuthorized ? "authorized" : "unauthorized",
      // Keep the same object while the song is unchanged, so views don't re-render.
      nowPlaying: song && previous && isSameSong(song, previous) ? previous : song,
      isPlaying: music.isPlaying,
      queuePosition: item ? music.nowPlayingItemIndex : -1,
      queueLength: music.queue.length,
      shuffle: music.shuffleMode === MusicKit.PlayerShuffleMode.songs,
      repeat:
        music.repeatMode === MusicKit.PlayerRepeatMode.one
          ? "one"
          : music.repeatMode === MusicKit.PlayerRepeatMode.all
            ? "all"
            : "none",
    });
  };

  private setState(changes: Partial<EngineState>): void {
    const next = { ...this.state, ...changes };
    const keys = Object.keys(next) as (keyof EngineState)[];
    if (keys.every((key) => next[key] === this.state[key])) return;
    this.state = next;
    for (const listener of this.listeners) listener();
  }
}

/** Loads MusicKit JS from Apple's CDN; Apple doesn't allow bundling it. */
function loadMusicKit(): Promise<MKGlobal> {
  return new Promise((resolve, reject) => {
    if (window.MusicKit) return resolve(window.MusicKit);
    document.addEventListener("musickitloaded", () => resolve(window.MusicKit!), { once: true });
    const script = document.createElement("script");
    script.src = scriptUrl;
    script.async = true;
    script.onerror = () => reject(new Error("Couldn't load MusicKit JS from Apple. Check your internet connection."));
    document.head.append(script);
  });
}

function songFromResource({ id, attributes }: MKSongResource): Song {
  return {
    id,
    title: attributes.name,
    artistName: attributes.artistName,
    albumName: attributes.albumName,
    durationMs: attributes.durationInMillis,
    artwork: attributes.artwork && artworkFrom(attributes.artwork),
  };
}

function songFromMediaItem(item: MKMediaItem): Song {
  return {
    id: item.id,
    title: item.title,
    artistName: item.artistName,
    albumName: item.albumName,
    durationMs: item.playbackDuration,
    artwork: item.artwork && artworkFrom(item.artwork),
  };
}

function artworkFrom({ url, width, height, bgColor }: MKArtwork): Artwork {
  return { url, width, height, backgroundColor: bgColor ? `#${bgColor}` : undefined };
}

function isSameSong(a: Song, b: Song): boolean {
  return a.id === b.id && a.title === b.title && a.durationMs === b.durationMs && a.artwork?.url === b.artwork?.url;
}

/** MusicKit rejects with `MKError`s whose text is in `description` or `errorCode`. */
function toError(error: unknown): Error {
  if (error instanceof Error && error.message) return error;
  const { description, errorCode } = (error ?? {}) as { description?: string; errorCode?: string };
  return new Error(description || errorCode || String(error));
}
