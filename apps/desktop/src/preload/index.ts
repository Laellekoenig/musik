import { contextBridge, ipcRenderer, type IpcRendererEvent } from "electron";
import type { Command, MenuState, MusikBridge } from "../shared/ipc";

const bridge: MusikBridge = {
  async developerToken() {
    const result: { token: string } | { error: string } = await ipcRenderer.invoke("developer-token");
    if ("error" in result) throw new Error(result.error);
    return result.token;
  },

  onCommand(listener) {
    const handler = (_event: IpcRendererEvent, command: Command) => listener(command);
    ipcRenderer.on("command", handler);
    return () => ipcRenderer.off("command", handler);
  },

  setMenuState(state: MenuState) {
    ipcRenderer.send("menu-state", state);
  },
};

contextBridge.exposeInMainWorld("musik", bridge);
