import Foundation
import MusicKit
import Observation

@MainActor
@Observable
final class AppleMusicAuthManager {
    static let shared = AppleMusicAuthManager()

    private(set) var status: MusicAuthorization.Status = .notDetermined
    private(set) var hasShownDeniedToast: Bool = false

    private init() {
        self.status = MusicAuthorization.currentStatus
    }

    var isAuthorized: Bool { status == .authorized }

    /// Show the system prompt. Call from `AppleMusicAuthView`.
    func requestAuthorization() async {
        let result = await MusicAuthorization.request()
        self.status = result
    }

    /// Called when a MusicDataRequest returns a 401/403 — re-prompts next track.
    func invalidate() {
        self.status = .notDetermined
        self.hasShownDeniedToast = false
    }

    /// Called by the toast UI once.
    func markDeniedToastShown() {
        self.hasShownDeniedToast = true
    }
}
