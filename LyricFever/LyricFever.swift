//
//  SpotifyLyricsInMenubarApp.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 26/07/23.
//

import SwiftUI
import Translation
import LaunchAtLogin

extension NSScreen {
    static var mainWidth: CGFloat {
        NSScreen.main?.frame.width ?? 1920
    }
    static var mainHeight: CGFloat {
        NSScreen.main?.frame.height ?? 1080
    }
}

enum MusicType {
    case spotify
    case appleMusic
}

@main
struct LyricFever: App {
    @State var viewmodel = ViewModel.shared
    @Environment(\.openWindow) var openWindow
    @Environment(\.openURL) var openURL
    @State var artworkImage: NSImage?
    
    var body: some Scene {
        MenuBarExtra {
            MenubarWindowView()
                .environment(viewmodel)
        } label: {
            // Text(Image) Doesn't render propertly in MenubarExtra. Stupid Apple. Must resort to if/else
            Group {
                if let menuBarTitle {
                    Text(menuBarTitle)
                } else {
                    Image(systemName: "music.note.list")
                }
            }
//            .task(id: viewmodel.currentlyPlayingLyrics) {
//                guard let currentlyPlayingLyrics = viewmodel.currentlyPlayingLyrics else {
//                    return
//                }
//                
//            }
            .task(id: viewmodel.currentlyPlaying) {
                artworkImage = await viewmodel.currentPlayerInstance.artworkImage
            }
            .task(id: viewmodel.userDefaultStorage.latestUpdateWindowShown) {
                if viewmodel.userDefaultStorage.latestUpdateWindowShown < 23 {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    openWindow(id: "update")
                    viewmodel.userDefaultStorage.latestUpdateWindowShown = 23
                }
            }
            .task(id: viewmodel.userDefaultStorage.hasOnboarded) {
                if !viewmodel.userDefaultStorage.hasOnboarded {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    openWindow(id: "onboarding")
                } else {
                    do {
                        try await viewmodel.refreshLyrics()
                    } catch {
                        print("Couldn't refresh lyrics on hasOnboarding: \(error)")
                    }
                }
            }
                .onChange(of: viewmodel.showLyrics) {
                    viewmodel.toggleLyrics()
                }
                .floatingPanel(isPresented: $viewmodel.displayKaraoke) {
                    KaraokeView()
                        .animation(.easeIn(duration: 0.2))
                        .environment(viewmodel)
                }
                .onAppear {
                    viewmodel.onAppear(openWindow)
                }
                .onReceive(DistributedNotificationCenter.default().publisher(for: Notification.Name(rawValue:  "com.apple.Music.playerInfo"))) { notification in
                    viewmodel.appleMusicPlaybackDidChange(notification)
                }
                .onReceive(DistributedNotificationCenter.default().publisher(for: Notification.Name(rawValue:  "com.spotify.client.PlaybackStateChanged"))) { notification in
                    viewmodel.spotifyPlaybackDidChange(notification)
                }
                .translationTask(viewmodel.translationSessionConfig) { session in
                    await viewmodel.translationTask(session)
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    viewmodel.saveKaraokeFontOnTermination()
                }
                .onChange(of: viewmodel.userDefaultStorage.romanize) {
                    viewmodel.romanizeDidChange()
                }
                .onChange(of: viewmodel.userDefaultStorage.translate) {
                    if !viewmodel.reloadTranslationConfigIfTranslating() {
                        viewmodel.translatedLyric = []
                    }
                }
                .onChange(of: viewmodel.currentPlayer) {
                    print("Setting hasOnboarded to false due to player change")
                    viewmodel.userDefaultStorage.hasOnboarded = false
                }
                .onChange(of: viewmodel.fullscreen) {
                    if viewmodel.fullscreen {
                        openWindow(id: "fullscreen")
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                }
                .onChange(of: viewmodel.userDefaultStorage.hasOnboarded) {
                    if viewmodel.userDefaultStorage.hasOnboarded {
                        viewmodel.didOnboard()
                    } else {
                        viewmodel.stopLyricUpdater()
                    }
                }
                .onChange(of: viewmodel.userDefaultStorage.translate) {
                    viewmodel.openTranslationHelpOnFirstRun(openURL)
                }
                .onChange(of: viewmodel.userDefaultStorage.cookie) {
                    viewmodel.spotifyLyricProvider.accessToken = nil
                }
                .onChange(of: viewmodel.isPlaying) {
                    if viewmodel.isPlaying, viewmodel.showLyrics, viewmodel.userDefaultStorage.hasOnboarded {
                        if !viewmodel.currentlyPlayingLyrics.isEmpty  {
                            print("timer started for spotify change, lyrics not nil")
                            viewmodel.startLyricUpdater()
                        }
                    } else {
                        viewmodel.stopLyricUpdater()
                    }
                }
                .task(id: viewmodel.currentlyPlayingAppleMusicPersistentID) {
                    if viewmodel.currentlyPlayingAppleMusicPersistentID != nil {
                        print("Apple Music: calling Starter on new persistent ID")
                        await viewmodel.appleMusicStarter()
                    }
                }
                .onChange(of: viewmodel.currentlyPlaying) {
                    print("song change")
                    viewmodel.currentlyPlayingLyricsIndex = nil
                    viewmodel.currentlyPlayingLyrics = []
                    viewmodel.translatedLyric = []
                    viewmodel.romanizedLyrics = []
                    
                    Task {
                        if viewmodel.userDefaultStorage.hasOnboarded, let currentlyPlaying = viewmodel.currentlyPlaying, let currentlyPlayingName = viewmodel.currentlyPlayingName, let lyrics = await viewmodel.fetch(for: currentlyPlaying, currentlyPlayingName) {
                            viewmodel.currentlyPlayingLyrics = lyrics
                            viewmodel.fetchBackgroundColor()
                            viewmodel.reloadTranslationConfigIfTranslating()
                            if viewmodel.userDefaultStorage.romanize {
                                print("Romanized Lyrics generated from song change for \(viewmodel.currentlyPlaying)")
                                viewmodel.romanizedLyrics = viewmodel.currentlyPlayingLyrics.compactMap({
                                    RomanizerService.generateRomanizedLyric($0)
                                })
                            }
                            viewmodel.lyricsIsEmptyPostLoad = lyrics.isEmpty
                            if viewmodel.isPlaying, !viewmodel.currentlyPlayingLyrics.isEmpty, viewmodel.showLyrics, viewmodel.userDefaultStorage.hasOnboarded {
                                print("STARTING UPDATER")
                                viewmodel.startLyricUpdater()
                            }
                        }
                    }
                }
        }
        .menuBarExtraStyle(.window)
        Window("Lyric Fever: Fullscreen", id: "fullscreen") {
            FullscreenView()
                .preferredColorScheme(.dark)
                .environment(viewmodel)
                .onAppear {
                    // Block "Esc" button
                    NSEvent.addLocalMonitorForEvents(matching: .keyDown) { (aEvent) -> NSEvent? in
                            if aEvent.keyCode == 53 { // if esc pressed
                                return nil
                            }
                            return aEvent
                        }
                    Task { @MainActor in
                        let window = NSApp.windows.first {$0.identifier?.rawValue == "fullscreen"}
                        window?.collectionBehavior = .fullScreenPrimary
                        if window?.styleMask.rawValue != 49167 {
                            window?.toggleFullScreen(true)
                        }
                    }
                }
                .onDisappear {
                    NSApp.setActivationPolicy(.accessory)
                    viewmodel.fullscreen = false
                }
        }
        .defaultSize(width: NSScreen.mainWidth, height: NSScreen.mainHeight)
        Window("Lyric Fever: Onboarding", id: "onboarding") { // << here !!
            OnboardingWindow().frame(minWidth: 700, maxWidth: 700, minHeight: 600, maxHeight: 600, alignment: .center)
                .environment(viewmodel)
                .preferredColorScheme(.dark)
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                }
                .onDisappear {
                    if !viewmodel.fullscreen {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .windowLevel(.floating)
        Window("Lyric Fever: Update 2.3", id: "update") { // << here !!
            UpdateWindow().frame(minWidth: 700, maxWidth: 700, minHeight: 500, maxHeight: 500, alignment: .center)
                .environment(viewmodel)
                .preferredColorScheme(.dark)
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                }
                .onDisappear {
                    if !viewmodel.fullscreen {
                        NSApp.setActivationPolicy(.accessory)
                    }
                }
        }
            .windowResizability(.contentSize)
            .windowStyle(.hiddenTitleBar)
            .windowLevel(.floating)
    }
    
    var menuBarTitle: String? {
        // Update message takes priority
        if viewmodel.mustUpdateUrgent {
            return String(localized: "⚠️ Please Update (Click Check Updates)").trunc(length: viewmodel.userDefaultStorage.truncationLength)
        } else if viewmodel.userDefaultStorage.hasOnboarded {
            // Try to work through lyric logic if onboarded
            // NEW: Revert to song name if fullscreen / karaoke activated
            if !viewmodel.fullscreen, !viewmodel.userDefaultStorage.karaoke, viewmodel.isPlaying, viewmodel.showLyrics, let currentlyPlayingLyricsIndex = viewmodel.currentlyPlayingLyricsIndex {
                // Attempt to display translations
                // Implicit assumption: translatedLyric.count == currentlyPlayingLyrics.count
                if viewmodel.translationExists {
                    // I don't localize, because I deliver the lyric verbatim
                    return viewmodel.translatedLyric[currentlyPlayingLyricsIndex].trunc()
                } else {
                    // Attempt to display Romanization
                    if viewmodel.userDefaultStorage.romanize, let toLatin = viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words.applyingTransform(.toLatin, reverse: false) {
                        // I don't localize, because I deliver the lyric verbatim
                        return toLatin.trunc()
                    } else {
                        // I don't localize, because I deliver the lyric verbatim
                        return viewmodel.currentlyPlayingLyrics[currentlyPlayingLyricsIndex].words.trunc()
                    }
                }
            // Backup: Display name and artist
            } else if viewmodel.userDefaultStorage.showSongDetailsInMenubar, let currentlyPlayingName = viewmodel.currentlyPlayingName, let currentlyPlayingArtist = viewmodel.currentlyPlayingArtist {
                if viewmodel.isPlaying {
                    return String(localized: "Now Playing: \(currentlyPlayingName) - \(currentlyPlayingArtist)").trunc()//.trunc()
                } else {
                    return String(localized: "Now Paused: \(currentlyPlayingName) - \(currentlyPlayingArtist)").trunc()//.trunc()
                }
            }
            // Onboarded but app is not open
            return nil
        } else {
            // Hasn't onboarded
            return String(localized: "⚠️ Complete Setup (Click Settings)").trunc()
        }
        
    }
}


extension String {
  // https://gist.github.com/budidino/8585eecd55fd4284afaaef762450f98e
    @MainActor
    func trunc(length: Int? = nil, trailing: String = "…") -> String {
        let length = length ?? ViewModel.shared.userDefaultStorage.truncationLength
        return (self.count > length) ? self.prefix(length) + trailing : self
    }
}

