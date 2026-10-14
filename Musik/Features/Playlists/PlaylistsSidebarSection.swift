import MusicKit
import SwiftUI

/// The library's playlists, one row per playlist tagged `SidebarItem.playlist`.
struct PlaylistsSidebarSection: View {
    @Environment(LibraryPlaylists.self) private var playlists
    @Environment(PlayerModel.self) private var player
    /// Bumped by Refresh Playlists to restart the load task.
    @State private var refreshID = 0

    var body: some View {
        Section {
            switch playlists.state {
            case .loading:
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
            case .failed(let message):
                placeholder("Couldn't Load Playlists")
                    .help(message)
            case .loaded(let items) where items.isEmpty:
                placeholder("No Playlists")
            case .loaded(let items):
                ForEach(items) { playlist in
                    row(playlist)
                }
            }
        } header: {
            Text("Playlists")
                .contextMenu { refreshButton }
        }
        .task(id: refreshID) { await playlists.load() }
    }

    private var refreshButton: some View {
        Button("Refresh Playlists", systemImage: "arrow.clockwise") {
            playlists.reset()
            refreshID += 1
        }
    }

    private func row(_ playlist: Playlist) -> some View {
        Label {
            Text(playlist.name)
        } icon: {
            if let artwork = playlist.artwork {
                ArtworkView(artwork: artwork, size: 18, cornerRadius: 3)
            } else {
                Image(systemName: "music.note.list")
            }
        }
        .lineLimit(1)
        .tag(SidebarItem.playlist(playlist.id))
        .contextMenu {
            Button("Play", systemImage: "play.fill") { player.play(playlist) }
            Button("Shuffle", systemImage: "shuffle") { player.shuffle(playlist) }
            Divider()
            refreshButton
        }
    }

    private func placeholder(_ text: String) -> some View {
        Text(text)
            .foregroundStyle(.secondary)
            .contextMenu { refreshButton }
    }
}
