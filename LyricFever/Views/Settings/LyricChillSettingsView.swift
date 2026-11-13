import SwiftUI

enum LyricChillSettingsTab: String, CaseIterable, Identifiable {
    case general
    case karaoke
    case shortcuts
    case about

    var id: String { rawValue }

    var localizedName: LocalizedStringResource {
        switch self {
        case .general: "General"
        case .karaoke: "Karaoke"
        case .shortcuts: "Shortcuts"
        case .about: "About"
        }
    }

    var iconName: String {
        switch self {
        case .general: "gearshape"
        case .karaoke: "quote.bubble"
        case .shortcuts: "keyboard"
        case .about: "info.circle"
        }
    }

    var modularTab: ModularSettingsTab {
        ModularSettingsTab(id: id, title: localizedName, systemImage: iconName)
    }
}
extension Notification.Name {
    static let lyricChillSettingsTabRequested = Notification.Name("LyricChill.settingsTabRequested")
}

private let settingsSidebarWidth: CGFloat = 180
private let settingsWindowWidth: CGFloat = 750
private let settingsWindowHeight: CGFloat = 550
private let settingsSidebarRowHeight: CGFloat = 32
private let settingsSidebarFontSize: CGFloat = 16
private let settingsTitleHeaderHeight: CGFloat = 48

struct LyricChillSettingsView: View {
    @Environment(ViewModel.self) private var viewModel
    @StateObject private var navigationState = ModularSettingsNavigationState()
    @State private var selectedTab: LyricChillSettingsTab? = .general
    @State private var searchText = ""
    @State private var isIndexingSettings = true
    @FocusState private var isSearchFieldFocused: Bool

    init(initialTab: LyricChillSettingsTab = .general) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: .constant(.all)) {
                sidebar
            } detail: {
                detailView
            }

            if isIndexingSettings {
                ZStack {
                    LyricChillGeneralSettingsView()
                        .environment(viewModel)
                        .environment(\.modularSettingsTab, LyricChillSettingsTab.general.modularTab)
                    KaraokeSettingsView()
                        .environment(viewModel)
                        .environment(\.modularSettingsTab, LyricChillSettingsTab.karaoke.modularTab)
                    GlobalKeyboardShortcutsView()
                        .environment(\.modularSettingsTab, LyricChillSettingsTab.shortcuts.modularTab)
                    LyricChillAboutSettingsView()
                        .environment(\.modularSettingsTab, LyricChillSettingsTab.about.modularTab)
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
        .onChange(of: searchText) { _, newValue in
            navigationState.searchText = newValue
            guard !newValue.isEmpty else { return }
            let tabs = filteredTabs
            if let selectedTab, !tabs.contains(selectedTab) {
                self.selectedTab = tabs.first
            } else if selectedTab == nil {
                selectedTab = tabs.first
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .lyricChillSettingsTabRequested)) { notification in
            clearSearchFocus()
            guard let tab = notification.object as? LyricChillSettingsTab else { return }
            searchText = ""
            selectedTab = tab
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isIndexingSettings = false
            }
        }
    }

    private var filteredTabs: [LyricChillSettingsTab] {
        guard !searchText.isEmpty else { return LyricChillSettingsTab.allCases }
        let query = searchText.lowercased()
        return LyricChillSettingsTab.allCases.filter { tab in
            let matchesTabName = tab.rawValue.lowercased().contains(query)
                || String(localized: tab.localizedName).lowercased().contains(query)
            let matchesSetting = navigationState.registeredItems.contains { item in
                item.tabID == tab.id && (
                    item.title.lowercased().contains(query)
                        || item.localizedTitle.lowercased().contains(query)
                        || item.keywords.contains { $0.lowercased().contains(query) }
                )
            }
            return matchesTabName || matchesSetting
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 13))

            TextField("Search", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .focused($isSearchFieldFocused)
                .onExitCommand(perform: clearSearchFocus)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.leading, -4)
        .padding(.trailing, 10)
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Color.clear.frame(height: 45)
            HStack(spacing: 10) {
                Image("LyricChillLogo")
                    .resizable()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("LyricChill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.bottom, 10)

            searchField
                .padding(.bottom, 12)
        }
        .padding(.leading, 15)
        .padding(.trailing, 2)
    }

    @ViewBuilder
    private var sidebarContent: some View {
        Section {
            if filteredTabs.isEmpty {
                Text("No results")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
                    .padding(.top, 4)
            } else {
                ForEach(filteredTabs) { tab in
                    VStack(alignment: .leading, spacing: 2) {
                        sidebarItem(for: tab)

                        if !searchText.isEmpty {
                            let matchingItems = navigationState.registeredItems.filter { item in
                                item.tabID == tab.id && (
                                    item.title.localizedCaseInsensitiveContains(searchText)
                                        || item.localizedTitle.localizedCaseInsensitiveContains(searchText)
                                        || item.keywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
                                )
                            }

                            ForEach(matchingItems) { item in
                                let resultColor = selectedTab == tab ? Color.white : Color.secondary

                                Button {
                                    selectedTab = tab
                                    navigationState.scrollToItemID = item.title
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.turn.down.right")
                                            .font(.system(size: 9))
                                            .foregroundColor(resultColor)
                                            .padding(.leading, 12)

                                        Text(modularSettingsHighlightedText(
                                            text: item.localizedTitle,
                                            query: searchText,
                                            color: nil
                                        ))
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(resultColor)
                                        .lineLimit(1)
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(height: 18)
                                .simultaneousGesture(TapGesture().onEnded { _ in clearSearchFocus() })
                            }
                        }
                    }
                    .tag(tab)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                            .padding(.horizontal, 10)
                    )
                }
            }
        }
        .collapsible(false)
    }

    private var sidebar: some View {
        List(selection: $selectedTab) {
            sidebarContent
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top, spacing: 0) {
            sidebarHeader
        }
        .edgesIgnoringSafeArea(.top)
        .navigationSplitViewColumnWidth(min: settingsSidebarWidth, ideal: settingsSidebarWidth)
    }

    @ViewBuilder
    private var detailView: some View {
        let activeTab = selectedTab ?? filteredTabs.first ?? .general

        ZStack(alignment: .top) {
            tabContent(for: activeTab)
                .environmentObject(navigationState)
                .environment(\.modularSettingsTab, activeTab.modularTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, settingsTitleHeaderHeight)

            VStack(spacing: 0) {
                HStack {
                    Text(String(localized: activeTab.localizedName))
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.leading, 20)
                    Spacer()
                }
                .frame(height: settingsTitleHeaderHeight)
                .background(.bar)
                Divider()
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .edgesIgnoringSafeArea(.top)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { _ in clearSearchFocus() })
    }

    @ViewBuilder
    private func sidebarItem(for tab: LyricChillSettingsTab) -> some View {
        NavigationLink(value: tab) {
            Label {
                Text(String(localized: tab.localizedName))
                    .font(.system(size: settingsSidebarFontSize, weight: .medium))
                    .padding(.leading, 2)
                    .foregroundStyle(selectedTab == tab ? Color.white : Color.primary)
            } icon: {
                Image(systemName: tab.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: settingsSidebarRowHeight - 15)
                    .foregroundStyle(selectedTab == tab ? Color.white : Color.accentColor)
            }
        }
        .frame(height: settingsSidebarRowHeight)
        .simultaneousGesture(TapGesture().onEnded { _ in clearSearchFocus() })
    }

    @ViewBuilder
    private func tabContent(for tab: LyricChillSettingsTab) -> some View {
        switch tab {
        case .general:
            ModularSettingsContainer(tab.modularTab) {
                LyricChillGeneralSettingsView().environment(viewModel)
            }
        case .karaoke:
            ModularSettingsContainer(tab.modularTab) {
                KaraokeSettingsView().environment(viewModel)
            }
        case .shortcuts:
            ModularSettingsContainer(tab.modularTab) {
                GlobalKeyboardShortcutsView()
            }
        case .about:
            ModularSettingsContainer(tab.modularTab) {
                LyricChillAboutSettingsView()
            }
        }
    }

    private func clearSearchFocus() {
        DispatchQueue.main.async {
            isSearchFieldFocused = false
        }
    }
}
