import AppKit
import SwiftUI

/// A searchable settings sidebar that filters tabs and their registered settings.
///
/// The sidebar list remains scrollable while search results exceed the available
/// height. Its header and search field stay fixed above the scrolling list.
public struct ModularSettingsSidebar<Header: View>: View {
    private let tabs: [ModularSettingsTab]
    private let searchPrompt: LocalizedStringKey
    private let header: Header
    @Binding private var selection: String?
    @EnvironmentObject private var navigationState: ModularSettingsNavigationState
    @FocusState private var isSearchFieldFocused: Bool

    public init(
        tabs: [ModularSettingsTab],
        selection: Binding<String?>,
        searchPrompt: LocalizedStringKey = "Search",
        @ViewBuilder header: () -> Header
    ) {
        self.tabs = tabs
        self._selection = selection
        self.searchPrompt = searchPrompt
        self.header = header()
    }

    public var body: some View {
        List(selection: $selection) {
            sidebarContent
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .top, spacing: 0) {
            sidebarHeader
        }
        .onAppear(perform: updateSelectionForSearch)
        .onChange(of: navigationState.searchText) { _ in
            updateSelectionForSearch()
        }
        .onChange(of: navigationState.registeredItems) { _ in
            updateSelectionForSearch()
        }
        .onChange(of: tabIDs) { _ in
            updateSelectionForSearch()
        }
    }

    private var searchQuery: String {
        navigationState.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var tabIDs: [String] {
        tabs.map(\.id)
    }

    private var matchingTabs: [ModularSettingsTab] {
        guard !searchQuery.isEmpty else { return tabs }

        return tabs.filter { tab in
            let localizedTabTitle = String(localized: tab.title)
            let matchesTab = tab.id.localizedCaseInsensitiveContains(searchQuery)
                || localizedTabTitle.localizedCaseInsensitiveContains(searchQuery)
            let matchesSetting = navigationState.registeredItems.contains { item in
                item.tabID == tab.id && matches(item, query: searchQuery)
            }
            return matchesTab || matchesSetting
        }
    }

    @ViewBuilder
    private var sidebarContent: some View {
        Section {
            if matchingTabs.isEmpty {
                Text("No Results")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
                    .padding(.top, 4)
            } else {
                ForEach(matchingTabs) { tab in
                    VStack(alignment: .leading, spacing: 2) {
                        sidebarTabRow(tab)

                        ForEach(matchingItems(for: tab)) { item in
                            searchResultRow(item, in: tab)
                        }
                    }
                    .tag(tab.id)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selection == tab.id ? Color.accentColor : Color.clear)
                            .padding(.horizontal, 10)
                    )
                }
            }
        }
        .collapsible(false)
    }

    private var sidebarHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            searchField
        }
        .padding(.leading, 15)
        .padding(.trailing, 10)
        .padding(.bottom, 12)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 13))

            TextField(searchPrompt, text: $navigationState.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isSearchFieldFocused)
                .accessibilityLabel(searchPrompt)

            if !navigationState.searchText.isEmpty {
                Button {
                    navigationState.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help("Clear Search")
                .accessibilityLabel("Clear Search")
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
    }

    private func sidebarTabRow(_ tab: ModularSettingsTab) -> some View {
        let isSelected = selection == tab.id
        return Label {
            Text(String(localized: tab.title))
                .font(.system(size: 16, weight: .medium))
                .padding(.leading, 2)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        } icon: {
            Image(systemName: tab.systemImage)
                .resizable()
                .scaledToFit()
                .frame(height: 17)
                .foregroundStyle(isSelected ? Color.white : Color.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 32)
        .simultaneousGesture(TapGesture().onEnded {
            isSearchFieldFocused = false
        })
    }

    private func matchingItems(for tab: ModularSettingsTab) -> [ModularSettingsSearchItem] {
        guard !searchQuery.isEmpty else { return [] }
        return navigationState.registeredItems.filter { item in
            item.tabID == tab.id && matches(item, query: searchQuery)
        }
    }

    private func searchResultRow(
        _ item: ModularSettingsSearchItem,
        in tab: ModularSettingsTab
    ) -> some View {
        let resultColor = selection == tab.id ? Color.white : Color.secondary

        return Button {
            selection = tab.id
            navigationState.scrollToItemID = item.title
            isSearchFieldFocused = false
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 9))
                    .foregroundStyle(resultColor)
                    .padding(.leading, 12)

                Text(modularSettingsHighlightedText(
                    text: item.localizedTitle,
                    query: searchQuery,
                    color: nil
                ))
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(resultColor)
                .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 18)
        .accessibilityLabel(Text(item.localizedTitle))
        .accessibilityHint("Shows this setting")
    }

    private func matches(_ item: ModularSettingsSearchItem, query: String) -> Bool {
        item.title.localizedCaseInsensitiveContains(query)
            || item.localizedTitle.localizedCaseInsensitiveContains(query)
            || item.keywords.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    private func updateSelectionForSearch() {
        let filteredTabs = matchingTabs
        guard let selection,
              filteredTabs.contains(where: { $0.id == selection }) else {
            self.selection = filteredTabs.first?.id
            return
        }
    }
}

public extension ModularSettingsSidebar where Header == EmptyView {
    init(
        tabs: [ModularSettingsTab],
        selection: Binding<String?>,
        searchPrompt: LocalizedStringKey = "Search"
    ) {
        self.init(tabs: tabs, selection: selection, searchPrompt: searchPrompt) {
            EmptyView()
        }
    }
}
