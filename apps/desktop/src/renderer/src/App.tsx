import { usePlayerState } from "@musik/core/react";
import { HomeView } from "./home/HomeView";
import { LoginView } from "./LoginView";

/** Gates the app on Apple Music authorization. */
export function App() {
  const isAuthorized = usePlayerState((state) => state.auth === "authorized");

  return (
    <>
      {/* The window has no title bar; this strip lets you drag it. */}
      <div className="fixed inset-x-0 top-0 z-10 h-7 [-webkit-app-region:drag]" />
      {isAuthorized ? <HomeView /> : <LoginView />}
    </>
  );
}
