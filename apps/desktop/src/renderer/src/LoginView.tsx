import { usePlayer, usePlayerState } from "@musik/core/react";
import { Music } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Empty, EmptyContent, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty";

/** MusicKit shows Apple's sign-in page in a popup and asks the user to grant access. */
export function LoginView() {
  const player = usePlayer();
  const auth = usePlayerState((state) => state.auth);
  const setupError = usePlayerState((state) => state.setupError);
  const errorMessage = usePlayerState((state) => state.errorMessage);

  return (
    <main className="h-full">
      <Empty className="h-full">
        <EmptyHeader>
          <EmptyMedia>
            <Music className="size-14 text-primary" strokeWidth={2.25} />
          </EmptyMedia>
          <EmptyTitle className="text-2xl font-semibold">
            <h1>Musik</h1>
          </EmptyTitle>
          <EmptyDescription className="select-text">
            {setupError ?? "Connect your Apple Music account to search and play songs."}
          </EmptyDescription>
        </EmptyHeader>

        {!setupError && (
          <EmptyContent>
            <Button size="lg" disabled={auth === "pending"} onClick={player.authorize}>
              Continue with Apple Music
            </Button>
            {errorMessage && (
              <p className="text-destructive select-text" role="alert">
                {errorMessage}
              </p>
            )}
          </EmptyContent>
        )}
      </Empty>
    </main>
  );
}
