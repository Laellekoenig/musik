import MusicKit
import SwiftUI

/// The player stays in place; song search appears as a centered command panel.
struct HomeView: View {
    @Environment(PlayerModel.self) private var player
    @State private var isSearchPresented = false

    var body: some View {
        ZStack {
            NowPlayingView()
                .padding(28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(!isSearchPresented)
                .accessibilityHidden(isSearchPresented)

            if isSearchPresented {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .onTapGesture { isSearchPresented = false }
                    .accessibilityHidden(true)

                SongSearchView { isSearchPresented = false }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 36)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeOut(duration: 0.16), value: isSearchPresented)
        .background { ArtworkBackdrop(artwork: player.currentEntry?.artwork) }
        .focusedSceneValue(\.focusSongSearch) { isSearchPresented = true }
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
