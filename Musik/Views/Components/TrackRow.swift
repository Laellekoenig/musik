import MusicKit
import SwiftUI

/// A list row for anything song-like: search results, library songs,
/// album tracks (with track numbers) and playlist entries.
struct TrackRow: View {
    enum Leading {
        case artwork(Artwork?)
        case trackNumber(Int?)
        case none
    }

    let title: String
    var subtitle: String?
    var duration: TimeInterval?
    var leading: Leading = .none
    var isCurrent = false

    var body: some View {
        HStack(spacing: 12) {
            leadingView

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .lineLimit(1)
                    .foregroundStyle(isCurrent ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let duration {
                Text(duration.formattedDuration)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
    }

    @ViewBuilder
    private var leadingView: some View {
        switch leading {
        case .artwork(let artwork):
            ArtworkView(artwork: artwork, size: 40)
                .overlay {
                    if isCurrent {
                        nowPlayingIndicator
                            .frame(width: 40, height: 40)
                            .background(.black.opacity(0.4), in: .rect(cornerRadius: 5))
                            .foregroundStyle(.white)
                    }
                }
        case .trackNumber(let number):
            Group {
                if isCurrent {
                    nowPlayingIndicator.foregroundStyle(.tint)
                } else {
                    Text(number.map(String.init) ?? "")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 24, alignment: .trailing)
        case .none:
            EmptyView()
        }
    }

    private var nowPlayingIndicator: some View {
        Image(systemName: "speaker.wave.2.fill")
            .font(.caption)
    }
}

extension TrackRow {
    init(_ song: Song, leading: Leading? = nil, isCurrent: Bool = false) {
        self.init(
            title: song.title,
            subtitle: song.artistName,
            duration: song.duration,
            leading: leading ?? .artwork(song.artwork),
            isCurrent: isCurrent
        )
    }

    /// Album tracks default to showing track numbers instead of artwork.
    init(_ track: Track, leading: Leading? = nil, isCurrent: Bool = false) {
        self.init(
            title: track.title,
            subtitle: track.artistName,
            duration: track.duration,
            leading: leading ?? .trackNumber(track.trackNumber),
            isCurrent: isCurrent
        )
    }

    init(_ entry: Playlist.Entry, leading: Leading? = nil, isCurrent: Bool = false) {
        self.init(
            title: entry.title,
            subtitle: entry.artistName,
            duration: entry.duration,
            leading: leading ?? .artwork(entry.artwork),
            isCurrent: isCurrent
        )
    }
}

#Preview {
    List {
        TrackRow(title: "Song Title", subtitle: "Artist", duration: 215, leading: .artwork(nil))
        TrackRow(title: "Playing Now", subtitle: "Artist", duration: 187, leading: .artwork(nil), isCurrent: true)
        TrackRow(title: "Album Track", subtitle: "Artist", duration: 3725, leading: .trackNumber(3))
    }
}
