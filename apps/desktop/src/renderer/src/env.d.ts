import type { MusikBridge } from "../../shared/ipc";

declare global {
  interface Window {
    musik: MusikBridge;
  }
}
