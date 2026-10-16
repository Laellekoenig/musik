import { usePlayer, usePlayerState } from "@musik/core/react";
import { useEffect, useEffectEvent } from "react";
import type { Command } from "../../shared/ipc";

/** Keeps the app menu in step with the player, and carries out its commands. */
export function useAppMenu(openSearch: () => void): void {
  const player = usePlayer();
  const hasQueue = usePlayerState((state) => state.nowPlaying !== null);
  const isPlaying = usePlayerState((state) => state.isPlaying);
  const shuffle = usePlayerState((state) => state.shuffle);
  const repeat = usePlayerState((state) => state.repeat);

  useEffect(() => {
    window.musik.setMenuState({ canSearch: true, hasQueue, isPlaying, shuffle, repeat });
    return () =>
      window.musik.setMenuState({ canSearch: false, hasQueue: false, isPlaying: false, shuffle, repeat });
  }, [hasQueue, isPlaying, shuffle, repeat]);

  const perform = useEffectEvent((command: Command) => {
    switch (command) {
      case "search":
        return openSearch();
      case "play-pause":
        return player.togglePlayPause();
      case "next":
        return player.skipToNext();
      case "previous":
        return player.skipToPrevious();
      case "toggle-shuffle":
        return player.toggleShuffle();
      case "cycle-repeat":
        return player.cycleRepeat();
      case "repeat-none":
        return player.setRepeat("none");
      case "repeat-all":
        return player.setRepeat("all");
      case "repeat-one":
        return player.setRepeat("one");
    }
  });

  useEffect(() => window.musik.onCommand((command) => perform(command)), []);
}
