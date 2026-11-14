import AppKit
import SwiftUI

/// Describes one destination in a modular settings sidebar.
public struct ModularSettingsTab: Hashable, Identifiable {
    public let id: String
    public let title: LocalizedStringResource
    public let systemImage: String

    public init(
        id: String,
        title: LocalizedStringResource,
        systemImage: String
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
            && lhs.title.key == rhs.title.key
            && lhs.systemImage == rhs.systemImage
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title.key)
        hasher.combine(systemImage)
    }
}

public enum ModularSettingsPreferences {
    /// Default preference key shared by rows that show settings demo videos.
    public static let showDemoVideosKey = "ShowSettingsDemoVideos"
}

public enum ModularSettingsMetrics {
    public static let containerPadding: CGFloat = 16
    public static let sectionSpacing: CGFloat = 20
    public static let rowContentSpacing: CGFloat = 8
    public static let labelSpacing: CGFloat = 4
    public static let rowMinimumHeight: CGFloat = 24
    public static let rowVerticalPadding: CGFloat = 6
    public static let rowHorizontalPadding: CGFloat = 10
}

public struct ModularSettingsSearchItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let localizedTitle: String
    public let tabID: String
    public let keywords: [String]

    init(title: String, tabID: String, keywords: [String]) {
        self.id = "\(tabID):\(title)"
        self.title = title
        self.localizedTitle = NSLocalizedString(title, comment: "")
        self.tabID = tabID
        self.keywords = keywords
    }
}

@MainActor
public final class ModularSettingsNavigationState: ObservableObject {
    @Published public var searchText = ""
    @Published public var scrollToItemID: String?
    @Published public private(set) var registeredItems: [ModularSettingsSearchItem] = []

    private var registrationCounts = [String: Int]()

    public init() {}

    public func register(title: String, tabID: String, keywords: [String] = []) {
        let key = "\(tabID):\(title)"
        let count = registrationCounts[key, default: 0]
        registrationCounts[key] = count + 1
        guard count == 0 else { return }

        let allKeywords = keywords
            .flatMap(Self.tokens)
            + Self.tokens(title)
            + Self.tokens(NSLocalizedString(title, comment: ""))

        registeredItems.append(
            ModularSettingsSearchItem(
                title: title,
                tabID: tabID,
                keywords: Array(Set(allKeywords)).sorted()
            )
        )
    }

    public func unregister(title: String, tabID: String) {
        let key = "\(tabID):\(title)"
        let count = registrationCounts[key, default: 0]
        guard count > 1 else {
            registrationCounts[key] = nil
            registeredItems.removeAll { $0.id == key }
            return
        }
        registrationCounts[key] = count - 1
    }

    private static func tokens(_ value: String) -> [String] {
        value.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 1 }
    }
}

private struct ModularSettingsTabKey: EnvironmentKey {
    static let defaultValue = ModularSettingsTab(id: "default", title: "Settings", systemImage: "gearshape")
}

private struct ModularSettingsPreRenderingKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    var modularSettingsTab: ModularSettingsTab {
        get { self[ModularSettingsTabKey.self] }
        set { self[ModularSettingsTabKey.self] = newValue }
    }

    var isModularSettingsPreRendering: Bool {
        get { self[ModularSettingsPreRenderingKey.self] }
        set { self[ModularSettingsPreRenderingKey.self] = newValue }
    }
}

public struct ModularSettingsContainer<Content: View>: View {
    private let tab: ModularSettingsTab
    private let content: () -> Content
    @EnvironmentObject private var navigationState: ModularSettingsNavigationState

    public init(_ tab: ModularSettingsTab, @ViewBuilder content: @escaping () -> Content) {
        self.tab = tab
        self.content = content
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                content()
                    .padding(ModularSettingsMetrics.containerPadding)
            }
            .environment(\.modularSettingsTab, tab)
            .onChange(of: navigationState.scrollToItemID) { itemID in
                guard let itemID else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation { proxy.scrollTo(itemID, anchor: .center) }
                    navigationState.scrollToItemID = nil
                }
            }
        }
    }
}

public struct ModularSettingsRow<Content: View>: View {
    private let title: LocalizedStringResource
    private let leadingIcon: NSImage?
    private let helperText: LocalizedStringKey?
    private let warningText: LocalizedStringKey?
    private let requirements: [ModularSettingsRequirement]
    private let keywords: [String]
    private let demoVideoName: String?
    private let content: Content
    @AppStorage(ModularSettingsPreferences.showDemoVideosKey) private var showDemoVideos = true
    @Environment(\.modularSettingsTab) private var tab
    @Environment(\.isModularSettingsPreRendering) private var isPreRendering
    @EnvironmentObject private var navigationState: ModularSettingsNavigationState

    public init(
        _ title: LocalizedStringResource,
        leadingIcon: NSImage? = nil,
        helperText: LocalizedStringKey? = nil,
        warningText: LocalizedStringKey? = nil,
        requirements: [ModularSettingsRequirement] = [],
        keywords: [String] = [],
        demoVideoName: String? = nil,
        showDemoVideosPreferenceKey: String = ModularSettingsPreferences.showDemoVideosKey,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.leadingIcon = leadingIcon
        self.helperText = helperText
        self.warningText = warningText
        self.requirements = requirements
        self.keywords = keywords
        self.demoVideoName = demoVideoName
        self._showDemoVideos = AppStorage(wrappedValue: true, showDemoVideosPreferenceKey)
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: ModularSettingsMetrics.rowContentSpacing) {
            HStack {
                HStack(spacing: ModularSettingsMetrics.labelSpacing) {
                    if let leadingIcon {
                        Image(nsImage: leadingIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }

                    Text(modularSettingsHighlightedText(
                        text: String(localized: title),
                        query: navigationState.searchText
                    ))
                    if let helperText { ModularSettingsInfoButton(text: helperText) }
                    if let warningText { ModularSettingsWarningButton(text: warningText) }
                    ModularSettingsRequirementWarning(requirements: requirements)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                content
                    .frame(alignment: .trailing)
            }
            .frame(minHeight: ModularSettingsMetrics.rowMinimumHeight)
            if showDemoVideos,
               let demoVideoName,
               let videoURL = Bundle.main.url(forResource: demoVideoName, withExtension: "mp4") {
                ModularSettingsLoopingVideoView(videoURL: videoURL)
                    .frame(height: 180)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.top, 4)
                    .padding(.bottom, 6)
            }
        }
        .padding(.vertical, ModularSettingsMetrics.rowVerticalPadding)
        .padding(.horizontal, ModularSettingsMetrics.rowHorizontalPadding)
        .id(title.key)
        .onAppear { navigationState.register(title: title.key, tabID: tab.id, keywords: keywords) }
        .onDisappear {
            if !isPreRendering {
                navigationState.unregister(title: title.key, tabID: tab.id)
            }
        }
    }
}

/// Describes one capability required by a settings row.
public struct ModularSettingsRequirement: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let isSatisfied: Bool

    public init(id: String? = nil, name: String, isSatisfied: Bool) {
        self.id = id ?? name
        self.name = name
        self.isSatisfied = isSatisfied
    }

    public static func accessibility(isGranted: Bool) -> Self {
        Self(name: "Accessibility permission", isSatisfied: isGranted)
    }

    /// Event posting is presented under the same Accessibility permission in
    /// the macOS privacy UI, so it intentionally shares that warning label.
    public static func inputEvents(isGranted: Bool) -> Self {
        Self(name: "Accessibility permission", isSatisfied: isGranted)
    }

    public static func screenRecording(isGranted: Bool) -> Self {
        Self(name: "Screen Recording permission", isSatisfied: isGranted)
    }
}

/// Shows one warning popover containing the distinct requirements that are
/// currently unavailable for a row.
public struct ModularSettingsRequirementWarning: View {
    private let requirements: [ModularSettingsRequirement]

    public init(requirements: [ModularSettingsRequirement]) {
        self.requirements = requirements
    }

    private var missingRequirements: [ModularSettingsRequirement] {
        var seenNames = Set<String>()
        return requirements.filter { requirement in
            !requirement.isSatisfied && seenNames.insert(requirement.name).inserted
        }
    }

    private var warningText: LocalizedStringKey {
        let names = missingRequirements
            .map { NSLocalizedString($0.name, comment: "") }
            .joined(separator: ", ")
        let format = NSLocalizedString("Requires %@.", comment: "")
        return LocalizedStringKey(String(format: format, names))
    }

    public var body: some View {
        if !missingRequirements.isEmpty {
            ModularSettingsWarningButton(text: warningText)
        }
    }
}

public struct ModularSettingsSection<Content: View>: View {
    private let title: LocalizedStringKey?
    private let helperText: LocalizedStringKey?
    private let content: Content

    public init(
        _ title: LocalizedStringKey? = nil,
        helperText: LocalizedStringKey? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.helperText = helperText
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                HStack(spacing: 4) {
                    Text(title).font(.headline)
                    if let helperText { ModularSettingsInfoButton(text: helperText) }
                }
                .padding(.leading, 4)
            }
            VStack(spacing: 0) { content }
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ModularSettingsSectionStyle.backgroundColor.opacity(0.6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.regularMaterial)
                        }
                }
        }
        .padding(.top, title == nil ? -10 : 0)
    }
}

public struct ModularSettingsInfoButton: View {
    let text: LocalizedStringKey
    @State private var isPresented = false

    public init(text: LocalizedStringKey) { self.text = text }

    public var body: some View {
        Button { isPresented.toggle() } label: {
            Image(systemName: "questionmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented, arrowEdge: .top) {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(15)
                .frame(minWidth: 200, maxWidth: 300)
        }
    }
}

public struct ModularSettingsWarningButton: View {
    let text: LocalizedStringKey
    @State private var isPresented = false

    public init(text: LocalizedStringKey) { self.text = text }

    public var body: some View {
        Button { isPresented.toggle() } label: {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isPresented, arrowEdge: .top) {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(15)
                .frame(minWidth: 200, maxWidth: 300)
        }
    }
}

public func modularSettingsHighlightedText(
    text: String,
    query: String,
    color: Color? = .blue
) -> AttributedString {
    var attributed = AttributedString(text)
    guard !query.isEmpty else { return attributed }

    var searchStart = attributed.startIndex
    while searchStart < attributed.endIndex {
        let remaining = String(attributed[searchStart...].characters)
        guard let range = remaining.lowercased().range(of: query.lowercased()) else { break }
        let offset = remaining.distance(from: remaining.startIndex, to: range.lowerBound)
        let length = remaining.distance(from: range.lowerBound, to: range.upperBound)
        let start = attributed.index(searchStart, offsetByCharacters: offset)
        let end = attributed.index(start, offsetByCharacters: length)
        if let color { attributed[start..<end].foregroundColor = color }
        attributed[start..<end].inlinePresentationIntent = .stronglyEmphasized
        searchStart = end
    }
    return attributed
}
