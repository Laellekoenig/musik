import MusicKit
import SwiftUI

/// Square artwork with rounded corners, falling back to a placeholder when nil.
struct ArtworkView: View {
    let artwork: Artwork?
    var size: CGFloat
    var cornerRadius: CGFloat?
    var placeholder = "music.note"

    var body: some View {
        Group {
            if let artwork {
                ArtworkImage(artwork, width: size, height: size)
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: placeholder)
                            .font(.system(size: size * 0.4))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: cornerRadius ?? max(3, size / 8)))
    }
}

#Preview {
    ArtworkView(artwork: nil, size: 64)
        .padding()
}
