import SwiftUI

@main
struct MusikApp: App {
    @State private var player = PlayerModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(player)
                .frame(minWidth: 760, minHeight: 500)
        }
        .defaultSize(width: 1000, height: 700)
        .commands {
            PlaybackCommands(player: player)
        }
    }
}
