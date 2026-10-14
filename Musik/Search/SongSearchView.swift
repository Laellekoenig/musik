import MusicKit
import SwiftUI

/// A search field for Apple Music songs with the results below it. Driven
/// from the keyboard: ↑/↓ pick a result, Return plays it, Esc closes.
struct SongSearchView: View {
    @Environment(PlayerModel.self) private var player
    @FocusState.Binding var isFocused: Bool
    @Binding var query: String

    @State private var results: [Song] = []
    @State private var highlighted: Song.ID?
    @State private var errorMessage: String?

    private var term: String {
        query.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        VStack(spacing: 12) {
            field
            if !term.isEmpty {
                resultsList
            }
        }
        .task(id: term) { await search() }
    }

    private var field: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search songs", text: $query)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit(playHighlighted)
                .onKeyPress(.downArrow) { moveHighlight(by: 1) }
                .onKeyPress(.upArrow) { moveHighlight(by: -1) }
                .onExitCommand(perform: close)

            if !query.isEmpty {
                Button("Clear", systemImage: "xmark.circle.fill", action: close)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            } else if !isFocused {
                Text("⌘N")
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.title3)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: .rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isFocused ? AnyShapeStyle(.tint) : AnyShapeStyle(.separator), lineWidth: isFocused ? 2 : 1)
        }
        .frame(maxWidth: 480)
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
            .background(.regularMaterial, in: .rect(cornerRadius: 10))
            .frame(maxWidth: 480)
            .onChange(of: highlighted) {
                if let highlighted { proxy.scrollTo(highlighted) }
            }
        }
    }

    @ViewBuilder
    private var overlay: some View {
        if let errorMessage {
            ContentUnavailableView("Search Failed", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
        } else if results.isEmpty {
            ProgressView()
        }
    }

    private func search() async {
        let term = term
        guard !term.isEmpty else {
            results = []
            errorMessage = nil
            return
        }

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
            errorMessage = results.isEmpty ? "No songs match “\(term)”." : nil
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
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
        close()
    }

    private func close() {
        query = ""
        isFocused = false
    }
}
