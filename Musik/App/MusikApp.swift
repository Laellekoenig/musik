import SwiftUI

@main
struct MusikApp: App {
    @State private var player = PlayerModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(player)
                .frame(minWidth: 380, minHeight: 600)
        }
        .defaultSize(width: 460, height: 780)
        .windowStyle(.hiddenTitleBar)
        .commands {
            SearchCommands()
            PlaybackCommands(player: player)
        }
    }
}
