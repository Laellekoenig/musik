import MusicKit
import SwiftUI

/// The header of an album or playlist: large artwork beside the title, a
/// tinted subtitle, an optional description, an info line and Play/Shuffle.
struct CollectionHeader: View {
    let artwork: Artwork?
    var placeholder = "music.note"
    let title: String
    var subtitle: String?
    var description: String?
    var info: String?
    var canPlay = true
    let play: () -> Void
    let shuffle: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 20) {
            ArtworkView(artwork: artwork, size: 200, cornerRadius: 8, placeholder: placeholder)
                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.largeTitle.bold())
                    .lineLimit(2)
                if let subtitle {
                    Text(subtitle)
                        .font(.title2)
                        .foregroundStyle(.tint)
                        .lineLimit(1)
                }
                if let description, !description.isEmpty {
                    Text(description)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .help(description)
                }
                if let info {
                    Text(info)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button(action: play) {
                        Label("Play", systemImage: "play.fill")
                            .frame(minWidth: 70)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: shuffle) {
                        Label("Shuffle", systemImage: "shuffle")
                            .frame(minWidth: 70)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)
                .disabled(!canPlay)
                .padding(.top, 8)
            }
        }
        .padding(.top, 8)
    }
}

extension CollectionHeader {
    /// "12 songs, 48 min"; the duration is left out when unknown.
    static func songSummary(count: Int, duration: TimeInterval?) -> String {
        var summary = count == 1 ? "1 song" : "\(count) songs"
        if let duration, duration > 0 {
            summary += ", " + Duration.seconds(duration).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
        }
        return summary
    }
}

#Preview {
    CollectionHeader(
        artwork: nil,
        title: "Album Title",
        subtitle: "Artist",
        info: CollectionHeader.songSummary(count: 12, duration: 2880),
        play: {},
        shuffle: {}
    )
    .padding()
}
