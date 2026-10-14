import MusicKit
import SwiftUI

/// Gates the app on Apple Music authorization.
struct ContentView: View {
    @State private var status = MusicAuthorization.currentStatus

    var body: some View {
        if status == .authorized {
            RootView()
        } else {
            LoginView(status: $status)
        }
    }
}
