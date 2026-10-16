import { usePlayerState } from "@musik/core/react";
import { HomeView } from "./home/HomeView";
import { LoginView } from "./LoginView";

/** Gates the app on Apple Music authorization. */
export function App() {
  const isAuthorized = usePlayerState((state) => state.auth === "authorized");

  return (
    <>
      {/* The window has no title bar; this strip lets you drag it. */}
      <div className="titlebar" />
      {isAuthorized ? <HomeView /> : <LoginView />}
    </>
  );
}
