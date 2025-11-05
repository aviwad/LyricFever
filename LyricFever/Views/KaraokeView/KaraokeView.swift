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

struct KaraokeView: View {
    @Environment(ViewModel.self) var viewmodel
    @AppStorage("karaokeTransparency") var karaokeTransparency: Double = 50

    // Adjust threshold here
    private var useForcedWhiteText: Bool {
        karaokeTransparency / 100 > 0.40
    }

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
            Text(verbatim: viewmodel.translatedLyric[currentlyPlayingLyricsIndex])
                .font(.custom(viewmodel.karaokeFont.fontName, size: 0.9 * (viewmodel.karaokeFont.pointSize)))
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
                if viewmodel.userDefaultStorage.karaokeShowMultilingual,
                   originalAndTranslationAreDifferent(for: currentlyPlayingLyricsIndex) {
                    multilingualView(currentlyPlayingLyricsIndex)
                        .compositingGroup()
                } else {
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

    var body: some View {
        if #available(macOS 26.0, *) {
            lyricsView()
                .lineLimit(2)
                .foregroundStyle(useForcedWhiteText ? Color.white : Color.primary)
                .minimumScaleFactor(0.9)
                .font(.custom(viewmodel.karaokeFont.fontName, size: viewmodel.karaokeFont.pointSize))
                .padding(10)
                .padding(.horizontal, 10)
                .background {
                    if viewmodel.userDefaultStorage.karaokeUseAlbumColor, karaokeTransparency > 0 {
                        viewmodel.currentAlbumArt
                            .opacity(karaokeTransparency / 100)
                    }
                }
                .glassEffect(in: .rect(cornerRadius: 16))
                .cornerRadius(16)
                .onHover { hover in
                    if viewmodel.userDefaultStorage.karaokeModeHoveringSetting {
                        viewmodel.karaokeModeHovering = hover
                    }
                }
                .multilineTextAlignment(.center)
                .frame(minWidth: 800, maxWidth: 800, minHeight: 100, maxHeight: 100, alignment: .center)
        } else {
            // fall back
            lyricsView()
                .lineLimit(2)
                .foregroundStyle(useForcedWhiteText ? Color.white : Color.primary)
                .minimumScaleFactor(0.9)
                .font(.custom(viewmodel.karaokeFont.fontName, size: viewmodel.karaokeFont.pointSize))
                .padding(10)
                .padding(.horizontal, 10)
                .background {
                    // Material + optional album overlay
                    Rectangle()
                        .fill(Material.regular)
                        .overlay(
                            Group {
                                if viewmodel.userDefaultStorage.karaokeUseAlbumColor, karaokeTransparency > 0 {
                                    viewmodel.currentAlbumArt
                                        .opacity(karaokeTransparency / 100)
                                }
                            }
                        )
                        .cornerRadius(16)
                        .ignoresSafeArea()
                }
                .onHover { hover in
                    if viewmodel.userDefaultStorage.karaokeModeHoveringSetting {
                        viewmodel.karaokeModeHovering = hover
                    }
                }
                .multilineTextAlignment(.center)
                .frame(minWidth: 800, maxWidth: 800, minHeight: 100, maxHeight: 100, alignment: .center)
        }
    }
}
