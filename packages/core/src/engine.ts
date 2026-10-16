import type { EngineState, RepeatMode, Song } from "./types";

/**
 * The platform boundary: one implementation per platform, everything else is
 * shared. Desktop uses MusicKit JS (`@musik/musickit-web`); a mobile app would
 * implement this with native MusicKit.
 *
 * Engines report raw state and throw `Error`s with readable messages. Product
 * behavior (Music.app-style previous, which errors to show) lives in `Player`.
 */
export interface MusicEngine {
  getState(): EngineState;
  /** Called after every state change. Returns an unsubscribe function. */
  subscribe(listener: () => void): () => void;
  /** Seconds into the current song. */
  getPlaybackTime(): number;

  /** Asks the user to sign in to Apple Music. */
  authorize(): Promise<void>;

  searchSongs(term: string, options: { limit: number; signal?: AbortSignal }): Promise<Song[]>;

  /** Replaces the queue with `songs` and plays `songs[startIndex]`, keeping shuffle and repeat. */
  playQueue(songs: Song[], startIndex: number): Promise<void>;
  play(): Promise<void>;
  pause(): void;
  skipToNext(): Promise<void>;
  skipToPrevious(): Promise<void>;
  seek(seconds: number): Promise<void>;
  setShuffle(on: boolean): void;
  setRepeat(mode: RepeatMode): void;
}
