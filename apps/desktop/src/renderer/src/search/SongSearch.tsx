import type { Song } from "@musik/core";
import { usePlayer, usePlayerState, useSongSearch } from "@musik/core/react";
import { SearchX, TriangleAlert } from "lucide-react";
import { useEffect, useState, type ReactNode } from "react";
import { Command, CommandDialog, CommandGroup, CommandInput, CommandItem, CommandList } from "@/components/ui/command";
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty";
import { Spinner } from "@/components/ui/spinner";
import { TrackRow } from "../components/TrackRow";

/** A floating search panel: ↑/↓ pick a result, Return plays it, Esc or a click outside closes it. */
export function SongSearch(props: { open: boolean; onOpenChange: (open: boolean) => void }) {
  return (
    <CommandDialog
      open={props.open}
      onOpenChange={props.onOpenChange}
      title="Search Songs"
      description="Search Apple Music for a song to play."
    >
      <SongSearchPanel onClose={() => props.onOpenChange(false)} />
    </CommandDialog>
  );
}

/** Mounted only while the dialog is open, so each search starts out empty. */
function SongSearchPanel({ onClose }: { onClose: () => void }) {
  const player = usePlayer();
  const nowPlayingId = usePlayerState((state) => state.nowPlaying?.id);
  const [query, setQuery] = useState("");
  const { term, results, isLoading, error } = useSongSearch(query);
  /** The highlighted result's song ID. */
  const [highlighted, setHighlighted] = useState("");

  // Each new set of results starts with the first one highlighted.
  useEffect(() => setHighlighted(results[0]?.id ?? ""), [results]);

  /** Queues all results so next/previous move through them, then closes to bring the player back into view. */
  const play = (song: Song) => {
    player.playSongs(results, song);
    onClose();
  };

  return (
    <Command shouldFilter={false} value={highlighted} onValueChange={setHighlighted}>
      <CommandInput autoFocus spellCheck={false} placeholder="Search songs" value={query} onValueChange={setQuery} />

      {term && (
        <CommandList>
          {results.length > 0 && (
            <CommandGroup>
              {results.map((song) => (
                // `*:[svg]:hidden` drops the check mark items leave room for; songs aren't options.
                <CommandItem
                  key={song.id}
                  className="*:[svg]:hidden"
                  value={song.id}
                  onSelect={() => play(song)}
                >
                  <TrackRow song={song} isCurrent={song.id === nowPlayingId} />
                </CommandItem>
              ))}
            </CommandGroup>
          )}

          {error ? (
            <SearchStatus icon={<TriangleAlert />} title="Search Failed" description={error} />
          ) : isLoading ? (
            <div className="flex justify-center py-6">
              <Spinner className="size-5 text-muted-foreground" aria-label="Searching" />
            </div>
          ) : results.length === 0 ? (
            <SearchStatus
              icon={<SearchX />}
              title={`No Results for “${term}”`}
              description="Check the spelling or try a new search."
            />
          ) : null}
        </CommandList>
      )}
    </Command>
  );
}

function SearchStatus(props: { icon: ReactNode; title: string; description: string }) {
  return (
    <Empty className="p-6">
      <EmptyHeader>
        <EmptyMedia variant="icon">{props.icon}</EmptyMedia>
        <EmptyTitle className="text-base">{props.title}</EmptyTitle>
        <EmptyDescription className="select-text">{props.description}</EmptyDescription>
      </EmptyHeader>
    </Empty>
  );
}
