import MusicKit
import SwiftUI

/// An album's header and track list. Works for library and catalog albums:
/// `with([.tracks])` loads from whichever source the album came from.
struct AlbumDetailView: View {
    @Environment(PlayerModel.self) private var player
    let album: Album
    @State private var detailed: LoadState<Album> = .loading

    var body: some View {
        List {
            header
                .listRowSeparator(.hidden)
                .padding(.bottom, 12)

            switch detailed {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            case .failed(let message):
                ContentUnavailableView("Couldn't Load Tracks", systemImage: "exclamationmark.triangle", description: Text(message))
                    .listRowSeparator(.hidden)
            case .loaded(let album):
                let tracks = album.tracks ?? []
                ForEach(tracks) { track in
                    Button {
                        player.play(tracks, startingAt: track)
                    } label: {
                        TrackRow(track, isCurrent: player.isCurrent(track))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(album.title)
        .task(id: album.id) {
            if detailed.value != nil { return }
            detailed = .loading
            detailed = await LoadState { try await album.with([.tracks]) }
        }
    }

    private var header: some View {
        CollectionHeader(
            artwork: album.artwork,
            title: album.title,
            subtitle: album.artistName,
            info: info,
            play: { player.play(detailed.value ?? album) },
            shuffle: { player.shuffle(detailed.value ?? album) }
        )
    }

    /// "Rock · 2019 · 12 songs, 48 min"
    private var info: String {
        let tracks = detailed.value?.tracks
        let songs = CollectionHeader.songSummary(
            count: tracks?.count ?? album.trackCount,
            duration: tracks?.reduce(0) { $0 + ($1.duration ?? 0) }
        )

        let year = album.releaseDate.map { String(Calendar.current.component(.year, from: $0)) }
        return [album.genreNames.first, year, songs].compactMap { $0 }.joined(separator: " · ")
    }
}
