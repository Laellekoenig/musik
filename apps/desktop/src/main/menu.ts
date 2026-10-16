import { app, Menu, type MenuItemConstructorOptions } from "electron";
import type { Command, MenuState } from "../shared/ipc";

/**
 * The app menu. Space isn't Play/Pause because a bare-key shortcut would
 * swallow spaces typed into the search field.
 */
export function buildMenu(state: MenuState, send: (command: Command) => void): Menu {
  const isMac = process.platform === "darwin";
  const { hasQueue } = state;
  const separator: MenuItemConstructorOptions = { type: "separator" };

  const template: MenuItemConstructorOptions[] = [
    ...(isMac ? [{ role: "appMenu" } as const] : []),
    {
      label: "File",
      submenu: [
        // In place of New Window: the app is one window.
        {
          label: "Search Songs",
          accelerator: "CommandOrControl+F",
          enabled: state.canSearch,
          click: () => send("search"),
        },
        separator,
        isMac ? { role: "close" } : { role: "quit" },
      ],
    },
    // Copy, paste and select all in the search field need these.
    { role: "editMenu" },
    {
      label: "Controls",
      submenu: [
        {
          label: state.isPlaying ? "Pause" : "Play",
          accelerator: "CommandOrControl+P",
          enabled: hasQueue,
          click: () => send("play-pause"),
        },
        separator,
        { label: "Next", accelerator: "CommandOrControl+Right", enabled: hasQueue, click: () => send("next") },
        { label: "Previous", accelerator: "CommandOrControl+Left", enabled: hasQueue, click: () => send("previous") },
        separator,
        {
          label: "Shuffle",
          type: "checkbox",
          checked: state.shuffle,
          accelerator: "Alt+CommandOrControl+S",
          click: () => send("toggle-shuffle"),
        },
        {
          label: "Repeat",
          submenu: (["none", "all", "one"] as const).map((mode) => ({
            label: { none: "Off", all: "All", one: "One" }[mode],
            type: "radio",
            checked: state.repeat === mode,
            click: () => send(`repeat-${mode}`),
          })),
        },
        { label: "Cycle Repeat Mode", accelerator: "Alt+CommandOrControl+R", click: () => send("cycle-repeat") },
      ],
    },
    // Reload and developer tools, while developing.
    ...(app.isPackaged ? [] : [{ role: "viewMenu" } as const]),
    { role: "windowMenu" },
  ];

  return Menu.buildFromTemplate(template);
}
