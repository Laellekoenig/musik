import MusicKit
import SwiftUI

/// The window-wide transport bar. Shows a disabled empty state when nothing is queued.
struct NowPlayingBar: View {
    @Environment(PlayerModel.self) private var player

    var body: some View {
        HStack(spacing: 16) {
            nowPlayingInfo
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 4) {
                controls
                PlaybackProgressView()
            }
            .frame(minWidth: 280, idealWidth: 420, maxWidth: 480)

            // Balances the info column so the controls stay centered.
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .disabled(!player.hasQueue)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private var nowPlayingInfo: some View {
        HStack(spacing: 10) {
            ArtworkView(artwork: player.currentEntry?.artwork, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(player.currentEntry?.title ?? "Not Playing")
                    .lineLimit(1)
                    .foregroundStyle(player.hasQueue ? .primary : .secondary)
                if let subtitle = player.currentEntry?.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 20) {
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
                    .font(.title)
                    .frame(width: 28)
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
        .font(.title3)
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
