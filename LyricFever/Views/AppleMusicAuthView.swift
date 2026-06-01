import SwiftUI
import MusicKit

struct AppleMusicAuthView: View {
    @Environment(\.dismiss) private var dismiss
    let authManager: AppleMusicAuthManager

    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 48))
                .foregroundStyle(.pink)

            Text("Connect Apple Music")
                .font(.title2.weight(.semibold))

            Text("LyricFever can fetch synced lyrics directly from Apple Music for songs in the catalog. This is far more accurate than third-party sources for recent releases.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            Text("Sign-in happens once and is stored by macOS in Keychain.")
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack {
                Button("Not now") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    isRequesting = true
                    Task {
                        await authManager.requestAuthorization()
                        isRequesting = false
                        dismiss()
                    }
                } label: {
                    if isRequesting {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Text("Connect")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(isRequesting)
            }
            .padding(.top, 12)
        }
        .padding(28)
        .frame(width: 380)
    }
}
