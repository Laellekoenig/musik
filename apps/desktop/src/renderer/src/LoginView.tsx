import { usePlayer, usePlayerState } from "@musik/core/react";
import { Music } from "lucide-react";

/** MusicKit shows Apple's sign-in page in a popup and asks the user to grant access. */
export function LoginView() {
  const player = usePlayer();
  const auth = usePlayerState((state) => state.auth);
  const setupError = usePlayerState((state) => state.setupError);
  const errorMessage = usePlayerState((state) => state.errorMessage);

  return (
    <main className="login">
      <Music className="login-icon" size={56} strokeWidth={2.25} />
      <h1 className="login-title">Musik</h1>

      {setupError ? (
        <p className="login-message">{setupError}</p>
      ) : (
        <>
          <p className="login-message">Connect your Apple Music account to search and play songs.</p>
          <button className="button-prominent" disabled={auth === "pending"} onClick={player.authorize}>
            Continue with Apple Music
          </button>
          {errorMessage && (
            <p className="login-error" role="alert">
              {errorMessage}
            </p>
          )}
        </>
      )}
    </main>
  );
}
