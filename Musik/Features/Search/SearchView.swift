import MusicKit
import SwiftUI

/// Apple Music catalog search: top songs, then shelves of albums and playlists.
struct SearchView: View {
    @State private var query = ""
    @State private var results: MusicCatalogSearchResponse?
    @State private var searchError: String?

    private static let maxSongs = 12

    var body: some View {
        ScrollView {
            if let results {
                VStack(alignment: .leading, spacing: 28) {
                    if !results.songs.isEmpty {
                        SongList(title: "Songs", songs: Array(results.songs.prefix(Self.maxSongs)))
                    }
                    if !results.albums.isEmpty {
                        MusicShelf(title: "Albums", items: results.albums) { album in
                            MusicItemLink(album) { AlbumCard(album, size: 140) }
                        }
                    }
                    if !results.playlists.isEmpty {
                        MusicShelf(title: "Playlists", items: results.playlists) { playlist in
                            MusicItemLink(playlist) { AlbumCard(playlist, size: 140) }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Search")
        .searchable(text: $query, placement: .toolbar, prompt: "Songs, albums, playlists")
        .task(id: query) { await search() }
        .overlay { overlay }
    }

    private var term: String {
        query.trimmingCharacters(in: .whitespaces)
    }

    @ViewBuilder
    private var overlay: some View {
        if let searchError {
            ContentUnavailableView("Search Failed", systemImage: "exclamationmark.triangle", description: Text(searchError))
        } else if let results {
            if results.isEmpty {
                ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("Try a different search."))
            }
        } else if term.isEmpty {
            ContentUnavailableView("Search Apple Music", systemImage: "magnifyingglass", description: Text("Find songs, albums and playlists."))
        } else {
            // The first search for a term; later ones keep the previous results up.
            ProgressView()
        }
    }

    private func search() async {
        let term = term
        guard !term.isEmpty else {
            results = nil
            searchError = nil
            return
        }

        // Debounce: a new keystroke cancels this task before the request fires.
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        do {
            var request = MusicCatalogSearchRequest(term: term, types: [Song.self, Album.self, Playlist.self])
            request.limit = 25
            let response = try await request.response()
            guard !Task.isCancelled else { return }
            results = response
            searchError = nil
        } catch {
            guard !Task.isCancelled else { return }
            searchError = error.localizedDescription
        }
    }
}

private extension MusicCatalogSearchResponse {
    /// Only the types this view requests and shows.
    var isEmpty: Bool {
        songs.isEmpty && albums.isEmpty && playlists.isEmpty
    }
}
