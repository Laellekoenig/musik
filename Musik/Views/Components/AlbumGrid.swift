import MusicKit
import SwiftUI

/// An adaptive grid of album cards that push `AlbumDetailView` when clicked.
/// Not scrollable itself, so it can sit in a `ScrollView` below other content.
struct AlbumGrid<Albums: RandomAccessCollection>: View where Albums.Element == Album {
    let albums: Albums

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: AlbumCard.defaultSize), spacing: 20, alignment: .top)], spacing: 24) {
            ForEach(albums) { album in
                MusicItemLink(album) {
                    AlbumCard(album)
                }
            }
        }
        .padding()
    }
}

/// Artwork with a title and subtitle underneath, for albums, playlists and stations.
struct AlbumCard: View {
    static let defaultSize: CGFloat = 160

    let artwork: Artwork?
    let title: String
    var subtitle: String?
    var size = AlbumCard.defaultSize

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ArtworkView(artwork: artwork, size: size, cornerRadius: 6)
                .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                .padding(.bottom, 4)

            Text(title)
                .lineLimit(1)
            if let subtitle {
                Text(subtitle)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: size, alignment: .leading)
        .contentShape(.rect)
        .help(title)
    }
}

extension AlbumCard {
    init(_ album: Album, size: CGFloat = AlbumCard.defaultSize) {
        self.init(artwork: album.artwork, title: album.title, subtitle: album.artistName, size: size)
    }

    init(_ playlist: Playlist, size: CGFloat = AlbumCard.defaultSize) {
        self.init(artwork: playlist.artwork, title: playlist.name, subtitle: playlist.curatorName, size: size)
    }

    init(_ item: RecentlyPlayedMusicItem, size: CGFloat = AlbumCard.defaultSize) {
        self.init(artwork: item.artwork, title: item.title, subtitle: item.subtitle, size: size)
    }
}

#Preview {
    HStack(alignment: .top) {
        AlbumCard(artwork: nil, title: "Album Title", subtitle: "Artist")
        AlbumCard(artwork: nil, title: "A Very Long Album Title That Truncates")
    }
    .padding()
}
