import LaunchAtLogin
import SwiftUI

struct LyricChillGeneralSettingsView: View {
    @Environment(ViewModel.self) private var viewModel
    @Environment(\.openWindow) private var openWindow
    @State private var showingSpotifyConnection = false
    @AppStorage("spotifyOrAppleMusic") private var spotifyOrAppleMusic = false
    @AppStorage("truncationLength") private var truncationLength = 40

    var body: some View {
        @Bindable var viewModel = viewModel
        let playerIsAuthorized = viewModel.currentPlayerInstance.isAuthorized

        VStack(alignment: .leading, spacing: 20) {
            ModularSettingsSection("Playback") {
                ModularSettingsRow(
                    "Music app",
                    helperText: "Choose the app LyricChill reads playback information from.",
                    keywords: ["Spotify", "Apple Music", "player"]
                ) {
                    Picker("", selection: $spotifyOrAppleMusic) {
                        Text("Spotify").tag(false)
                        Text("Apple Music").tag(true)
                    }
                    .labelsHidden()
                }

                Divider()

                ModularSettingsRow(
                    "Player access",
                    helperText: "LyricChill needs permission to read the selected music app's playback state.",
                    warningText: playerIsAuthorized ? nil : "Open setup to grant or check access for the selected music app.",
                    keywords: ["permission", "authorization"]
                ) {
                    HStack(spacing: 10) {
                        ModularSettingsPermissionStatusIcon(isGranted: playerIsAuthorized)
                        Text(playerIsAuthorized ? "Ready" : "Setup required")
                            .foregroundStyle(.secondary)
                        Button("Open Setup") {
                            openWindow(id: "onboarding")
                        }
                    }
                }

                Divider()
            }

            ModularSettingsSection("Lyrics") {
                ModularSettingsRow(
                    "Primary lyric source",
                    helperText: "LyricChill tries this source first, then falls back to other available providers.",
                    keywords: ["LRCLIB", "Spotify", "NetEase", "provider"]
                ) {
                    Picker("", selection: $viewModel.userDefaultStorage.lyricSourcePreference) {
                        Text("LRCLIB").tag("LRCLIB")
                        Text("Spotify").tag("Spotify")
                        Text("NetEase").tag("NetEase")
                    }
                    .labelsHidden()
                }

                Divider()

                ModularSettingsRow(
                    "Spotify lyrics",
                    helperText: "Spotify login is optional. LRCLIB and NetEase work without a Spotify account.",
                    keywords: ["login", "account", "cookie", "connect"]
                ) {
                    HStack(spacing: 10) {
                        Text(viewModel.userDefaultStorage.cookie.isEmpty ? "Not connected" : "Connected")
                            .foregroundStyle(.secondary)
                        Button("Manage") {
                            showingSpotifyConnection = true
                        }
                    }
                }

                Divider()

                ModularSettingsRow(
                    "Menu bar lyric length",
                    helperText: "Choose the maximum number of characters shown in the menu bar.",
                    keywords: ["truncation", "characters", "display"]
                ) {
                    Picker("", selection: $truncationLength) {
                        ForEach([30, 40, 50, 60], id: \.self) { length in
                            Text("\(length) characters").tag(length)
                        }
                    }
                    .labelsHidden()
                }
            }

            ModularSettingsSection("System") {
                ModularSettingsRow("Launch at login", keywords: ["startup", "launch"]) {
                    LaunchAtLogin.Toggle("")
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showingSpotifyConnection) {
            NavigationStack {
                ApiView(onComplete: { showingSpotifyConnection = false })
            }
            .frame(minWidth: 720, minHeight: 560)
            .preferredColorScheme(.dark)
        }
    }
}
