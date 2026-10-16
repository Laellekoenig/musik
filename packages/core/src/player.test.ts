import { describe, expect, mock, test } from "bun:test";
import type { MusicEngine } from "./engine";
import { artworkUrl, formatDuration } from "./format";
import { Player } from "./player";
import type { EngineState, Song } from "./types";

const song = (id: string): Song => ({ id, title: `Song ${id}`, artistName: "Artist" });

function fakeEngine(overrides: Partial<EngineState> = {}, playbackTime = 0) {
  let state: EngineState = {
    auth: "authorized",
    setupError: null,
    nowPlaying: song("1"),
    isPlaying: true,
    queuePosition: 0,
    queueLength: 3,
    shuffle: false,
    repeat: "none",
    ...overrides,
  };
  const listeners = new Set<() => void>();
  const engine = {
    getState: () => state,
    subscribe: (listener: () => void) => {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },
    getPlaybackTime: () => playbackTime,
    authorize: mock(async () => {}),
    searchSongs: mock(async () => []),
    playQueue: mock(async (_songs: Song[], _index: number) => {}),
    play: mock(async () => {}),
    pause: mock(() => {}),
    skipToNext: mock(async () => {}),
    skipToPrevious: mock(async () => {}),
    seek: mock(async (_seconds: number) => {}),
    setShuffle: mock((_on: boolean) => {}),
    setRepeat: mock((_mode: string) => {}),
  } satisfies MusicEngine;
  const emit = (changes: Partial<EngineState>) => {
    state = { ...state, ...changes };
    for (const listener of listeners) listener();
  };
  return { engine, emit };
}

const flush = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("Player", () => {
  test("mirrors engine state", () => {
    const { engine, emit } = fakeEngine();
    const player = new Player(engine);
    emit({ isPlaying: false });
    expect(player.getState().isPlaying).toBe(false);
  });

  test("playSongs queues every song and starts at the chosen one", () => {
    const { engine } = fakeEngine();
    const songs = [song("a"), song("b"), song("c")];
    new Player(engine).playSongs(songs, songs[1]!);
    expect(engine.playQueue).toHaveBeenCalledWith(songs, 1);
  });

  test("only the latest playSongs failure is reported", async () => {
    const { engine } = fakeEngine();
    let rejectFirst!: (error: Error) => void;
    engine.playQueue.mockImplementationOnce(() => new Promise((_, reject) => (rejectFirst = reject)));
    const player = new Player(engine);
    player.playSongs([song("a")], song("a"));
    player.playSongs([song("b")], song("b"));
    rejectFirst(new Error("superseded"));
    await flush();
    expect(player.getState().errorMessage).toBeNull();
  });

  test("previous restarts the song after 3 seconds", () => {
    const { engine } = fakeEngine({ queuePosition: 1 }, 10);
    new Player(engine).skipToPrevious();
    expect(engine.seek).toHaveBeenCalledWith(0);
    expect(engine.skipToPrevious).not.toHaveBeenCalled();
  });

  test("previous goes back within the first 3 seconds", () => {
    const { engine } = fakeEngine({ queuePosition: 1 }, 2);
    new Player(engine).skipToPrevious();
    expect(engine.skipToPrevious).toHaveBeenCalled();
  });

  test("skipping past the end of the queue isn't an error", async () => {
    const { engine } = fakeEngine({ queuePosition: 2, queueLength: 3 });
    engine.skipToNext.mockImplementationOnce(async () => {
      throw new Error("end of queue");
    });
    const player = new Player(engine);
    player.skipToNext();
    await flush();
    expect(player.getState().errorMessage).toBeNull();
  });

  test("other failures are reported until dismissed", async () => {
    const { engine } = fakeEngine({ isPlaying: false });
    engine.play.mockImplementationOnce(async () => {
      throw new Error("No subscription");
    });
    const player = new Player(engine);
    player.togglePlayPause();
    await flush();
    expect(player.getState().errorMessage).toBe("No subscription");
    player.dismissError();
    expect(player.getState().errorMessage).toBeNull();
  });

  test("repeat cycles none → all → one → none", () => {
    const { engine, emit } = fakeEngine();
    const player = new Player(engine);
    for (const [from, to] of [["none", "all"], ["all", "one"], ["one", "none"]] as const) {
      emit({ repeat: from });
      player.cycleRepeat();
      expect(engine.setRepeat).toHaveBeenLastCalledWith(to);
    }
  });
});

describe("format", () => {
  test("formatDuration", () => {
    expect(formatDuration(0)).toBe("0:00");
    expect(formatDuration(187.9)).toBe("3:07");
    expect(formatDuration(3725)).toBe("1:02:05");
    expect(formatDuration(Number.NaN)).toBe("0:00");
  });

  test("artworkUrl fills the size template", () => {
    expect(artworkUrl({ url: "https://x/{w}x{h}bb.jpg" }, 560)).toBe("https://x/560x560bb.jpg");
    expect(artworkUrl({ url: "https://x/{w}x{h}{c}.{f}" }, 80)).toBe("https://x/80x80bb.jpg");
  });
});
