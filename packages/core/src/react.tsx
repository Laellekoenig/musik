import { createContext, useContext, useEffect, useState, useSyncExternalStore, type ReactNode } from "react";
import { errorMessage } from "./format";
import type { Player } from "./player";
import type { PlayerState, Song } from "./types";

// Hooks only, no components: these work in React DOM and React Native alike.

const PlayerContext = createContext<Player | null>(null);

export function PlayerProvider({ player, children }: { player: Player; children: ReactNode }) {
  return <PlayerContext.Provider value={player}>{children}</PlayerContext.Provider>;
}

export function usePlayer(): Player {
  const player = useContext(PlayerContext);
  if (!player) throw new Error("usePlayer() needs a <PlayerProvider> above it");
  return player;
}

/** Re-renders when the selected value changes. Select primitives or existing objects, never new ones. */
export function usePlayerState<T>(select: (state: PlayerState) => T): T {
  const player = usePlayer();
  return useSyncExternalStore(player.subscribe, () => select(player.getState()));
}

/** Seconds into the current song, polled every `intervalMs` while `active`. */
export function usePlaybackTime(active: boolean, intervalMs = 500): number {
  const player = usePlayer();
  const [time, setTime] = useState(player.getPlaybackTime);

  useEffect(() => {
    if (!active) return;
    setTime(player.getPlaybackTime());
    const timer = setInterval(() => setTime(player.getPlaybackTime()), intervalMs);
    return () => clearInterval(timer);
  }, [player, active, intervalMs]);

  return time;
}

const noSongs: Song[] = [];

export interface SongSearch {
  /** The trimmed query. */
  term: string;
  results: Song[];
  isLoading: boolean;
  error: string | null;
}

/** Catalog search for `query`, debounced; typing again cancels the previous request. */
export function useSongSearch(query: string, limit = 25): SongSearch {
  const player = usePlayer();
  const term = query.trim();
  const [response, setResponse] = useState({ term: "", results: noSongs, error: null as string | null });

  useEffect(() => {
    if (!term) return;
    const controller = new AbortController();
    const timer = setTimeout(() => {
      player.searchSongs(term, { limit, signal: controller.signal }).then(
        (results) => {
          if (!controller.signal.aborted) setResponse({ term, results, error: null });
        },
        (error: unknown) => {
          if (!controller.signal.aborted) setResponse({ term, results: [], error: errorMessage(error) });
        },
      );
    }, 250);
    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [player, term, limit]);

  const isFresh = response.term === term;
  return {
    term,
    results: isFresh ? response.results : noSongs,
    isLoading: term !== "" && !isFresh,
    error: isFresh ? response.error : null,
  };
}
