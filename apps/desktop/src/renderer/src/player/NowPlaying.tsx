import { formatDuration } from "@musik/core";
import { usePlaybackTime, usePlayer, usePlayerState } from "@musik/core/react";
import { Pause, Play, Repeat, Repeat1, Shuffle, SkipBack, SkipForward } from "lucide-react";
import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { ArtworkView } from "../components/ArtworkView";

const artworkSize = 280;

/** The current song's artwork and title, with the progress bar and transport controls below it. */
export function NowPlaying() {
  const song = usePlayerState((state) => state.nowPlaying);

  return (
    <div className="now-playing">
      <ArtworkView
        className="now-playing-artwork"
        artwork={song?.artwork}
        size={artworkSize}
        radius={artworkSize / 24}
      />

      <div className="now-playing-titles">
        <div className={song ? "now-playing-title" : "now-playing-title is-secondary"}>
          {song?.title ?? "Not Playing"}
        </div>
        <div className="now-playing-subtitle">{song?.artistName ?? " "}</div>
      </div>

      <fieldset className="now-playing-controls" disabled={!song}>
        <PlaybackProgress />
        <PlaybackControls />
      </fieldset>
    </div>
  );
}

/** Shuffle, previous, play/pause, next and repeat. */
function PlaybackControls() {
  const player = usePlayer();
  const isPlaying = usePlayerState((state) => state.isPlaying);
  const shuffle = usePlayerState((state) => state.shuffle);
  const repeat = usePlayerState((state) => state.repeat);

  return (
    <div className="transport">
      <ControlButton label={shuffle ? "Turn Shuffle Off" : "Turn Shuffle On"} pressed={shuffle} onClick={player.toggleShuffle}>
        <Shuffle />
      </ControlButton>
      <ControlButton label="Previous" onClick={player.skipToPrevious}>
        <SkipBack fill="currentColor" />
      </ControlButton>
      <ControlButton label={isPlaying ? "Pause" : "Play"} large onClick={player.togglePlayPause}>
        {isPlaying ? <Pause fill="currentColor" /> : <Play fill="currentColor" />}
      </ControlButton>
      <ControlButton label="Next" onClick={player.skipToNext}>
        <SkipForward fill="currentColor" />
      </ControlButton>
      <ControlButton
        label={{ none: "Repeat Off", all: "Repeat All", one: "Repeat One" }[repeat]}
        pressed={repeat !== "none"}
        onClick={player.cycleRepeat}
      >
        {repeat === "one" ? <Repeat1 /> : <Repeat />}
      </ControlButton>
    </div>
  );
}

function ControlButton(props: {
  label: string;
  onClick: () => void;
  /** For toggles: tinted when on, dimmed when off. */
  pressed?: boolean;
  large?: boolean;
  children: ReactNode;
}) {
  const classes = ["control", props.large && "is-large", props.pressed !== undefined && "is-toggle"];
  return (
    <button
      className={classes.filter(Boolean).join(" ")}
      title={props.label}
      aria-label={props.label}
      aria-pressed={props.pressed}
      onClick={props.onClick}
    >
      {props.children}
    </button>
  );
}

/** Elapsed / scrubber / remaining. The playback time is polled. */
function PlaybackProgress() {
  const player = usePlayer();
  const song = usePlayerState((state) => state.nowPlaying);
  /** Non-null while the user drags the slider, so polling doesn't fight them. */
  const [scrubTime, setScrubTime] = useState<number | null>(null);
  const time = usePlaybackTime(song !== null && scrubTime === null);
  const slider = useRef<HTMLInputElement>(null);

  const duration = (song?.durationMs ?? 0) / 1000;
  const max = Math.max(duration, 1);
  const shown = Math.min(scrubTime ?? time, duration);

  // A new song resets any in-progress drag.
  useEffect(() => setScrubTime(null), [song?.id]);

  // The native `change` event fires when the user lets go; React's onChange fires on every move.
  useEffect(() => {
    const input = slider.current!;
    const commit = () => {
      player.seek(input.valueAsNumber);
      setScrubTime(null);
    };
    input.addEventListener("change", commit);
    return () => input.removeEventListener("change", commit);
  }, [player]);

  return (
    <div className="progress">
      <span className="progress-time is-elapsed">{song ? formatDuration(shown) : "--:--"}</span>
      <input
        ref={slider}
        className="progress-slider"
        type="range"
        min={0}
        max={max}
        step="any"
        value={shown}
        disabled={duration <= 0}
        aria-label="Playback Position"
        style={{ "--progress": `${(shown / max) * 100}%` } as CSSProperties}
        onChange={(event) => setScrubTime(event.currentTarget.valueAsNumber)}
      />
      <span className="progress-time">{song && duration > 0 ? `-${formatDuration(duration - shown)}` : "--:--"}</span>
    </div>
  );
}
