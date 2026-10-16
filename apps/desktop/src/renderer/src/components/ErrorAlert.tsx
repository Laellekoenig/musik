import { usePlayer, usePlayerState } from "@musik/core/react";
import { useEffect, useRef } from "react";

/** Shows the player's most recent error until it's dismissed. */
export function ErrorAlert() {
  const player = usePlayer();
  const message = usePlayerState((state) => state.errorMessage);
  const dialog = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const element = dialog.current!;
    if (message && !element.open) element.showModal();
    if (!message && element.open) element.close();
  }, [message]);

  return (
    <dialog ref={dialog} className="alert" onClose={player.dismissError}>
      <h2>Something went wrong</h2>
      <p>{message}</p>
      <form method="dialog">
        <button className="button-prominent" autoFocus>
          OK
        </button>
      </form>
    </dialog>
  );
}
