import MusicKit
import SwiftUI

struct ContentView: View {
    @State private var status = MusicAuthorization.currentStatus

    var body: some View {
        if status == .authorized {
            SearchView()
        } else {
            LoginView(status: $status)
        }
    }
}

/// MusicKit has no separate sign-in form on macOS: it uses the Apple Account
/// the user is signed into in the Music app, and asks them to grant access.
struct LoginView: View {
    @Binding var status: MusicAuthorization.Status

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.tint)

            Text("Musik")
                .font(.largeTitle.bold())

            if status == .notDetermined {
                Text("Connect your Apple Music account to search and play songs.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button("Continue with Apple Music") {
                    Task { status = await MusicAuthorization.request() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Text("Musik doesn't have access to Apple Music. Allow it in System Settings › Privacy & Security › Media & Apple Music, then reopen Musik.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button("Open System Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Media")!)
                }
                .controlSize(.large)
            }
        }
        .padding(40)
        .frame(maxWidth: 420)
    }
}

#Preview {
    LoginView(status: .constant(.notDetermined))
}
