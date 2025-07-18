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
import TipKit

@available(macOS 14.0, *)
struct FullscreenView: View {
    @Environment(ViewModel.self) var viewmodel
    @State var newSpotifyMusicArtworkImage: NSImage?
    @Binding var currentPlayer: PlayerType
    @State var newArtworkUrl: String?
    @State var newAppleMusicArtworkImage: NSImage?
    @State var animate = true
    @State var showSettingsPopover = false
    @State var gradient = [Color(red: 33/255, green: 69/255, blue: 152/255),Color(red: 218/255, green: 62/255, blue: 136/255)]
    @State var currentHover = hoverOptions.none
    
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
        case settings
        case sharing
    }
    
    @ViewBuilder func FullscreenButtons() -> some View {
        let highlightTip = NewSettings()
        HStack(alignment: .center, spacing: 6) {
            Button {
                if currentPlayer == .spotify, let soundVolume = viewmodel.spotifyScript?.soundVolume {
                    viewmodel.spotifyScript?.setSoundVolume?(soundVolume-5)
                } else if currentPlayer == .appleMusic, let soundVolume = viewmodel.appleMusicScript?.soundVolume {
                    viewmodel.appleMusicScript?.setSoundVolume?(soundVolume-5)
                }
            } label: {
                HoverableIcon(systemName: "speaker.minus")
            }
            .buttonStyle(FullscreenButtonIconStyle())
            .onHover { hover in currentHover = hover ? .volumelow : .none }
            .keyboardShortcut(.downArrow, modifiers: [])

            Button {
                if currentPlayer == .appleMusic {
                    viewmodel.appleMusicScript?.playpause?()
                } else if currentPlayer == .spotify {
                    viewmodel.spotifyScript?.playpause?()
                }
            } label: {
                HoverableIcon(systemName: viewmodel.isPlaying ? "pause" : "play")
            }
            .buttonStyle(FullscreenButtonIconStyle())
            .onHover { hover in currentHover = hover ? .playpause : .none }
            .keyboardShortcut(" ", modifiers: [])

            Button {
                if currentPlayer == .spotify, let soundVolume = viewmodel.spotifyScript?.soundVolume {
                    viewmodel.spotifyScript?.setSoundVolume?(soundVolume+5)
                } else if currentPlayer == .appleMusic, let soundVolume = viewmodel.appleMusicScript?.soundVolume {
                    viewmodel.appleMusicScript?.setSoundVolume?(soundVolume+5)
                }
            } label: {
                HoverableIcon(systemName: "speaker.plus")
            }
            .buttonStyle(FullscreenButtonIconStyle())
            .onHover { hover in currentHover = hover ? .volumehigh : .none }
            .keyboardShortcut(.upArrow, modifiers: [])
        }
        .font(.system(size: 15))
        HStack(alignment: .center, spacing: 5) {
            Button {
                if viewmodel.showLyrics {
                    viewmodel.showLyrics = false
                    viewmodel.stopLyricUpdater()
                } else {
                    viewmodel.showLyrics = true
                    // Only Spotify has access to Fullscreen view
                    viewmodel.startLyricUpdater()
                }
                
            } label: {
                HoverableIcon(systemName: "music.note.list", sideLength: 28, disabled: !viewmodel.showLyrics)
                    
            }
            .buttonStyle(FullscreenButtonIconStyle())
            .onHover { hover in
                currentHover = hover ? .showlyrics : .none
            }
            .keyboardShortcut("h")
            .disabled(viewmodel.currentlyPlayingLyrics.isEmpty)
            
            Button {
                viewmodel.userDefaultStorage.translate.toggle()
            } label: {
                HoverableIcon(systemName: "translate", sideLength: 28, disabled: !viewmodel.userDefaultStorage.translate)
            }
            .buttonStyle(FullscreenButtonIconStyle())
            .onHover { hover in
                currentHover = hover ? .translate : .none
            }
            .keyboardShortcut("t")
            .disabled(viewmodel.currentlyPlayingLyrics.isEmpty)
                            
            
            
            Button {
                animate.toggle()
            } label: {
                HoverableIcon(systemName: "leaf", sideLength: 28, disabled: !animate)
            }
            .buttonStyle(FullscreenButtonIconStyle())
            .onHover { hover in
                currentHover = hover ? .pauseanimation : .none
            }
            .keyboardShortcut("a")
            
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
        }
        .font(.system(size: 12))
    }
    
    @ViewBuilder var albumArt: some View {
        VStack {
            Spacer()
            if currentPlayer == .appleMusic , let newAppleMusicArtworkImage {
                Image(nsImage: newAppleMusicArtworkImage)
                                        .resizable()
                                        .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                                        .shadow(radius: 5)
                                        .frame(width: canDisplayLyrics ? 550 : 700, height: canDisplayLyrics ? 550 : 700)
            }
            else if currentPlayer == .spotify, let newArtworkUrl  {
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
                            .listRowSeparator(.hidden)
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
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .mask(LinearGradient(gradient: Gradient(colors: [.clear, .black, .clear]), startPoint: .top, endPoint: .bottom))
                Spacer()
                
            }
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

                if currentPlayer == .spotify, let artworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl, artworkUrl != "" {
                    print(artworkUrl)
                    withAnimation {
                        self.newArtworkUrl = artworkUrl
                    }
                }
                else if currentPlayer == .appleMusic, let artwork = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data  {
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
                if let newArtwork, var dominantColors = try? newArtwork.dominantColors(with: .best, algorithm: .kMeansClustering) {
                    dominantColors.sort(by: {$0.saturationComponent > $1.saturationComponent})
                    gradient = dominantColors.map({adjustedColor($0)})
                }
            }
            .onChange(of: viewmodel.currentlyPlayingName) { _ in
                if currentPlayer == .spotify, let artworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl, artworkUrl != "" {
                    print("spotify artwork is \(artworkUrl)")
                    withAnimation {
                        self.newArtworkUrl = artworkUrl
                    }
                }
                else if currentPlayer == .appleMusic, let artwork = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data  {
                    newAppleMusicArtworkImage = artwork
                }
                else if let artistName = viewmodel.currentlyPlayingArtist, let currentAlbumName = viewmodel.currentAlbumName {
                    print("\(artistName) \(currentAlbumName)")
                    Task {
                        if let mbid = await viewmodel.findMbid(albumName: currentAlbumName, artistName: artistName) {
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
