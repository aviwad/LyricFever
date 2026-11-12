import ApplicationServices
import AppKit
import Combine
import CoreGraphics
import Foundation

/// Shared macOS TCC permission state for settings and onboarding views.
@MainActor
public final class ModularSettingsPermissionManager: ObservableObject {
    public static let shared = ModularSettingsPermissionManager()

    @Published public private(set) var isAccessibilityGranted = false
    @Published public private(set) var isEventSynthesisGranted = false
    @Published public private(set) var isScreenCaptureGranted = false
    @Published public private(set) var isRestarting = false

    public var hasAccessibilityPermission: Bool {
        isAccessibilityGranted && isEventSynthesisGranted
    }

    public var hasEventInjectionPermission: Bool {
        hasAccessibilityPermission
    }

    public var hasAllRequiredPermissions: Bool {
        hasAccessibilityPermission && isScreenCaptureGranted
    }

    private struct PermissionSnapshot: Equatable {
        let accessibility: Bool
        let eventSynthesis: Bool
        let screenCapture: Bool
    }

    private struct ObserverRegistration {
        let center: NotificationCenter
        let token: NSObjectProtocol
    }

    private var lastSnapshot: PermissionSnapshot?
    private var notificationObservers: [ObserverRegistration] = []
    private var refreshWorkItem: DispatchWorkItem?
    private var refreshGeneration = 0
    private var refreshDeadline: Date?

    public init() {
        checkPermissions()
        installNotificationObservers()
    }

    deinit {
        refreshWorkItem?.cancel()
        for observer in notificationObservers {
            observer.center.removeObserver(observer.token)
        }
    }

    /// Reads the current state and continues polling while the permission
    /// settings are likely to be open.
    public func refresh() {
        checkPermissions()
        scheduleRefresh(duration: 90, interval: 0.5)
    }

    /// Reads all permissions without prompting the user.
    public func checkPermissions() {
        let axOptions: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false
        ]
        let snapshot = PermissionSnapshot(
            accessibility: AXIsProcessTrustedWithOptions(axOptions),
            eventSynthesis: CGPreflightPostEventAccess(),
            screenCapture: CGPreflightScreenCaptureAccess()
        )

        guard snapshot != lastSnapshot else { return }
        lastSnapshot = snapshot
        isAccessibilityGranted = snapshot.accessibility
        isEventSynthesisGranted = snapshot.eventSynthesis
        isScreenCaptureGranted = snapshot.screenCapture
    }

    public func requestAccessibilityPermission() {
        let axOptions: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        _ = AXIsProcessTrustedWithOptions(axOptions)
        _ = CGRequestPostEventAccess()
        checkPermissions()
        openSystemSettings(type: "Privacy_Accessibility")
        scheduleRefresh(duration: 90, interval: 0.5)
    }

    public func requestScreenCapturePermission() {
        _ = CGRequestScreenCaptureAccess()
        checkPermissions()
        openSystemSettings(type: "Privacy_ScreenCapture")
        scheduleRefresh(duration: 90, interval: 0.5)
    }

    public func openSystemSettings(type: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(type)") else {
            return
        }
        _ = NSWorkspace.shared.open(url)
        scheduleRefresh(duration: 90, interval: 0.5)
    }

    /// Relaunches the current application bundle after a permission change.
    public func restartApplication() {
        guard !isRestarting else { return }

        let applicationURL = Bundle.main.bundleURL.standardizedFileURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.createsNewApplicationInstance = true
        isRestarting = true

        NSWorkspace.shared.openApplication(at: applicationURL, configuration: configuration) {
            [weak self] application, error in
            DispatchQueue.main.async {
                guard error == nil, application != nil else {
                    self?.isRestarting = false
                    return
                }
                NSApp.terminate(nil)
            }
        }
    }

    private func installNotificationObservers() {
        let applicationCenter = NotificationCenter.default
        notificationObservers.append(
            ObserverRegistration(
                center: applicationCenter,
                token: applicationCenter.addObserver(
                    forName: NSApplication.didBecomeActiveNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.scheduleRefresh(duration: 4, interval: 0.25)
                    }
                }
            )
        )
        notificationObservers.append(
            ObserverRegistration(
                center: applicationCenter,
                token: applicationCenter.addObserver(
                    forName: NSApplication.didResignActiveNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.scheduleRefresh(duration: 90, interval: 0.5)
                    }
                }
            )
        )
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        notificationObservers.append(
            ObserverRegistration(
                center: workspaceCenter,
                token: workspaceCenter.addObserver(
                    forName: NSWorkspace.didActivateApplicationNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.scheduleRefresh(duration: 4, interval: 0.25)
                    }
                }
            )
        )
        notificationObservers.append(
            ObserverRegistration(
                center: workspaceCenter,
                token: workspaceCenter.addObserver(
                    forName: NSWorkspace.didTerminateApplicationNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.scheduleRefresh(duration: 4, interval: 0.25)
                    }
                }
            )
        )
        notificationObservers.append(
            ObserverRegistration(
                center: workspaceCenter,
                token: workspaceCenter.addObserver(
                    forName: NSWorkspace.didWakeNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.scheduleRefresh(duration: 10, interval: 0.5)
                    }
                }
            )
        )
    }

    private func scheduleRefresh(duration: TimeInterval, interval: TimeInterval) {
        let requestedDeadline = Date().addingTimeInterval(duration)
        if let refreshDeadline, refreshDeadline >= requestedDeadline {
            checkPermissions()
            return
        }

        refreshWorkItem?.cancel()
        refreshGeneration += 1
        let generation = refreshGeneration
        refreshDeadline = requestedDeadline
        checkPermissions()
        scheduleRefreshStep(generation: generation, interval: interval)
    }

    private func scheduleRefreshStep(generation: Int, interval: TimeInterval) {
        guard generation == refreshGeneration,
              let deadline = refreshDeadline else {
            return
        }

        let remaining = deadline.timeIntervalSinceNow
        guard remaining > 0 else {
            refreshWorkItem = nil
            refreshDeadline = nil
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self,
                  generation == self.refreshGeneration else {
                return
            }

            self.refreshWorkItem = nil
            self.checkPermissions()
            self.scheduleRefreshStep(generation: generation, interval: interval)
        }
        refreshWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + min(interval, remaining),
            execute: workItem
        )
    }
}
