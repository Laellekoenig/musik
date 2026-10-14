import SwiftUI

/// A titled, horizontally scrolling row of cards, e.g. albums or playlists in
/// search results. What a card does when clicked is up to `card`.
struct MusicShelf<Items: RandomAccessCollection, Card: View>: View where Items.Element: Identifiable {
    let title: String
    let items: Items
    @ViewBuilder var card: (Items.Element) -> Card

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.bold())

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 16) {
                    ForEach(items, content: card)
                }
                .padding(.bottom, 8)
            }
        }
    }
}
