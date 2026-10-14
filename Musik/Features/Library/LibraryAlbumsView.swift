import MusicKit
import SwiftUI

struct LibraryAlbumsView: View {
    @State private var library = LibraryItems<Album>()
    /// Bumped by Refresh to restart the load task.
    @State private var refreshID = 0

    var body: some View {
        LoadStateView(library.state) { albums in
            if albums.isEmpty {
                ContentUnavailableView(
                    "No Albums in Your Library",
                    systemImage: "square.stack",
                    description: Text("Albums you add to your library appear here.")
                )
            } else {
                ScrollView {
                    AlbumGrid(albums: albums)
                }
            }
        }
        .navigationTitle("Albums")
        .toolbar {
            RefreshButton {
                library.reset()
                refreshID += 1
            }
        }
        .task(id: refreshID) {
            var request = MusicLibraryRequest<Album>()
            request.sort(by: \.title, ascending: true)
            await library.load(request)
        }
    }
}
