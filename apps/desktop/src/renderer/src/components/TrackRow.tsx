import { formatDuration, type Song } from "@musik/core";
import { Volume2 } from "lucide-react";
import { ArtworkView } from "./ArtworkView";

/** A list row for a song: artwork, title and artist, duration. */
export function TrackRow({ song, isCurrent = false }: { song: Song; isCurrent?: boolean }) {
  return (
    <div className="track-row">
      <div className="track-row-artwork">
        <ArtworkView artwork={song.artwork} size={40} />
        {isCurrent && (
          <div className="track-row-playing">
            <Volume2 size={14} fill="currentColor" aria-label="Now Playing" />
          </div>
        )}
      </div>

      <div className="track-row-titles">
        <div className={isCurrent ? "track-row-title is-current" : "track-row-title"}>{song.title}</div>
        <div className="track-row-subtitle">{song.artistName}</div>
      </div>

      {song.durationMs !== undefined && (
        <div className="track-row-duration">{formatDuration(song.durationMs / 1000)}</div>
      )}
    </div>
  );
}
