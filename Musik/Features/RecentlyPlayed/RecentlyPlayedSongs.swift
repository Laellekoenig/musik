import MusicKit
import Observation

/// The recently played songs, shared through the environment so plays are
/// recorded while any screen is showing. Apple Music's history lags behind,
/// so songs played in this app are kept on top of what it returns.
@MainActor
@Observable
final class RecentlyPlayedSongs {
    private var fetched: LoadState<[Song]> = .loading
    /// Played in this app since launch, most recent first.
    private var played: [Song] = []

    static let maxCount = 50

    var state: LoadState<[Song]> {
        switch fetched {
        case .loaded(let songs):
            .loaded(Self.merge(played, songs))
        case .loading, .failed:
            played.isEmpty ? fetched : .loaded(played)
        }
    }

    /// Moves `song` to the top.
    func record(_ song: Song) {
        played.removeAll { $0.isSameSong(as: song) }
        played.insert(song, at: 0)
        if played.count > Self.maxCount { played.removeLast() }
    }

    /// Fetches Apple Music's history; a no-op once loaded unless `force`d.
    func load(force: Bool = false) async {
        if fetched.value != nil && !force { return }
        let loaded = await LoadState { try await Self.fetch() }
        guard !Task.isCancelled else { return }
        fetched = loaded
    }

    /// Recently played songs, batch by batch up to `maxCount`.
    private static func fetch() async throws -> [Song] {
        var batch = try await MusicRecentlyPlayedRequest<Song>().response().items
        var songs: [Song] = []
        var seen = Set<MusicItemID>()

        while true {
            // Duplicate IDs would confuse `ForEach`.
            songs += batch.filter { seen.insert($0.id).inserted }
            guard songs.count < maxCount, batch.hasNextBatch,
                  let next = try await batch.nextBatch(), !next.isEmpty
            else { break }
            batch = next
        }
        return Array(songs.prefix(maxCount))
    }

    private static func merge(_ played: [Song], _ fetched: [Song]) -> [Song] {
        let rest = fetched.filter { song in !played.contains { $0.isSameSong(as: song) } }
        return Array((played + rest).prefix(maxCount))
    }
}

private extension Song {
    /// The history has catalog songs while plays from the library have library
    /// IDs, so the same song is also matched by title and artist.
    func isSameSong(as other: Song) -> Bool {
        id == other.id || (title == other.title && artistName == other.artistName)
    }
}
