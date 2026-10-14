import MusicKit
import SwiftUI

struct LibraryArtistsView: View {
    @State private var library = LibraryItems<Artist>()
    /// Bumped by Refresh to restart the load task.
    @State private var refreshID = 0

    var body: some View {
        LoadStateView(library.state) { artists in
            if artists.isEmpty {
                ContentUnavailableView(
                    "No Artists in Your Library",
                    systemImage: "music.mic",
                    description: Text("Artists of the music in your library appear here.")
                )
            } else {
                List(artists) { artist in
                    NavigationLink(value: artist) {
                        HStack(spacing: 10) {
                            ArtworkView(artwork: artist.artwork, size: 32, cornerRadius: 16, placeholder: "person.fill")
                            Text(artist.name)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Artists")
        .toolbar {
            RefreshButton {
                library.reset()
                refreshID += 1
            }
        }
        .task(id: refreshID) {
            var request = MusicLibraryRequest<Artist>()
            request.sort(by: \.name, ascending: true)
            await library.load(request)
        }
    }
}
