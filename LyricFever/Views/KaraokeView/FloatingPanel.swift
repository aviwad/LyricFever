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
                panel?.center()
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
            .onChange(of: viewModel.shared.karaoke) {
                if !viewModel.shared.karaoke {
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
    @Binding var isPresented: Bool
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
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        backgroundColor = NSColor.clear
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        contentView = NSHostingView(rootView: view()
        .preferredColorScheme(.dark)
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
        let rect = self.screen?.frame
        self.setFrameOrigin(NSPoint(x: (rect!.width - self.frame.width)/2, y: (rect!.height - self.frame.height)/5))
    }
}
