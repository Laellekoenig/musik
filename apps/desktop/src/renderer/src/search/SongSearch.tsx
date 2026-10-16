import type { Song } from "@musik/core";
import { usePlayer, usePlayerState, useSongSearch } from "@musik/core/react";
import { CircleX, Search, SearchX, TriangleAlert } from "lucide-react";
import { useEffect, useRef, useState, type KeyboardEvent } from "react";
import { TrackRow } from "../components/TrackRow";

/** A floating search panel: ↑/↓ pick a result, Return plays it, Esc closes. */
export function SongSearch({ onClose }: { onClose: () => void }) {
  const player = usePlayer();
  const nowPlayingId = usePlayerState((state) => state.nowPlaying?.id);
  const [query, setQuery] = useState("");
  const { term, results, isLoading, error } = useSongSearch(query);
  const [highlighted, setHighlighted] = useState<string | null>(null);
  const field = useRef<HTMLInputElement>(null);
  const list = useRef<HTMLDivElement>(null);

  // Each new set of results starts with the first one highlighted.
  useEffect(() => setHighlighted(results[0]?.id ?? null), [results]);

  useEffect(() => {
    list.current?.querySelector("[data-highlighted]")?.scrollIntoView({ block: "nearest" });
  }, [highlighted]);

  /** Queues all results so next/previous move through them, then closes to bring the player back into view. */
  const play = (song: Song) => {
    player.playSongs(results, song);
    onClose();
  };

  const moveHighlight = (offset: 1 | -1) => {
    const index = results.findIndex((song) => song.id === highlighted);
    const next = Math.min(Math.max((index === -1 ? -offset : index) + offset, 0), results.length - 1);
    setHighlighted(results[next]?.id ?? null);
  };

  const onFieldKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if ((event.key === "ArrowDown" || event.key === "ArrowUp") && results.length > 0) {
      event.preventDefault();
      moveHighlight(event.key === "ArrowDown" ? 1 : -1);
    } else if (event.key === "Enter") {
      const song = results.find((result) => result.id === highlighted);
      if (song) play(song);
    }
  };

  return (
    <div
      className="search-panel"
      role="dialog"
      aria-modal
      aria-label="Search Songs"
      onKeyDown={(event) => {
        if (event.key === "Escape") onClose();
      }}
    >
      <div className="search-field">
        <Search className="search-field-icon" size={18} />
        <input
          ref={field}
          autoFocus
          spellCheck={false}
          placeholder="Search songs"
          value={query}
          onChange={(event) => setQuery(event.currentTarget.value)}
          onKeyDown={onFieldKeyDown}
        />
        {query && (
          <button
            className="search-clear"
            title="Clear Search"
            aria-label="Clear Search"
            onClick={() => {
              setQuery("");
              field.current?.focus();
            }}
          >
            <CircleX size={16} />
          </button>
        )}
        <button className="search-esc" aria-label="Close Search" onClick={onClose}>
          esc
        </button>
      </div>

      {term && (
        <div className="search-results" ref={list} data-empty={results.length === 0 || undefined}>
          {results.map((song) => (
            <button
              key={song.id}
              className="search-result"
              tabIndex={-1}
              data-highlighted={song.id === highlighted || undefined}
              onMouseMove={() => setHighlighted(song.id)}
              onClick={() => play(song)}
            >
              <TrackRow song={song} isCurrent={song.id === nowPlayingId} />
            </button>
          ))}

          {error ? (
            <div className="status">
              <TriangleAlert size={32} />
              <div className="status-title">Search Failed</div>
              <div>{error}</div>
            </div>
          ) : isLoading ? (
            <div className="spinner" aria-label="Searching" />
          ) : results.length === 0 ? (
            <div className="status">
              <SearchX size={32} />
              <div className="status-title">No Results for “{term}”</div>
              <div>Check the spelling or try a new search.</div>
            </div>
          ) : null}
        </div>
      )}
    </div>
  );
}
