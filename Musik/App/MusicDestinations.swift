import MusicKit
import SwiftUI

extension View {
    /// Registers the detail screens for every music item that can be pushed
    /// with `NavigationLink(value:)`. Applied once at the navigation stack's root.
    func musicDestinations() -> some View {
        self
            .navigationDestination(for: Album.self) { AlbumDetailView(album: $0) }
            .navigationDestination(for: Artist.self) { ArtistDetailView(artist: $0) }
            .navigationDestination(for: Playlist.self) { PlaylistDetailView(playlist: $0) }
    }
}
