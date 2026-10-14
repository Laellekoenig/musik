import MusicKit
import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var songs: MusicItemCollection<Song> = []
    @State private var errorMessage: String?

    private let player = ApplicationMusicPlayer.shared

    var body: some View {
        List(songs) { song in
            Button {
                Task { await play(song) }
            } label: {
                SongRow(song: song)
            }
            .buttonStyle(.plain)
        }
        .searchable(text: $query, placement: .toolbar, prompt: "Search songs")
        .task(id: query) { await search() }
        .overlay {
            if songs.isEmpty {
                ContentUnavailableView(
                    query.isEmpty ? "Search Apple Music" : "No Results",
                    systemImage: "magnifyingglass",
                    description: Text(query.isEmpty ? "Find a song and click it to play." : "Try a different search.")
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            NowPlayingBar(state: player.state, queue: player.queue)
        }
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func search() async {
        let term = query.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else {
            songs = []
            return
        }

        // Debounce: a new keystroke cancels this task before the request fires.
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        do {
            var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
            request.limit = 25
            let response = try await request.response()
            guard !Task.isCancelled else { return }
            songs = response.songs
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }

    private func play(_ song: Song) async {
        do {
            player.queue = [song]
            try await player.play()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SongRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 12) {
            if let artwork = song.artwork {
                ArtworkImage(artwork, width: 44)
                    .clipShape(.rect(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
                    .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .lineLimit(1)
                Text(song.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
    }
}

private struct NowPlayingBar: View {
    @ObservedObject var state: ApplicationMusicPlayer.State
    @ObservedObject var queue: ApplicationMusicPlayer.Queue

    var body: some View {
        if let entry = queue.currentEntry {
            HStack(spacing: 12) {
                if let artwork = entry.artwork {
                    ArtworkImage(artwork, width: 36)
                        .clipShape(.rect(cornerRadius: 4))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .lineLimit(1)
                    if let subtitle = entry.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: state.playbackStatus == .playing ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }

    private func togglePlayback() {
        let player = ApplicationMusicPlayer.shared
        if state.playbackStatus == .playing {
            player.pause()
        } else {
            Task { try? await player.play() }
        }
    }
}
