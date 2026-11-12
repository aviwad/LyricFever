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
    @AppStorage("karaokeUseAlbumColor") var karaokeUseAlbumColor: Bool = true
    @AppStorage("fixedKaraokeColorHex") var fixedKaraokeColorHex: String = "#2D3CCC"

    private var useForcedWhiteText: Bool {
        karaokeTransparency / 100 > 0.35
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
                .font(.custom(viewmodel.karaokeFont.fontName, size: 0.9 * viewmodel.karaokeFont.pointSize))
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
                Text(verbatim: currentWords(for: currentlyPlayingLyricsIndex))
            }
        } else {
            Text("")
        }
    }

    private var currentBackgroundColor: Color {
        guard karaokeUseAlbumColor, let albumColor = viewmodel.currentBackground else {
            return Color(NSColor(hexString: fixedKaraokeColorHex)!)
        }
        return albumColor
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            // Keep Liquid Glass rendering lively while the karaoke panel is visible.
            TimelineView(.animation) { timeline in
                let offset = 0.1 * sin(timeline.date.timeIntervalSinceReferenceDate * 20 * .pi)
                lyricsView()
                    .id(viewmodel.currentlyPlayingLyricsIndex)
                    .lineLimit(2)
                    .foregroundStyle(useForcedWhiteText ? Color.white : Color.primary)
                    .minimumScaleFactor(0.9)
                    .font(.custom(viewmodel.karaokeFont.fontName, size: viewmodel.karaokeFont.pointSize))
                    .padding(10)
                    .padding(.horizontal, 10)
                    .background {
                        if karaokeTransparency > 0 {
                            currentBackgroundColor.opacity(karaokeTransparency / 100)
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
                    .offset(y: offset)
            }
        } else {
            lyricsView()
                .id(viewmodel.currentlyPlayingLyricsIndex)
                .lineLimit(2)
                .foregroundStyle(useForcedWhiteText ? Color.white : Color.primary)
                .minimumScaleFactor(0.9)
                .font(.custom(viewmodel.karaokeFont.fontName, size: viewmodel.karaokeFont.pointSize))
                .padding(10)
                .padding(.horizontal, 10)
                .background {
                    Rectangle()
                        .fill(Material.regular)
                        .overlay {
                            if karaokeTransparency > 0 {
                                currentBackgroundColor.opacity(karaokeTransparency / 100)
                            }
                        }
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
