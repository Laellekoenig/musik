import SwiftUI

/// File › Search Songs (⌘N), in place of New Window: the app is one window.
struct SearchCommands: Commands {
    @FocusedValue(\.focusSongSearch) private var focusSongSearch

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Search Songs") { focusSongSearch?() }
                .keyboardShortcut("n")
                .disabled(focusSongSearch == nil)
        }
    }
}

private struct FocusSongSearchKey: FocusedValueKey {
    typealias Value = () -> Void
}

extension FocusedValues {
    /// Focuses the search field of the key window, published by `HomeView`.
    var focusSongSearch: (() -> Void)? {
        get { self[FocusSongSearchKey.self] }
        set { self[FocusSongSearchKey.self] = newValue }
    }
}
