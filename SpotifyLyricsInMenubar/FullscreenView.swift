//
//  FullscreenView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2024-07-27.
//

import SwiftUI
import vibrant
import SDWebImageSwiftUI

struct FullscreenView: View {
    @EnvironmentObject var viewmodel: viewModel
    @AppStorage("spotifyOrAppleMusic") var spotifyOrAppleMusic: Bool = false
    @State var newAppleMusicArtworkImage: NSImage?
    @State var newSpotifyMusicArtworkImage: NSImage?
    @State var newArtworkUrl: String?
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
                        .frame(width: 550, height: 550)
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
                            case .failure(let error):
                                Image(systemName: "music.note.list")
                                    .resizable()
                                    .shadow(radius: 3)
                                    .scaleEffect(0.5)
                                    .background(.gray)
                        }
                    }
//                     } placeholder: {
//                         Image(systemName: "music.note.list")
//                             .resizable()
//                     }
                     .onSuccess { image, data, cacheType in
                         if let data {
                             newSpotifyMusicArtworkImage = NSImage(data: data)
                         }
                     }
                        .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                        .shadow(radius: 5)
                        .frame(width: 550, height: 550)
                } else {
                    Image(systemName: "music.note.list")
                        .resizable()
                        .shadow(radius: 3)
                        .scaleEffect(0.5)
                        .background(.gray)
                        .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                        .shadow(radius: 5)
                        .frame(width: 550, height: 550)
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
//            if gradient.count >= 6 {
//                VStack {
//                    Text("Muted \(gradient.first?.description)")
//                    .foregroundStyle(gradient[0])
//                    Text("Dark Muted \(gradient[1].description)")
//                    .foregroundStyle(gradient[1])
//                    Text("Light Muted \(gradient[2].description)")
//                    .foregroundStyle(gradient[2])
//                    Text("Vibrant \(gradient[3].description)")
//                    .foregroundStyle(gradient[3])
//                    Text("Dark Vibrant \(gradient[4].description)")
//                    .foregroundStyle(gradient[4])
//                    Text("Light Vibrant \(gradient[5].description)")
//                    .foregroundStyle(gradient[5])
//                }
//                .bold()
//                .background(.white)
//            }
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
                    .frame( minWidth: 0.50*(geo.size.width), maxWidth: 0.50*(geo.size.width))
                   // .frame(minWidth: 1000, maxWidth: .infinity)
                lyrics
                    .frame( minWidth: 0.50*(geo.size.width), maxWidth: 0.50*(geo.size.width))
            }
        }
        .background {
            BackgroundView(colors: $gradient)
        }
        .onAppear {
            withAnimation {
                if spotifyOrAppleMusic {
                    self.newAppleMusicArtworkImage = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data
                    if let newAppleMusicArtworkImage {
                        let palette = Vibrant.from(newAppleMusicArtworkImage).getPalette()
                        if let muted = palette.Muted?.uiColor, let darkMuted = palette.DarkMuted?.uiColor, let lightMuted = palette.LightMuted?.uiColor, let darkVibrant = palette.DarkVibrant?.uiColor, let vibrant = palette.Vibrant?.uiColor, let lightVibrant = palette.LightVibrant?.uiColor {
                            gradient = [Color(muted),Color(darkMuted),Color(lightMuted),Color(darkVibrant),Color(vibrant),Color(lightVibrant)]
                        }
                    }
                } else {
                    self.newArtworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl
                }
            }
        }
        .onChange(of: newSpotifyMusicArtworkImage) { newArtwork in
            print("NEW ARTWORK")
            guard let newArtwork else {
                return
            }
            let palette = Vibrant.from(newArtwork).getPalette()
            if let muted = palette.Muted?.uiColor, let darkMuted = palette.DarkMuted?.uiColor, let lightMuted = palette.LightMuted?.uiColor, let darkVibrant = palette.DarkVibrant?.uiColor, let vibrant = palette.Vibrant?.uiColor, let lightVibrant = palette.LightVibrant?.uiColor {
                gradient = [Color(muted),Color(darkMuted),Color(lightMuted),Color(darkVibrant),Color(vibrant),Color(lightVibrant)]
            }
        }
        .onChange(of: viewmodel.currentlyPlayingName) { _ in
            withAnimation {
                if spotifyOrAppleMusic {
                    self.newAppleMusicArtworkImage = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data
                    if let newAppleMusicArtworkImage {
                        let palette = Vibrant.from(newAppleMusicArtworkImage).getPalette()
                        if let muted = palette.Muted?.uiColor, let darkMuted = palette.DarkMuted?.uiColor, let lightMuted = palette.LightMuted?.uiColor, let darkVibrant = palette.DarkVibrant?.uiColor, let vibrant = palette.Vibrant?.uiColor, let lightVibrant = palette.LightVibrant?.uiColor {
                            gradient = [Color(muted),Color(darkMuted),Color(lightMuted),Color(darkVibrant),Color(vibrant),Color(lightVibrant)]
                        }
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
        //    controls
         //       .padding()
        }
        .onChange(of: colors) {
            print("change color called")
            withAnimation(.easeInOut(duration: BackgroundView.animationDuration/2)){
                points = self.colors.map { .random(withColor: $0) }
            }
        }
        .onReceive(timer) { _ in animate() }
       // .onAppear { animate() }
    }
    
}

private extension BackgroundView {
    var controls: some View {
        VStack {
            Spacer()
            labeldSlider("bias", value: $bias, in: 0.001 ... 0.5)
            labeldSlider("power", value: $power, in: 1 ... 10)
            labeldSlider("noise", value: $noise, in: 0 ... 400)
        }
    }

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
