//
//  MenubarWindowView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//

import SwiftUI
import LaunchAtLogin

struct MenubarWindowView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.openWindow) var openWindow
    @Environment(ViewModel.self) var viewmodel
    
    var songTitle: LocalizedStringKey {
        if let currentlyPlayingName = viewmodel.currentlyPlayingName, let currentlyPlayingArtist = viewmodel.currentlyPlayingArtist {
            if viewmodel.isPlaying {
                return "Now Playing: \(currentlyPlayingName) - \(currentlyPlayingArtist)"//.trunc()
            } else {
                return "Now Paused: \(currentlyPlayingName) - \(currentlyPlayingArtist)"//.trunc()
            }
        }
        return "Open \(viewmodel.currentPlayer.description)!"
    }
    
    var body: some View {
        @Bindable var viewmodel = viewmodel
        VStack {
            Text(songTitle)
            Toggle("Show Song Details in Menubar", isOn: $viewmodel.userDefaultStorage.showSongDetailsInMenubar)
            Divider()
            if let currentlyPlaying = viewmodel.currentlyPlaying, let currentlyPlayingName = viewmodel.currentlyPlayingName {
                Text(!viewmodel.currentlyPlayingLyrics.isEmpty ? "Lyrics Found 😃" : "No Lyrics Found ☹️")
                Button(viewmodel.currentlyPlayingLyrics.isEmpty ? "Check for Lyrics Again" : "Refresh Lyrics") {
                    
                    Task {
                        do {
                            try await viewmodel.refreshLyrics()
                        } catch {
                            print("Couldn't refresh lyrics: error \(error)")
                        }
                    }
                }
                .keyboardShortcut("r")
                if viewmodel.currentlyPlayingLyrics.isEmpty {
                    Button("Upload Local LRC File") {
                        Task {
                            do {
                                try await viewmodel.uploadLocalLRCFile()
                            } catch {
                                print("Couldn't upload local lrc file: error \(error)")
                            }
                        }
                    }
                } else {
                    Button("Delete Lyrics (wrong lyrics)") {
                        viewmodel.deleteLyric(trackID: currentlyPlaying)
                    }
                }
            // Special case where Apple Music -> Spotify ID matching fails (perhaps Apple Music music was not the media in foreground, network failure, genuine no match)
            // Apple Music Persistent ID exists but Spotify ID (currently playing) is nil
            } else if viewmodel.currentlyPlayingAppleMusicPersistentID != nil, viewmodel.currentlyPlaying == nil {
                Text("No Lyrics (Couldn't find Spotify ID) ☹️")
                Button("Check for Lyrics Again") {
                    Task {
                        // Fetch updates the currentlyPlaying ID which will call Lyric Updater
                        try await viewmodel.appleMusicFetch()
                    }
                }
                .keyboardShortcut("r")
            }
            Toggle("Show Lyrics", isOn: $viewmodel.showLyrics)
            .disabled(!viewmodel.userDefaultStorage.hasOnboarded)
            .keyboardShortcut("h")
            Divider()
            if viewmodel.userDefaultStorage.translate {
                Text(!viewmodel.translatedLyric.isEmpty ? "Translated Lyrics 😃" : "No Translation ☹️")
                if viewmodel.translatedLyric.isEmpty {
                    Button("Translation Help") {
                        openURL(URL(string: "https://aviwadhwa.com/TranslationHelp")!)
                    }
                }
            }
            
            Toggle("Translate To \(viewmodel.userLocaleLanguageString)", isOn: $viewmodel.userDefaultStorage.translate)
            .disabled(!viewmodel.userDefaultStorage.hasOnboarded)
            Divider()
            Toggle("Romanize", isOn: $viewmodel.userDefaultStorage.romanize)
            Divider()
            Text("Menubar Size is \(viewmodel.userDefaultStorage.truncationLength)")
            if viewmodel.userDefaultStorage.truncationLength != 60 {
                Button("Increase Size to \(viewmodel.userDefaultStorage.truncationLength+10) ") {
                    viewmodel.userDefaultStorage.truncationLength = viewmodel.userDefaultStorage.truncationLength + 10
                }
                .keyboardShortcut("+")
            }
            if viewmodel.userDefaultStorage.truncationLength != 30 {
                Button("Decrease Size to \(viewmodel.userDefaultStorage.truncationLength-10)") {
                    viewmodel.userDefaultStorage.truncationLength = viewmodel.userDefaultStorage.truncationLength - 10
                }
                .keyboardShortcut("-")
            }
            Divider()
            Toggle("Fullscreen", isOn: $viewmodel.displayFullscreen)
            .disabled(!viewmodel.userDefaultStorage.hasOnboarded)
            Toggle(viewmodel.showLyrics ? "Karaoke Mode" : "Karaoke Mode (Enable Show Lyrics)", isOn: $viewmodel.userDefaultStorage.karaoke)
                .disabled(!viewmodel.userDefaultStorage.hasOnboarded || !viewmodel.showLyrics)
                .keyboardShortcut("k")
            Divider()
            if viewmodel.currentPlayer == .spotify {
                 Toggle("Spotify Connect Audio Delay", isOn: $viewmodel.spotifyConnectDelay)
                     .disabled(!viewmodel.userDefaultStorage.hasOnboarded)
                if viewmodel.spotifyConnectDelay {
                     Text("Offset is \(viewmodel.userDefaultStorage.spotifyConnectDelayCount) ms")
                     if viewmodel.userDefaultStorage.spotifyConnectDelayCount != 3000 {
                         Button("Increase Offset to \(viewmodel.userDefaultStorage.spotifyConnectDelayCount+100)") {
                             viewmodel.userDefaultStorage.spotifyConnectDelayCount = viewmodel.userDefaultStorage.spotifyConnectDelayCount + 100
                         }
                     }
                    if viewmodel.userDefaultStorage.spotifyConnectDelayCount != 300 {
                         Button("Decrease Offset to \(viewmodel.userDefaultStorage.spotifyConnectDelayCount-100)") {
                             viewmodel.userDefaultStorage.spotifyConnectDelayCount = viewmodel.userDefaultStorage.spotifyConnectDelayCount - 100
                         }
                     }
                 }
                 Divider()
                Toggle("AirPlay Audio Delay", isOn: $viewmodel.airplayDelay)
                    .disabled(!viewmodel.userDefaultStorage.hasOnboarded)
            }
            Divider()
            Button("Settings (New Karaoke Settings!)") {
                openWindow(id: "onboarding")
                NSApplication.shared.activate(ignoringOtherApps: true)
                // send notification to check auth
                NotificationCenter.default.post(name: Notification.Name("didClickSettings"), object: nil)
            }.keyboardShortcut("s")
            LaunchAtLogin.Toggle(String(localized: "Launch at Login"))
            .disabled(!viewmodel.userDefaultStorage.hasOnboarded)
            .keyboardShortcut("l")
            Button("Check for Updates…") {
                viewmodel.updaterService.updaterController.checkForUpdates(nil)
            }
            //    .disabled(!viewmodel.canCheckForUpdates)
                .keyboardShortcut("u")
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
    }
}
