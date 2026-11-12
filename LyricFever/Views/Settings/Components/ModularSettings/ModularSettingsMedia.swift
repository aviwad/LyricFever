import AVFoundation
import AVKit
import AppKit
import SwiftUI

/// Plays a bundled settings demonstration video without audio.
///
/// The view stays empty while `isModularSettingsPreRendering` is enabled, so
/// indexing settings rows does not start background players.
public struct ModularSettingsLoopingVideoView: View {
    private let videoURL: URL
    @Environment(\.isModularSettingsPreRendering) private var isPreRendering

    public init(videoURL: URL) {
        self.videoURL = videoURL
    }

    public var body: some View {
        if isPreRendering {
            Color.clear
        } else {
            ModularSettingsLoopingVideoRepresentable(videoURL: videoURL)
        }
    }
}

private struct ModularSettingsLoopingVideoRepresentable: NSViewRepresentable {
    let videoURL: URL

    func makeNSView(context: Context) -> ModularSettingsLoopingVideoNSView {
        let view = ModularSettingsLoopingVideoNSView()
        view.setupPlayer(with: videoURL)
        return view
    }

    func updateNSView(_ nsView: ModularSettingsLoopingVideoNSView, context: Context) {
        if nsView.currentURL != videoURL {
            nsView.setupPlayer(with: videoURL)
        }
    }

    static func dismantleNSView(_ nsView: ModularSettingsLoopingVideoNSView, coordinator: Coordinator) {
        nsView.cleanup()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    struct Coordinator {}
}

private final class ModularSettingsLoopingVideoNSView: NSView {
    private var looper: AVPlayerLooper?
    private var player: AVQueuePlayer?
    private(set) var currentURL: URL?

    private var playerLayer: AVPlayerLayer? {
        layer as? AVPlayerLayer
    }

    override func makeBackingLayer() -> CALayer {
        let playerLayer = AVPlayerLayer()
        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = NSColor.clear.cgColor
        return playerLayer
    }

    func setupPlayer(with url: URL) {
        cleanup()
        currentURL = url
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        let player = AVQueuePlayer()
        let looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        playerLayer?.player = player
        player.isMuted = true
        player.play()
        self.looper = looper
        self.player = player
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if let oldWindow = window {
            NotificationCenter.default.removeObserver(
                self,
                name: NSWindow.willCloseNotification,
                object: oldWindow
            )
        }
        if let newWindow {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowWillClose(_:)),
                name: NSWindow.willCloseNotification,
                object: newWindow
            )
        } else {
            cleanup()
        }
    }

    @objc private func windowWillClose(_ notification: Notification) {
        cleanup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func cleanup() {
        player?.pause()
        playerLayer?.player = nil
        looper = nil
        player = nil
        currentURL = nil
    }

    override func scrollWheel(with event: NSEvent) {
        nextResponder?.scrollWheel(with: event)
    }
}
