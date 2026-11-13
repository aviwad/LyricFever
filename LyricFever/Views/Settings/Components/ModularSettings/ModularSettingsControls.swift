import AppKit
import Foundation
import SwiftUI

public enum ModularSettingsSectionStyle {
    public static var dragPreviewBackgroundColor: Color {
        Color(nsColor: .underPageBackgroundColor)
    }

    /// An adaptive base tint that keeps material-backed sections legible in
    /// both appearances.
    public static var backgroundColor: Color {
        let color = NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(calibratedWhite: 0.20, alpha: 1.0)
            }
            return NSColor(calibratedWhite: 1.00, alpha: 1.0)
        }
        return Color(nsColor: color)
    }
}

public func withModularSettingsAnimation(_ action: () -> Void) {
    if #available(macOS 14.0, *) {
        withAnimation(.snappy(duration: 0.18), action)
    } else {
        withAnimation(.easeOut(duration: 0.18), action)
    }
}

public struct ModularSettingsAnimatedValue: View {
    private let text: String
    @State private var displayedText: String

    public init(text: String) {
        self.text = text
        _displayedText = State(initialValue: text)
    }

    public var body: some View {
        Text(displayedText)
            .monospacedDigit()
            .contentTransition(.numericText())
            .onChange(of: text) { newText in
                withModularSettingsAnimation {
                    displayedText = newText
                }
            }
    }
}

public struct ModularSettingsPermissionStatusIcon: View {
    private let isGranted: Bool

    public init(isGranted: Bool) {
        self.isGranted = isGranted
    }

    public var body: some View {
        Image(systemName: isGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundStyle(isGranted ? .green : .red)
            .accessibilityLabel(isGranted ? "Granted" : "Not granted")
    }
}

public struct ModularSettingsSliderRow<V>: View
where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
    private let title: LocalizedStringResource
    private let helperText: LocalizedStringKey?
    private let warningText: LocalizedStringKey?
    private let requirements: [ModularSettingsRequirement]
    private let keywords: [String]
    private let demoVideoName: String?
    private let range: ClosedRange<V>
    private let defaultValue: V
    private let step: V?
    private let valueString: (V) -> String
    @Binding private var value: V
    @AppStorage(ModularSettingsPreferences.showDemoVideosKey) private var showDemoVideos = true
    @Environment(\.modularSettingsTab) private var tab
    @Environment(\.isModularSettingsPreRendering) private var isPreRendering
    @EnvironmentObject private var navigationState: ModularSettingsNavigationState
    @State private var resetTask: Task<Void, Never>?

    public init(
        _ title: LocalizedStringResource,
        helperText: LocalizedStringKey? = nil,
        warningText: LocalizedStringKey? = nil,
        requirements: [ModularSettingsRequirement] = [],
        keywords: [String] = [],
        demoVideoName: String? = nil,
        showDemoVideosPreferenceKey: String = ModularSettingsPreferences.showDemoVideosKey,
        value: Binding<V>,
        range: ClosedRange<V>,
        defaultValue: V,
        step: V? = nil,
        valueString: @escaping (V) -> String = { String(format: "%.2f", Double($0)) }
    ) {
        self.title = title
        self.helperText = helperText
        self.warningText = warningText
        self.requirements = requirements
        self.keywords = keywords
        self.demoVideoName = demoVideoName
        self._showDemoVideos = AppStorage(wrappedValue: true, showDemoVideosPreferenceKey)
        self._value = value
        self.range = range
        self.defaultValue = defaultValue
        self.step = step
        self.valueString = valueString
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            VStack(spacing: 6) {
                HStack {
                    HStack(spacing: ModularSettingsMetrics.labelSpacing) {
                        Text(modularSettingsHighlightedText(
                            text: String(localized: title),
                            query: navigationState.searchText
                        ))
                        if let helperText {
                            ModularSettingsInfoButton(text: helperText)
                        }
                        if let warningText {
                            ModularSettingsWarningButton(text: warningText)
                        }
                        ModularSettingsRequirementWarning(requirements: requirements)
                    }

                    Spacer()

                    Button("↺") {
                        resetToDefault()
                    }
                    .help("Reset to default")
                    .disabled(abs(value - defaultValue) < 0.001)
                }

                HStack {
                    Group {
                        if let step {
                            Slider(value: animatedValueBinding, in: range, step: V.Stride(step))
                        } else {
                            Slider(value: animatedValueBinding, in: range)
                        }
                    }

                    ModularSettingsAnimatedValue(text: valueString(value))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 50, alignment: .trailing)
                }
            }

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
        .padding(.vertical, 8)
        .padding(.horizontal, ModularSettingsMetrics.rowHorizontalPadding)
        .id(title.key)
        .onAppear {
            navigationState.register(title: title.key, tabID: tab.id)
        }
        .onDisappear {
            if !isPreRendering {
                navigationState.unregister(title: title.key, tabID: tab.id)
            }
        }
    }

    private var animatedValueBinding: Binding<V> {
        Binding(
            get: { value },
            set: { newValue in
                withModularSettingsAnimation {
                    value = newValue
                }
            }
        )
    }

    private func resetToDefault() {
        resetTask?.cancel()
        let start = Double(value)
        let end = Double(defaultValue)
        resetTask = Task { @MainActor in
            let steps = 40
            let startTime = DispatchTime.now().uptimeNanoseconds
            let duration: UInt64 = 150_000_000

            for step in 1...steps {
                guard !Task.isCancelled else { return }
                let targetTime = startTime + duration * UInt64(step) / UInt64(steps)
                let currentTime = DispatchTime.now().uptimeNanoseconds
                if targetTime > currentTime {
                    try? await Task.sleep(nanoseconds: targetTime - currentTime)
                }
                guard !Task.isCancelled else { return }

                let linearProgress = Double(step) / Double(steps)
                let progress = 1 - pow(1 - linearProgress, 3)
                withModularSettingsAnimation {
                    value = V(start + (end - start) * progress)
                }
            }
            resetTask = nil
        }
    }
}

public struct ModularSettingsShortcutRow: View {
    private let title: LocalizedStringResource
    private let helperText: LocalizedStringKey?
    private let warningText: LocalizedStringKey?
    private let requirements: [ModularSettingsRequirement]
    private let keywords: [String]
    private let shortcutText: String
    private let isListening: Bool
    private let canReset: Bool
    private let onListen: () -> Void
    private let onReset: () -> Void

    public init(
        _ title: LocalizedStringResource,
        helperText: LocalizedStringKey? = nil,
        warningText: LocalizedStringKey? = nil,
        requirements: [ModularSettingsRequirement] = [],
        keywords: [String] = [],
        shortcutText: String,
        isListening: Bool = false,
        canReset: Bool = true,
        onListen: @escaping () -> Void,
        onReset: @escaping () -> Void
    ) {
        self.title = title
        self.helperText = helperText
        self.warningText = warningText
        self.requirements = requirements
        self.keywords = keywords
        self.shortcutText = shortcutText
        self.isListening = isListening
        self.canReset = canReset
        self.onListen = onListen
        self.onReset = onReset
    }

    public var body: some View {
        ModularSettingsRow(
            title,
            helperText: helperText,
            warningText: warningText,
            requirements: requirements,
            keywords: keywords
        ) {
            HStack(spacing: 8) {
                Text(shortcutText)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 8)

                Button(action: onListen) {
                    Image(systemName: "record.circle")
                }
                .buttonStyle(.plain)
                .disabled(isListening)
                .help("Record shortcut")

                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.plain)
                .disabled(!canReset)
                .help("Reset shortcut")
            }
        }
    }
}

public struct ModularSettingsReorderableRowContext {
    public let index: Int
    public let isLast: Bool

    public init(index: Int, isLast: Bool) {
        self.index = index
        self.isLast = isLast
    }
}

public struct ModularSettingsReorderableList<Item: Identifiable, RowContent: View, DragPreview: View>: View
where Item.ID == String {
    private let items: [Item]
    private let rowContent: (Item, ModularSettingsReorderableRowContext) -> RowContent
    private let dragPreview: (Item) -> DragPreview
    private let moveBefore: (String, String) -> Bool
    private let moveToEnd: (String) -> Void
    @State private var targetedItemID: String?

    public init(
        items: [Item],
        @ViewBuilder rowContent: @escaping (Item, ModularSettingsReorderableRowContext) -> RowContent,
        @ViewBuilder dragPreview: @escaping (Item) -> DragPreview,
        moveBefore: @escaping (String, String) -> Bool,
        moveToEnd: @escaping (String) -> Void
    ) {
        self.items = items
        self.rowContent = rowContent
        self.dragPreview = dragPreview
        self.moveBefore = moveBefore
        self.moveToEnd = moveToEnd
    }

    @ViewBuilder
    public var body: some View {
        if #available(macOS 27.0, *) {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    decoratedRow(
                        for: item,
                        context: ModularSettingsReorderableRowContext(
                            index: index,
                            isLast: index == items.count - 1
                        )
                    )
                }
                .reorderable()
            }
            .reorderContainer(for: Item.self) { difference in
                applyNativeReorder(difference)
            }
        } else {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                decoratedRow(
                    for: item,
                    context: ModularSettingsReorderableRowContext(
                        index: index,
                        isLast: index == items.count - 1
                    )
                )
                .draggable(item.id) {
                    dragPreview(item)
                        .background(ModularSettingsSectionStyle.dragPreviewBackgroundColor)
                }
                .dropDestination(for: String.self) { sourceIDs, _ in
                    guard let sourceID = sourceIDs.first,
                          sourceID != item.id,
                          items.contains(where: { $0.id == sourceID }) else {
                        return false
                    }
                    return moveBefore(sourceID, item.id)
                } isTargeted: { isTargeted in
                    if isTargeted {
                        targetedItemID = item.id
                    } else if targetedItemID == item.id {
                        targetedItemID = nil
                    }
                }
            }
        }
    }

    private func decoratedRow(
        for item: Item,
        context: ModularSettingsReorderableRowContext
    ) -> some View {
        rowContent(item, context)
            .contentShape(Rectangle())
            .contentShape(.dragPreview, Rectangle())
            .overlay(
                targetedItemID == item.id
                    ? Color.accentColor.opacity(0.12)
                    : Color.clear
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
    }

    @available(macOS 27.0, *)
    private func applyNativeReorder(
        _ difference: ReorderDifference<String, ReorderableSingleCollectionIdentifier>
    ) {
        guard let sourceID = difference.sources.first else { return }

        switch difference.destination.position {
        case .before(let targetID):
            _ = moveBefore(sourceID, targetID)
        case .end:
            moveToEnd(sourceID)
        }
    }
}
