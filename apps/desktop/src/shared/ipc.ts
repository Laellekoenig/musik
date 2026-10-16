import type { RepeatMode } from "@musik/core";

/** Menu actions, sent from the main process to the page. */
export type Command =
  | "search"
  | "play-pause"
  | "next"
  | "previous"
  | "toggle-shuffle"
  | "cycle-repeat"
  | `repeat-${RepeatMode}`;

/** What the menu shows, sent from the page whenever it changes. */
export interface MenuState {
  canSearch: boolean;
  hasQueue: boolean;
  isPlaying: boolean;
  shuffle: boolean;
  repeat: RepeatMode;
}

/** `window.musik`, exposed by the preload script. */
export interface MusikBridge {
  developerToken(): Promise<string>;
  /** Returns an unsubscribe function. */
  onCommand(listener: (command: Command) => void): () => void;
  setMenuState(state: MenuState): void;
}
