import MusicKit
import SwiftUI

/// The "Controls" menu. Space isn't used for Play/Pause because a bare-key
/// menu shortcut would swallow spaces typed into the search field.
struct PlaybackCommands: Commands {
    let player: PlayerModel

    var body: some Commands {
        // Nothing to print; frees ⌘P for Play/Pause.
        CommandGroup(replacing: .printItem) {}

        CommandMenu("Controls") {
            Button(player.isPlaying ? "Pause" : "Play", action: player.togglePlayPause)
                .keyboardShortcut("p")
                .disabled(!player.hasQueue)

            Divider()

            Button("Next", action: player.skipToNext)
                .keyboardShortcut(.rightArrow)
                .disabled(!player.hasQueue)

            Button("Previous", action: player.skipToPrevious)
                .keyboardShortcut(.leftArrow)
                .disabled(!player.hasQueue)

            Divider()

            Toggle("Shuffle", isOn: Binding(
                get: { player.isShuffled },
                set: { player.setShuffleMode($0 ? .songs : .off) }
            ))
            .keyboardShortcut("s", modifiers: [.command, .option])

            Picker("Repeat", selection: Binding(
                get: { player.repeatMode },
                set: { player.setRepeatMode($0) }
            )) {
                Text("Off").tag(MusicPlayer.RepeatMode.none)
                Text("All").tag(MusicPlayer.RepeatMode.all)
                Text("One").tag(MusicPlayer.RepeatMode.one)
            }

            Button("Cycle Repeat Mode", action: player.cycleRepeatMode)
                .keyboardShortcut("r", modifiers: [.command, .option])
        }
    }
}
