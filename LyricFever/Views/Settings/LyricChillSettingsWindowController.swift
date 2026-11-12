import AppKit
import SwiftUI

@MainActor
final class LyricChillSettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = LyricChillSettingsWindowController()

    private var windowController: NSWindowController?

    func open(viewModel: ViewModel, tab: LyricChillSettingsTab = .general) {
        if let windowController, let window = windowController.window {
            configure(window)
            windowController.showWindow(nil)
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            NotificationCenter.default.post(name: .lyricChillSettingsTabRequested, object: tab)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 550),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.identifier = NSUserInterfaceItemIdentifier("LyricChillSettingsWindow")
        window.title = "LyricChill Settings"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.center()
        window.minSize = NSSize(width: 750, height: 550)
        configure(window)
        window.level = .normal
        window.contentViewController = LyricChillSettingsHostingController(
            viewModel: viewModel,
            initialTab: tab
        )

        let controller = NSWindowController(window: window)
        controller.window?.delegate = self
        windowController = controller

        controller.showWindow(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        windowController = nil
        if !ViewModel.shared.fullscreen {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func configure(_ window: NSWindow) {
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .participatesInCycle,
        ]
    }
}

private final class LyricChillSettingsHostingController: NSHostingController<AnyView> {
    init(viewModel: ViewModel, initialTab: LyricChillSettingsTab) {
        let rootView = LyricChillSettingsView(initialTab: initialTab)
            .environment(viewModel)
        super.init(rootView: AnyView(rootView))
    }

    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        preferredContentSize = NSSize(width: 750, height: 550)
    }
}
