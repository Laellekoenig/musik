import MusicKit
import SwiftUI

/// A floating search panel: ↑/↓ pick a result, Return plays it, Esc closes.
struct SongSearchView: View {
    @Environment(PlayerModel.self) private var player
    let onClose: () -> Void

    @FocusState private var isFocused: Bool
    @State private var query = ""
    @State private var results: [Song] = []
    @State private var highlighted: Song.ID?
    @State private var errorMessage: String?
    @State private var isLoading = false

    private var term: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            field
            if !term.isEmpty {
                Divider()
                resultsList
            }
        }
        .frame(maxWidth: 480)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.separator, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
        .accessibilityAddTraits(.isModal)
        .onExitCommand(perform: onClose)
        .task { isFocused = true }
        .task(id: term) { await search() }
    }

    private var field: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search songs", text: $query)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit(playHighlighted)
                .onKeyPress(.downArrow) { moveHighlight(by: 1) }
                .onKeyPress(.upArrow) { moveHighlight(by: -1) }

            if !query.isEmpty {
                Button("Clear Search", systemImage: "xmark.circle.fill") {
                    query = ""
                    isFocused = true
                }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }

            Button(action: onClose) {
                Text("esc")
                    .font(.caption)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: .rect(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Close Search")
        }
        .font(.title3)
        .padding(16)
    }

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(results) { song in
                        Button {
                            play(song)
                        } label: {
                            TrackRow(song, isCurrent: player.isCurrent(song))
                                .padding(.horizontal, 8)
                                .background(
                                    song.id == highlighted ? AnyShapeStyle(.selection) : AnyShapeStyle(.clear),
                                    in: .rect(cornerRadius: 6)
                                )
                        }
                        .buttonStyle(.plain)
                        .id(song.id)
                    }
                }
                .padding(6)
            }
            .overlay { overlay }
            .frame(height: results.isEmpty ? 180 : min(CGFloat(results.count) * 56 + 12, 336))
            .onChange(of: highlighted) {
                if let highlighted { proxy.scrollTo(highlighted) }
            }
        }
    }

    @ViewBuilder
    private var overlay: some View {
        if let errorMessage {
            ContentUnavailableView("Search Failed", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
        } else if isLoading {
            ProgressView()
        } else if results.isEmpty {
            ContentUnavailableView.search(text: term)
        }
    }

    private func search() async {
        let term = term
        results = []
        highlighted = nil
        errorMessage = nil
        isLoading = !term.isEmpty
        guard !term.isEmpty else { return }

        // Debounce: a new keystroke cancels this task before the request fires.
        try? await Task.sleep(for: .milliseconds(250))
        guard !Task.isCancelled else { return }

        do {
            var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
            request.limit = 25
            let response = try await request.response()
            guard !Task.isCancelled else { return }
            results = Array(response.songs)
            highlighted = results.first?.id
            isLoading = false
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func moveHighlight(by offset: Int) -> KeyPress.Result {
        guard !results.isEmpty else { return .ignored }
        let index = results.firstIndex { $0.id == highlighted } ?? -offset
        highlighted = results[min(max(index + offset, 0), results.count - 1)].id
        return .handled
    }

    private func playHighlighted() {
        if let song = results.first(where: { $0.id == highlighted }) {
            play(song)
        }
    }

    /// Queues all results so next/previous move through them, then closes the
    /// search to bring the player back into view.
    private func play(_ song: Song) {
        player.play(results, startingAt: song)
        onClose()
    }
}
