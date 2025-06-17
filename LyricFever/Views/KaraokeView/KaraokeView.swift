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
//    let material: NSVisualEffectView.Material
//    let blendingMode: NSVisualEffectView.BlendingMode
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
        nsView.material = .hudWindow
        nsView.blendingMode = .behindWindow
    }
}

//@available(macOS 14.0, *)
struct KaraokeView: View {
    @EnvironmentObject var viewmodel: viewModel
    @Namespace var animation
    func multilingualView(_ currentlyPlayingLyricsIndex: Int) -> some View {
        VStack(spacing: 6) {
            if !viewmodel.romanizedLyrics.isEmpty {
                Text(verbatim: viewmodel.romanizedLyrics[currentlyPlayingLyricsIndex])
            } else {
                Text(verbatim: viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words)
            }
            Text(verbatim: viewmodel.translatedLyric[currentlyPlayingLyricsIndex])
                .font(.custom(viewmodel.karaokeFont.fontName, size: 0.9*(viewmodel.karaokeFont.pointSize)))
                .opacity(0.85)
        }
    }
    
    @ViewBuilder func lyricsView() -> some View {
        if let currentlyPlayingLyricsIndex = viewmodel.currentlyPlayingLyricsIndex {
            if viewmodel.translationExists {
                if viewmodel.karaokeShowMultilingual {
                    multilingualView(currentlyPlayingLyricsIndex)
                }
                else {
                    Text(verbatim: viewmodel.translatedLyric[currentlyPlayingLyricsIndex])
                }
            } else {
                if !viewmodel.romanizedLyrics.isEmpty {
                    Text(verbatim: viewmodel.romanizedLyrics[currentlyPlayingLyricsIndex])
                } else {
                    Text(verbatim: viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words)
                }
            }
        } else {
            Text("")
        }
    }
    
    var body: some View {
        lyricsView()
//            .animation(.easeInOut(duration: 0.2))
            .lineLimit(2)
//            .id(viewmodel.currentlyPlayingLyricsIndex)
            .foregroundStyle(.white)
            .minimumScaleFactor(0.9)
//            .animation(.smooth(duration: 0.2))
//            .transition( AnyTransition.asymmetric(insertion: .scale, removal: .opacity))
            
//            .minimumScaleFactor(0.1)
            .font(.custom(viewmodel.karaokeFont.fontName, size: viewmodel.karaokeFont.pointSize))
//            .font(.system(size: viewmodel.karaokeFontSize, weight: .bold, design: .default))
            .padding(10)
            .padding(.horizontal, 10)
            .background {
                Group {
                    if viewmodel.karaokeUseAlbumColor, let currentBackground = viewmodel.currentBackground {
                        currentBackground
                    } else {
                        viewmodel.colorBinding.wrappedValue
                    }
                }
                .transition(.opacity)
                .opacity(viewModel.shared.karaokeTransparency/100)
//                .drawingGroup()
//                .transition(.opacity)
//                .animation(nil)
//                .animation(.snappy(duration: 0.1), value: viewmodel.currentlyPlayingLyricsIndex)
            }
            .drawingGroup()
            .background(
                VisualEffectView().ignoresSafeArea()
            )
            .cornerRadius(16)
//                .background(VisualEffectView().animation(nil))
            .onHover { hover in
                if viewmodel.karaokeModeHoveringSetting {
                    viewmodel.karaokeModeHovering = hover
                }
            }
            .multilineTextAlignment(.center)
            .frame(minWidth: 800, maxWidth: 800, minHeight: 100, maxHeight: 100, alignment: .center)
//            .animation(.default, value: viewmodel.currentlyPlayingLyricsIndex)

    }
}
