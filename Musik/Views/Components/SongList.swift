import MusicKit
import SwiftUI

/// A titled list of songs in adaptive columns. Clicking a song queues the
/// whole list from that song, so next/previous move through it.
struct SongList: View {
    @Environment(PlayerModel.self) private var player
    let title: String
    let songs: [Song]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.bold())

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 24)], spacing: 4) {
                ForEach(songs) { song in
                    Button {
                        player.play(songs, startingAt: song)
                    } label: {
                        TrackRow(song, isCurrent: player.isCurrent(song))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
