import { Player } from "@musik/core";
import { PlayerProvider } from "@musik/core/react";
import { createMusicKitEngine } from "@musik/musickit-web";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { version } from "../../../package.json";
import { App } from "./App";
import "./styles.css";

const engine = createMusicKitEngine({
  developerToken: window.musik.developerToken,
  app: { name: "Musik", build: version },
});
const player = new Player(engine);

// shadcn's dark theme hangs off a `dark` class; follow the system appearance.
const darkMode = window.matchMedia("(prefers-color-scheme: dark)");
const applyAppearance = () => document.documentElement.classList.toggle("dark", darkMode.matches);
applyAppearance();
darkMode.addEventListener("change", applyAppearance);

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <PlayerProvider player={player}>
      <App />
    </PlayerProvider>
  </StrictMode>,
);
