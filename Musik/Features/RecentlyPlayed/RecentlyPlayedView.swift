import MusicKit
import SwiftUI

/// The songs the user played recently, most recent first. Songs move to the
/// top as they start playing (see `RecentlyPlayedSongs`).
struct RecentlyPlayedView: View {
    @Environment(PlayerModel.self) private var player
    @Environment(RecentlyPlayedSongs.self) private var recent
    /// Bumped by Refresh to restart the load task.
    @State private var refreshID = 0

    var body: some View {
        LoadStateView(recent.state) { songs in
            if songs.isEmpty {
                ContentUnavailableView(
                    "Nothing Played Yet",
                    systemImage: "clock",
                    description: Text("Songs you play on Apple Music appear here.")
                )
            } else {
                List(songs) { song in
                    Button {
                        play(song)
                    } label: {
                        TrackRow(song, isCurrent: player.isCurrent(song))
                    }
                    .buttonStyle(.plain)
                }
                .animation(.default, value: songs.map(\.id))
            }
        }
        .navigationTitle("Recently Played")
        .toolbar {
            RefreshButton { refreshID += 1 }
        }
        // Loads once per session; the list then updates as songs play.
        .task(id: refreshID) { await recent.load(force: refreshID > 0) }
    }

    /// Moves the song to the top right away rather than once playback starts.
    /// The queue follows the list as shown: the song, then the rest in order.
    private func play(_ song: Song) {
        recent.record(song)
        player.play(recent.state.value ?? [song], startingAt: song)
    }
}
