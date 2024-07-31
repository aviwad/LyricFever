//
//  FullscreenView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2024-07-27.
//

import SwiftUI

struct FullscreenView: View {
    @EnvironmentObject var viewmodel: viewModel
    @AppStorage("spotifyOrAppleMusic") var spotifyOrAppleMusic: Bool = false
    @State var newAppleMusicArtworkImage: NSImage?
    @State var newArtworkUrl: String?
    
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
                        .padding(.horizontal, 10)
                        .blur(radius: (i == viewmodel.currentlyPlayingLyricsIndex || i == viewmodel.currentlyPlayingLyrics.count-1) ? 0 : 8)
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
            BackgroundView()
        }
        .onAppear {
            withAnimation {
                if spotifyOrAppleMusic {
                    self.newAppleMusicArtworkImage = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as! MusicArtwork).data
                } else {
                    self.newArtworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl
                }
            }
        }
        .onChange(of: viewmodel.currentlyPlayingName) { _ in
            withAnimation {
                if spotifyOrAppleMusic {
                    self.newAppleMusicArtworkImage = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as! MusicArtwork).data
                } else {
                    self.newArtworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl
                }
            }
        }
    }
}

struct BackgroundView: View {

@State var gradient = [Color.red, Color.purple, Color.orange]

@State var startPoint = UnitPoint(x: 0, y: 0)
@State var endPoint = UnitPoint(x: 0, y: 2)

var body: some View {
    LinearGradient(gradient: Gradient(colors: self.gradient), startPoint: self.startPoint, endPoint: self.endPoint)
    .edgesIgnoringSafeArea(.all)
    .onAppear {
        withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            self.startPoint = UnitPoint(x: 1, y: -1)
            self.endPoint = UnitPoint(x: 0, y: 1)
        }
    }
}}
