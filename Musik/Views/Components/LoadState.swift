import SwiftUI

/// The state of a one-off async load.
enum LoadState<Value> {
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        if case .loaded(let value) = self { value } else { nil }
    }
}

extension LoadState {
    /// Runs `operation`, capturing its result or error message.
    init(catching operation: () async throws -> Value) async {
        do {
            self = .loaded(try await operation())
        } catch {
            self = .failed(error.localizedDescription)
        }
    }
}

/// Shows a spinner while loading, an inline error on failure, and `content`
/// once loaded. Empty states are up to `content`.
struct LoadStateView<Value, Content: View>: View {
    let state: LoadState<Value>
    @ViewBuilder var content: (Value) -> Content

    init(_ state: LoadState<Value>, @ViewBuilder content: @escaping (Value) -> Content) {
        self.state = state
        self.content = content
    }

    var body: some View {
        switch state {
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let value):
            content(value)
        case .failed(let message):
            ContentUnavailableView("Couldn't Load", systemImage: "exclamationmark.triangle", description: Text(message))
        }
    }
}
