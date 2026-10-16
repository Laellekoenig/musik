// The slice of MusicKit JS v3 this package uses. Apple doesn't publish types:
// https://js-cdn.music.apple.com/musickit/v3/docs/

export interface MKArtwork {
  url: string;
  width?: number;
  height?: number;
  bgColor?: string;
}

/** A queue item. */
export interface MKMediaItem {
  id: string;
  title: string;
  artistName: string;
  albumName?: string;
  /** Milliseconds. */
  playbackDuration?: number;
  artwork?: MKArtwork;
}

/** A song resource from the Apple Music API. */
export interface MKSongResource {
  id: string;
  attributes: {
    name: string;
    artistName: string;
    albumName?: string;
    durationInMillis?: number;
    artwork?: MKArtwork;
  };
}

export interface MKInstance {
  readonly isAuthorized: boolean;
  readonly isPlaying: boolean;
  readonly nowPlayingItem: MKMediaItem | undefined;
  readonly nowPlayingItemIndex: number;
  readonly currentPlaybackTime: number;
  readonly queue: { readonly length: number };
  shuffleMode: number;
  repeatMode: number;
  readonly api: {
    music(
      path: string,
      query?: Record<string, unknown>,
      options?: { fetchOptions?: RequestInit },
    ): Promise<{ data: unknown }>;
  };
  addEventListener(name: string, callback: () => void): void;
  authorize(): Promise<string | undefined>;
  setQueue(options: { songs: string[]; startWith?: number; startPlaying?: boolean }): Promise<unknown>;
  play(): Promise<void>;
  pause(): void;
  skipToNextItem(): Promise<void>;
  skipToPreviousItem(): Promise<void>;
  seekToTime(seconds: number): Promise<void>;
}

export interface MKGlobal {
  configure(options: { developerToken: string; app: { name: string; build: string } }): Promise<MKInstance>;
  PlayerShuffleMode: { off: number; songs: number };
  PlayerRepeatMode: { none: number; one: number; all: number };
}

declare global {
  interface Window {
    MusicKit?: MKGlobal;
  }
}
