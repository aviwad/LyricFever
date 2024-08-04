//
//  FullscreenView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2024-07-27.
//

import SwiftUI
import vibrant

struct FullscreenView: View {
    @EnvironmentObject var viewmodel: viewModel
    @AppStorage("spotifyOrAppleMusic") var spotifyOrAppleMusic: Bool = false
    @State var newAppleMusicArtworkImage: NSImage?
    @State var newArtworkUrl: String?
    @State var gradient = [Color.red, Color.purple, Color.orange]
    @State var points: ColorSpots = .init()
    
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
                    AsyncImage(url: .init(string: newArtworkUrl), transaction:Transaction(animation: .default)) { phase in
                        switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                            default:
                                Image(systemName: "music.note.list")
                        }
                    }
                        .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                        .shadow(radius: 5)
                        .frame(width: 550, height: 550)
                       // .frame(minWidth: 0, maxWidth: .infinity)
                } else {
                    Image(systemName: "music.note.list")
                }
            }
            if let currentlyPlayingName = viewmodel.currentlyPlayingName, let currentlyPlayingArtist = viewmodel.currentlyPlayingArtist {
                Text(currentlyPlayingName)
                    .font(.title)
                    .bold()
                    .padding(.top, 30)
                Text(currentlyPlayingArtist)
                    .font(.title2)
            }
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
            HStack {
                Button("Muted") {
                    
                }
                Button("Dark Muted") {
                    
                }
                Button("Light Muted") {
                    
                }
                Button("Vibrant") {
                    
                }
                Button("Dark Vibrant") {
                    
                }
                Button("Light Vibrant") {
                    
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
                    .frame( minWidth: 0.50*(geo.size.width), maxWidth: 0.50*(geo.size.width))
                   // .frame(minWidth: 1000, maxWidth: .infinity)
                lyrics
                    .frame( minWidth: 0.50*(geo.size.width), maxWidth: 0.50*(geo.size.width))
            }
        }
        .background {
            BackgroundView(colors: $gradient, points: $points)
        }
        .onAppear {
            withAnimation {
                if spotifyOrAppleMusic {
                    self.newAppleMusicArtworkImage = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data
                    if let newAppleMusicArtworkImage {
                        let palette = Vibrant.from(newAppleMusicArtworkImage).getPalette()
                        if let muted = palette.Muted?.uiColor, let darkMuted = palette.DarkMuted?.uiColor, let lightMuted = palette.LightMuted?.uiColor, let darkVibrant = palette.DarkVibrant?.uiColor, let vibrant = palette.Vibrant?.uiColor {
                            gradient = [Color(muted),Color(darkMuted),Color(lightMuted),Color(darkVibrant),Color(vibrant)]
                        }
                    }
                } else {
                    self.newArtworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl
                }
            }
        }
        .onChange(of: gradient) { newGradient in
            points = newGradient.map { .random(withColor: $0) }
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

//struct BackgroundView: View {
//
//@State var startPoint = UnitPoint(x: 0, y: 0)
//@State var endPoint = UnitPoint(x: 0, y: 2)
//@Binding var gradient: [SwiftUI.Color]
//
//var body: some View {
//    ZStack {
//        LinearGradient(gradient: Gradient(colors: self.gradient), startPoint: self.startPoint, endPoint: self.endPoint)
//        .edgesIgnoringSafeArea(.all)
//        .onAppear {
//            withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
//                self.startPoint = UnitPoint(x: 1, y: -1)
//                self.endPoint = UnitPoint(x: 0, y: 1)
//            }
//        }
//    }
//}}

struct BackgroundView: View {
    @Binding var colors: [SwiftUI.Color]
    @Binding var points: ColorSpots
    //@State var points: ColorSpots = BackgroundView.colors.map { .random(withColor: $0) }

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
//            controls
//                .padding()
        }
        .onReceive(timer) { _ in animate() }
        .onAppear { animate() }
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
