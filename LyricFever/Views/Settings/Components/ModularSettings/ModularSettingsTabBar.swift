import SwiftUI

/// A native, horizontally scrollable tab bar for modular settings pages.
///
/// The picker stays centered while all tabs fit. When it overflows, the tab
/// group becomes horizontally scrollable and fades at both edges, matching the
/// tab bar used by the DesktopRenamer launcher. The optional add and delete
/// controls remain outside the scrolling region so they stay reachable.
public struct ModularSettingsTabBar<Item: Identifiable, TabLabel: View>: View where Item.ID: Hashable {
    private let title: LocalizedStringKey
    private let items: [Item]
    @Binding private var selection: Item.ID?
    private let fadeWidth: CGFloat
    private let barHeight: CGFloat
    private let onAdd: (() -> Void)?
    private let onDelete: ((Item) -> Void)?
    private let canDelete: (Item) -> Bool
    private let accessibilityLabel: (Item) -> String?
    private let tabLabel: (Item) -> TabLabel

    @State private var contentWidth: CGFloat = 0
    @State private var viewportWidth: CGFloat = 0
    @State private var tabBarOverflows = false

    public init(
        _ title: LocalizedStringKey = "Tabs",
        items: [Item],
        selection: Binding<Item.ID?>,
        fadeWidth: CGFloat = 32,
        barHeight: CGFloat = 36,
        onAdd: (() -> Void)? = nil,
        onDelete: ((Item) -> Void)? = nil,
        canDelete: @escaping (Item) -> Bool = { _ in true },
        accessibilityLabel: @escaping (Item) -> String? = { _ in nil },
        @ViewBuilder tabLabel: @escaping (Item) -> TabLabel
    ) {
        self.title = title
        self.items = items
        self._selection = selection
        self.fadeWidth = fadeWidth
        self.barHeight = barHeight
        self.onAdd = onAdd
        self.onDelete = onDelete
        self.canDelete = canDelete
        self.accessibilityLabel = accessibilityLabel
        self.tabLabel = tabLabel
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 8) {
            tabStrip

            if let onAdd {
                ModularSettingsTabBarIconButton(
                    systemName: "plus",
                    help: "New Tab",
                    action: onAdd
                )
            }

            if let selectedItem,
               let onDelete,
               items.count > 1,
               canDelete(selectedItem) {
                ModularSettingsTabBarIconButton(
                    systemName: "trash",
                    help: "Delete Tab",
                    role: .destructive
                ) {
                    onDelete(selectedItem)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.22), value: tabGroupID)
    }

    private var selectedItem: Item? {
        guard let selection else { return nil }
        return items.first { $0.id == selection }
    }

    private var tabGroupID: String {
        items.map { String(describing: $0.id) }.joined(separator: ":")
    }

    private var tabStrip: some View {
        ZStack {
            GeometryReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        if tabBarOverflows {
                            Color.clear.frame(width: fadeWidth)
                        }

                        nativePicker
                            .id(tabGroupID)
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                            .fixedSize(horizontal: true, vertical: false)
                            .background {
                                GeometryReader { pickerProxy in
                                    Color.clear.preference(
                                        key: ModularSettingsTabBarContentWidthKey.self,
                                        value: pickerProxy.size.width
                                    )
                                }
                            }

                        if tabBarOverflows {
                            Color.clear.frame(width: 6)
                        }
                    }
                    .frame(
                        minWidth: proxy.size.width,
                        alignment: tabBarOverflows ? .leading : .center
                    )
                    .frame(height: barHeight, alignment: .center)
                }
                .scrollIndicators(.hidden)
                .mask(tabBarMask)
            }
        }
        .frame(height: barHeight)
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ModularSettingsTabBarViewportWidthKey.self,
                    value: proxy.size.width
                )
            }
        }
        .onPreferenceChange(ModularSettingsTabBarContentWidthKey.self) { width in
            contentWidth = width
            tabBarOverflows = width > viewportWidth + 0.5
        }
        .onPreferenceChange(ModularSettingsTabBarViewportWidthKey.self) { width in
            viewportWidth = width
            tabBarOverflows = contentWidth > width + 0.5
        }
    }

    private var tabBarMask: some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [.clear, .black],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: fadeWidth)

            Rectangle()
                .fill(Color.black)

            LinearGradient(
                colors: [.black, .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: fadeWidth)
        }
    }

    @ViewBuilder
    private var nativePicker: some View {
        if #available(macOS 27.0, *) {
            Picker(title, selection: $selection) {
                pickerOptions
            }
            .labelsHidden()
            .pickerStyle(.tabs)
            .controlSize(.large)
        } else {
            Picker(title, selection: $selection) {
                pickerOptions
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.large)
        }
    }

    @ViewBuilder
    private var pickerOptions: some View {
        ForEach(items) { item in
            if let label = accessibilityLabel(item) {
                tabLabel(item)
                    .lineLimit(1)
                    .accessibilityLabel(Text(label))
                    .tag(Optional(item.id))
            } else {
                tabLabel(item)
                    .lineLimit(1)
                    .tag(Optional(item.id))
            }
        }
    }
}

/// Keeps tab selection stable when the selected item is removed.
public enum ModularSettingsTabBarSelection {
    /// Selects the preceding item after deleting the selected tab, or the new
    /// first item when deleting the first tab. Deleting another tab preserves
    /// the current selection.
    public static func selectionAfterRemoving<ID: Hashable>(
        _ removedID: ID,
        from orderedIDs: [ID],
        selectedID: ID?
    ) -> ID? {
        guard selectedID == removedID else { return selectedID }
        guard let removedIndex = orderedIDs.firstIndex(of: removedID) else {
            return orderedIDs.first
        }

        var remainingIDs = orderedIDs
        remainingIDs.remove(at: removedIndex)
        guard !remainingIDs.isEmpty else { return nil }

        return remainingIDs[max(removedIndex - 1, 0)]
    }
}

private struct ModularSettingsTabBarIconButton: View {
    let systemName: String
    let help: LocalizedStringKey
    var role: ButtonRole?
    let action: () -> Void

    init(
        systemName: String,
        help: LocalizedStringKey,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.help = help
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .frame(width: 32, height: 32)
        .help(help)
        .accessibilityLabel(help)
    }
}

private struct ModularSettingsTabBarContentWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ModularSettingsTabBarViewportWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
