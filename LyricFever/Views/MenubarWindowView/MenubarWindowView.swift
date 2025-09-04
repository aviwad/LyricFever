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
    @Environment(\.colorScheme) var colorScheme
    @State var currentHoveredItem = MenubarButtonHighlight.none
    
    @ViewBuilder
    var profilePicViewHeaderView: some View {
        ZStack {
            if let artworkImage = viewmodel.artworkImage {
                Image(nsImage: artworkImage)
                    .resizable()
                    .frame(width: 112, height: 112)
                    .clipShape(.rect(cornerRadius: 9))
                    .animation(.smooth(duration: 0.3))
                    .shadow(color: viewmodel.currentBackground ?? .clear, radius: 70)
                    .shadow(color: viewmodel.currentBackground ?? .clear, radius: 70)
            } else {
                Image(systemName: "music.note.list")
                    .resizable()
                    .shadow(radius: 1)
                    .scaleEffect(0.5)
                    .background(.gray)
                    .frame(width: 112, height: 112)
                    .clipShape(.rect(cornerRadius: 9))
            }
            
            ZStack {
                if viewmodel.isFetching {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .clipShape(.rect(cornerRadius: 9))
                    
                    ProgressView()
                }
            }
            .animation(.smooth(duration: 2), value: viewmodel.isFetching)
        }
        .frame(width: 112, height: 112)
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
            .onHover { isHovering in
                currentHoveredItem = isHovering ? .rewind : .none
            }
            SongControlButton(systemImage: viewmodel.isPlaying ? "pause.fill" : "play.fill", wiggle: false) {
                viewmodel.currentPlayerInstance.togglePlayback()
            }
            .controlSize(.large)
            .onHover { isHovering in
                currentHoveredItem = isHovering ? (viewmodel.isPlaying ? .pause : .play) : .none
            }
            .contentTransition(.symbolEffect(.replace, options: .speed(2)))
            
            SongControlButton(systemImage: "forward.fill") {
                viewmodel.currentPlayerInstance.forward()
            }
            .onHover { isHovering in
                currentHoveredItem = isHovering ? .forward : .none
            }
        }
        .frame(height: 30)
//        .buttonStyle(.accessoryBar)
    }
    
    @ViewBuilder
    var headerView: some View {
        HStack(spacing: 12) {
            profilePicViewHeaderView
                .onHover { isHovering in
                    currentHoveredItem = isHovering ? viewmodel.currentPlayerInstance.currentHoverItem : .none
                }
                .onTapGesture {
                    viewmodel.currentPlayerInstance.activate()
                    dismiss()
                }
            VStack {
                HStack {
                    songDetails
//                    LikeButton()
//                        .task(id: viewmodel.currentlyPlaying) {
//                            guard let currentlyPlaying = viewmodel.currentlyPlaying else {
//                                print("Ignoring nil currentlyPlaying for heart check")
//                                return
//                            }
//                            print("Task to check if \(viewmodel.currentlyPlaying) is hearted")
//                            do {
//                                viewmodel.isHearted = try await viewmodel.spotifyLyricProvider.checkHeartedStatusFor(trackID: currentlyPlaying)
//                            } catch {
//                                print(error)
//                            }
//                        }
//                        .onHover { isHovering in
//                            currentHoveredItem = isHovering ? (viewmodel.isHearted ? .unheart : .heart) : .none
//                        }
                }
                songControls
                
                ProgressView(value: viewmodel.currentTime.currentTime, total: Double(viewmodel.duration))
                    .progressViewStyle(ColoredThinProgressViewStyle(color: .secondary, thickness: 4))
                    .frame(height: 4)
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
        // even out vertical padding with divider as compared to Menubar button
        .padding(.bottom, 2)
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
            .onHover { isHovering in
                if isHovering {
                    switch displayLyrics {
                        case .enabled:
                            currentHoveredItem = .disableLyrics
                        case .disabled:
                            currentHoveredItem = .unavailableLyrics
                        case .clickable:
                            currentHoveredItem = .enableLyrics
                        default:
                            currentHoveredItem = .none
                    }
                } else {
                    currentHoveredItem = .none
                }
            }
            MenubarButton(buttonText: "", imageText: "arrow.up.left.and.arrow.down.right", buttonState: displayFullscreen) {
                viewmodel.displayFullscreen.toggle()
                dismiss()
            }
            .onHover { isHovering in
                currentHoveredItem = isHovering ? .enableFullscreen : .none
            }
//            .foregroundStyle(.white)
            MenubarButton(buttonText: "", imageText: "dock.rectangle", buttonState: displayKaraoke) {
                viewmodel.userDefaultStorage.karaoke.toggle()
            }
            .onHover { isHovering in
                if isHovering {
                    switch displayKaraoke {
                        case .enabled:
                            currentHoveredItem = .disableKaraoke
                        case .disabled:
                            currentHoveredItem = .unavailableKaraoke
                        case .clickable:
                            currentHoveredItem = .enableKaraoke
                        default:
                            currentHoveredItem = .none
                    }
                } else {
                    currentHoveredItem = .none
                }
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
        guard viewmodel.userDefaultStorage.hasOnboarded else {
            return .disabled
        }
        guard viewmodel.showLyrics else {
            return .disabled
        }
        guard !viewmodel.lyricsIsEmptyPostLoad else {
            return .disabled
        }
        if viewmodel.userDefaultStorage.karaoke {
            return .enabled
        } else {
            return .clickable
        }
    }
    
    var refreshState: ButtonState {
        guard viewmodel.userDefaultStorage.hasOnboarded else {
            return .disabled
        }
        if viewmodel.isFetching {
            return .loading
        } else {
            return .clickable
        }
    }
    
    var translationState: ButtonState {
        guard viewmodel.userDefaultStorage.hasOnboarded else {
            return .disabled
        }
        guard !viewmodel.lyricsIsEmptyPostLoad else {
            return .disabled
        }
        if viewmodel.userDefaultStorage.translate {
            if viewmodel.translationExists {
                return .enabled
            } else if viewmodel.isFetchingTranslation {
                return .loading
            } else {
                return .missing
            }
        } else if viewmodel.userDefaultStorage.romanize {
            return .enabled
        } else {
            return .clickable
        }
    }
    
    var searchState: ButtonState {
        guard viewmodel.userDefaultStorage.hasOnboarded else {
            return .disabled
        }
        return .clickable
    }
    
    var deleteOrUploadState: ButtonState {
        guard viewmodel.userDefaultStorage.hasOnboarded else {
            return .disabled
        }
        // attach a separate disabled modifier to prevent slash flashing
//        if viewmodel.isFetching {
//            return .disabled
//        }
        return .clickable
    }
    
    @ViewBuilder
    var viewSelector: some View {
        @Bindable var viewmodel = viewmodel
        HStack {
            SmallMenubarButton(buttonText: "", imageText: "arrow.clockwise", buttonState: refreshState) {
                Task {
                    do {
                        try await viewmodel.refreshLyrics()
                    } catch {
                        print("Couldn't refresh lyrics: error \(String(describing: error))")
                    }
                }
            }
            .disabled(refreshState == .loading)
            .onHover { isHovering in
                if isHovering {
                    switch refreshState {
                        case .loading:
                            currentHoveredItem = .refreshingLyrics
                        case .disabled:
                            currentHoveredItem = .none
                        case .clickable:
                            currentHoveredItem = .refreshLyrics
                        default:
                            currentHoveredItem = .none
                    }
                } else {
                    currentHoveredItem = .none
                }
            }
            SmallMenubarButton(buttonText: "", imageText: "magnifyingglass", buttonState: searchState) {
                NSApplication.shared.activate(ignoringOtherApps: true)
                openWindow(id: "search")
            }
            Menu {
                translationAndRomanizationView
            } label: {
                HStack(spacing: 6) {
                    Text("...")
                    if viewmodel.airplayDelay {
                        Image(systemName: "airplayaudio")
                            .imageScale(.medium)
                    }
                }
                .accessibilityLabel(viewmodel.airplayDelay ? Text("More options, AirPlay delay enabled") : Text("More options"))
            }
            .disabled(translationState == .disabled)
            .buttonStyle(SmallMenubarButtonStyle(imageText: "translate", buttonState: translationState))
            .onHover { isHovering in
                if isHovering {
                    switch translationState {
                        case .enabled:
                            currentHoveredItem = .translateEnabled
                        case .disabled:
                            currentHoveredItem = .translationUnavailable
                        case .loading:
                            currentHoveredItem = .translationLoading
                        case .clickable:
                            currentHoveredItem = .translate
                        case .missing:
                            currentHoveredItem = .translationFail
                    }
                } else {
                    currentHoveredItem = .none
                }
            }
            SmallMenubarButton(buttonText: "", imageText: viewmodel.lyricsIsEmptyPostLoad ? "arrow.up.document" : "trash", buttonState: deleteOrUploadState) {
                if viewmodel.lyricsIsEmptyPostLoad {
                    Task {
                        do {
                            try await viewmodel.uploadLocalLRCFile()
                        } catch {
                            print("MenuBarWindowView: Upload LRC: Error occurred: \(error)")
                        }
                    }
                } else {
                    guard let currentlyPlaying = viewmodel.currentlyPlaying else { return }
                    viewmodel.deleteLyric(trackID: currentlyPlaying)
                }
            }
            .disabled(viewmodel.isFetching)
            .onHover { isHovering in
                if isHovering {
                    if viewmodel.lyricsIsEmptyPostLoad {
                        currentHoveredItem = .upload
                    } else {
                        currentHoveredItem = .delete
                    }
                } else {
                    currentHoveredItem = .none
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
    var otherOptions: some View {
        @Bindable var viewmodel = viewmodel
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
    }
    
    @ViewBuilder
    var systemControlView: some View {
        HStack {
            Menu {
                otherOptions
                    .foregroundStyle(viewmodel.currentBackground ?? .primary)
            } label: {
//                HStack(spacing: 6) {
                    Text("...")
//                    .font(.caption)
//                }
//                .accessibilityLabel(viewmodel.airplayDelay ? Text("More options, AirPlay delay enabled") : Text("More options"))
            }
//            .buttonStyle(.bordered)
            .menuIndicator(.hidden)
            if viewmodel.airplayDelay {
                Image(systemName: "airplayaudio")
                    .opacity(0.8)
            }
            if viewmodel.spotifyConnectDelay {
                Image(systemName: "tortoise")
                    .opacity(0.8)
            }
            Spacer()
            Text(currentHoveredItem.description)
                .textCase(.uppercase)
                .font(.system(size: 12, weight: .light, design: .monospaced))
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.top, 8)
    }
    
    var menubarSizeSliderBinding: Binding<Double> {
        Binding (
            get: { Double(viewmodel.userDefaultStorage.truncationLength) },
            set: { newValue in
                let steps = [30, 40, 50, 60]
                let closest = steps.min(by: { abs(Double($0) - newValue) < abs(Double($1) - newValue) }) ?? 40
                viewmodel.userDefaultStorage.truncationLength = closest
            }
        )
    }
    
    @ViewBuilder
    var menubarSizeSlider: some View {
        @Bindable var viewmodel = viewmodel
        HStack {
            Image(systemName: "textformat.size")
                .frame(width: 30)
            Slider(value: menubarSizeSliderBinding, in: 30...60, step: 10, label: {
                Text("Menubar Size")
            })
            .labelsHidden()
            .frame(width: 160)
            Text("\(viewmodel.userDefaultStorage.truncationLength)")
                .frame(width: 23)
        }
        .tint(.secondary)
//        .tint(colorScheme == .dark ? viewmodel.currentBackground : .white)
    }
    
    var volumeBinding: Binding<Double> {
        Binding(
            get: { Double(viewmodel.currentVolume) },
            set: { newValue in
                viewmodel.currentPlayerInstance.setVolume(to: newValue)
                viewmodel.currentVolume = Int(newValue)
            }
        )
    }
    
    @ViewBuilder
    var volumeSlider: some View {
        @Bindable var viewmodel = viewmodel
        HStack {
            Image(systemName: "speaker.wave.3", variableValue: Double(viewmodel.currentVolume)/100)
                .frame(width: 30)
            if #available(macOS 26.0, *) {
                Slider(value: volumeBinding, in: 0...100) {
                    Text("Volume")
                } ticks: {
                    
                }
                .labelsHidden()
                .frame(width: 160)
            } else {
                Slider(value: volumeBinding, in: 0...100) {
                    Text("Volume")
                }
                .labelsHidden()
                .frame(width: 160)
            }
            Text("\(viewmodel.currentVolume)")
                .frame(width: 23)
        }
        .tint(.secondary)
//        .tint(colorScheme == .dark ? viewmodel.currentBackground : .white)
    }
    
    var body: some View {
        VStack {
            headerView
            Divider()
            lyricModifierView
            Divider()
            viewSelector
            Divider()
            menubarSizeSlider
            volumeSlider
            if viewmodel.spotifyConnectDelay {
                Divider()
                spotifyConnectDelayPicker
            }
            Divider()
            systemControlView
        }
//        .preferredColorScheme(.dark)
        .foregroundStyle(.white)
        .padding(14)
        .background(
            viewmodel.currentBackground
                .brightness(-0.4)
                .opacity(0.6)
                .animation(.smooth, value: viewmodel.currentBackground)
        )
        .onAppear {
            viewmodel.currentVolume = viewmodel.currentPlayerInstance.volume
        }
    }
}

