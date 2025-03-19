//
//  FloatingPanel.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2024-10-29.
//

// Taken from the Cindori blog, updated to fit my needs

import SwiftUI

extension View {
    /** Present a ``FloatingPanel`` in SwiftUI fashion
     - Parameter isPresented: A boolean binding that keeps track of the panel's presentation state
     - Parameter contentRect: The initial content frame of the window
     - Parameter content: The displayed content
     **/
    func floatingPanel<Content: View>(isPresented: Binding<Bool>,
                                      contentRect: CGRect = CGRect(x: 0, y: 0, width: 800, height: 100),
                                      @ViewBuilder content: @escaping () -> Content) -> some View {
//        self.modifier(FloatingPanelModifier(isPresented: isPresented, contentRect: contentRect, view: content))
        self.modifier(FloatingPanelModifier(isPresented: isPresented, contentRect: contentRect, view: content))
    }
}

// Add a  ``FloatingPanel`` to a view hierarchy
struct FloatingPanelModifier<PanelContent: View>: ViewModifier {
    /// Determines wheter the panel should be presented or not
    @Binding var isPresented: Bool
 
    /// Determines the starting size of the panel
    /// .frame(minWidth: 600, maxWidth: 600, minHeight: 100, maxHeight: 100, alignment: .center)
    var contentRect: CGRect// = CGRect(x: 0, y: 0, width: 600, height: 100)
 
    /// Holds the panel content's view closure
    @ViewBuilder let view: () -> PanelContent
 
    /// Stores the panel instance with the same generic type as the view closure
    @State var panel: FloatingPanel<PanelContent>?
 
    func body(content: Content) -> some View {
        content
            .onAppear {
                /// When the view appears, create, center and present the panel if ordered
                panel = FloatingPanel(view: view, contentRect: contentRect, isPresented: $isPresented)
                panel?.center()
                if isPresented {
                    present()
                }
            }.onDisappear {
                /// When the view disappears, close and kill the panel
                panel?.close()
                panel = nil
            }.onChange(of: isPresented) { value in
                /// On change of the presentation state, make the panel react accordingly
                if value {
//                    present()
                    panel?.orderFront(nil)
                    panel?.fadeIn()
                } else {
//                    panel?.close()
                    panel?.fadeOut()
                }
            }
            .onChange(of: viewModel.shared.karaoke) { value in
                if !value {
                    panel?.close()
                }
            }
    }
 
    /// Present the panel and make it the key window
    func present() {
        panel?.orderFront(nil)
//        panel?.makeKey()
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
        /// Initialize the binding variable by assigning the whole value via an underscore
        self._isPresented = isPresented
     
        /// Init the window as usual
        super.init(contentRect: contentRect,
                   styleMask: [.nonactivatingPanel, .fullSizeContentView, .closable], //.resizable, .closable], //.fullSizeContentView],
                   backing: .buffered,
                   defer: true)
     
        /// Allow the panel to be on top of other windows
        isFloatingPanel = true
        level = .mainMenu
     
        /// Allow the pannel to be overlaid in a fullscreen space
        collectionBehavior.insert(.canJoinAllSpaces)
        
//        layer?.cornerRadius = 16.0
     
        /// Don't show a window title, even if it's set
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
//        func centerAtBottom() {
//            guard let screenFrame = NSScreen.main?.frame else { return }
//            
//            // Calculate x position to center horizontally
//            let xPosition = (screenFrame.width - contentRect.width) / 2
//            
//            // Set y position to a small offset above the bottom of the screen
//            let yPosition: CGFloat = 50 // Adjust this to move it slightly up from the screen's bottom
//            
//            // Set the panel's frame origin
//            setFrameOrigin(NSPoint(x: xPosition, y: yPosition))
//        }
//        centerAtBottom()
     
        /// Since there is no title bar make the window moveable by dragging on the background
        isMovableByWindowBackground = true
     
        /// Hide when unfocused
        hidesOnDeactivate = false
        backgroundColor = NSColor.clear
        
        
        
//        hasTitleBar = true
     
        /// Hide all traffic light buttons
//        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
     
        /// Sets animations accordingly
//        animationBehavior = .documentWindow
     
        /// Set the content view.
        /// The safe area is ignored because the title bar still interferes with the geometry
        contentView = NSHostingView(rootView: view()
//            .ignoresSafeArea()
            .preferredColorScheme(.dark)
//            .background(VisualEffectView())//.ignoresSafeArea())
            .environment(\.floatingPanel, self))
        hasShadow = false
//        let visualEffect = NSVisualEffectView()
//        visualEffect.blendingMode = .behindWindow
//        visualEffect.state = .active
//        visualEffect.material = .hudWindow
        
//        contentView?.addSubview(visualEffect)
//        guard let constraints = self.contentView else {
//                    return
//                }
//        visualEffect.leadingAnchor.constraint(equalTo: constraints.leadingAnchor).isActive = true
//                visualEffect.trailingAnchor.constraint(equalTo: constraints.trailingAnchor).isActive = true
//                visualEffect.topAnchor.constraint(equalTo: constraints.topAnchor).isActive = true
//                visualEffect.bottomAnchor.constraint(equalTo: constraints.bottomAnchor).isActive = true
//        contentView?.layer?.cornerRadius = 20
//        contentView?.layer?.backgroundColor = Color(hue: 3, saturation: 3, brightness: 3)
//
//        let animation: CABasicAnimation = .init()
//        animation.delegate = self as! any CAAnimationDelegate
//        self.animations = [.alpha: animation]
    }
    
//    override func mouseEntered(with event: NSEvent) {
//        close()
//    }
//    
//    override func mouseExited(with event: NSEvent) {
//        orderFront(nil)
////        makeKey()
//        fadeIn()
//    }
    
    override func resignMain() {
        super.resignMain()
//        close()
    }
    
    func fadeIn() {
        self.alphaValue = 0.0
        self.animator().alphaValue = 1.0
    }
    
    func fadeOut() {
//        let lol: NSAnimationContext = .init()
        NSAnimationContext.runAnimationGroup { hi in
            hi.duration = 0.1
            self.animator().alphaValue = 0.0
        }
    }
    
     
    /// Close and toggle presentation, so that it matches the current state of the panel
    override func close() {
//        fadeOut()
        NSAnimationContext.runAnimationGroup { hi in
            hi.completionHandler = {
                super.close()
//                self.isPresented = false
            }
            self.animator().alphaValue = 0.0
        }
//        super.close()
//        isPresented = false
    }
     
    /// `canBecomeKey` and `canBecomeMain` are both required so that text inputs inside the panel can receive focus
    // this is disabled because we don't want to steal key focus when karaoke pops back up
//    override var canBecomeKey: Bool {
//        return true
//    }
     
    override var canBecomeMain: Bool {
        return true
    }
    override func center() {
        let rect = self.screen?.frame
        self.setFrameOrigin(NSPoint(x: (rect!.width - self.frame.width)/2, y: (rect!.height - self.frame.height)/5))
    }
}

//extension NSPanel. {
//
//    enum Horizontal {
//        case left, center, right
//    }
//
//    enum Vertical {
//        case top, center, bottom
//    }
//}
