//
//  SpotifyLyricsInMenubarApp.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 26/07/23.
//

import SwiftUI
@main
struct SpotifyLyricsInMenubarApp: App {
    @StateObject var viewmodel = viewModel.shared
    
    var body: some Scene {
        MenuBarExtra(content: {
            Text(songTitle)
            
            if let currentlyPlaying = viewmodel.currentlyPlaying, let currentlyPlayingName = viewmodel.currentlyPlayingName {
                Text(!viewmodel.currentlyPlayingLyrics.isEmpty ? "Lyrics Found 😃" : "No Lyrics Found ☹️")
                if viewmodel.currentlyPlayingLyrics.isEmpty {
                    Button("Check For Lyrics Again") {
                        
                        Task {
                            viewmodel.currentlyPlayingLyrics = try await viewmodel.fetchNetworkLyrics(for: currentlyPlaying, currentlyPlayingName)
                            print("HELLOO")
                            if viewmodel.isPlaying, !viewmodel.currentlyPlayingLyrics.isEmpty {
                                viewmodel.startLyricUpdater()
                            }
                        }
                    }
                }
            }
            Divider()
            Button("Check for Updates…", action: {viewmodel.updaterController.checkForUpdates(nil)})
                .disabled(!viewmodel.canCheckForUpdates)
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        } , label: {
            Text(menuBarTitle)
                .onAppear {
                    print("Application just started. lets check whats playing")
                    if viewmodel.spotifyScript?.playerState == .playing {
                        viewmodel.isPlaying = true
                    }
                    if let currentTrack = viewmodel.spotifyScript?.currentTrack?.spotifyUrl?.components(separatedBy: ":").last, let currentTrackName = viewmodel.spotifyScript?.currentTrack?.name {
                        viewmodel.currentlyPlaying = currentTrack
                        viewmodel.currentlyPlayingName = currentTrackName
                        print(currentTrack)
                    }
                }
                .onReceive(DistributedNotificationCenter.default().publisher(for: Notification.Name(rawValue:  "com.spotify.client.PlaybackStateChanged")), perform: { notification in
                    print("playback changed in spotify")
                    if notification.userInfo?["Player State"] as? String == "Playing" {
                        print("is playing")
                        viewmodel.isPlaying = true
                    } else {
                        print("paused. timer canceled")
                        viewmodel.isPlaying = false
                        // manually cancels the lyric-updater task bc media is paused
                    }
                    viewmodel.currentlyPlaying = (notification.userInfo?["Track ID"] as? String)?.components(separatedBy: ":").last
                    viewmodel.currentlyPlayingName = (notification.userInfo?["Name"] as? String)
                })
                .onChange(of: viewmodel.isPlaying) { nowPlaying in
                    if nowPlaying {
                        if !viewmodel.currentlyPlayingLyrics.isEmpty {
                            print("timer started for spotify change, lyrics not nil")
                            viewmodel.startLyricUpdater()
                        }
                    } else {
                        viewmodel.stopLyricUpdater()
                    }
                }
                .onChange(of: viewmodel.currentlyPlaying) { nowPlaying in
                    print("song change")
                    viewmodel.currentlyPlayingLyricsIndex = nil
                    viewmodel.currentlyPlayingLyrics = []
                    Task {
                        if let nowPlaying, let currentlyPlayingName = viewmodel.currentlyPlayingName, let lyrics = await viewmodel.fetch(for: nowPlaying, currentlyPlayingName) {
                            viewmodel.currentlyPlayingLyrics = lyrics
                            if viewmodel.isPlaying, !viewmodel.currentlyPlayingLyrics.isEmpty {
                                print("STARTING UPDATER")
                                viewmodel.startLyricUpdater()
                            }
                        }
                    }
                }
        })
    }
    
    var songTitle: String {
        if let currentlyPlayingName = viewmodel.currentlyPlayingName {
            return "Now \(viewmodel.isPlaying ? "Playing" : "Paused"): \(currentlyPlayingName)"
        }
        return "Nothing Playing"
    }
    
    var menuBarTitle: String {
        if viewmodel.isPlaying, let currentlyPlayingLyricsIndex = viewmodel.currentlyPlayingLyricsIndex {
            return viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words.trunc(length: 50)
        } else if let currentlyPlayingName = viewmodel.currentlyPlayingName {
            return "Now \(viewmodel.isPlaying ? "Playing" : "Paused"): \(currentlyPlayingName.trunc(length: 50))"
        }
        return "Nothing Playing"
    }
}

extension String {
  // https://gist.github.com/budidino/8585eecd55fd4284afaaef762450f98e
  func trunc(length: Int, trailing: String = "…") -> String {
    return (self.count > length) ? self.prefix(length) + trailing : self
  }
}
