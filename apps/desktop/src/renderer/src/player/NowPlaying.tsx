import { formatDuration } from "@musik/core";
import { usePlaybackTime, usePlayer, usePlayerState } from "@musik/core/react";
import { Pause, Play, Repeat, Repeat1, Shuffle, SkipBack, SkipForward } from "lucide-react";
import { useEffect, useId, useState } from "react";
import { Button } from "@/components/ui/button";
import { Slider } from "@/components/ui/slider";
import { Toggle } from "@/components/ui/toggle";
import { cn } from "@/lib/utils";
import { ArtworkView } from "../components/ArtworkView";

const artworkSize = 280;

/** The current song's artwork and title, with the progress bar and transport controls below it. */
export function NowPlaying() {
  const song = usePlayerState((state) => state.nowPlaying);

  return (
    <div className="flex flex-col items-center gap-4">
      <ArtworkView className="shadow-2xl" artwork={song?.artwork} size={artworkSize} radius={artworkSize / 24} />

      <div className="grid max-w-full gap-0.5 text-center">
        <div className={cn("truncate text-base font-semibold", !song && "text-muted-foreground")}>
          {song?.title ?? "Not Playing"}
        </div>
        <div className="truncate text-sm text-muted-foreground">{song?.artistName ?? "\u00a0"}</div>
      </div>

      <fieldset className="grid w-full max-w-90 min-w-0 gap-3" disabled={!song}>
        <PlaybackProgress />
        <PlaybackControls />
      </fieldset>
    </div>
  );
}

/** Tinted when on, dimmed when off. */
const toggleClassName = "size-10 text-muted-foreground aria-pressed:bg-transparent aria-pressed:text-primary";

/** Shuffle, previous, play/pause, next and repeat. */
function PlaybackControls() {
  const player = usePlayer();
  const isPlaying = usePlayerState((state) => state.isPlaying);
  const shuffle = usePlayerState((state) => state.shuffle);
  const repeat = usePlayerState((state) => state.repeat);
  const shuffleLabel = shuffle ? "Turn Shuffle Off" : "Turn Shuffle On";
  const repeatLabel = { none: "Repeat Off", all: "Repeat All", one: "Repeat One" }[repeat];
  const playLabel = isPlaying ? "Pause" : "Play";

  return (
    <div className="flex items-center justify-center gap-3">
      <Toggle
        className={toggleClassName}
        title={shuffleLabel}
        aria-label={shuffleLabel}
        pressed={shuffle}
        onPressedChange={player.toggleShuffle}
      >
        <Shuffle className="size-5" />
      </Toggle>
      <Button variant="ghost" size="icon-lg" title="Previous" aria-label="Previous" onClick={player.skipToPrevious}>
        <SkipBack className="size-6" fill="currentColor" />
      </Button>
      <Button className="size-14" title={playLabel} aria-label={playLabel} onClick={player.togglePlayPause}>
        {isPlaying ? (
          <Pause className="size-6" fill="currentColor" />
        ) : (
          <Play className="size-6 translate-x-px" fill="currentColor" />
        )}
      </Button>
      <Button variant="ghost" size="icon-lg" title="Next" aria-label="Next" onClick={player.skipToNext}>
        <SkipForward className="size-6" fill="currentColor" />
      </Button>
      <Toggle
        className={toggleClassName}
        title={repeatLabel}
        aria-label={repeatLabel}
        pressed={repeat !== "none"}
        onPressedChange={player.cycleRepeat}
      >
        {repeat === "one" ? <Repeat1 className="size-5" /> : <Repeat className="size-5" />}
      </Toggle>
    </div>
  );
}

/** Elapsed / scrubber / remaining. The playback time is polled. */
function PlaybackProgress() {
  const player = usePlayer();
  const song = usePlayerState((state) => state.nowPlaying);
  /** Non-null while the user drags the slider, so polling doesn't fight them. */
  const [scrubTime, setScrubTime] = useState<number | null>(null);
  const time = usePlaybackTime(song !== null && scrubTime === null);
  const labelId = useId();

  const duration = (song?.durationMs ?? 0) / 1000;
  const max = Math.max(duration, 1);
  const shown = Math.min(scrubTime ?? time, duration);

  // A new song resets any in-progress drag.
  useEffect(() => setScrubTime(null), [song?.id]);

  return (
    <div className="flex items-center gap-3 text-xs text-muted-foreground tabular-nums">
      <span id={labelId} className="sr-only">
        Playback Position
      </span>
      <span className="w-10 text-right">{song ? formatDuration(shown) : "--:--"}</span>
      <Slider
        className="flex-1"
        min={0}
        max={max}
        value={[shown]}
        disabled={duration <= 0}
        aria-labelledby={labelId}
        onValueChange={(value) => setScrubTime(first(value))}
        onValueCommitted={(value) => {
          player.seek(first(value));
          setScrubTime(null);
        }}
      />
      <span className="w-10">{song && duration > 0 ? `-${formatDuration(duration - shown)}` : "--:--"}</span>
    </div>
  );
}

/** The slider has one thumb, but its callbacks are typed for any number. */
const first = (value: number | readonly number[]): number => (typeof value === "number" ? value : (value[0] ?? 0));
