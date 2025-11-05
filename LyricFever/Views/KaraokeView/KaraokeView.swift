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
import AppKit

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        if #available(macOS 26.0, *) {
            let glassEffectView = NSGlassEffectView()
            glassEffectView.style = NSGlassEffectView.Style.regular
            return glassEffectView
        } else {
            let visualEffectView = NSVisualEffectView()
            visualEffectView.blendingMode = .behindWindow
            visualEffectView.state = .active
            visualEffectView.material = .hudWindow
            return visualEffectView
        }
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if #available(macOS 26.0, *), let glassEffectView = nsView as? NSGlassEffectView {
            glassEffectView.style = NSGlassEffectView.Style.regular
        } else if let visualEffectView = nsView as? NSVisualEffectView {
            visualEffectView.material = .hudWindow
            visualEffectView.blendingMode = .behindWindow
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    var srgbComponents: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let nsColor = NSColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    private var relativeLuminance: Double {
        let (r, g, b, _) = srgbComponents
        func gamma(_ c: CGFloat) -> Double {
            let f = Double(c)
            return f <= 0.03928 ? f / 12.92 : pow((f + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * gamma(r) + 0.7152 * gamma(g) + 0.0722 * gamma(b)
    }

    func contrastRatio(against other: Color) -> Double {
        let l1 = self.relativeLuminance
        let l2 = other.relativeLuminance
        let lighter = max(l1, l2)
        let darker = min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

struct KaraokeView: View {
    @Environment(ViewModel.self) var viewmodel
    @AppStorage("karaokeTransparency") var karaokeTransparency: Double = 50
    
    private var systemVisualEffectBackgroundColor: Color {
        if NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return Color(hex: 0x2C2C2C) // dark mode
        } else {
            return Color(hex: 0xE0E0E0) // light mode
        }
    }

    // Blend album color over system background based on transparency
    private func blendedBackgroundColor(albumColor: Color, transparency: Double) -> Color {
        let systemBG = systemVisualEffectBackgroundColor
        let (r1, g1, b1, _) = systemBG.srgbComponents
        let (r2, g2, b2, _) = albumColor.srgbComponents

        return Color(
            .sRGB,
            red: Double(r1 * (1 - transparency) + r2 * transparency),
            green: Double(g1 * (1 - transparency) + g2 * transparency),
            blue: Double(b1 * (1 - transparency) + b2 * transparency),
            opacity: 1.0
        )
    }

    private var effectiveTextColor: Color {
        let transparency = karaokeTransparency / 100.0

        if transparency <= 0.01 {
            return .primary
        }

        let bg = blendedBackgroundColor(albumColor: viewmodel.currentAlbumArt, transparency: transparency)
        let contrastWithWhite = Color.white.contrastRatio(against: bg)
        let contrastWithBlack = Color.black.contrastRatio(against: bg)

        return contrastWithWhite > contrastWithBlack ? .white : .black
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

    @ViewBuilder
    var finalKaraokeView: some View {
        lyricsView()
            .lineLimit(2)
            .foregroundStyle(effectiveTextColor)
            .minimumScaleFactor(0.9)
            .font(.custom(viewmodel.karaokeFont.fontName, size: viewmodel.karaokeFont.pointSize))
            .padding(10)
            .padding(.horizontal, 10)
            .background {
                viewmodel.currentAlbumArt
                    .transition(.opacity)
                    .opacity(karaokeTransparency / 100)
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
