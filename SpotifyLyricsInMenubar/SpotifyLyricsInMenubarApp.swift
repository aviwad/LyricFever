//
//  SpotifyLyricsInMenubarApp.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 26/07/23.
//

import SwiftUI
import MusicPlayer

@main
struct SpotifyLyricsInMenubarApp: App {
    @State var currentlyPlaying: String?
    @State var currentlyPlayingName: String?
    @State var currentlyPlayingLyrics: [LyricLine] = []
    @State var currentlyPlayingLyricsIndex: Int?
    @State var currentMS: TimeInterval = 0
    @State var isPlaying: Bool = true
    @State var timer = Timer.publish(every: 1, tolerance: 1, on: .main, in: .common).autoconnect()
    
    var player = MusicPlayers.Scriptable(name: .spotify)!
    
    var body: some Scene {
        MenuBarExtra(content: {
            Text(menuBarTitleText())
            
            if let currentlyPlaying, let currentlyPlayingName {
                Text(!currentlyPlayingLyrics.isEmpty ? "Lyrics Found 😃" : "No Lyrics Found ☹️")
                if currentlyPlayingLyrics.isEmpty {
                    Button("Check For Lyrics Again") {
                        Task {
                            currentlyPlayingLyrics = await lyricsFetcher().fetchLyrics(for: currentlyPlaying, currentlyPlayingName)
                            if isPlaying, !currentlyPlayingLyrics.isEmpty {
                                timer = Timer.publish(every: 1, tolerance: 1, on: .main, in: .common).autoconnect()
                            }
                        }
                    }
                }
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        } , label: {
            Text(menuBarText())
           // Text("hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh")
                .onAppear {
                    print("Application just started. lets check whats playing")
                    if let currentTrack = player.currentTrack {
                        print(currentTrack)
                    } else {
                        timer.upstream.connect().cancel()
                    }
                }
                .onReceive(DistributedNotificationCenter.default().publisher(for: Notification.Name(rawValue:  "com.spotify.client.PlaybackStateChanged")), perform: { notification in
                    print("playback changed in spotify")
                    if notification.userInfo?["Player State"] as? String == "Playing" {
                        print("is playing")
                        isPlaying = true
//                        playbackBasedTimer.invalidate()
                        if !currentlyPlayingLyrics.isEmpty {
                            print("timer started for spotify change, lyrics not nil")
                            timer = Timer.publish(every: 1, tolerance: 1, on: .main, in: .common).autoconnect()
                        }
                     //   updateLyricsIndexPlaybackBased()
                    } else {
                        print("paused. timer canceled")
                        isPlaying = false
                        timer.upstream.connect().cancel()
                    }
                    currentlyPlaying = (notification.userInfo?["Track ID"] as? String)?.components(separatedBy: ":").last
                    currentlyPlayingName = (notification.userInfo?["Name"] as? String)
                })
                .onChange(of: currentlyPlaying) { nowPlaying in
                    print("song change")
                    currentlyPlayingLyrics = []
                    currentlyPlayingLyricsIndex = nil
                    timer.upstream.connect().cancel()
                    if let nowPlaying, let currentlyPlayingName {
                        Task {
                           currentlyPlayingLyrics = await lyricsFetcher().fetchLyrics(for: nowPlaying, currentlyPlayingName)
                            if isPlaying, !currentlyPlayingLyrics.isEmpty {
                                timer = Timer.publish(every: 1, tolerance: 1, on: .main, in: .common).autoconnect()
                            }
                        }
                    }
                }
                .onReceive(timer, perform: { nih in
                    print("lyrics exist: \(!currentlyPlayingLyrics.isEmpty)")
                    currentMS = player.playbackTime * 1000
                    print("timer: \(currentMS)")
                    currentlyPlayingLyricsIndex = currentlyPlayingLyrics.lastIndex(where: {$0.startTimeMS < currentMS})
                    print(currentlyPlayingLyricsIndex ?? "nil")
                })
        })
    }
    
    func menuBarTitleText() -> String {
        if let currentlyPlayingName {
            return "Now Playing: \(currentlyPlayingName)"
        }
        return "Nothing Playing"
    }
    
    func menuBarText() -> String {
        if isPlaying, let currentlyPlayingLyricsIndex {
            return currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words
        } else if let currentlyPlayingName {
            return "Now \(isPlaying ? "Playing" : "Paused"): \(currentlyPlayingName)"
        }
        return "Nothing Playing"
    }
}
