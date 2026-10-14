import MusicKit
import SwiftUI

/// The app's only page: what's playing, and a song search below it. While
/// searching, the artwork shrinks to make room for the results.
struct HomeView: View {
    @Environment(PlayerModel.self) private var player
    @FocusState private var isSearchFocused: Bool
    @State private var query = ""

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 28) {
            NowPlayingView(artworkSize: isSearching ? 120 : 280)
            SongSearchView(isFocused: $isSearchFocused, query: $query)
        }
        .padding(.horizontal, 28)
        .padding(.top, 36)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.smooth, value: isSearching)
        .background { ArtworkBackdrop(artwork: player.currentEntry?.artwork) }
        .focusedSceneValue(\.focusSongSearch) { isSearchFocused = true }
        .alert("Something went wrong", isPresented: Binding(
            get: { player.errorMessage != nil },
            set: { if !$0 { player.errorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(player.errorMessage ?? "")
        }
    }
}

/// The current artwork, heavily blurred, filling the window behind everything.
private struct ArtworkBackdrop: View {
    let artwork: Artwork?

    var body: some View {
        GeometryReader { proxy in
            if let artwork {
                let side = max(proxy.size.width, proxy.size.height)
                ArtworkImage(artwork, width: side, height: side)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .blur(radius: 60)
                    .opacity(0.45)
                    .clipped()
            }
        }
        .ignoresSafeArea()
        .animation(.smooth, value: artwork)
    }
}
