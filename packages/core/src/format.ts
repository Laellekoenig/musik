import type { Artwork } from "./types";

/** "3:07", or "1:02:05" for an hour or more. */
export function formatDuration(seconds: number): string {
  const total = Number.isFinite(seconds) ? Math.max(0, Math.floor(seconds)) : 0;
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const secs = String(total % 60).padStart(2, "0");
  return hours > 0 ? `${hours}:${String(minutes).padStart(2, "0")}:${secs}` : `${minutes}:${secs}`;
}

const artworkDefaults: Record<string, string> = { c: "bb", f: "jpg" };

/** The URL of `artwork` scaled to a square of `pixels` (physical pixels, so multiply by the screen scale). */
export function artworkUrl(artwork: Artwork, pixels: number): string {
  const side = String(Math.round(pixels));
  return artwork.url.replace(/\{(\w)\}/g, (_, key: string) =>
    key === "w" || key === "h" ? side : (artworkDefaults[key] ?? ""),
  );
}

export function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
