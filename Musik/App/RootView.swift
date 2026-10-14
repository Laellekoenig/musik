import SwiftUI

/// The authorized app: sidebar, a navigation stack per destination, and the
/// now playing bar along the bottom of the window.
struct RootView: View {
    @Environment(PlayerModel.self) private var player
    @State private var selection: SidebarItem? = .recentlyPlayed
    @State private var playlists = LibraryPlaylists()

    var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                SidebarView(selection: $selection)
            } detail: {
                NavigationStack {
                    destination
                        .musicDestinations()
                }
                // Switching sections starts from that section's root.
                .id(selection)
            }

            NowPlayingBar()
        }
        .environment(playlists)
        .alert("Something went wrong", isPresented: Binding(
            get: { player.errorMessage != nil },
            set: { if !$0 { player.errorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(player.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var destination: some View {
        switch selection {
        case .recentlyPlayed: RecentlyPlayedView()
        case .search: SearchView()
        case .songs: LibrarySongsView()
        case .albums: LibraryAlbumsView()
        case .artists: LibraryArtistsView()
        case .playlist(let id): LibraryPlaylistDetailView(id: id)
        case nil:
            ContentUnavailableView("Nothing Selected", systemImage: "music.note.house")
        }
    }
}
