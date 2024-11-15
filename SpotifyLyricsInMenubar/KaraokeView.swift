//
//  KaraokeView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2024-10-08.
//

import SwiftUI
import SDWebImageSwiftUI
import ColorKit
import Combine

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()

        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
//        view.layer?.cornerRadius = 16.0
//        visualEffect.layer?.cornerRadius = 16.0

        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        //
    }
}

//@available(macOS 14.0, *)
struct KaraokeView: View {
    @EnvironmentObject var viewmodel: viewModel
//    @State var displayOptions = false
    
    func lyrics() -> String {
        if let currentlyPlayingLyricsIndex = viewmodel.currentlyPlayingLyricsIndex {
            return viewmodel.translate && !viewmodel.translatedLyric.isEmpty ? viewmodel.translatedLyric[currentlyPlayingLyricsIndex] : viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words
        }
        return ""
    }
    
    var body: some View {
//        ZStack {
//            if displayOptions {
//                Text("options")
//            }
//            Group {
//                if let index = viewmodel.currentlyPlayingLyricsIndex{
//
//                } else {
//                    Text("Lyric Fever")
//                }
//            }
        Text(lyrics())
//                        .opacity(displayOptions ? 0 : 1)
            .font(.system(size: 30, weight: .bold, design: .default))
            .foregroundStyle(.white)
            .minimumScaleFactor(0.1)
            .padding(.horizontal, 10)
            .multilineTextAlignment(.center)
           // .frame(maxWidth: .infinity, alignment: .center)
            .frame(minWidth: 600, maxWidth: 600, minHeight: 100, maxHeight: 100, alignment: .center)
//                    .background(VisualEffectView().ignoresSafeArea())
            .animation(.snappy(duration: 0.2), value: viewmodel.currentlyPlayingLyricsIndex)
//        }
//        .onHover { hover in
//            displayOptions = hover
//        }
//        .onChange(of: viewmodel.isPlaying) {
//            if !viewmodel.isPlaying {
//                viewmodel.displayKaraoke = false
//            } else {
//                viewmodel.displayKaraoke = true
//            }
//        }
//        .onChange(of: viewmodel.currentlyPlaying) {
//            if viewmodel.currentlyPlaying != nil {
//                viewmodel.fetchBackgroundColor()
//            }
//        }
        .background {
            if let currentBackground = viewmodel.currentBackground {
                currentBackground
                    .opacity(0.5)
            }
        }
        .onDisappear {
            
        }
//        .onAppear {
//            if viewmodel.currentBackground == nil {
////                viewmodel.fetchBackgroundColor()
//            }
//            Task { @MainActor in
//                print("on appear")
//                let window = NSApp.windows.first {$0.identifier?.rawValue == "karaoke"}
//                window?.level = NSWindow.Level(Int(CGShieldingWindowLevel()) + 1)
//                window?.collectionBehavior = [.stationary, .ignoresCycle, .fullScreenDisallowsTiling, .canJoinAllSpaces]
//                
//                window?.styleMask.remove(.titled)
//                window?.isMovableByWindowBackground = true
//            }
//        }
    }
//    func adjustedColor(_ nsColor: NSColor) -> Color {
//        // Convert NSColor to HSB components
//        var hue: CGFloat = 0
//        var saturation: CGFloat = 0
//        var brightness: CGFloat = 0
//        var alpha: CGFloat = 0
//        
//        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
//        
//        // Adjust brightness
//        brightness = brightness - 0.2
//        
//        if saturation < 0.8 {
//            // Adjust contrast
//            saturation = saturation * 3
//        }
//        
//        // Create new NSColor with modified HSB values
//        let modifiedNSColor = NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
//        
//        // Convert NSColor to SwiftUI Color
//        return Color(modifiedNSColor)
//    }
}
