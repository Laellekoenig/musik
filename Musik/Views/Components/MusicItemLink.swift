import MusicKit
import SwiftUI

/// A card that pushes `item`'s detail view (see `musicDestinations()`) when
/// clicked, with Play and Shuffle in its context menu.
struct MusicItemLink<Item: PlayableMusicItem & Hashable, Label: View>: View {
    @Environment(PlayerModel.self) private var player
    let item: Item
    let label: Label

    init(_ item: Item, @ViewBuilder label: () -> Label) {
        self.item = item
        self.label = label()
    }

    var body: some View {
        NavigationLink(value: item) {
            label
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Play", systemImage: "play.fill") { player.play(item) }
            Button("Shuffle", systemImage: "shuffle") { player.shuffle(item) }
        }
    }
}
