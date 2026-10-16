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
    <div className="home">
      <ArtworkBackdrop artwork={artwork} />

      <main className="home-player" inert={isSearchOpen}>
        <NowPlaying />
      </main>

      {isSearchOpen && (
        <div
          className="search-overlay"
          onPointerDown={(event) => {
            if (event.target === event.currentTarget) setSearchOpen(false);
          }}
        >
          <SongSearch onClose={() => setSearchOpen(false)} />
        </div>
      )}

      <ErrorAlert />
    </div>
  );
}

/** The current artwork, heavily blurred, filling the window behind everything. */
function ArtworkBackdrop({ artwork }: { artwork: Artwork | undefined }) {
  if (!artwork) return null;
  const src = artworkUrl(artwork, 300);

  return (
    <div className="backdrop" aria-hidden>
      <img key={src} src={src} alt="" />
    </div>
  );
}
