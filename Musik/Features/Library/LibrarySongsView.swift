import MusicKit
import SwiftUI

struct LibrarySongsView: View {
    @Environment(PlayerModel.self) private var player
    @State private var library = LibraryItems<Song>()
    /// Bumped by Refresh to restart the load task.
    @State private var refreshID = 0
    @State private var selection = Set<Song.ID>()
    @State private var query = ""

    var body: some View {
        let filtered = filteredSongs

        LoadStateView(library.state) { songs in
            if songs.isEmpty {
                ContentUnavailableView(
                    "No Songs in Your Library",
                    systemImage: "music.note",
                    description: Text("Songs you add to your library appear here.")
                )
            } else {
                table(filtered)
                    .overlay {
                        if filtered.isEmpty {
                            ContentUnavailableView.search(text: query)
                        }
                    }
            }
        }
        .navigationTitle("Songs")
        .navigationSubtitle(subtitle)
        .searchable(text: $query, placement: .toolbar, prompt: "Filter songs")
        .toolbar {
            ToolbarItemGroup {
                Button("Play", systemImage: "play.fill") {
                    player.play(filtered)
                }
                .help("Play All")
                .disabled(filtered.isEmpty)

                Button("Shuffle", systemImage: "shuffle") {
                    player.shuffle(filtered)
                }
                .help("Shuffle All")
                .disabled(filtered.isEmpty)

                RefreshButton {
                    library.reset()
                    refreshID += 1
                }
            }
        }
        .task(id: refreshID) {
            var request = MusicLibraryRequest<Song>()
            request.sort(by: \.title, ascending: true)
            await library.load(request)
        }
    }

    private func table(_ songs: [Song]) -> some View {
        Table(songs, selection: $selection) {
            TableColumn("Title") { song in
                SongTitleCell(song: song, isCurrent: player.isCurrent(song))
            }
            .width(min: 160, ideal: 280)

            TableColumn("Artist") { song in
                Text(song.artistName)
            }
            .width(min: 100, ideal: 180)

            TableColumn("Album") { song in
                Text(song.albumTitle ?? "")
            }
            .width(min: 100, ideal: 180)

            TableColumn("Time") { song in
                Text(song.duration?.formattedDuration ?? "")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(56)
        }
        .contextMenu(forSelectionType: Song.ID.self) { ids in
            if let song = firstSong(in: ids) {
                Button("Play", systemImage: "play.fill") { play(from: song) }
            }
        } primaryAction: { ids in
            if let song = firstSong(in: ids) { play(from: song) }
        }
    }

    /// Client-side filter over the loaded songs.
    private var filteredSongs: [Song] {
        let songs = library.items
        let term = query.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return songs }
        return songs.filter { song in
            [song.title, song.artistName, song.albumTitle ?? ""].contains { $0.localizedStandardContains(term) }
        }
    }

    private var subtitle: String {
        let count = library.items.count.formatted()
        return library.isLoadingMore ? "Loading… \(count) songs" : "\(count) songs"
    }

    private func firstSong(in ids: Set<Song.ID>) -> Song? {
        filteredSongs.first { ids.contains($0.id) }
    }

    /// Queues the visible songs so next/previous move through the list.
    private func play(from song: Song) {
        player.play(filteredSongs, startingAt: song)
    }
}

private struct SongTitleCell: View {
    let song: Song
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 8) {
            ArtworkView(artwork: song.artwork, size: 24, cornerRadius: 3)
                .overlay {
                    if isCurrent {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.black.opacity(0.4), in: .rect(cornerRadius: 3))
                    }
                }
            Text(song.title)
                .foregroundStyle(isCurrent ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
        }
    }
}
