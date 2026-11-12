import AppKit
import SwiftUI
import LaunchAtLogin

struct LyricChillSettingsView: View {
    @Environment(ViewModel.self) private var viewModel
    @StateObject private var navigationState = ModularSettingsNavigationState()
    @State private var selection: String? = Self.generalTab.id

    private static let generalTab = ModularSettingsTab(
        id: "general",
        title: "General",
        systemImage: "gearshape"
    )
    private static let karaokeTab = ModularSettingsTab(
        id: "karaoke",
        title: "Karaoke",
        systemImage: "quote.bubble"
    )
    private static let shortcutsTab = ModularSettingsTab(
        id: "shortcuts",
        title: "Shortcuts",
        systemImage: "keyboard"
    )
    private static let aboutTab = ModularSettingsTab(
        id: "about",
        title: "About",
        systemImage: "info.circle"
    )
    private static let tabs = [generalTab, karaokeTab, shortcutsTab, aboutTab]

    var body: some View {
        NavigationSplitView {
            ModularSettingsSidebar(tabs: Self.tabs, selection: $selection) {
                HStack(spacing: 12) {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundleURL.path))
                        .resizable()
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("LyricChill")
                            .font(.title3.weight(.semibold))
                        Text("Settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 12)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 205, max: 240)
        } detail: {
            detailView
        }
        .environmentObject(navigationState)
        .frame(minWidth: 820, minHeight: 600)
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection ?? "general" {
        case "karaoke":
            ModularSettingsContainer(Self.karaokeTab) {
                KaraokeSettingsView()
                    .environment(viewModel)
            }
        case "shortcuts":
            ModularSettingsContainer(Self.shortcutsTab) {
                GlobalKeyboardShortcutsView()
            }
        case "about":
            ModularSettingsContainer(Self.aboutTab) {
                LyricChillAboutSettingsView()
            }
        default:
            ModularSettingsContainer(Self.generalTab) {
                LyricChillGeneralSettingsView()
                    .environment(viewModel)
            }
        }
    }
}

private struct LyricChillGeneralSettingsView: View {
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
                    Picker("Music app", selection: $spotifyOrAppleMusic) {
                        Text("Spotify").tag(false)
                        Text("Apple Music").tag(true)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 210)
                }

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
            }

            ModularSettingsSection("Lyrics") {
                ModularSettingsRow(
                    "Primary lyric source",
                    helperText: "LyricChill tries this source first, then falls back to other available providers.",
                    keywords: ["LRCLIB", "Spotify", "NetEase", "provider"]
                ) {
                    Picker("Primary lyric source", selection: $viewModel.userDefaultStorage.lyricSourcePreference) {
                        Text("LRCLIB").tag("LRCLIB")
                        Text("Spotify").tag("Spotify")
                        Text("NetEase").tag("NetEase")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }

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

                ModularSettingsRow(
                    "Menu bar lyric length",
                    helperText: "Choose the maximum number of characters shown in the menu bar.",
                    keywords: ["truncation", "characters", "display"]
                ) {
                    Picker("Menu bar lyric length", selection: $truncationLength) {
                        ForEach([30, 40, 50, 60], id: \.self) { length in
                            Text("\(length) characters").tag(length)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
            }

            ModularSettingsSection("System") {
                ModularSettingsRow("Launch at login", keywords: ["startup", "launch"]) {
                    LaunchAtLogin.Toggle("")
                        .labelsHidden()
                }
            }
        }
        .sheet(isPresented: $showingSpotifyConnection) {
            NavigationStack {
                ApiView(onComplete: { showingSpotifyConnection = false })
            }
            .frame(minWidth: 720, minHeight: 560)
            .preferredColorScheme(.dark)
        }
    }
}

private struct LyricChillAboutSettingsView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ModularSettingsSection("About LyricChill") {
                ModularSettingsRow("Version") {
                    Text(version)
                        .foregroundStyle(.secondary)
                }

                ModularSettingsRow("Community project") {
                    Link(
                        "GitHub repository",
                        destination: URL(string: "https://github.com/gitmichaelqiu/LyricChill")!
                    )
                }

                ModularSettingsRow("Lyrics and rights") {
                    Text("Lyrics are provided by third-party services and remain the property of their respective rights holders.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 360, alignment: .trailing)
                }
            }
        }
    }
}
