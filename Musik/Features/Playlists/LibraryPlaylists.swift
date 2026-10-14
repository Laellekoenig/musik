import MusicKit

/// The user's library playlists, loaded once by the sidebar and shared through
/// the environment, so the sidebar and playlist detail use the same values.
typealias LibraryPlaylists = LibraryItems<Playlist>

extension LibraryItems where Item == Playlist {
    /// Loads every library playlist, sorted by name like Music.app's sidebar.
    func load() async {
        var request = MusicLibraryRequest<Playlist>()
        request.sort(by: \.name, ascending: true)
        await load(request)
    }

    func playlist(id: MusicItemID) -> Playlist? {
        items.first { $0.id == id }
    }
}
