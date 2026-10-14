import MusicKit
import SwiftUI

/// The authorized app: sidebar, a navigation stack per destination, and the
/// now playing bar along the bottom of the window.
struct RootView: View {
    @Environment(PlayerModel.self) private var player
    @State private var selection: SidebarItem? = .recentlyPlayed
    @State private var playlists = LibraryPlaylists()
    @State private var recentlyPlayed = RecentlyPlayedSongs()

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
        .environment(recentlyPlayed)
        // A song counts as played once it's actually playing, so a paused
        // queue restored at launch isn't recorded.
        .onChange(of: playingSongID) {
            if let song = player.currentSong, player.isPlaying {
                recentlyPlayed.record(song)
            }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { player.errorMessage != nil },
            set: { if !$0 { player.errorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(player.errorMessage ?? "")
        }
    }

    private var playingSongID: MusicItemID? {
        player.isPlaying ? player.currentSong?.id : nil
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
