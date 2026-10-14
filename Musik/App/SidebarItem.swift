import MusicKit

/// A sidebar destination. Library playlists are identified by ID only, so a
/// selection keeps matching its row when the playlists reload; the detail
/// resolves the ID through `LibraryPlaylists`.
enum SidebarItem: Hashable {
    case recentlyPlayed
    case search
    case songs
    case albums
    case artists
    case playlist(MusicItemID)

    static let appleMusic: [SidebarItem] = [.recentlyPlayed, .search]
    static let library: [SidebarItem] = [.songs, .albums, .artists]

    /// Playlist rows show the playlist's own name and artwork instead.
    var title: String {
        switch self {
        case .search: "Search"
        case .recentlyPlayed: "Recently Played"
        case .songs: "Songs"
        case .albums: "Albums"
        case .artists: "Artists"
        case .playlist: "Playlist"
        }
    }

    var systemImage: String {
        switch self {
        case .search: "magnifyingglass"
        case .recentlyPlayed: "clock"
        case .songs: "music.note"
        case .albums: "square.stack"
        case .artists: "music.mic"
        case .playlist: "music.note.list"
        }
    }
}
