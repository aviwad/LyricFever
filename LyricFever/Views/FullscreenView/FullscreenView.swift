//
//  FullscreenView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2024-07-27.
//

import SwiftUI
import SDWebImage
import ColorKit
import Combine
import TipKit

struct FullscreenView: View {
    @Environment(ViewModel.self) var viewmodel
    
    // View
    #if os(macOS)
    @State var artworkImage: NSImage?
    #else
    @State var artworkImage: UIImage?
    #endif
    @State var gradient = [Color(red: 33/255, green: 69/255, blue: 152/255),Color(red: 218/255, green: 62/255, blue: 136/255)]
    
    // Fullscreen options
    @State var animate = true
    
    // Button State
    @State var currentHover = HoverOptions.none
    @State var timer = Timer
            .publish(every: BackgroundView.animationDuration, on: .main, in: .common)
            .autoconnect()
    @State var points: ColorSpots = .init()
    @State var showSettingsPopover = false
    
    var canDisplayLyrics: Bool {
        viewmodel.showLyrics && !viewmodel.lyricsIsEmptyPostLoad
    }
    
    enum HoverOptions {
        case playpause
        case showlyrics
        case pauseanimation
        case volumelow
        case volumehigh
        case translate
        case none
        case settings
        case sharing
    }
    
    @ViewBuilder
    func fullscreenButton(systemName: String, hoverType: HoverOptions, keyEquivalent: KeyEquivalent, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HoverableIcon(systemName: systemName)
        }
        .buttonStyle(FullscreenButtonIconStyle())
        #if os(macOS)
        .onHover { hover in currentHover = hover ? hoverType : .none }
        .keyboardShortcut(keyEquivalent, modifiers: [])
        #endif
    }
    
    @ViewBuilder func FullscreenButtons() -> some View {
        #if os(macOS)
        let highlightTip = NewSettings()
        #endif
        HStack(alignment: .center, spacing: 6) {
            fullscreenButton(systemName: "speaker.minus", hoverType: .volumelow, keyEquivalent: .downArrow) {
                viewmodel.currentPlayerInstance.decreaseVolume()
            }
//            .glassEffect()
            fullscreenButton(systemName: viewmodel.isPlaying ? "pause" : "play", hoverType: .playpause, keyEquivalent: " ") {
                viewmodel.currentPlayerInstance.togglePlayback()
            }
//            .glassEffect()
            fullscreenButton(systemName: "speaker.plus", hoverType: .volumehigh, keyEquivalent: .upArrow) {
                viewmodel.currentPlayerInstance.increaseVolume()
            }
//            .glassEffect()
        }
        .font(.system(size: 15))
        HStack(alignment: .center, spacing: 5) {
            Button {
                viewmodel.showLyrics.toggle()
            } label: {
                HoverableIcon(systemName: "music.note.list", sideLength: 28, disabled: !viewmodel.showLyrics)
                    
            }
            .buttonStyle(FullscreenButtonIconStyle())
            #if os(macOS)
            .onHover { hover in
                currentHover = hover ? .showlyrics : .none
            }
            .keyboardShortcut("h")
            #endif
            .disabled(viewmodel.currentlyPlayingLyrics.isEmpty)
            
            Button {
                viewmodel.userDefaultStorage.translate.toggle()
            } label: {
                HoverableIcon(systemName: "translate", sideLength: 28, disabled: !viewmodel.userDefaultStorage.translate)
            }
            .buttonStyle(FullscreenButtonIconStyle())
            #if os(macOS)
            .onHover { hover in
                currentHover = hover ? .translate : .none
            }
            .keyboardShortcut("t")
            #endif
            .disabled(viewmodel.currentlyPlayingLyrics.isEmpty)
                            
            
            
            Button {
                animate.toggle()
            } label: {
                HoverableIcon(systemName: "leaf", sideLength: 28, disabled: !animate)
            }
            .buttonStyle(FullscreenButtonIconStyle())
            #if os(macOS)
            .onHover { hover in
                currentHover = hover ? .pauseanimation : .none
            }
            .keyboardShortcut("a")
            #endif
            
            #if os(macOS)
            Button {
                highlightTip.invalidate(reason: .actionPerformed)
                showSettingsPopover = true
            } label: {
                HoverableIcon(systemName: "gear", sideLength: 28)
            }
            .buttonStyle(FullscreenButtonIconStyle())
            .popoverTip(highlightTip, arrowEdge: .bottom)
            .onHover { hover in
                currentHover = hover ? .settings : .none
            }
            .popover(isPresented: $showSettingsPopover) {
                @Bindable var viewmodel = viewmodel
                VStack(spacing: 7) {
                    Toggle("Blur surrounding lyrics", isOn: $viewmodel.userDefaultStorage.blurFullscreen)
                    Toggle("Animate on startup", isOn: $viewmodel.userDefaultStorage.animateOnStartupFullscreen)
                    Button("Reset to default") {
                        
                    }
                }
                .padding(10)
            }
            #endif
            #if os(macOS)
            if let currentlyPlaying = viewmodel.currentlyPlaying, currentlyPlaying.count == 22 {
                ShareLink(item: URL(string: "http://open.spotify.com/track/\(currentlyPlaying)")!) {
                    HoverableIcon(systemName: "square.and.arrow.up.circle.fill", sideLength: 30)
                }
                .imageScale(.large)
                .buttonStyle(FullscreenButtonIconStyle())
                .onHover { hover in
                    currentHover = hover ? .sharing : .none
                }
            }
            #endif
        }
        .font(.system(size: 12))
    }
    
    @ViewBuilder var albumArt: some View {
        VStack {
            Spacer()
            if let artworkImage {
                #if os(macOS)
                Image(nsImage: artworkImage)
                    .resizable()
                    .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                    .shadow(radius: 5)
                    .frame(width: canDisplayLyrics ? 550 : 700, height: canDisplayLyrics ? 550 : 700)
                #else
                Image(uiImage: artworkImage)
                    .resizable()
                    .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                    .shadow(radius: 5)
                    .frame(width: canDisplayLyrics ? 550 : 700, height: canDisplayLyrics ? 550 : 700)
                #endif
            }
            else {
                Image(systemName: "music.note.list")
                    .resizable()
                    .shadow(radius: 3)
                    .scaleEffect(0.5)
                    .background(.gray)
                    .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                    .shadow(radius: 5)
                    .frame(width: canDisplayLyrics ? 550 : 650, height: canDisplayLyrics ? 550 : 650)
            }
            Group {
                Text(verbatim: viewmodel.currentlyPlayingName ?? "")
                    .font(.title)
                    .bold()
                    .padding(.top, 30)
                Text(verbatim: viewmodel.currentlyPlayingArtist ?? "")
                    .font(.title2)
            }
            .frame(height: 35)
            FullscreenButtons()
            .frame(height: 25)
            .buttonStyle(.plain)
            .imageScale(.large)
            .bold()
            Text(displayHoverTooltip())
                .textCase(.uppercase)
                .font(.system(size: 14, weight: .light, design: .monospaced))
                .frame(height: 20)
            Spacer()
        }
    }
    
    func displayHoverTooltip() -> LocalizedStringKey {
        switch currentHover {
            case .playpause:
                viewmodel.isPlaying ? "Pause (spacebar)" : "Play (spacebar)"
            case .showlyrics:
                viewmodel.showLyrics ? "Hide lyrics (⌘ + H)" : "Show lyrics (⌘ + H)"
            case .pauseanimation:
                animate ? "Pause animations (saves battery) (⌘ + A)" : "Unpause animations (uses battery) (⌘ + A)"
            case .volumelow:
                "Decrease volume by 5 (Down Arrow)"
            case .volumehigh:
                "Increase volume by 5 (Up Arrow)"
            case .none:
                ""
            case .translate:
                viewmodel.userDefaultStorage.translate ? "Hide translations (⌘ + T)" : "Translate lyrics (⌘ + T)"
            case .settings:
                "Display fullscreen options"
            case .sharing:
                "Share Spotify link"
        }
    }
    
    @ViewBuilder func lyricLineView(for element: LyricLine, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if !viewmodel.romanizedLyrics.isEmpty {
                Text(verbatim: viewmodel.romanizedLyrics[index])
                    .foregroundStyle(.white)
            } else {
                Text(verbatim: element.words)
                    .foregroundStyle(.white)
            }
            if viewmodel.translationExists {
                Text(verbatim: viewmodel.translatedLyric[index])
                    .font(.system(size: 33, weight: .semibold, design: .default))
                    .opacity(0.85)
            }
        }
    }
    
    @ViewBuilder func lyrics(padding: CGFloat) -> some View {
        ZStack {
            if viewmodel.currentlyPlayingLyrics.isEmpty {
                ProgressView()
            }
            VStack(alignment: .leading){
                Spacer()
                ScrollViewReader { proxy in
                    List (Array(viewmodel.currentlyPlayingLyrics.enumerated()), id: \.element) { offset, element in
                        lyricLineView(for: element, index: offset)
                            .opacity(offset == viewmodel.currentlyPlayingLyrics.count - 1 ? 0 : (offset == viewmodel.currentlyPlayingLyricsIndex ? 1 : 0.8))
                            .font(.system(size: 40, weight: .bold, design: .default))
                            .padding(20)
                        #if os(macOS)
                            .listRowSeparator(.hidden)
                        #endif
                            .blur(radius: viewmodel.userDefaultStorage.blurFullscreen ? (offset == viewmodel.currentlyPlayingLyricsIndex ? 0 : 5) : 0)
                    }
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            if let currentIndex = viewmodel.currentlyPlayingLyricsIndex {
                                proxy.scrollTo(viewmodel.currentlyPlayingLyrics[currentIndex], anchor: .center)
                            }
                        }
                    }
                    .padding(.trailing, 100)
                    .safeAreaInset(edge: .top) {
                        Spacer()
                            .id("first")
                            .frame(height: padding)
                        }
                    .safeAreaInset(edge: .bottom) {
                        Spacer()
                            .id("last")
                            .frame(height: padding)
                        }
                    .onChange(of: viewmodel.translatedLyric) {
                        withAnimation() {
                            if let currentIndex = viewmodel.currentlyPlayingLyricsIndex {
                                proxy.scrollTo(viewmodel.currentlyPlayingLyrics[currentIndex], anchor: .center)
                            } else {
                                proxy.scrollTo("first", anchor: .top)
                            }
                            
                        }
                    }
                    .onChange(of: viewmodel.currentlyPlayingLyricsIndex) {
                        withAnimation() {
                            if let currentIndex = viewmodel.currentlyPlayingLyricsIndex {
                                proxy.scrollTo(viewmodel.currentlyPlayingLyrics[currentIndex], anchor: .center)
                            } else {
                                proxy.scrollTo("first", anchor: .top)
                            }
                            
                        }
                    }
                }
                #if os(macOS)
                .scrollContentBackground(.hidden)
                #endif
                .scrollDisabled(true)
                .mask(LinearGradient(gradient: Gradient(colors: [.clear, .black, .clear]), startPoint: .top, endPoint: .bottom))
                Spacer()
                
            }
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            HStack {
                albumArt
                    .frame( minWidth: 0.50*(geo.size.width), maxWidth: canDisplayLyrics ? 0.50*(geo.size.width) : .infinity)
                if canDisplayLyrics {
                    lyrics(padding: 0.5*(geo.size.height))
                        .frame( minWidth: 0.50*(geo.size.width), maxWidth: 0.50*(geo.size.width))
                }
            }
        }
        .background {
            BackgroundView(colors: $gradient, timer: $timer, points: $points)
        }
        .onAppear {
            if !viewmodel.userDefaultStorage.animateOnStartupFullscreen {
                animate = false
            }
            do {
                try Tips.configure()
            }
            catch {
                print("Error configuring tips: \(error)")
            }
        }
        .onChange(of: artworkImage) {
            print("NEW ARTWORK")
            if let artworkImage, let dominantColors = try? artworkImage.dominantColors(with: .best, algorithm: .kMeansClustering) {
                gradient = dominantColors.map({adjustedColor($0)})
            }
        }
        .task(id: viewmodel.currentlyPlayingName) {
            if let artworkImage = await viewmodel.currentPlayerInstance.artworkImage {
                self.artworkImage = artworkImage
            }
            else if let artistName = viewmodel.currentlyPlayingArtist, let currentAlbumName = viewmodel.currentAlbumName {
                if let mbid = await MusicBrainzArtworkService.findMbid(albumName: currentAlbumName, artistName: artistName) {
                    self.artworkImage = await MusicBrainzArtworkService.artworkImage(for: mbid)
                }
            }
        }
    }
    
    #if os(macOS)
    typealias PlatformColor = NSColor
    #else
    typealias PlatformColor = UIColor
    #endif

    func adjustedColor(_ color: PlatformColor) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        brightness = max(brightness - 0.2, 0.1)
        if saturation < 0.9 {
            saturation = max(0.1, saturation * 3)
        }
    #if os(macOS)
        let modifiedColor = NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        return Color(modifiedColor)
    #else
        let modifiedColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        return Color(modifiedColor)
    #endif
    }
}
