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
    @AppStorage("spotifyOrAppleMusic") var spotifyOrAppleMusic: Bool = false
    @State var newArtworkUrl: String?
    @State var newAppleMusicArtworkImage: NSImage?
    @State var animate = true
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
        case translate
        case none
    }
    
    @ViewBuilder var albumArt: some View {
        VStack {
            Spacer()
            if spotifyOrAppleMusic, let newAppleMusicArtworkImage {
                Image(nsImage: newAppleMusicArtworkImage)
                                        .resizable()
                                        .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                                        .shadow(radius: 5)
                                        .frame(width: canDisplayLyrics ? 550 : 700, height: canDisplayLyrics ? 550 : 700)
            }
            else if let newArtworkUrl  {
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
                    spotifyOrAppleMusic ? viewmodel.appleMusicScript?.playpause?() : viewmodel.spotifyScript?.playpause?()
                    
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
                        viewmodel.startLyricUpdater(appleMusicOrSpotify: spotifyOrAppleMusic)
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
                    viewmodel.translate.toggle()
                } label: {
                    Image(systemName: "translate")
                }
                .onHover { hover in
                    currentHover = hover ? .translate : .none
                }
                .keyboardShortcut("t")
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
                .keyboardShortcut("a")
                
                Button {
                    if !spotifyOrAppleMusic, let soundVolume = viewmodel.spotifyScript?.soundVolume {
                        viewmodel.spotifyScript?.setSoundVolume?(soundVolume-5)
                    } else if let soundVolume = viewmodel.appleMusicScript?.soundVolume{
                        viewmodel.appleMusicScript?.setSoundVolume?(soundVolume-5)
                    }
                } label: {
                    Image(systemName: "speaker.minus")
                }
                .onHover { hover in
                    currentHover = hover ? .volumelow : .none
                }
                .keyboardShortcut(KeyEquivalent.downArrow, modifiers: [])
                
                Button {
                    if !spotifyOrAppleMusic, let soundVolume = viewmodel.spotifyScript?.soundVolume {
                        viewmodel.spotifyScript?.setSoundVolume?(soundVolume+5)
                    } else if let soundVolume = viewmodel.appleMusicScript?.soundVolume{
                        viewmodel.appleMusicScript?.setSoundVolume?(soundVolume+5)
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
                animate ? "Pause animations (saves battery) (⌘ + A)" : "Unpause animations (uses battery) (⌘ + A)"
            case .volumelow:
                "Decrease volume by 5 (Down Arrow)"
            case .volumehigh:
                "Increase volume by 5 (Up Arrow)"
            case .none:
                ""
            case .translate:
                viewmodel.translate ? "Hide translations (⌘ + T)" : "Translate lyrics (⌘ + T)"
        }
    }
    
    @ViewBuilder func lyricLineView(for element: LyricLine, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(element.words)
                .foregroundStyle(.white)
            if viewmodel.translate, !viewmodel.translatedLyric.isEmpty {
                Text(viewmodel.translatedLyric[index])
                    .font(.system(size: 33, weight: .semibold, design: .default))
                    .opacity(0.85)
            }
        }
    }
    
    @ViewBuilder func lyrics(padding: CGFloat) -> some View {
        VStack(alignment: .leading){
            Spacer()
            ScrollViewReader { proxy in
                List (Array(viewmodel.currentlyPlayingLyrics.enumerated()), id: \.element) { offset, element in
                    lyricLineView(for: element, index: offset)
                        .opacity(offset == viewmodel.currentlyPlayingLyrics.count - 1 ? 0 : 1)
                        .font(.system(size: 40, weight: .bold, design: .default))
                        .padding(20)
                        .listRowSeparator(.hidden)
                        .blur(radius: offset == viewmodel.currentlyPlayingLyricsIndex ? 0 : 8)
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
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .mask(LinearGradient(gradient: Gradient(colors: [.clear, .black, .clear]), startPoint: .top, endPoint: .bottom))
            Spacer()
            
        }
    }
    
    var body: some View {
        if viewmodel.fullscreenInProgress {
            // The animation to fullscreen can look jarring otherwise
            Color(.windowBackgroundColor)
        } else {
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
                ZStack {
                    BackgroundView(colors: $gradient, timer: $timer, points: $points)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
            .onAppear {
                if !spotifyOrAppleMusic, let artworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl, artworkUrl != "" {
                    print(artworkUrl)
                    withAnimation {
                        self.newArtworkUrl = artworkUrl
                    }
                }
                else if spotifyOrAppleMusic, let artwork = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data  {
                    newAppleMusicArtworkImage = artwork
                }
                else if let artistName = viewmodel.currentlyPlayingArtist, let albumName = viewmodel.spotifyScript?.currentTrack?.album {
                    print("\(artistName) \(albumName)")
                    Task {
                        if let mbid = await viewmodel.findMbid(albumName: albumName, artistName: artistName) {
                            withAnimation {
                                self.newArtworkUrl = "https://coverartarchive.org/release/\(mbid)/front"
                            }
                        }
                        
                    }
                }
            }
            .onChange(of: newAppleMusicArtworkImage) { newArtwork in
                print("NEW ARTWORK")
                if let newArtwork, let dominantColors = try? newArtwork.dominantColors(with: .best, algorithm: .kMeansClustering) {
                    gradient = dominantColors.map({adjustedColor($0)})
                }
            }
            .onChange(of: newSpotifyMusicArtworkImage) { newArtwork in
                print("NEW ARTWORK")
                if let newArtwork, let dominantColors = try? newArtwork.dominantColors(with: .best, algorithm: .kMeansClustering) {
                    gradient = dominantColors.map({adjustedColor($0)})
                }
            }
            .onChange(of: viewmodel.currentlyPlayingName) { _ in
                if !spotifyOrAppleMusic, let artworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl, artworkUrl != "" {
                    print("spotify artwork is \(artworkUrl)")
                    withAnimation {
                        self.newArtworkUrl = artworkUrl
                    }
                }
                else if spotifyOrAppleMusic, let artwork = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data  {
                    newAppleMusicArtworkImage = artwork
                }
                else if let artistName = viewmodel.currentlyPlayingArtist, let albumName = viewmodel.spotifyScript?.currentTrack?.album {
                    print("\(artistName) \(albumName)")
                    Task {
                        if let mbid = await viewmodel.findMbid(albumName: albumName, artistName: artistName) {
                            withAnimation {
                                print("setting newartwork url to: https://coverartarchive.org/release/\(mbid)/front")
                                self.newArtworkUrl = "https://coverartarchive.org/release/\(mbid)/front"
                            }
                        }
                        
                    }
                }
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
        brightness = max(brightness - 0.2, 0.1)
        
        if saturation < 0.9 {
            // Adjust contrast
            saturation = max(0.1, saturation * 3)
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

    static let animationDuration: Double = 20
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
