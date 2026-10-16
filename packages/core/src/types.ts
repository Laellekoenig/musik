/** Cover art. `url` is a template with `{w}` and `{h}` placeholders; see `artworkUrl`. */
export interface Artwork {
  url: string;
  width?: number;
  height?: number;
  /** CSS color, e.g. "#1a2b3c". */
  backgroundColor?: string;
}

export interface Song {
  /** Apple Music catalog ID. */
  id: string;
  title: string;
  artistName: string;
  albumName?: string;
  durationMs?: number;
  artwork?: Artwork;
}

export type RepeatMode = "none" | "all" | "one";

/** `pending` while the engine is starting up and doesn't know yet. */
export type AuthStatus = "pending" | "authorized" | "unauthorized";

/** Everything a `MusicEngine` reports. Playback time isn't here: it changes constantly, so it's polled. */
export interface EngineState {
  auth: AuthStatus;
  /** Why the engine couldn't start (e.g. no developer token). Nothing works until it's fixed. */
  setupError: string | null;
  nowPlaying: Song | null;
  isPlaying: boolean;
  /** Index of `nowPlaying` in the queue, or -1. */
  queuePosition: number;
  queueLength: number;
  shuffle: boolean;
  repeat: RepeatMode;
}

export interface PlayerState extends EngineState {
  /** The most recent playback error, shown in one alert. */
  errorMessage: string | null;
}
