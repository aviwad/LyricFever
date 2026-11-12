import AppKit
import SwiftUI
import LaunchAtLogin

struct LyricChillSettingsView: View {
    @Environment(ViewModel.self) private var viewModel
    @StateObject private var navigationState = ModularSettingsNavigationState()
    @State private var selection: String? = Self.generalTab.id
    @State private var isIndexingSettings = true

    private let settingsWindowWidth: CGFloat = 750
    private let settingsWindowHeight: CGFloat = 550
    private let titleHeaderHeight: CGFloat = 48

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
        ZStack {
            NavigationSplitView(columnVisibility: .constant(.all)) {
                ModularSettingsSidebar(tabs: Self.tabs, selection: $selection) {
                    sidebarHeader
                }
                .navigationSplitViewColumnWidth(min: 180, ideal: 180, max: 180)
            } detail: {
                detailView
            }

            if isIndexingSettings {
                ZStack {
                    LyricChillGeneralSettingsView()
                        .environment(viewModel)
                        .environment(\.modularSettingsTab, Self.generalTab)
                    KaraokeSettingsView()
                        .environment(viewModel)
                        .environment(\.modularSettingsTab, Self.karaokeTab)
                    GlobalKeyboardShortcutsView()
                        .environment(\.modularSettingsTab, Self.shortcutsTab)
                    LyricChillAboutSettingsView()
                        .environment(\.modularSettingsTab, Self.aboutTab)
                }
                .environmentObject(navigationState)
                .environment(\.isModularSettingsPreRendering, true)
                .frame(width: settingsWindowWidth, height: settingsWindowHeight)
                .opacity(0.001)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
        .environmentObject(navigationState)
        .navigationTitle("")
        .edgesIgnoringSafeArea(.top)
        .frame(width: settingsWindowWidth, height: settingsWindowHeight)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isIndexingSettings = false
            }
        }
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Color.clear.frame(height: 45)
            HStack(spacing: 10) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundleURL.path))
                    .resizable()
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

                Text("LyricChill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
            }
            .padding(.bottom, 10)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        let activeTab = Self.tabs.first { $0.id == selection } ?? Self.generalTab

        ZStack(alignment: .top) {
            tabContent(for: activeTab)
                .environmentObject(navigationState)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, titleHeaderHeight)

            VStack(spacing: 0) {
                HStack {
                    Text(String(localized: activeTab.title))
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.leading, 20)
                    Spacer()
                }
                .frame(height: titleHeaderHeight)
                .background(.bar)
                Divider()
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .edgesIgnoringSafeArea(.top)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func tabContent(for tab: ModularSettingsTab) -> some View {
        switch tab.id {
        case Self.karaokeTab.id:
            ModularSettingsContainer(Self.karaokeTab) {
                KaraokeSettingsView()
                    .environment(viewModel)
            }
        case Self.shortcutsTab.id:
            ModularSettingsContainer(Self.shortcutsTab) {
                GlobalKeyboardShortcutsView()
            }
        case Self.aboutTab.id:
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
                    Picker("Primary lyric source", selection: $viewModel.userDefaultStorage.lyricSourcePreference) {
                        Text("LRCLIB").tag("LRCLIB")
                        Text("Spotify").tag("Spotify")
                        Text("NetEase").tag("NetEase")
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 150)
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
                        .toggleStyle(.switch)
                        .frame(width: 50, alignment: .trailing)
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

                Divider()

                ModularSettingsRow("Community project") {
                    Link(
                        "GitHub repository",
                        destination: URL(string: "https://github.com/gitmichaelqiu/LyricChill")!
                    )
                }

                Divider()

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
