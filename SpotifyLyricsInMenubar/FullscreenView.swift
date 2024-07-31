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
            if spotifyOrAppleMusic {
                if let newAppleMusicArtworkImage {
                    Image(nsImage: newAppleMusicArtworkImage)
                        .resizable()
                        .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10, bottomTrailing: 10, topTrailing: 10)))
                        .shadow(radius: 5)
                        .frame(width: 600, height: 600)
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
                        .frame(width: 600, height: 600)
                       // .frame(minWidth: 0, maxWidth: .infinity)
                } else {
                    Image(systemName: "music.note.list")
                }
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
        }
    }
    
    @ViewBuilder var lyrics: some View {
        GeometryReader { geo in
            VStack(alignment: .leading){
                Spacer()
                    .frame(maxHeight: 0.45*(geo.size.height))
                ScrollViewReader { proxy in
                    List (viewmodel.currentlyPlayingLyrics.indices, id:\.self) { i in
                        Text(viewmodel.currentlyPlayingLyrics[i].words)
                            .bold(viewmodel.currentlyPlayingLyricsIndex == i)
                            .font(.system(size: 50, weight: .bold, design: .default))
                            .padding(.vertical, 20)
                            .blur(radius: viewmodel.currentlyPlayingLyricsIndex == i ? 0 : 5)
                            .onChange(of: viewmodel.currentlyPlayingLyricsIndex) { newIndex in
                                withAnimation {
                                    proxy.scrollTo(newIndex, anchor: .topLeading)
                                }
                            }
                            //.frame(width: 0.7*geo.size.width, alignment: .trailing)
                            .listRowSeparator(.hidden)
                            .contentShape(.rect)
//                            .scrollTransition { effect, phase in
//                                effect
//                                    
//                            }
//                            .onTapGesture {
//                                if spotifyOrAppleMusic {
//                                    viewmodel.appleMusicScript?.setPlayerPosition?(viewmodel.currentlyPlayingLyrics[i].startTimeMS)
//                                } else {
//                                    viewmodel.spotifyScript?.setPlayerPosition?(viewmodel.currentlyPlayingLyrics[i].startTimeMS)
//                                }
//                                viewmodel.currentlyPlayingLyricsIndex = i
//                            }
//                            .scrollTransition(.animated(.smooth)) { view, transition in
////                                content
////                                    .opacity(phase.isIdentity ? 1 : 0)
////                                    .scaleEffect(phase.isIdentity ? 1 : 0.75)
////                                    .blur(radius: phase.isIdentity ? 0 : 10)
//                                view
//                                    .scaleEffect(transition.isIdentity ? 1 : 0.5)
//                            }
                    }
                    
                    .scrollContentBackground(.hidden)
                    .padding(.trailing, 100)
                    .frame( maxWidth: viewmodel.currentlyPlayingLyricsIndex == nil ? .none : .infinity, minHeight: 0.55*(geo.size.height), maxHeight: 0.55*(geo.size.height), alignment: .bottom)
                }
                .scrollPosition(id: $viewmodel.currentlyPlayingLyricsIndex)
                .mask(LinearGradient(gradient: Gradient(colors: [.black, .black, .black, .clear]), startPoint: .top, endPoint: .bottom))
            }
        }
    }
    
    var body: some View {
        HStack {
            albumArt
                .frame(minWidth: 1000, maxWidth: .infinity)
            lyrics
        }
        .background {
            
        }
        .onAppear {
            withAnimation {
                self.newArtworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl
                self.newAppleMusicArtworkImage = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as! MusicArtwork).data
            }
        }
        .onChange(of: viewmodel.currentlyPlayingName) { _ in
            withAnimation {
                self.newArtworkUrl = viewmodel.spotifyScript?.currentTrack?.artworkUrl
                self.newAppleMusicArtworkImage = (viewmodel.appleMusicScript?.currentTrack?.artworks?().firstObject as! MusicArtwork).data
            }
        }
    }
}
