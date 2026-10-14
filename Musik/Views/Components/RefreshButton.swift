import SwiftUI

/// The toolbar's Refresh button (⌘R). Each screen that can reload shows its
/// own; only the visible screen's toolbar is active, so the shortcut is unique.
struct RefreshButton: View {
    let action: () -> Void

    var body: some View {
        Button("Refresh", systemImage: "arrow.clockwise", action: action)
            .keyboardShortcut("r")
            .help("Refresh")
    }
}
