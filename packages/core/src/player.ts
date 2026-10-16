import type { MusicEngine } from "./engine";
import { errorMessage } from "./format";
import type { PlayerState, RepeatMode, Song } from "./types";

const nextRepeatMode: Record<RepeatMode, RepeatMode> = { none: "all", all: "one", one: "none" };

/**
 * Wraps a `MusicEngine` with Music.app behavior and error reporting. Views
 * read `getState()` and call these methods; nothing else touches the engine.
 * Methods are bound, so they can be passed straight to event handlers.
 */
export class Player {
  private state: PlayerState;
  private readonly listeners = new Set<() => void>();
  /** Bumped by every `playSongs`, so a superseded start can tell it's stale. */
  private startCount = 0;

  constructor(private readonly engine: MusicEngine) {
    this.state = { ...engine.getState(), errorMessage: null };
    engine.subscribe(() => this.update(engine.getState()));
  }

  getState = (): PlayerState => this.state;

  subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };

  getPlaybackTime = (): number => this.engine.getPlaybackTime();

  isCurrent = (song: Song): boolean => this.state.nowPlaying?.id === song.id;

  authorize = (): void => this.perform(() => this.engine.authorize());

  searchSongs = (term: string, options: { limit: number; signal?: AbortSignal }): Promise<Song[]> =>
    this.engine.searchSongs(term, options);

  /** Queues `songs` so next/previous move through them, starting at `first`. Keeps the shuffle mode, like Music.app. */
  playSongs = (songs: Song[], first: Song): void => {
    const start = ++this.startCount;
    const index = Math.max(0, songs.findIndex((song) => song.id === first.id));
    this.engine.playQueue(songs, index).catch((error: unknown) => {
      // A start that a newer one replaced fails too; that's expected.
      if (start === this.startCount) this.fail(error);
    });
  };

  togglePlayPause = (): void => {
    if (this.state.isPlaying) {
      this.engine.pause();
    } else if (this.state.nowPlaying) {
      this.perform(() => this.engine.play());
    }
  };

  /** Skipping past either end of the queue may throw; that's not worth an alert. */
  skipToNext = (): void => {
    const { queuePosition, queueLength } = this.state;
    this.perform(() => this.engine.skipToNext(), queuePosition < queueLength - 1);
  };

  /** Like Music.app: restarts the current song if it's more than 3 s in. */
  skipToPrevious = (): void => {
    if (this.engine.getPlaybackTime() > 3) {
      this.seek(0);
    } else {
      this.perform(() => this.engine.skipToPrevious(), this.state.queuePosition > 0);
    }
  };

  seek = (seconds: number): void => this.perform(() => this.engine.seek(Math.max(0, seconds)));

  toggleShuffle = (): void => this.engine.setShuffle(!this.state.shuffle);

  setRepeat = (mode: RepeatMode): void => this.engine.setRepeat(mode);

  /** Cycles none → all → one → none. */
  cycleRepeat = (): void => this.setRepeat(nextRepeatMode[this.state.repeat]);

  dismissError = (): void => this.update({ errorMessage: null });

  private perform(operation: () => Promise<void>, alertOnError = true): void {
    operation().catch((error: unknown) => {
      if (alertOnError) this.fail(error);
      else console.warn(error);
    });
  }

  private fail(error: unknown): void {
    console.error(error);
    this.update({ errorMessage: errorMessage(error) });
  }

  private update(changes: Partial<PlayerState>): void {
    this.state = { ...this.state, ...changes };
    for (const listener of this.listeners) listener();
  }
}
