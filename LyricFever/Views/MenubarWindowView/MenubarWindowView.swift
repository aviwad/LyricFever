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
    @Environment(\.dismiss) var dismiss
    
    @ViewBuilder
    var profilePicViewHeaderView: some View {
        if let artworkImage = viewmodel.artworkImage {
            Image(nsImage: artworkImage)
                .resizable()
                .frame(width: 112, height: 112)
                .clipShape(.rect(cornerRadius: 12))
                .shadow(color: viewmodel.currentBackground ?? .clear, radius: 70)
                .shadow(color: viewmodel.currentBackground ?? .clear, radius: 70)
        } else {
            Image(systemName: "music.note.list")
                .resizable()
                .shadow(radius: 1)
                .scaleEffect(0.5)
                .background(.gray)
                .frame(width: 112, height: 112)
                .clipShape(.rect(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    var songDetails: some View {
        VStack {
            HStack {
                MarqueeText(viewmodel.currentlyPlayingName ?? "-", startDelay: 1.5, alignment: .leading, leftFade: 2)
                .frame(height: 15)
            }
            HStack {
                MarqueeText(viewmodel.currentlyPlayingArtist ?? "-", startDelay: 1.5, alignment: .leading, leftFade: 2)
                    .font(.caption)
                    .frame(height: 15)
            }
        }
    }
    
    @ViewBuilder
    var songControls: some View {
        HStack {
            SongControlButton(systemImage: "backward.fill") {
                viewmodel.currentPlayerInstance.rewind()
            }
            SongControlButton(systemImage: viewmodel.isPlaying ? "pause.fill" : "play.fill", wiggle: false) {
                viewmodel.currentPlayerInstance.togglePlayback()
            }
            .contentTransition(.symbolEffect(.replace, options: .speed(2)))
            
            SongControlButton(systemImage: "forward.fill") {
                viewmodel.currentPlayerInstance.forward()
            }
        }
        .frame(height: 30)
        .buttonStyle(.accessoryBar)
    }
    
    @ViewBuilder
    var headerView: some View {
        HStack(spacing: 12) {
            profilePicViewHeaderView
                .onTapGesture {
                    viewmodel.currentPlayerInstance.activate()
                    dismiss()
                }
            VStack {
                HStack {
                    songDetails
                    LikeButton()
                }
                songControls
                
                ProgressView(value: viewmodel.currentTime.currentTime, total: Double(viewmodel.duration))
                    .frame(height: 6)
                    .padding(.horizontal, 4)
                HStack {
                    Text(viewmodel.formattedCurrentTime)
                        .font(.caption2)
                    Spacer()
                    Text(viewmodel.formattedDuration)
                        .font(.caption2)
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    var displayLyrics: ButtonState {
        if !viewmodel.userDefaultStorage.hasOnboarded {
            return .disabled
        } else if viewmodel.lyricsIsEmptyPostLoad {
            return .disabled
        } else if viewmodel.showLyrics {
            return .enabled
        } else {
            return .clickable
        }
    }
    
    
    @ViewBuilder
    var lyricModifierView: some View {
        HStack {
            MenubarButton(buttonText: "", imageText: "music.note.list", buttonState: displayLyrics) {
                viewmodel.showLyrics.toggle()
            }
            MenubarButton(buttonText: "", imageText: "arrow.up.left.and.arrow.down.right", buttonState: displayFullscreen) {
                viewmodel.displayFullscreen.toggle()
                dismiss()
            }
            MenubarButton(buttonText: "", imageText: "dock.rectangle", buttonState: displayKaraoke) {
                viewmodel.displayKaraokeInMenuBar.toggle()
            }
//            if viewmodel.currentlyPlayingLyrics.isEmpty {
//                sampleButton(buttonText: "lol", imageText: "arrow.up.document") {
//                    
//                }
//            } else {
//            }
        }
//        if let currentlyPlaying = viewmodel.currentlyPlaying, let currentlyPlayingName = viewmodel.currentlyPlayingName {
//            Text(!viewmodel.currentlyPlayingLyrics.isEmpty ? "Lyrics Found 😃" : "No Lyrics Found ☹️")
//            Button(viewmodel.currentlyPlayingLyrics.isEmpty ? "Check for Lyrics Again" : "Refresh Lyrics") {
//                
//                Task {
//                    do {
//                        try await viewmodel.refreshLyrics()
//                    } catch {
//                        print("Couldn't refresh lyrics: error \(error)")
//                    }
//                }
//            }
//            .keyboardShortcut("r")
//            if viewmodel.currentlyPlayingLyrics.isEmpty {
//                Button("Upload Local LRC File") {
//                    Task {
//                        do {
//                            try await viewmodel.uploadLocalLRCFile()
//                        } catch {
//                            print("Couldn't upload local lrc file: error \(error)")
//                        }
//                    }
//                }
//            } else {
//                Button("Delete Lyrics (wrong lyrics)") {
//                    viewmodel.deleteLyric(trackID: currentlyPlaying)
//                }
//            }
//        // Special case where Apple Music -> Spotify ID matching fails (perhaps Apple Music music was not the media in foreground, network failure, genuine no match)
//        // Apple Music Persistent ID exists but Spotify ID (currently playing) is nil
//        } else if viewmodel.currentlyPlayingAppleMusicPersistentID != nil, viewmodel.currentlyPlaying == nil {
//            Text("No Lyrics (Couldn't find Spotify ID) ☹️")
//            Button("Check for Lyrics Again") {
//                Task {
//                    // Fetch updates the currentlyPlaying ID which will call Lyric Updater
//                    try await viewmodel.appleMusicFetch()
//                }
//            }
//            .keyboardShortcut("r")
//        }
//        Toggle("Show Lyrics", isOn: $viewmodel.showLyrics)
//        .disabled(!viewmodel.userDefaultStorage.hasOnboarded)
//        .keyboardShortcut("h")
    }
    
    @ViewBuilder
    var searchButton: some View {
        Button {
            
        } label: {
            Image(systemName: "magnifyingglass")
        }
    }
    
    @ViewBuilder
    var translationAndRomanizationView: some View {
        @Bindable var viewmodel = viewmodel
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
    }
    
    @ViewBuilder
    var spotifyConnectDelayPicker: some View {
        Text("TODO")
    }
    
    
    var displayFullscreen: ButtonState {
        if !viewmodel.userDefaultStorage.hasOnboarded {
            return .disabled
        } else if viewmodel.displayFullscreen {
            return .enabled
        } else {
            return .clickable
        }
    }
    
    var displayKaraoke: ButtonState {
        if !viewmodel.userDefaultStorage.hasOnboarded {
            return .disabled
        } else if !viewmodel.showLyrics {
            return .disabled
        } else if viewmodel.lyricsIsEmptyPostLoad {
            return .disabled
        } else if !viewmodel.userDefaultStorage.karaoke {
            return .clickable
        } else {
            return .enabled
        }
    }
    
    var refreshState: ButtonState {
        if viewmodel.isFetching {
            return .disabled
        } else {
            return .clickable
        }
    }
    
    @ViewBuilder
    var viewSelector: some View {
        @Bindable var viewmodel = viewmodel
        HStack {
            ZStack {
                MenubarButton(buttonText: "", imageText: "arrow.clockwise", buttonState: refreshState) {
                    Task {
                        do {
                            try await viewmodel.refreshLyrics()
                        } catch {
                            print("Couldn't refresh lyrics: error \(String(describing: error))")
                        }
                    }
                }
                if viewmodel.isFetching {
                    ProgressView()
                    .controlSize(.small)
                    .padding(.vertical, 16)
                }
            }
            MenubarButton(buttonText: "", imageText: "magnifyingglass", buttonState: .clickable) {
                
            }
            MenubarButton(buttonText: "", imageText: viewmodel.lyricsIsEmptyPostLoad ? "arrow.up.document" : "trash", buttonState: .clickable) {
                if viewmodel.lyricsIsEmptyPostLoad {
                } else {
                    guard let currentlyPlaying = viewmodel.currentlyPlaying else { return }
                    viewmodel.deleteLyric(trackID: currentlyPlaying)
                }
            }
            .contentTransition(.symbolEffect(.replace))
        }
    }
    
    @ViewBuilder
    var streamingDelayView: some View {
        @Bindable var viewmodel = viewmodel
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
            Toggle("AirPlay Audio Delay", isOn: $viewmodel.airplayDelay)
                .disabled(!viewmodel.userDefaultStorage.hasOnboarded)
            Divider()
        }
    }
    
    @ViewBuilder
    var systemControlView: some View {
        @Bindable var viewmodel = viewmodel
        HStack {
            Menu {
                Divider()
                Toggle("Show Song Details in Menubar", isOn: $viewmodel.userDefaultStorage.showSongDetailsInMenubar)
                Divider()
                streamingDelayView
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
            } label: {
                Image(systemName: "ellipsis")
            }
            .buttonStyle(.bordered)
            .menuIndicator(.hidden)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    @ViewBuilder
    var menubarSizePicker: some View {
        @Bindable var viewmodel = viewmodel
        HStack {
            Image(systemName: "textformat.size")
            Slider(value: .init(
                get: { Double(viewmodel.userDefaultStorage.truncationLength) },
                set: { newValue in
                    let steps = [30, 40, 50, 60]
                    let closest = steps.min(by: { abs(Double($0) - newValue) < abs(Double($1) - newValue) }) ?? 40
                    viewmodel.userDefaultStorage.truncationLength = closest
                }
            ), in: 30...60, step: 10, label: {
                Text("Menubar Size")
            })
            .labelsHidden()
            .frame(width: 160)
            Text("\(viewmodel.userDefaultStorage.truncationLength)")
        }
    }
    
    var body: some View {
        VStack {
            headerView
                .animation(.smooth, value: viewmodel.artworkImage)
            Divider()
            lyricModifierView
            Divider()
            viewSelector
            Divider()
            searchButton
            Divider()
            translationAndRomanizationView
            Divider()
            menubarSizePicker
            if viewmodel.spotifyConnectDelay {
                Divider()
                spotifyConnectDelayPicker
            }
            Divider()
            systemControlView
        }
        .padding(20)
        .background(
            viewmodel.currentBackground
                .brightness(-0.3)
                .opacity(0.5)
                .animation(.smooth, value: viewmodel.currentBackground)
        )
    }
}

