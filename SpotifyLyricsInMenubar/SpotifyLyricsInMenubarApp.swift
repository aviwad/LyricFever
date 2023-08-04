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
    @State var currentlyPlayingLyrics: [LyricLine]?
    @State var currentlyPlayingLyricsIndex: Int? = nil
    @State var currentMS: TimeInterval = 0
//    @State var isPlaying: Bool = true
//    @State var playbackBasedTimer: Timer = Timer()
    @State var timer = Timer.publish(every: 1, tolerance: 1, on: .main, in: .common).autoconnect()
    
    var player = MusicPlayers.Scriptable(name: .spotify)!
    
    var body: some Scene {
        MenuBarExtra(content: {
            Text(menuBarTitleText())
//            Button(isPlaying ? "Play" : "Pause") {
//                withAnimation() {
//                    isPlaying.toggle()
//                }
//            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        } , label: {
            Text(menuBarText())
           // Text("hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh")
                .lineLimit(1)
                .truncationMode(.tail)
                .onAppear {
                    print("Application just started. lets check whats playing")
                    if let currentTrack = player.currentTrack {
                        print(currentTrack)
                    } else {
                        timer.upstream.connect().cancel()
                    }
                }
                .onReceive(DistributedNotificationCenter.default().publisher(for: Notification.Name(rawValue:  "com.spotify.client.PlaybackStateChanged")), perform: { notification in
                    
                    if notification.userInfo?["Player State"] as? String == "Playing", currentlyPlayingLyrics != nil {
                    //    isPlaying = true
//                        playbackBasedTimer.invalidate()
                        timer = Timer.publish(every: 1, tolerance: 1, on: .main, in: .common).autoconnect()
                     //   updateLyricsIndexPlaybackBased()
                    } else {
                    //    isPlaying = false
                        timer.upstream.connect().cancel()
                    }
                    currentlyPlaying = (notification.userInfo?["Track ID"] as? String)?.components(separatedBy: ":").last
                    currentlyPlayingName = (notification.userInfo?["Name"] as? String)
                })
                .onChange(of: currentlyPlaying) { nowPlaying in
                    currentlyPlayingLyrics = nil
                    currentlyPlayingLyricsIndex = 0
                    Task {
                        if let lyrics = await lyricsFetcher().fetchLyrics(for: nowPlaying) {
                            currentlyPlayingLyrics = lyrics
                            //updateLyricsIndexPlaybackBased()
                        }
                    }
                }
                // a timer is necessary to refresh the lyrics because we don't receive notifications for playback scrubbing
                // (ie user scrubbing to new playback position whilst still playing)
                .onReceive(timer, perform: { nih in
                    currentMS = player.playbackTime * 1000
                    print("timer: \(currentMS)")
                    currentlyPlayingLyricsIndex = currentlyPlayingLyrics?.lastIndex(where: {$0.startTimeMS < currentMS})
                    print(currentlyPlayingLyricsIndex)
                })
        })
    }
    
    func menuBarTitleText() -> String {
        //currentlyPlayingName ?? "Nothing Playing"
        if let currentlyPlayingName {
            return "Now Playing: \(currentlyPlayingName)"
        }
        return "Nothing Playing"
    }
    
    func menuBarText() -> String {
        if let currentlyPlayingLyrics, let currentlyPlayingLyricsIndex {
            return currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words
        } else if let currentlyPlayingName {
            return "Now Playing: \(currentlyPlayingName)"
        }
        return "Loading"
    }
    
//    func updateLyricsIndexPlaybackBased() {
//        currentMS = player.playbackTime * 1000
//        print("update called on current playtime \(currentMS.magnitude)")
//        if let currentlyPlayingLyrics {
//            print("current lyrics available")
//            if let nextMS = currentlyPlayingLyrics.first(where: {$0.startTimeMS > currentMS}) {
//                let diff = (nextMS.startTimeMS - currentMS) / 1000
//                print("next subtitle renders at playtime \(nextMS.startTimeMS.magnitude)")
//                print("different is \(diff)")
////                DispatchQueue.main.asyncAfter(deadline: .now() + diff) {
////                    currentlyPlayingLyricsIndex += 1
////                    updateLyricsIndexPlaybackBased()
////                }
//                DispatchQueue.main.asyncAfter(deadline: <#T##DispatchTime#>, execute: <#T##DispatchWorkItem#>)
//                playbackBasedTimer = Timer.scheduledTimer(withTimeInterval: diff, repeats: false) { timer in
//                    currentlyPlayingLyricsIndex += 1
//                    updateLyricsIndexPlaybackBased()
//                }
////                playbackBasedTimer = Timer.scheduledTimer(withTimeInterval: diff, repeats: false) { timer in
////             //       currentlyPlayingLyricsIndex = currentlyPlayingLyrics.lastIndex(where: {$0.startTimeMS < currentMS}) ?? 0
////                    print("timer ran, time interval worked")
////                 //   updateLyricsIndexPlaybackBased()
////                    
////                }
//                
//            }
//        }
//
//    }
}
