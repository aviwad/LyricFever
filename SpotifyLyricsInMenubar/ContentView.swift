//
//  ContentView.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 26/07/23.
//

import SwiftUI

struct ContentView: View {
    @State var currentlyPlaying: String?
    @State var currentlyPlayingLyrics: [LyricLine] = []
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(currentlyPlaying != nil ? "Current Spotify Track ID: \(currentlyPlaying!)" : "Nothing playing")
            List {
                ForEach(currentlyPlayingLyrics.indices, id: \.self) { lyricIndex in
                    HStack {
                        Text(currentlyPlayingLyrics[lyricIndex].startTimeMS)
                            .font(.subheadline)
                        Text(currentlyPlayingLyrics[lyricIndex].words)
                    }
                }
            }
        }
        .onReceive(DistributedNotificationCenter.default().publisher(for: Notification.Name(rawValue:  "com.spotify.client.PlaybackStateChanged")), perform: { notification in
            currentlyPlaying = (notification.userInfo?["Track ID"] as? String)?.components(separatedBy: ":").last
        })
        .onChange(of: currentlyPlaying) { nowPlaying in
            print(nowPlaying)
            Task {
                if let lyrics = await lyricsFetcher().fetchLyrics(for: nowPlaying) {
                    currentlyPlayingLyrics = lyrics
                }
            }
        }
        .padding()
    }
    
    actor lyricsFetcher {
        func fetchLyrics(for trackID: String?) async -> [LyricLine]? {
            if let trackID, let url = URL(string: "https://spotify-lyric-api.herokuapp.com/?trackid=\(trackID)"), let urlResponseAndData = try? await URLSession.shared.data(from: url), let lyrics = try? JSONDecoder().decode(LyricJson.self, from: urlResponseAndData.0) {
                return lyrics.lines
            }
            return nil
        }
    }
}
