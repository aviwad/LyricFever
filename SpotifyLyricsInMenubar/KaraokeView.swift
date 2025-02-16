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
    @Namespace var animation
    
//    @State var displayOptions = false
    
//    func lyrics() -> String {
//        if let currentlyPlayingLyricsIndex = viewmodel.currentlyPlayingLyricsIndex {
//            return viewmodel.translate && !viewmodel.translatedLyric.isEmpty ? viewmodel.translatedLyric[currentlyPlayingLyricsIndex] : viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words
//        }
//        return ""
//    }
    
    func multilingualView(_ currentlyPlayingLyricsIndex: Int) -> some View {
        VStack {
            Text(viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words)
            Text(viewmodel.translatedLyric[currentlyPlayingLyricsIndex])
                .font(.system(size: 27, weight: .semibold, design: .default))
                .opacity(0.85)
//                .font(.system(size: 30, weight: .regular, design: .default))
        }
    }
    
    @ViewBuilder func lyricsView() -> some View {
        if let currentlyPlayingLyricsIndex = viewmodel.currentlyPlayingLyricsIndex {
            if viewmodel.translate && !viewmodel.translatedLyric.isEmpty {
                if viewmodel.karaokeShowMultilingual {
                    multilingualView(currentlyPlayingLyricsIndex)
                }
                else {
                    Text(viewmodel.translatedLyric[currentlyPlayingLyricsIndex])
                }
            } else {
                Text(viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words)
            }
        } else {
            Text("")
        }
    }
    
    var body: some View {
        lyricsView()
            .id(viewmodel.currentlyPlayingLyricsIndex)
            .transition(.opacity)
            .animation(.snappy(duration: 0.2), value: viewmodel.currentlyPlayingLyricsIndex)
            .font(.system(size: 30, weight: .bold, design: .default))
            .foregroundStyle(.white)
            .minimumScaleFactor(0.1)
            .padding(10)
            .multilineTextAlignment(.center)
            .frame(minWidth: 600, maxWidth: 600, minHeight: 100, maxHeight: 100, alignment: .center)
//            .animation(.default, value: viewmodel.currentlyPlayingLyricsIndex)
            .onHover { hover in
                if viewmodel.karaokeModeHoveringSetting {
                    viewmodel.karaokeModeHovering = hover
                }
            }
        .background {
            if let currentBackground = viewmodel.currentBackground {
                currentBackground
                    .opacity(viewModel.shared.karaokeTransparency)
            }
        }
    }
}
