//
//  FullscreenView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2024-07-27.
//

import SwiftUI
import SDWebImageSwiftUI
import ColorKit
import Combine

@available(macOS 14.0, *)
struct FullscreenView: View {
    @EnvironmentObject var viewmodel: viewModel
    @State var newSpotifyMusicArtworkImage: NSImage?
    @State var newArtworkUrl: String?
    @State var animate = true
    @State var avgColor: Color = Color(red: 33/255, green: 69/255, blue: 152/255)
    @State var gradient = [Color(red: 33/255, green: 69/255, blue: 152/255),Color(red: 218/255, green: 62/255, blue: 136/255)]
    @State var timer = Timer
        .publish(every: BackgroundView.animationDuration, on: .main, in: .common)
        .autoconnect()
    @State var currentHover = hoverOptions.none
    @State var points: ColorSpots = .init()
    
    var canDisplayLyrics: Bool {
        viewmodel.showLyrics && !viewmodel.lyricsIsEmptyPostLoad
    }
    
    enum hoverOptions {
        case playpause
        case showlyrics
        case pauseanimation
        case volumelow
        case volumehigh
        case none
    }
    
    @ViewBuilder var albumArt: some View {
        VStack {
            Spacer()
            if let newArtworkUrl  {
                WebImage(url: .init(string: newArtworkUrl), options: .queryMemoryData)
                    .resizable()
                    .placeholder(content: {
                        Image(systemName: "music.note.list")
                        .resizable()
                        .shadow(radius: 3)
                        .scaleEffect(0.5)
                        .background(.gray)
                    })
                 .onSuccess { image, data, cacheType in
                     if let data {
                         newSpotifyMusicArtworkImage = NSImage(data: data)
                     }
                 }
                    .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                    .shadow(radius: 5)
                    .frame(width: canDisplayLyrics ? 550 : 700, height: canDisplayLyrics ? 550 : 700)
            } else {
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
                Text(viewmodel.currentlyPlayingName ?? "")
                    .font(.title)
                    .bold()
                    .padding(.top, 30)
                Text(viewmodel.currentlyPlayingArtist ?? "")
                    .font(.title2)
            }
            .frame(height: 35)
            HStack {
                Button {
                    viewmodel.spotifyScript?.playpause?()
                } label: {
                    Image(systemName: "playpause")
                }
                .onHover { hover in
                    currentHover = hover ? .playpause : .none
                }
                .keyboardShortcut(KeyEquivalent(" "), modifiers: [])
                Button {
                    if viewmodel.showLyrics {
                        viewmodel.showLyrics = false
                        viewmodel.stopLyricUpdater()
                    } else {
                        viewmodel.showLyrics = true
                        // Only Spotify has access to Fullscreen view
                        viewmodel.startLyricUpdater(appleMusicOrSpotify: false)
                    }
                    
                } label: {
                    Image(systemName: "music.note.list")
                }
                .onHover { hover in
                    currentHover = hover ? .showlyrics : .none
                }
                .keyboardShortcut("h")
                .disabled(viewmodel.currentlyPlayingLyrics.isEmpty)
                Button {
                    withAnimation {
                        animate.toggle()
                    }
                    if animate {
                        timer = Timer
                            .publish(every: BackgroundView.animationDuration, on: .main, in: .common)
                            .autoconnect()
                        withAnimation(.easeInOut(duration: BackgroundView.animationDuration)) {
                            points = self.gradient.map { .random(withColor: $0) }
                        }
                    } else {
                        timer.upstream.connect().cancel()
                    }
                } label: {
                    Image(systemName: "sparkles")
                }
                .onHover { hover in
                    currentHover = hover ? .pauseanimation : .none
                }
                Button {
                    if let soundVolume = viewmodel.spotifyScript?.soundVolume {
                        viewmodel.spotifyScript?.setSoundVolume?(soundVolume-5)
                    }
                } label: {
                    Image(systemName: "speaker.minus")
                }
                .onHover { hover in
                    currentHover = hover ? .volumelow : .none
                }
                .keyboardShortcut(KeyEquivalent.downArrow, modifiers: [])
                Button {
                    if let soundVolume = viewmodel.spotifyScript?.soundVolume {
                        viewmodel.spotifyScript?.setSoundVolume?(soundVolume+5)
                    }
                } label: {
                    Image(systemName: "speaker.plus")
                }
                .onHover { hover in
                    currentHover = hover ? .volumehigh : .none
                }
                .keyboardShortcut(KeyEquivalent.upArrow, modifiers: [])
            }
            Text(displayHoverTooltip())
                .textCase(.uppercase)
                .font(.system(size: 14, weight: .light, design: .monospaced))
                .frame(height: 20)
            Spacer()
        }
    }
    
    func displayHoverTooltip() -> String {
        switch currentHover {
            case .playpause:
                viewmodel.isPlaying ? "Pause (spacebar)" : "Play (spacebar)"
            case .showlyrics:
                viewmodel.showLyrics ? "Hide lyrics (⌘ + H)" : "Show lyrics (⌘ + H)"
            case .pauseanimation:
                animate ? "Pause animations (saves battery)" : "Unpause animations (uses battery)"
            case .volumelow:
                "Decrease volume by 5 (down arrow)"
            case .volumehigh:
                "Increase volume by 5 (up arrow)"
            case .none:
                ""
        }
    }
    
    @ViewBuilder var lyrics: some View {
        VStack(alignment: .leading){
            Spacer()
            ScrollView(showsIndicators: false){
                ForEach (viewmodel.currentlyPlayingLyrics.indices, id:\.self) { i in
                    Text(viewmodel.currentlyPlayingLyrics[i].words)
                        .opacity(i == viewmodel.currentlyPlayingLyrics.count - 1 ? 0 : 1)
                        .font(.system(size: 40, weight: .bold, design: .default))
                        .padding(.vertical, 20)
                        .blur(radius: i == viewmodel.currentlyPlayingLyricsIndex ? 0 : 8)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                .scrollTargetLayout()
                .safeAreaPadding(EdgeInsets(top: 600, leading: 0, bottom: 500, trailing: 200))
                
                .scrollContentBackground(.hidden)
            }
            .scrollDisabled(true)
            .mask(LinearGradient(gradient: Gradient(colors: [.clear, .black, .clear]), startPoint: .top, endPoint: .bottom))
            .scrollPosition(id: $viewmodel.currentlyPlayingLyricsIndex, anchor: .center)
            Spacer()
            
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            HStack {
                albumArt
                    .frame( minWidth: 0.50*(geo.size.width), maxWidth: canDisplayLyrics ? 0.50*(geo.size.width) : .infinity)
                if canDisplayLyrics {
                    lyrics
                        .frame( minWidth: 0.50*(geo.size.width), maxWidth: 0.50*(geo.size.width))
                }
            }
        }
        .background {
            ZStack {
                if animate {
                    BackgroundView(colors: $gradient, timer: $timer)
                } else {
                    avgColor
                }
            }
            .ignoresSafeArea()
            .transition(.opacity)
        }
        .onAppear {
            withAnimation {
                self.newArtworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl
            }
            Task { @MainActor in
                let window = NSApp.windows.first {$0.identifier?.rawValue == "fullscreen"}
                window?.collectionBehavior = .fullScreenPrimary
                if window?.styleMask.rawValue != 49167 {
                    window?.toggleFullScreen(true)
                }
            }
        }
        .onChange(of: newSpotifyMusicArtworkImage) { newArtwork in
            print("NEW ARTWORK")
            if let newArtwork, let dominantColors = try? newArtwork.dominantColors(with: .best, algorithm: .kMeansClustering) {
                gradient = dominantColors.map({adjustedColor($0)})
                if let avgColor = try? adjustedColor(newArtwork.averageColor()) {
                    withAnimation {
                        self.avgColor = avgColor
                    }
                }
            }
        }
        .onChange(of: viewmodel.currentlyPlayingName) { _ in
            withAnimation {
                self.newArtworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl
            }
        }
    }
    func adjustedColor(_ nsColor: NSColor) -> Color {
        // Convert NSColor to HSB components
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Adjust brightness
        brightness = brightness - 0.2
        
        if saturation < 0.8 {
            // Adjust contrast
            saturation = saturation * 3
        }
        
        // Create new NSColor with modified HSB values
        let modifiedNSColor = NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        
        // Convert NSColor to SwiftUI Color
        return Color(modifiedNSColor)
    }
}

@available(macOS 14.0, *)
struct BackgroundView: View {
    @Binding var colors: [SwiftUI.Color]
    @Binding var timer: Publishers.Autoconnect<Timer.TimerPublisher>
    @Binding var points: ColorSpots

    static let animationDuration: Double = 5
    @State var bias: Float = 0.002
    @State var power: Float = 2.5
    @State var noise: Float = 2

    var body: some View {
        MulticolorGradient(
            points: points,
            bias: bias,
            power: power,
            noise: noise
        )
        .onChange(of: colors) {
            print("change color called")
            withAnimation(.easeInOut(duration: BackgroundView.animationDuration/2)){
                points = self.colors.map { .random(withColor: $0) }
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: BackgroundView.animationDuration)) {
                points = self.colors.map { .random(withColor: $0) }
            }
        }
//        .onAppear {
//            points = self.colors.map { .random(withColor: $0) }
//        }
    }
    
}

private extension ColorSpot {
    static func random(withColor color: SwiftUI.Color) -> ColorSpot {
        .init(
            position: .init(x: CGFloat.random(in: 0 ..< 1), y: CGFloat.random(in: 0 ..< 1)),
            color: color
        )
    }
}
