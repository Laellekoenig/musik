import { usePlayer, usePlayerState } from "@musik/core/react";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

/** Shows the player's most recent error until it's dismissed. */
export function ErrorAlert() {
  const player = usePlayer();
  const message = usePlayerState((state) => state.errorMessage);

  return (
    <AlertDialog
      open={message !== null}
      onOpenChange={(open) => {
        if (!open) player.dismissError();
      }}
    >
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Something went wrong</AlertDialogTitle>
          <AlertDialogDescription className="select-text">{message}</AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogAction onClick={player.dismissError}>
            OK
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
