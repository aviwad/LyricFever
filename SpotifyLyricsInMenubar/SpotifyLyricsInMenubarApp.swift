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
  //  @State var timer = Timer.publish(every: 1, tolerance: 1, on: .main, in: .common).autoconnect()
    @State private var lyricUpdateWorkItem: DispatchWorkItem?
    
    var player = MusicPlayers.Scriptable(name: .spotify)!
    
    var workItem: DispatchWorkItem?
    
    var body: some Scene {
        MenuBarExtra(content: {
            Text(menuBarTitleText())
            
            if let currentlyPlaying, let currentlyPlayingName {
                Text(!currentlyPlayingLyrics.isEmpty ? "Lyrics Found 😃" : "No Lyrics Found ☹️")
                if currentlyPlayingLyrics.isEmpty {
                    Button("Check For Lyrics Again") {
                        Task {
                            currentlyPlayingLyrics = try await lyricsFetcher().fetchNetworkLyrics(for: currentlyPlaying, currentlyPlayingName)
                            print("HELLOO")
                            if isPlaying, !currentlyPlayingLyrics.isEmpty {
                                startLyricUpdater()
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
                .onAppear {
                    print("Application just started. lets check whats playing")
                    if let currentTrack = player.currentTrack {
                        print(currentTrack)
                    } else {
                        stopLyricUpdater()
                    }
                }
                .onReceive(DistributedNotificationCenter.default().publisher(for: Notification.Name(rawValue:  "com.spotify.client.PlaybackStateChanged")), perform: { notification in
                    print("playback changed in spotify")
                    if notification.userInfo?["Player State"] as? String == "Playing" {
                        print("is playing")
                        isPlaying = true
                        if !currentlyPlayingLyrics.isEmpty {
                            print("timer started for spotify change, lyrics not nil")
                            startLyricUpdater()
                        }
                    } else {
                        print("paused. timer canceled")
                        isPlaying = false
                        stopLyricUpdater()
                    }
                    currentlyPlaying = (notification.userInfo?["Track ID"] as? String)?.components(separatedBy: ":").last
                    currentlyPlayingName = (notification.userInfo?["Name"] as? String)
                })
                .onChange(of: currentlyPlaying) { nowPlaying in
                    print("song change")
                    currentlyPlayingLyricsIndex = nil
                    currentlyPlayingLyrics = []
                    stopLyricUpdater()
                    if let nowPlaying, let currentlyPlayingName {
                        Task {
                            currentlyPlayingLyrics = try await lyricsFetcher().fetchLyrics(for: nowPlaying, currentlyPlayingName)
                            if isPlaying, !currentlyPlayingLyrics.isEmpty {
                                startLyricUpdater()
                            }
                        }
                    }
                }
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
    
    func lyricUpdater(_ newIndex: Int) {
        print("lyrics exist: \(!currentlyPlayingLyrics.isEmpty)")
        currentMS = player.playbackTime * 1000
        print("timer: \(currentMS)")
        if currentlyPlayingLyrics.count > newIndex {
            currentlyPlayingLyricsIndex = newIndex
        } else {
            currentlyPlayingLyricsIndex = nil
        }
        print(currentlyPlayingLyricsIndex ?? "nil")
        startLyricUpdater()
    }
    
    func startLyricUpdater() {
        let currentTime = player.playbackTime * 1000
        guard let lastIndex = currentlyPlayingLyrics.firstIndex(where: {$0.startTimeMS > currentTime}) else {
            stopLyricUpdater()
            return
        }
        let nextTimestamp = currentlyPlayingLyrics[lastIndex].startTimeMS
        let diff = nextTimestamp - currentTime
        print("the difference is \(diff)")
        lyricUpdateWorkItem = DispatchWorkItem {
            self.lyricUpdater(lastIndex)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(diff)), execute: lyricUpdateWorkItem!)
    }
    
    func stopLyricUpdater() {
        lyricUpdateWorkItem?.cancel()
    }
}
