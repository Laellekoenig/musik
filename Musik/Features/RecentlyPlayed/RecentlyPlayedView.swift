import MusicKit
import SwiftUI

/// The albums, playlists and stations the user played recently, then the
/// songs they played recently.
struct RecentlyPlayedView: View {
    @Environment(PlayerModel.self) private var player
    @State private var recent: LoadState<Recent> = .loading
    /// Bumped by Refresh to restart the load task.
    @State private var refreshID = 0
    @State private var isStale = true

    private struct Recent {
        var containers: [RecentlyPlayedMusicItem]
        var songs: [Song]

        static func load() async throws -> Recent {
            async let containers: [RecentlyPlayedMusicItem] = fetch(max: 30)
            async let songs: [Song] = fetch(max: 50)
            return try await Recent(containers: containers, songs: songs)
        }

        /// The recently played items of one type, batch by batch up to `max`.
        private static func fetch<Item>(max: Int) async throws -> [Item]
        where Item: MusicRecentlyPlayedRequestable & Decodable {
            var batch = try await MusicRecentlyPlayedRequest<Item>().response().items
            var items: [Item] = []
            var seen = Set<MusicItemID>()

            while true {
                // Duplicate IDs would confuse `ForEach`.
                items += batch.filter { seen.insert($0.id).inserted }
                guard items.count < max, batch.hasNextBatch,
                      let next = try await batch.nextBatch(), !next.isEmpty
                else { break }
                batch = next
            }
            return Array(items.prefix(max))
        }
    }

    var body: some View {
        LoadStateView(recent) { recent in
            if recent.containers.isEmpty && recent.songs.isEmpty {
                ContentUnavailableView(
                    "Nothing Played Yet",
                    systemImage: "clock",
                    description: Text("Music you play on Apple Music appears here.")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        if !recent.containers.isEmpty {
                            MusicShelf(title: "Recently Played", items: recent.containers, card: card)
                        }
                        if !recent.songs.isEmpty {
                            SongList(title: "Recently Played Songs", songs: recent.songs)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Recently Played")
        .toolbar {
            RefreshButton {
                isStale = true
                refreshID += 1
            }
        }
        // Keeps the current content up while refreshing; returning from a
        // pushed detail view doesn't reload.
        .task(id: refreshID) {
            guard isStale else { return }
            let loaded = await LoadState { try await Recent.load() }
            guard !Task.isCancelled else { return }
            recent = loaded
            isStale = false
        }
    }

    /// Albums and playlists push their detail view; stations (the rest) can only be played.
    @ViewBuilder
    private func card(_ item: RecentlyPlayedMusicItem) -> some View {
        switch item {
        case .album(let album):
            MusicItemLink(album) { AlbumCard(item) }
        case .playlist(let playlist):
            MusicItemLink(playlist) { AlbumCard(item) }
        default:
            Button {
                player.play(item)
            } label: {
                AlbumCard(item)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button("Play", systemImage: "play.fill") { player.play(item) }
            }
        }
    }
}
