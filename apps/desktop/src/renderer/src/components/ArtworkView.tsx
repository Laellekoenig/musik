import { artworkUrl, type Artwork } from "@musik/core";
import { Music } from "lucide-react";
import { cn } from "@/lib/utils";

/** Square artwork with rounded corners, falling back to a placeholder. */
export function ArtworkView(props: { artwork: Artwork | undefined; size: number; radius?: number; className?: string }) {
  const { artwork, size } = props;

  return (
    <div
      className={cn("grid flex-none place-items-center overflow-hidden bg-muted text-muted-foreground", props.className)}
      style={{
        width: size,
        height: size,
        borderRadius: props.radius ?? Math.max(3, size / 8),
        backgroundColor: artwork?.backgroundColor,
      }}
    >
      {artwork ? (
        <img
          className="block size-full object-cover"
          src={artworkUrl(artwork, size * Math.ceil(window.devicePixelRatio))}
          alt=""
          draggable={false}
        />
      ) : (
        <Music style={{ width: size * 0.4, height: size * 0.4 }} />
      )}
    </div>
  );
}
