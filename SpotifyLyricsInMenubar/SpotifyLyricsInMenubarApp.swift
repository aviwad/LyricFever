//
//  SpotifyLyricsInMenubarApp.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 26/07/23.
//

import SwiftUI
import ServiceManagement

@main
struct SpotifyLyricsInMenubarApp: App {
    @StateObject var viewmodel = viewModel.shared
    @AppStorage("launchOnLogin") var launchOnLogin: Bool = false
    // True: means Apple Music, False: Spotify
    @AppStorage("spotifyOrAppleMusic") var spotifyOrAppleMusic: Bool = false
    @State var showLyrics: Bool = true
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @AppStorage("truncationLength") var truncationLength: Int = 40
    @Environment(\.openWindow) var openWindow
    var body: some Scene {
        MenuBarExtra(content: {
            Text(songTitle)
            Divider()
            if let currentlyPlaying = viewmodel.currentlyPlaying, let currentlyPlayingName = viewmodel.currentlyPlayingName {
                Text(!viewmodel.currentlyPlayingLyrics.isEmpty ? "Lyrics Found 😃" : "No Lyrics Found ☹️")
                Button(viewmodel.currentlyPlayingLyrics.isEmpty ? "Check For Lyrics Again" : "Refresh Lyrics") {
                    
                    Task {
                        if spotifyOrAppleMusic {
                            try await viewmodel.appleMusicNetworkFetch()
                        }
                        viewmodel.currentlyPlayingLyrics = try await viewmodel.fetchNetworkLyrics(for: currentlyPlaying, currentlyPlayingName, spotifyOrAppleMusic)
                        print("HELLOO")
                        if viewmodel.isPlaying, !viewmodel.currentlyPlayingLyrics.isEmpty, showLyrics {
                            viewmodel.startLyricUpdater(appleMusicOrSpotify: spotifyOrAppleMusic)
                        }
                    }
                }
            // Special case where Apple Music -> Spotify ID matching fails (perhaps Apple Music music was not the media in foreground, network failure, genuine no match)
            // Apple Music Persistent ID exists but Spotify ID (currently playing) is nil
            } else if viewmodel.currentlyPlayingAppleMusicPersistentID != nil, viewmodel.currentlyPlaying == nil {
                Text("No Lyrics (Couldn't find Spotify ID) ☹️")
                Button("Check For Lyrics Again") {
                    Task {
                        // Fetch updates the currentlyPlaying ID which will call Lyric Updater
                        try await viewmodel.appleMusicFetch()
                    }
                }
                
            }
            Divider()
            Button(launchOnLogin ? "Don't Launch At Login" : "Automatically Launch On Login") {
                if launchOnLogin {
                    try? SMAppService.mainApp.unregister()
                    launchOnLogin = false
                } else {
                    try? SMAppService.mainApp.register()
                    launchOnLogin = true
                }
            }
            Button(showLyrics ? "Don't Show Lyrics" : "Show Lyrics") {
                if showLyrics {
                    showLyrics = false
                    viewmodel.stopLyricUpdater()
                } else {
                    showLyrics = true
                    viewmodel.startLyricUpdater(appleMusicOrSpotify: spotifyOrAppleMusic)
                }
            }
            Divider()
            Button("Settings") {
                NSApplication.shared.activate(ignoringOtherApps: true)
                openWindow(id: "onboarding")
                // send notification to check auth
                NotificationCenter.default.post(name: Notification.Name("didClickSettings"), object: nil)
            }.keyboardShortcut("s")
            Button("Check for Updates…", action: {viewmodel.updaterController.checkForUpdates(nil)})
                .disabled(!viewmodel.canCheckForUpdates)
                .keyboardShortcut("u")
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        } , label: {
            Text(viewmodel.mustUpdateUrgent ? "⚠️ Please Update (Click Check Updates)".trunc(length: truncationLength) : (hasOnboarded ? menuBarTitle : "⚠️ Please Complete Onboarding Process (Click Help)"))
                .onAppear {
                    if viewmodel.cookie.count == 0 {
                        hasOnboarded = false
                    }
                    guard hasOnboarded else {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        // why do i call this?
//                        viewmodel.spotifyScript?.name
//                        viewmodel.appleMusicScript?.name
                        openWindow(id: "onboarding")
                        return
                    }
                    guard let isRunning = spotifyOrAppleMusic ? viewmodel.appleMusicScript?.isRunning : viewmodel.spotifyScript?.isRunning, isRunning else {
                        return
                    }
                    print("Application just started. lets check whats playing")
                    if  spotifyOrAppleMusic ? viewmodel.appleMusicScript?.playerState == .playing :  viewmodel.spotifyScript?.playerState == .playing {
                        viewmodel.isPlaying = true
                    }
                    if spotifyOrAppleMusic {
                        Task {
                            let status = await viewmodel.requestMusicKitAuthorization()
                            
                            if status != .authorized {
                                hasOnboarded = false
                            }
                        }
                        let target = NSAppleEventDescriptor(bundleIdentifier: "com.apple.Music")
                        guard AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, true) == 0 else {
                            hasOnboarded = false
                            return
                        }
                        if let currentTrackName = viewmodel.appleMusicScript?.currentTrack?.name, let currentArtistName = viewmodel.appleMusicScript?.currentTrack?.artist {
                            // Don't set currentlyPlaying here: the persistentID change triggers the appleMusicFetch which will set spotify's currentlyPlaying
                            if currentTrackName == "" {
                                viewmodel.currentlyPlayingName = nil
                                viewmodel.currentlyPlayingArtist = nil
                            } else {
                                viewmodel.currentlyPlayingName = currentTrackName
                                viewmodel.currentlyPlayingArtist = currentArtistName
                            }
                            print("ON APPEAR HAS UPDATED APPLE MUSIC SONG ID")
                            viewmodel.currentlyPlayingAppleMusicPersistentID = viewmodel.appleMusicScript?.currentTrack?.persistentID
                        }
                    } else {
                        let target = NSAppleEventDescriptor(bundleIdentifier: "com.spotify.client")
                        guard AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, true) == 0 else {
                            hasOnboarded = false
                            return
                        }
                        if let currentTrack = viewmodel.spotifyScript?.currentTrack?.spotifyUrl?.components(separatedBy: ":").last, let currentTrackName = viewmodel.spotifyScript?.currentTrack?.name, let currentArtistName =  viewmodel.spotifyScript?.currentTrack?.artist, currentTrack != "", currentTrackName != "" {
                            viewmodel.currentlyPlaying = currentTrack
                            viewmodel.currentlyPlayingName = currentTrackName
                            viewmodel.currentlyPlayingArtist = currentArtistName
                            print(currentTrack)
                        }
                    }
                }
                .onReceive(DistributedNotificationCenter.default().publisher(for: Notification.Name(rawValue:  "com.apple.Music.playerInfo")), perform: { notification in
                    guard spotifyOrAppleMusic == true else {
                        print("#TODO we are still listening to apple music playback state changes even when user selected Spotify")
                        return
                    }
                    print("playback changed in apple music")
                    if notification.userInfo?["Player State"] as? String == "Playing" {
                        print("is playing")
                        viewmodel.isPlaying = true
                    } else {
                        print("paused. timer canceled")
                        viewmodel.isPlaying = false
                        // manually cancels the lyric-updater task bc media is paused
                    }
                    /*let currentlyPlaying = (notification.userInfo?["Track ID"] as? String)?.components(separatedBy: ":").last*/
                    let currentlyPlayingName = (notification.userInfo?["Name"] as? String)
                    //viewmodel.currentlyPlaying = nil
                    if currentlyPlayingName == "" {
                        viewmodel.currentlyPlayingName = nil
                        viewmodel.currentlyPlayingArtist = nil
                    } else {
                        viewmodel.currentlyPlayingName = currentlyPlayingName
                        viewmodel.currentlyPlayingArtist = (notification.userInfo?["Artist"] as? String)
                    }
                    viewmodel.currentlyPlayingAppleMusicPersistentID = viewmodel.appleMusicScript?.currentTrack?.persistentID
                })
                .onReceive(DistributedNotificationCenter.default().publisher(for: Notification.Name(rawValue:  "com.spotify.client.PlaybackStateChanged")), perform: { notification in
                    guard spotifyOrAppleMusic == false else {
                        print("#TODO we are still listening to spotify playback state changes even when user selected Apple Music")
                        return
                    }
                    print("playback changed in spotify")
                    if notification.userInfo?["Player State"] as? String == "Playing" {
                        print("is playing")
                        viewmodel.isPlaying = true
                    } else {
                        print("paused. timer canceled")
                        viewmodel.isPlaying = false
                        // manually cancels the lyric-updater task bc media is paused
                    }
                    let currentlyPlaying = (notification.userInfo?["Track ID"] as? String)?.components(separatedBy: ":").last
                    let currentlyPlayingName = (notification.userInfo?["Name"] as? String)
                    if currentlyPlaying != "", currentlyPlayingName != "" {
                        viewmodel.currentlyPlaying = currentlyPlaying
                        viewmodel.currentlyPlayingName = currentlyPlayingName
                        viewmodel.currentlyPlayingArtist = (notification.userInfo?["Artist"] as? String)
                    }
                })
                .onChange(of: spotifyOrAppleMusic) { newSpotifyOrAppleMusic in
                    guard let isRunning = spotifyOrAppleMusic ? viewmodel.appleMusicScript?.isRunning : viewmodel.spotifyScript?.isRunning, isRunning else {
                        viewmodel.isPlaying = false
                        viewmodel.currentlyPlaying = nil
                        viewmodel.currentlyPlayingName = nil
                        viewmodel.currentlyPlayingArtist = nil
                        viewmodel.currentlyPlayingAppleMusicPersistentID = nil
                        return
                    }
                    if spotifyOrAppleMusic {
                        Task {
                            let target = NSAppleEventDescriptor(bundleIdentifier: "com.apple.Music")
                            guard AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, true) == 0 else {
                                print("failed music automation permission")
                                hasOnboarded = false
                                return
                            }
                            let status = await viewmodel.requestMusicKitAuthorization()
                            
                            if status != .authorized {
                                hasOnboarded = false
                            }
                            hasOnboarded = true
                        }
                    } else {
                        let target = NSAppleEventDescriptor(bundleIdentifier: "com.spotify.client")
                        guard AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, true) == 0 else {
                            hasOnboarded = false
                            return
                        }
                        print("Spotify: has onboarded is true on media player switch")
                        hasOnboarded = true
                    }
                    print("Application just switched players. lets check whats playing")
                    viewmodel.isPlaying = spotifyOrAppleMusic ? viewmodel.appleMusicScript?.playerState == .playing : viewmodel.spotifyScript?.playerState == .playing
                    if spotifyOrAppleMusic {
                        if let currentTrackName = viewmodel.appleMusicScript?.currentTrack?.name, let currentlyPlayingArtist = viewmodel.appleMusicScript?.currentTrack?.artist {
                            // Don't set currentlyPlaying here: the persistentID change triggers the appleMusicFetch which will set spotify's currentlyPlaying
                            if currentTrackName == "" {
                                viewmodel.currentlyPlayingName = nil
                                viewmodel.currentlyPlayingArtist = nil
                            } else {
                                viewmodel.currentlyPlayingName = currentTrackName
                                viewmodel.currentlyPlayingArtist = currentlyPlayingArtist
                            }
                            viewmodel.currentlyPlayingAppleMusicPersistentID = viewmodel.appleMusicScript?.currentTrack?.persistentID
                        }
                    } else {
                        viewmodel.currentlyPlayingAppleMusicPersistentID = nil
                        if let currentTrack = viewmodel.spotifyScript?.currentTrack?.spotifyUrl?.components(separatedBy: ":").last, let currentTrackName = viewmodel.spotifyScript?.currentTrack?.name, let currentArtistName = viewmodel.spotifyScript?.currentTrack?.artist, currentTrack != "", currentTrackName != "" {
                            viewmodel.currentlyPlaying = currentTrack
                            viewmodel.currentlyPlayingName = currentTrackName
                            viewmodel.currentlyPlayingArtist = currentArtistName
                            print(currentTrack)
                        }
                    }
                }
                .onChange(of: hasOnboarded) { newHasOnboarded in
                    if newHasOnboarded {
                        guard let isRunning = spotifyOrAppleMusic ? viewmodel.appleMusicScript?.isRunning : viewmodel.spotifyScript?.isRunning, isRunning else {
                                viewmodel.isPlaying = false
                                viewmodel.currentlyPlaying = nil
                                viewmodel.currentlyPlayingName = nil
                                viewmodel.currentlyPlayingArtist = nil
                                viewmodel.currentlyPlayingAppleMusicPersistentID = nil
                            return
                        }
                        print("Application just started (finished onboarding). lets check whats playing")
                        if  spotifyOrAppleMusic ? viewmodel.appleMusicScript?.playerState == .playing :  viewmodel.spotifyScript?.playerState == .playing {
                            viewmodel.isPlaying = true
                        }
                        if spotifyOrAppleMusic {
                            if let currentTrackName = viewmodel.appleMusicScript?.currentTrack?.name, let currentArtistName = viewmodel.appleMusicScript?.currentTrack?.artist {
                                // Don't set currentlyPlaying here: the persistentID change triggers the appleMusicFetch which will set spotify's currentlyPlaying
                                if currentTrackName == "" {
                                    viewmodel.currentlyPlayingName = nil
                                    viewmodel.currentlyPlayingArtist = nil
                                } else {
                                    viewmodel.currentlyPlayingName = currentTrackName
                                    viewmodel.currentlyPlayingArtist = currentArtistName
                                }
                                print("ON APPEAR HAS UPDATED APPLE MUSIC SONG ID")
                                viewmodel.currentlyPlayingAppleMusicPersistentID = viewmodel.appleMusicScript?.currentTrack?.persistentID
                            }
                        } else {
                            if let currentTrack = viewmodel.spotifyScript?.currentTrack?.spotifyUrl?.components(separatedBy: ":").last, let currentTrackName = viewmodel.spotifyScript?.currentTrack?.name, let currentArtistName =  viewmodel.spotifyScript?.currentTrack?.artist, currentTrack != "", currentTrackName != "" {
                                viewmodel.currentlyPlaying = currentTrack
                                viewmodel.currentlyPlayingName = currentTrackName
                                viewmodel.currentlyPlayingArtist = currentArtistName
                                print(currentTrack)
                            }
                        }
                    }
                }
                .onChange(of: viewmodel.cookie) { newCookie in
                    viewmodel.accessToken = nil
                }
                .onChange(of: viewmodel.isPlaying) { nowPlaying in
                    if nowPlaying, showLyrics {
                        if !viewmodel.currentlyPlayingLyrics.isEmpty, spotifyOrAppleMusic ? viewmodel.appleMusicScript?.playerPosition != 0.0 : viewmodel.spotifyScript?.playerPosition != 0.0  {
                            print("timer started for spotify change, lyrics not nil")
                            viewmodel.startLyricUpdater(appleMusicOrSpotify: spotifyOrAppleMusic)
                        }
                    } else {
                        viewmodel.stopLyricUpdater()
                    }
                }
                .task(id: viewmodel.currentlyPlayingAppleMusicPersistentID) {
                    if viewmodel.currentlyPlayingAppleMusicPersistentID != nil {
                        // reset the store playback id so that the nil check actually works later
                        viewmodel.appleMusicStorePlaybackID = nil
                        await viewmodel.appleMusicStarter()
                    }
                }
                .onChange(of: viewmodel.currentlyPlaying) { nowPlaying in
                    print("song change")
                    // only set position to 0 when new song selected, user anyways expected song to start at position 0
                    // gets rid of spotify's playback position glitch when autoplaying
                    // see:
//                    viewmodel.spotifyScript?.playpause?()
//                    viewmodel.spotifyScript?.playpause?()
                    viewmodel.currentlyPlayingLyricsIndex = nil
                    viewmodel.currentlyPlayingLyrics = []
                    Task {
                        if let nowPlaying, let currentlyPlayingName = viewmodel.currentlyPlayingName, let lyrics = await viewmodel.fetch(for: nowPlaying, currentlyPlayingName, spotifyOrAppleMusic) {
                            viewmodel.currentlyPlayingLyrics = lyrics
                            if viewmodel.isPlaying, !viewmodel.currentlyPlayingLyrics.isEmpty, showLyrics {
                                print("STARTING UPDATER")
                                viewmodel.startLyricUpdater(appleMusicOrSpotify: spotifyOrAppleMusic)
                            }
                        }
                    }
                }
        })
        Window("Lyrics in Menubar: Onboarding", id: "onboarding") { // << here !!
            OnboardingWindow().frame(minWidth: 700, maxWidth: 700, minHeight: 600, maxHeight: 600, alignment: .center)
                .preferredColorScheme(.dark)
        }.windowResizability(.contentSize)
            .windowStyle(.hiddenTitleBar)
    }
    
    var songTitle: String {
        if let currentlyPlayingName = viewmodel.currentlyPlayingName, let currentlyPlayingArtist = viewmodel.currentlyPlayingArtist {
            return "Now \(viewmodel.isPlaying ? "Playing" : "Paused"): \(currentlyPlayingName) - \(currentlyPlayingArtist)".trunc(length: truncationLength)
        }
        return "Open \(spotifyOrAppleMusic ? "Apple Music" : "Spotify" )!"
    }
    
    var menuBarTitle: String {
        if viewmodel.isPlaying, showLyrics, let currentlyPlayingLyricsIndex = viewmodel.currentlyPlayingLyricsIndex {
            return viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words.trunc(length: truncationLength)
        } else if let currentlyPlayingName = viewmodel.currentlyPlayingName, let currentlyPlayingArtist = viewmodel.currentlyPlayingArtist {
            return "Now \(viewmodel.isPlaying ? "Playing" : "Paused"): \(currentlyPlayingName) - \(currentlyPlayingArtist)".trunc(length: truncationLength)
        }
        return "Nothing Playing on \(spotifyOrAppleMusic ? "Apple Music" : "Spotify" )"
    }
}

extension String {
  // https://gist.github.com/budidino/8585eecd55fd4284afaaef762450f98e
  func trunc(length: Int, trailing: String = "…") -> String {
    return (self.count > length) ? self.prefix(length) + trailing : self
  }
}
