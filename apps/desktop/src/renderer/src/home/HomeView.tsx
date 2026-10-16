import { artworkUrl, type Artwork } from "@musik/core";
import { usePlayerState } from "@musik/core/react";
import { useState } from "react";
import { ErrorAlert } from "../components/ErrorAlert";
import { NowPlaying } from "../player/NowPlaying";
import { SongSearch } from "../search/SongSearch";
import { useAppMenu } from "../useAppMenu";

/** The player stays in place; song search appears as a centered command panel. */
export function HomeView() {
  const [isSearchOpen, setSearchOpen] = useState(false);
  const artwork = usePlayerState((state) => state.nowPlaying?.artwork);
  useAppMenu(() => setSearchOpen(true));

  return (
    <div className="relative grid h-full place-items-center p-7">
      <ArtworkBackdrop artwork={artwork} />

      <main className="relative w-full">
        <NowPlaying />
      </main>

      <SongSearch open={isSearchOpen} onOpenChange={setSearchOpen} />
      <ErrorAlert />
    </div>
  );
}

/** The current artwork, heavily blurred, filling the window behind everything. */
function ArtworkBackdrop({ artwork }: { artwork: Artwork | undefined }) {
  if (!artwork) return null;
  const src = artworkUrl(artwork, 300);

  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden" aria-hidden>
      <img
        key={src}
        className="absolute -inset-[10%] size-[120%] max-w-none object-cover opacity-45 blur-[60px] duration-500 animate-in fade-in"
        src={src}
        alt=""
      />
    </div>
  );
}
