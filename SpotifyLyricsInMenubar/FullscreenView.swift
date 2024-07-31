//
//  FullscreenView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2024-07-27.
//

import SwiftUI

struct FullscreenView: View {
    @EnvironmentObject var viewmodel: viewModel
    var body: some View {
        if let currentlyPlayingLyricsIndex = viewmodel.currentlyPlayingLyricsIndex {
            ScrollViewReader { proxy in
                List (viewmodel.currentlyPlayingLyrics.indices, id:\.self) { i in
                    Text(viewmodel.currentlyPlayingLyrics[i].words)
                        .bold(currentlyPlayingLyricsIndex == i)
                        .font(.system(size: 50, weight: .bold, design: .default))
                        .padding(.vertical, 10)
                        .blur(radius: currentlyPlayingLyricsIndex == i ? 0 : 5)
                        .onChange(of: currentlyPlayingLyricsIndex) { newIndex in
                            withAnimation {
                                proxy.scrollTo(newIndex, anchor: .center)
                            }
                        }
            }
            }
        } else {
            Image(systemName: "music.note.list")
        }
    }
}
