import MusicKit
import SwiftUI

/// The current song's artwork and title, with the progress bar and transport
/// controls below it.
struct NowPlayingView: View {
    @Environment(PlayerModel.self) private var player
    var artworkSize: CGFloat = 280

    var body: some View {
        VStack(spacing: 16) {
            ArtworkView(artwork: player.currentEntry?.artwork, size: artworkSize, cornerRadius: artworkSize / 24)
                .shadow(color: .black.opacity(0.3), radius: 16, y: 8)

            VStack(spacing: 2) {
                Text(player.currentEntry?.title ?? "Not Playing")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(player.hasQueue ? .primary : .secondary)
                Text(player.currentEntry?.subtitle ?? " ")
                    .foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                PlaybackProgressView()
                PlaybackControls()
            }
            .frame(maxWidth: 360)
            .disabled(!player.hasQueue)
        }
    }
}

/// Shuffle, previous, play/pause, next and repeat.
private struct PlaybackControls: View {
    @Environment(PlayerModel.self) private var player

    var body: some View {
        HStack(spacing: 28) {
            Button(action: player.toggleShuffle) {
                Image(systemName: "shuffle")
                    .foregroundStyle(player.isShuffled ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            }
            .help(player.isShuffled ? "Turn Shuffle Off" : "Turn Shuffle On")

            Button(action: player.skipToPrevious) {
                Image(systemName: "backward.fill")
            }
            .help("Previous")

            Button(action: player.togglePlayPause) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.largeTitle)
                    .frame(width: 40)
            }
            .help(player.isPlaying ? "Pause" : "Play")

            Button(action: player.skipToNext) {
                Image(systemName: "forward.fill")
            }
            .help("Next")

            Button(action: player.cycleRepeatMode) {
                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                    .foregroundStyle(player.repeatMode == .none ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint))
            }
            .help(repeatHelp)
        }
        .font(.title2)
        .buttonStyle(.plain)
    }

    private var repeatHelp: String {
        switch player.repeatMode {
        case .all: "Repeat All"
        case .one: "Repeat One"
        default: "Repeat Off"
        }
    }
}

/// Elapsed / scrubber / remaining. `playbackTime` isn't published, so it's
/// polled via `TimelineView` while playing.
private struct PlaybackProgressView: View {
    @Environment(PlayerModel.self) private var player
    /// Non-nil while the user drags the slider, so polling doesn't fight them.
    @State private var scrubTime: TimeInterval?

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.5, paused: !player.isPlaying || scrubTime != nil)) { _ in
            let duration = player.currentDuration ?? 0
            let time = min(scrubTime ?? player.playbackTime, duration)

            HStack(spacing: 8) {
                Text(player.hasQueue ? time.formattedDuration : "--:--")
                    .frame(width: 44, alignment: .trailing)

                Slider(
                    value: Binding(get: { time }, set: { scrubTime = $0 }),
                    in: 0...max(duration, 1)
                ) { editing in
                    if !editing, let scrubTime {
                        player.seek(to: scrubTime)
                        self.scrubTime = nil
                    }
                }
                .controlSize(.mini)
                .disabled(duration <= 0)

                Text(player.hasQueue && duration > 0 ? "-" + (duration - time).formattedDuration : "--:--")
                    .frame(width: 44, alignment: .leading)
            }
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
        // A new track resets any in-progress drag.
        .onChange(of: player.currentEntry?.id) { scrubTime = nil }
    }
}
