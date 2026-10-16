import { formatDuration, type Song } from "@musik/core";
import { Volume2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { ArtworkView } from "./ArtworkView";

/** A list row for a song: artwork, title and artist, duration. */
export function TrackRow({ song, isCurrent = false }: { song: Song; isCurrent?: boolean }) {
  return (
    <div className="flex min-w-0 flex-1 items-center gap-3">
      <div className="relative flex-none">
        <ArtworkView artwork={song.artwork} size={40} radius={8} />
        {isCurrent && (
          <div className="absolute inset-0 grid place-items-center rounded-lg bg-black/40 text-white">
            <Volume2 className="size-3.5" fill="currentColor" aria-label="Now Playing" />
          </div>
        )}
      </div>

      <div className="grid min-w-0 flex-1 gap-0.5">
        <div className={cn("truncate font-medium", isCurrent && "text-primary")}>{song.title}</div>
        <div className="truncate text-xs text-muted-foreground">{song.artistName}</div>
      </div>

      {song.durationMs !== undefined && (
        <div className="text-xs text-muted-foreground tabular-nums">{formatDuration(song.durationMs / 1000)}</div>
      )}
    </div>
  );
}
