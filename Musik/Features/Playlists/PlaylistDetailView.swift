import MusicKit
import SwiftUI

/// A playlist's header and entries. Works for library and catalog playlists:
/// `with([.entries])` loads from whichever source the playlist came from.
struct PlaylistDetailView: View {
    @Environment(PlayerModel.self) private var player
    let playlist: Playlist
    @State private var detailed: LoadState<Detailed> = .loading
    @State private var isComplete = false

    /// Upper bound for very long playlists, loaded batch by batch.
    private static let maxEntries = 5_000

    private struct Detailed {
        var playlist: Playlist
        var entries: [Playlist.Entry]
    }

    var body: some View {
        List {
            header
                .listRowSeparator(.hidden)
                .padding(.bottom, 12)

            switch detailed {
            case .loading:
                spinner
            case .failed(let message):
                ContentUnavailableView("Couldn't Load Songs", systemImage: "exclamationmark.triangle", description: Text(message))
                    .listRowSeparator(.hidden)
            case .loaded(let detailed) where detailed.entries.isEmpty && isComplete:
                ContentUnavailableView("No Songs", systemImage: "music.note.list", description: Text("This playlist is empty."))
                    .listRowSeparator(.hidden)
            case .loaded(let detailed):
                ForEach(detailed.entries) { entry in
                    Button {
                        player.play(detailed.playlist, startingAt: entry)
                    } label: {
                        TrackRow(entry, isCurrent: player.isCurrent(entry))
                    }
                    .buttonStyle(.plain)
                }
                if !isComplete {
                    spinner
                }
            }
        }
        .navigationTitle(playlist.name)
        .task(id: playlist.id) { await load() }
    }

    private var header: some View {
        CollectionHeader(
            artwork: playlist.artwork,
            placeholder: "music.note.list",
            title: playlist.name,
            subtitle: playlist.curatorName,
            description: playlist.standardDescription ?? playlist.shortDescription,
            info: info,
            canPlay: !(isComplete && detailed.value?.entries.isEmpty == true),
            play: { player.play(detailed.value?.playlist ?? playlist) },
            shuffle: { player.shuffle(detailed.value?.playlist ?? playlist) }
        )
    }

    private var spinner: some View {
        ProgressView()
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
    }

    /// "12 songs, 48 min", once every entry is in.
    private var info: String? {
        guard isComplete, let entries = detailed.value?.entries, !entries.isEmpty else { return nil }
        return CollectionHeader.songSummary(
            count: entries.count,
            duration: entries.reduce(0) { $0 + ($1.duration ?? 0) }
        )
    }

    /// Shows the first batch of entries right away, then appends the rest.
    private func load() async {
        if isComplete { return }
        // Restarting after a cancelled load keeps the partial list on screen.
        if case .failed = detailed { detailed = .loading }

        do {
            let loaded = try await playlist.with([.entries])
            var batch = loaded.entries ?? []
            var entries: [Playlist.Entry] = []
            var seen = Set<Playlist.Entry.ID>()

            while true {
                // Duplicate IDs would confuse `ForEach`.
                entries += batch.filter { seen.insert($0.id).inserted }
                detailed = .loaded(Detailed(playlist: loaded, entries: entries))

                guard batch.hasNextBatch, entries.count < Self.maxEntries,
                      let next = try await batch.nextBatch(), !next.isEmpty
                else { break }
                batch = next
            }
            isComplete = true
        } catch {
            guard !Task.isCancelled else { return }
            // Keep what loaded so far; only a failure before anything showed replaces it.
            if detailed.value == nil {
                detailed = .failed(error.localizedDescription)
            } else {
                isComplete = true
            }
        }
    }
}

/// Resolves a sidebar playlist ID against the shared library playlists.
struct LibraryPlaylistDetailView: View {
    @Environment(LibraryPlaylists.self) private var playlists
    let id: MusicItemID

    var body: some View {
        if let playlist = playlists.playlist(id: id) {
            PlaylistDetailView(playlist: playlist)
        } else {
            LoadStateView(playlists.state) { _ in
                if playlists.isLoadingMore {
                    ProgressView()
                } else {
                    ContentUnavailableView("Playlist Not Found", systemImage: "music.note.list")
                }
            }
        }
    }
}
