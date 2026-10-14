import MusicKit
import Observation

/// Loads every result of a library request, page by page (offset + limit), and
/// publishes them as they arrive so long lists render before the rest is in.
@MainActor
@Observable
final class LibraryItems<Item: MusicLibraryRequestable> {
    private(set) var items: [Item] = []
    private(set) var isComplete = false
    private var errorMessage: String?

    /// A failure only replaces the list if nothing loaded before it.
    var state: LoadState<[Item]> {
        if let errorMessage, items.isEmpty { return .failed(errorMessage) }
        return items.isEmpty && !isComplete ? .loading : .loaded(items)
    }

    /// Whether some items are shown but more pages are still on their way.
    var isLoadingMore: Bool { !items.isEmpty && !isComplete && errorMessage == nil }

    /// Marks the items stale so the next `load` fetches them again. The current
    /// items stay up until the first new page replaces them.
    func reset() {
        isComplete = false
        errorMessage = nil
    }

    /// A no-op once complete; otherwise (re)starts from the first page, e.g.
    /// after `.task` was cancelled by navigating away mid-load, or a `reset`.
    func load(_ request: MusicLibraryRequest<Item>, pageSize: Int = 500, maxCount: Int = 25_000) async {
        guard !isComplete else { return }
        errorMessage = nil

        var request = request
        request.limit = pageSize
        var loaded: [Item] = []
        var seen = Set<MusicItemID>()
        var offset = 0

        do {
            while loaded.count < maxCount {
                try Task.checkCancellation()
                request.offset = offset
                let page = try await request.response().items
                // A superseded load mustn't overwrite the newer one's items.
                try Task.checkCancellation()
                offset += page.count
                let new = page.filter { seen.insert($0.id).inserted }
                // An empty page is the end; no new IDs guards against a request
                // that ignores `offset`.
                guard !new.isEmpty else { break }
                loaded += new
                items = loaded
            }
            // Also clears stale items when a reload comes back empty.
            items = loaded
            isComplete = true
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }
}
