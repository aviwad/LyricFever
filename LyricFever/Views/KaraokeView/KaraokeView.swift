//
//  KaraokeView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2024-10-08.
//

import SwiftUI
import SDWebImage
import ColorKit
import Combine

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()

        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        //
        nsView.material = .hudWindow
        nsView.blendingMode = .behindWindow
    }
}

struct KaraokeView: View {
    @Environment(ViewModel.self) var viewmodel
    @AppStorage("karaokeTransparency") var karaokeTransparency: Double = 50
    
    func currentWords(for currentlyPlayingLyricsIndex: Int) -> String {
        if !viewmodel.romanizedLyrics.isEmpty {
            return viewmodel.romanizedLyrics[currentlyPlayingLyricsIndex]
        } else if !viewmodel.chineseConversionLyrics.isEmpty {
            return viewmodel.chineseConversionLyrics[currentlyPlayingLyricsIndex]
        } else {
            return viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words
        }
    }
    
    func multilingualView(_ currentlyPlayingLyricsIndex: Int) -> some View {
        VStack(spacing: 6) {
            Text(verbatim: currentWords(for: currentlyPlayingLyricsIndex))
                
//            Text(verbatim: viewmodel.romanizedLyrics.isEmpty ? viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words : viewmodel.romanizedLyrics[currentlyPlayingLyricsIndex])
            Text(verbatim: viewmodel.translatedLyric[currentlyPlayingLyricsIndex])
                .font(.custom(viewmodel.karaokeFont.fontName, size: 0.9*(viewmodel.karaokeFont.pointSize)))
                .opacity(0.85)
        }
    }
    
    func originalAndTranslationAreDifferent(for currentlyPlayingLyricsIndex: Int) -> Bool {
        viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words != viewmodel.translatedLyric[currentlyPlayingLyricsIndex]
    }
    
    @ViewBuilder
    func lyricsView() -> some View {
        if let currentlyPlayingLyricsIndex = viewmodel.currentlyPlayingLyricsIndex {
            if viewmodel.translationExists {
                if viewmodel.userDefaultStorage.karaokeShowMultilingual, originalAndTranslationAreDifferent(for: currentlyPlayingLyricsIndex) {
                    multilingualView(currentlyPlayingLyricsIndex)
                        .compositingGroup()
                }
                else {
                    Text(verbatim: viewmodel.translatedLyric[currentlyPlayingLyricsIndex])
                }
            } else {
                if !viewmodel.romanizedLyrics.isEmpty {
                    Text(verbatim: viewmodel.romanizedLyrics[currentlyPlayingLyricsIndex])
                } else if !viewmodel.chineseConversionLyrics.isEmpty {
                    Text(verbatim: viewmodel.chineseConversionLyrics[currentlyPlayingLyricsIndex])
                } else {
                    Text(verbatim: viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words)
                }
            }
        } else {
            Text("")
        }
    }
    
    @ViewBuilder
    var finalKaraokeView: some View {
        lyricsView()
            .lineLimit(2)
            .foregroundStyle(.white)
            .minimumScaleFactor(0.9)
            .font(.custom(viewmodel.karaokeFont.fontName, size: viewmodel.karaokeFont.pointSize))
            .padding(10)
            .padding(.horizontal, 10)
            .background {
               viewmodel.currentAlbumArt
               .transition(.opacity)
               .opacity(karaokeTransparency/100)
           }
           .drawingGroup()
           .background(
               VisualEffectView().ignoresSafeArea()
           )
           .cornerRadius(16)
            .onHover { hover in
                if viewmodel.userDefaultStorage.karaokeModeHoveringSetting {
                    viewmodel.karaokeModeHovering = hover
                }
            }
            .multilineTextAlignment(.center)
            .frame(minWidth: 800, maxWidth: 800, minHeight: 100, maxHeight: 100, alignment: .center)
    }
    
    var body: some View {
        finalKaraokeView
    }
}
