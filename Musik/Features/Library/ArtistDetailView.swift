import MusicKit
import SwiftUI

/// A library artist's albums, newest first.
struct ArtistDetailView: View {
    let artist: Artist
    @State private var library = LibraryItems<Album>()

    var body: some View {
        LoadStateView(library.state) { albums in
            if albums.isEmpty {
                ContentUnavailableView(
                    "No Albums",
                    systemImage: "square.stack",
                    description: Text("Your library has no albums by \(artist.name).")
                )
            } else {
                ScrollView {
                    AlbumGrid(albums: albums)
                }
            }
        }
        .navigationTitle(artist.name)
        .task(id: artist.id) {
            var request = MusicLibraryRequest<Album>()
            request.filter(matching: \.artists, contains: artist)
            request.sort(by: \.releaseDate, ascending: false)
            await library.load(request)
        }
    }
}
