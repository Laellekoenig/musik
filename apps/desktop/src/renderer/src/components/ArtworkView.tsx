import { artworkUrl, type Artwork } from "@musik/core";
import { Music } from "lucide-react";

/** Square artwork with rounded corners, falling back to a placeholder. */
export function ArtworkView(props: { artwork: Artwork | undefined; size: number; radius?: number; className?: string }) {
  const { artwork, size } = props;

  return (
    <div
      className={props.className ? `artwork ${props.className}` : "artwork"}
      style={{
        width: size,
        height: size,
        borderRadius: props.radius ?? Math.max(3, size / 8),
        backgroundColor: artwork?.backgroundColor,
      }}
    >
      {artwork ? (
        <img src={artworkUrl(artwork, size * Math.ceil(window.devicePixelRatio))} alt="" draggable={false} />
      ) : (
        <Music size={size * 0.4} />
      )}
    </div>
  );
}
