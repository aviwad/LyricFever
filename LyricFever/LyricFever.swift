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
    
    var body: some Scene {
        MenuBarExtra {
            MenubarWindowView()
                .environment(\.colorScheme, .dark)
                .preferredColorScheme(.dark)
                .environment(viewmodel)
        } label: {
            // Text(Image) Doesn't render propertly in MenubarExtra. Stupid Apple. Must resort to if/else
            MenubarLabelView()
                .environment(viewmodel)
            .task(id: viewmodel.currentlyPlaying) {
                if viewmodel.currentlyPlaying == nil {
                    print("Incorrect task fired. Ignored on nil currentlyPlaying value")
                    return
                }
                do {
                    print("Fetching new artwork image for currentlyPlaying change")
                    if let artworkImage = await viewmodel.currentPlayerInstance.artworkImage {
                        viewmodel.artworkImage = artworkImage
                    } else if let artistName = viewmodel.currentlyPlayingArtist, let currentAlbumName = viewmodel.currentAlbumName {
                        if let mbid = await MusicBrainzArtworkService.findMbid(albumName: currentAlbumName, artistName: artistName) {
                            viewmodel.artworkImage = await MusicBrainzArtworkService.artworkImage(for: mbid)
                        }
                    }
                } catch {
                    print("Error fetching artwork image for currentlyPlaying: \(error)")
                }
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
                    guard !viewmodel.isFirstFetch else {
                        print("Onboarding Task: ignoring false runtime call, cannot refresh as first fetch")
                        return
                    }
                    // make refreshLyrics use the same Task<> that fetch(_) uses
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
                Task {
                    await viewmodel.onCurrentlyPlayingIDChange()
                }
            }
        }
        .menuBarExtraStyle(.window)
        Window("Lyric Fever: Fullscreen", id: "fullscreen") {
            FullscreenView()
                .windowFullScreenBehavior(.enabled)
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
        Window("Lyric Fever: Searching for \(viewmodel.currentlyPlayingName ?? "-") by \(viewmodel.currentlyPlayingArtist ?? "-")", id: "search") {
            SearchWindow().frame(minWidth: 700, maxWidth: 700, minHeight: 500, maxHeight: 500, alignment: .center)
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
}


extension String {
  // https://gist.github.com/budidino/8585eecd55fd4284afaaef762450f98e
    @MainActor
    func trunc(length: Int? = nil, trailing: String = "…") -> String {
        let length = length ?? ViewModel.shared.userDefaultStorage.truncationLength
        return (self.count > length) ? self.prefix(length) + trailing : self
    }
}

