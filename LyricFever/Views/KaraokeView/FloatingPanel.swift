//
//  FloatingPanel.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2024-10-29.
//

// Taken from the Cindori blog, updated to fit my needs

import SwiftUI

extension View {
    func floatingPanel<Content: View>(isPresented: Binding<Bool>,
                                      contentRect: CGRect = CGRect(x: 0, y: 0, width: 800, height: 100),
                                      @ViewBuilder content: @escaping () -> Content) -> some View {
        self.modifier(FloatingPanelModifier(isPresented: isPresented, contentRect: contentRect, view: content))
    }
}

struct FloatingPanelModifier<PanelContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var contentRect: CGRect
    @ViewBuilder let view: () -> PanelContent
    @State var panel: FloatingPanel<PanelContent>?
 
    func body(content: Content) -> some View {
        content
            .onAppear {
                panel = FloatingPanel(view: view, contentRect: contentRect, isPresented: $isPresented)
                if panel?.restorePosition() != true {
                    panel?.center()
                }
                if isPresented {
                    present()
                }
            }.onDisappear {
                panel?.close()
                panel = nil
            }.onChange(of: isPresented) {
                if isPresented {
                    panel?.orderFront(nil)
                    panel?.fadeIn()
                } else {
                    panel?.fadeOut()
                }
            }
            .onChange(of: ViewModel.shared.userDefaultStorage.karaoke) {
                if !ViewModel.shared.userDefaultStorage.karaoke {
                    panel?.close()
                }
            }
    }
 
    func present() {
        panel?.orderFront(nil)
        panel?.fadeIn()
    }
}

private struct FloatingPanelKey: EnvironmentKey {
    static let defaultValue: NSPanel? = nil
}
 
extension EnvironmentValues {
    var floatingPanel: NSPanel? {
        get { self[FloatingPanelKey.self] }
        set { self[FloatingPanelKey.self] = newValue }
    }
}

class FloatingPanel<Content: View>: NSPanel {
    private static var savedOriginDefaultsKey: String { "karaokeWindowOrigin" }
    @Binding var isPresented: Bool
    private var isSnappedToCenter: Bool = false
    private let snapThreshold: CGFloat = 25.0
    private var dragStartMouseLocation: NSPoint?
    private var dragStartWindowOrigin: NSPoint?

    init(view: () -> Content,
             contentRect: NSRect,
             backing: NSWindow.BackingStoreType = .buffered,
             defer flag: Bool = false,
             isPresented: Binding<Bool>) {
        self._isPresented = isPresented
     
        super.init(contentRect: contentRect,
                   styleMask: [.nonactivatingPanel, .fullSizeContentView, .closable],
                   backing: .buffered,
                   defer: true)
     
        isFloatingPanel = true
        level = .mainMenu
     
        collectionBehavior.insert(.canJoinAllSpaces)
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        backgroundColor = NSColor.clear
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        contentView = NSHostingView(rootView: view()
            .environment(\.floatingPanel, self))
        hasShadow = false
    }
    
    override func resignMain() {
        super.resignMain()
    }
    
    func fadeIn() {
        self.alphaValue = 0.0
        self.animator().alphaValue = 1.0
    }
    
    func fadeOut() {
        NSAnimationContext.runAnimationGroup { animation in
            animation.duration = 0.1
            self.animator().alphaValue = 0.0
        }
    }
    
     
    override func close() {
        savePosition()
        NSAnimationContext.runAnimationGroup { animation in
            animation.completionHandler = {
                super.close()
            }
            self.animator().alphaValue = 0.0
        }
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    override func center() {
        guard let rect = (self.screen ?? NSScreen.main)?.visibleFrame else { return }
        self.setFrameOrigin(NSPoint(
            x: rect.minX + (rect.width - self.frame.width) / 2,
            y: rect.minY + (rect.height - self.frame.height) / 5
        ))
    }

    @discardableResult
    func restorePosition() -> Bool {
        guard let savedOrigin = UserDefaults.standard.array(forKey: Self.savedOriginDefaultsKey) as? [Double],
              savedOrigin.count == 2 else {
            return false
        }

        var restoredFrame = frame
        restoredFrame.origin = NSPoint(x: savedOrigin[0], y: savedOrigin[1])

        let screenAndOverlap = NSScreen.screens.map { screen in
            let intersection = screen.visibleFrame.intersection(restoredFrame)
            let overlapArea = max(0, intersection.width) * max(0, intersection.height)
            return (screen, overlapArea)
        }
        guard let (screen, overlapArea) = screenAndOverlap.max(by: { $0.1 < $1.1 }), overlapArea > 0 else {
            return false
        }

        let visibleFrame = screen.visibleFrame
        let maxX = max(visibleFrame.minX, visibleFrame.maxX - frame.width)
        let maxY = max(visibleFrame.minY, visibleFrame.maxY - frame.height)
        let x = min(max(restoredFrame.minX, visibleFrame.minX), maxX)
        let y = min(max(restoredFrame.minY, visibleFrame.minY), maxY)
        setFrameOrigin(NSPoint(x: x, y: y))
        return true
    }

    private func savePosition() {
        UserDefaults.standard.set(
            [Double(frame.origin.x), Double(frame.origin.y)],
            forKey: Self.savedOriginDefaultsKey
        )
    }

    override func sendEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            dragStartMouseLocation = NSEvent.mouseLocation
            dragStartWindowOrigin = self.frame.origin
            super.sendEvent(event)
        case .leftMouseDragged:
            guard let startMouse = dragStartMouseLocation,
                  let startOrigin = dragStartWindowOrigin else {
                super.sendEvent(event)
                return
            }
            let currentMouse = NSEvent.mouseLocation
            let deltaX = currentMouse.x - startMouse.x
            let deltaY = currentMouse.y - startMouse.y
            var newOrigin = NSPoint(x: startOrigin.x + deltaX, y: startOrigin.y + deltaY)

            if let screenFrame = (self.screen ?? NSScreen.main)?.frame {
                let windowCenterX = newOrigin.x + self.frame.width / 2
                let distanceFromCenter = abs(windowCenterX - screenFrame.midX)
                if distanceFromCenter <= snapThreshold {
                    let snappedOriginX = screenFrame.minX + (screenFrame.width - self.frame.width) / 2
                    if !isSnappedToCenter {
                        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                        isSnappedToCenter = true
                    }
                    newOrigin.x = snappedOriginX
                } else {
                    isSnappedToCenter = false
                }
            }

            self.setFrameOrigin(newOrigin)
            // Don't call super — AppKit would otherwise also try to move the window
        case .leftMouseUp:
            dragStartMouseLocation = nil
            dragStartWindowOrigin = nil
            isSnappedToCenter = false
            savePosition()
            super.sendEvent(event)
        default:
            super.sendEvent(event)
        }
    }
}
