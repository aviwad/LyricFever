//
//  FullscreenView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2024-07-27.
//

import SwiftUI
import SDWebImageSwiftUI
import ColorKit

struct FullscreenView: View {
    @EnvironmentObject var viewmodel: viewModel
    @AppStorage("spotifyOrAppleMusic") var spotifyOrAppleMusic: Bool = false
    @State var newAppleMusicArtworkImage: NSImage?
    @State var newSpotifyMusicArtworkImage: NSImage?
    @State var newArtworkUrl: String?
    @State var showLyrics = true
    @State var gradient = [SwiftUI.Color(red: 33/255, green: 69/255, blue: 152/255),SwiftUI.Color(red: 218/255, green: 62/255, blue: 136/255)]
    
    @ViewBuilder var albumArt: some View {
        VStack {
            Spacer()
            if spotifyOrAppleMusic {
                if let newAppleMusicArtworkImage {
                    Image(nsImage: newAppleMusicArtworkImage)
                        .resizable()
                        .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                        .shadow(radius: 5)
                        .frame(width: showLyrics ? 550 : 700, height: showLyrics ? 550 : 700)
                }
            } else {
                if let newArtworkUrl  {
                    WebImage(url: .init(string: newArtworkUrl), options: .queryMemoryData) { image in
                        switch image {
                            case .empty:
                                Image(systemName: "music.note.list")
                                    .resizable()
                                    .shadow(radius: 3)
                                    .scaleEffect(0.5)
                                    .background(.gray)
                            case .success(let image):
                                image.resizable()
                            case .failure(_):
                                Image(systemName: "music.note.list")
                                    .resizable()
                                    .shadow(radius: 3)
                                    .scaleEffect(0.5)
                                    .background(.gray)
                        }
                    }
                     .onSuccess { image, data, cacheType in
                         if let data {
                             newSpotifyMusicArtworkImage = NSImage(data: data)
                         }
                     }
                        .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                        .shadow(radius: 5)
                        .frame(width: showLyrics ? 550 : 700, height: showLyrics ? 550 : 700)
                } else {
                    Image(systemName: "music.note.list")
                        .resizable()
                        .shadow(radius: 3)
                        .scaleEffect(0.5)
                        .background(.gray)
                        .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                        .shadow(radius: 5)
                        .frame(width: showLyrics ? 550 : 700, height: showLyrics ? 550 : 700)
                }
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
                    print("spotify or apple music: \(spotifyOrAppleMusic)")
                    if spotifyOrAppleMusic {
                        viewmodel.appleMusicScript?.playpause?()
                    } else {
                        viewmodel.spotifyScript?.playpause?()
                    }
                } label: {
                    Image(systemName: "pause")
                }
                .keyboardShortcut(KeyEquivalent(" "), modifiers: [])
                Button {
                    showLyrics.toggle()
                    
                } label: {
                    Image(systemName: "music.note.list")
                }
            }
            Spacer()
        }
    }
    
    @ViewBuilder var lyrics: some View {
        VStack(alignment: .leading){
            Spacer()
            ScrollView(showsIndicators: false){
                ForEach (viewmodel.currentlyPlayingLyrics.indices, id:\.self) { i in
                    Text(viewmodel.currentlyPlayingLyrics[i].words)
                        .font(.system(size: 50, weight: .bold, design: .default))
                        .padding(.vertical, 20)
                        .blur(radius: (i == viewmodel.currentlyPlayingLyricsIndex || i == viewmodel.currentlyPlayingLyrics.count-1) ? 0 : 8)
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
                    .frame( minWidth: 0.50*(geo.size.width), maxWidth: showLyrics ? 0.50*(geo.size.width) : .infinity)
                if showLyrics {
                    lyrics
                        .frame( minWidth: 0.50*(geo.size.width), maxWidth: 0.50*(geo.size.width))
                }
            }
        }
        .background {
            BackgroundView(colors: $gradient)
        }
        .onAppear {
            withAnimation {
                if spotifyOrAppleMusic {
                    self.newAppleMusicArtworkImage = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data
                    if let newAppleMusicArtworkImage, let dominantColors = try? newAppleMusicArtworkImage.dominantColors(with: .best, algorithm: .kMeansClustering) {
                        gradient = dominantColors.map({Color($0)})
                    }
                } else {
                    self.newArtworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl
                }
            }
        }
        .onChange(of: newSpotifyMusicArtworkImage) { newArtwork in
            print("NEW ARTWORK")
            if let newArtwork, let dominantColors = try? newArtwork.dominantColors(with: .best, algorithm: .kMeansClustering) {
                gradient = dominantColors.map({Color($0)})
            }
        }
        .onChange(of: viewmodel.currentlyPlayingName) { _ in
            withAnimation {
                if spotifyOrAppleMusic {
                    self.newAppleMusicArtworkImage = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data
                    if let newAppleMusicArtworkImage, let dominantColors = try? newAppleMusicArtworkImage.dominantColors(with: .best, algorithm: .kMeansClustering) {
                        gradient = dominantColors.map({Color($0)})
                    }
                } else {
                    self.newArtworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl
                }
            }
        }
    }
}

struct BackgroundView: View {
    @Binding var colors: [SwiftUI.Color]
    @State var points: ColorSpots = .init()

    static let animationDuration: Double = 5
    @State var bias: Float = 0.002
    @State var power: Float = 2.5
    @State var noise: Float = 2

    let timer = Timer
        .publish(every: BackgroundView.animationDuration * 0.8, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        ZStack {
            MulticolorGradient(
                points: points,
                bias: bias,
                power: power,
                noise: noise
            )
            .ignoresSafeArea()
        }
        .onChange(of: colors) {
            print("change color called")
            withAnimation(.easeInOut(duration: BackgroundView.animationDuration/2)){
                points = self.colors.map { .random(withColor: $0) }
            }
        }
        .onReceive(timer) { _ in animate() }
    }
    
}

private extension BackgroundView {
    func animate() {
        print("animate called")
        withAnimation(.easeInOut(duration: BackgroundView.animationDuration)) {
            points = self.colors.map { .random(withColor: $0) }
        }
    }

    func labeldSlider(
        _ label: String,
        value: Binding<Float>,
        in bounds: ClosedRange<Float>
    ) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(label)
                Text(String(format: "%.4f", value.wrappedValue))
            }
            .font(.system(size: 10))
            .frame(minWidth: 50, alignment: .leading)

            Slider(value: value, in: bounds)
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
