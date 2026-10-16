import { join } from "node:path";
import { app, BrowserWindow, components, ipcMain, Menu, nativeTheme, shell } from "electron";
import type { Command, MenuState } from "../shared/ipc";
import { mintDeveloperToken } from "./developer-token";
import { buildMenu } from "./menu";

if (!app.isPackaged) {
  try {
    process.loadEnvFile(join(app.getAppPath(), ".env.local"));
  } catch {
    // No .env.local yet; the page explains what to set.
  }
}

// Apple's sign-in page turns away Electron's user agent, so present as plain Chrome.
app.userAgentFallback = app.userAgentFallback.replace(/ (Electron|Musik)\/\S+/g, "");

let mainWindow: BrowserWindow | null = null;
let isQuitting = false;
let menuState: MenuState = { canSearch: false, hasQueue: false, isPlaying: false, shuffle: false, repeat: "none" };

function send(command: Command): void {
  mainWindow?.webContents.send("command", command);
}

function updateMenu(): void {
  Menu.setApplicationMenu(buildMenu(menuState, send));
}

function createWindow(): BrowserWindow {
  const win = new BrowserWindow({
    width: 460,
    height: 780,
    minWidth: 380,
    minHeight: 600,
    titleBarStyle: "hidden",
    backgroundColor: nativeTheme.shouldUseDarkColors ? "#1e1e1e" : "#ececec",
    show: false,
    webPreferences: {
      preload: join(__dirname, "../preload/index.js"),
      sandbox: true,
    },
  });

  win.once("ready-to-show", () => win.show());

  // MusicKit signs in through a popup on apple.com that reports back to this
  // window, so those open in-app. Other links open in the browser.
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (new URL(url).hostname.endsWith(".apple.com")) return { action: "allow" };
    void shell.openExternal(url);
    return { action: "deny" };
  });

  // Music keeps playing with the window closed, like Music.app; the Dock icon brings it back.
  win.on("close", (event) => {
    if (process.platform === "darwin" && !isQuitting) {
      event.preventDefault();
      win.hide();
    }
  });

  // MusicKit needs an http(s) origin for sign-in, so a packaged build will need
  // to serve the page from one instead of file://.
  if (process.env.ELECTRON_RENDERER_URL) {
    void win.loadURL(process.env.ELECTRON_RENDERER_URL);
  } else {
    void win.loadFile(join(__dirname, "../renderer/index.html"));
  }

  return win;
}

ipcMain.handle("developer-token", () => {
  try {
    return { token: mintDeveloperToken() };
  } catch (error) {
    return { error: (error as Error).message };
  }
});

ipcMain.on("menu-state", (_event, state: MenuState) => {
  menuState = state;
  updateMenu();
});

app.on("before-quit", () => {
  isQuitting = true;
});

app.on("activate", () => mainWindow?.show());

app.on("window-all-closed", () => app.quit());

void app.whenReady().then(async () => {
  // Electron for Content Security downloads the Widevine CDM on first launch.
  // MusicKit needs it for full-length playback (without it, only previews play).
  try {
    await components.whenReady();
  } catch (error) {
    console.error("Widevine CDM unavailable:", error);
  }
  updateMenu();
  mainWindow = createWindow();
});
