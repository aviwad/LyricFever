//
//  MainSettingsView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//

//
//  MainSettingsView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-19.
//

import SwiftUI
import SDWebImageSwiftUI

enum MainSettingsError: Error, Identifiable, CaseIterable {
    case openSpotify
    case openAppleMusic
    case missingAuthorization
    case authorized
    
    var id: Self { self }
    
    var description: LocalizedStringKey {
        switch self {
        case .openSpotify:
            return LocalizedStringKey("Please open Spotify!")
        case .openAppleMusic:
            return LocalizedStringKey("Please open Apple Music!")
        case .missingAuthorization:
            return LocalizedStringKey("Please give required permissions!")
        case .authorized:
            return " "
        }
    }
}

/// What the player picker shows: a fixed app, or Auto (follow whichever app is playing)
enum PlayerChoice: Hashable {
    case spotify
    case appleMusic
    case auto
}

struct MainSettingsView: View {
    @Environment(ViewModel.self) var viewModel
    @State var permissionDenied: Bool = false
    @State var error: MainSettingsError = .openSpotify
    // True once a "Give ... Permissions" button was pressed, so its result replaces the Auto hint
    @State var hasCheckedPermissions: Bool = false
    @AppStorage("spotifyOrAppleMusic") var spotifyOrAppleMusic: Bool = false
    
    /// Auto turns on auto-switch (the same setting as the menu toggle) and keeps the last-used app as the starting one.
    /// Picking Spotify or Apple Music turns auto-switch off and locks to that app.
    func playerChoiceBinding(isAuto: Bool) -> Binding<PlayerChoice> {
        Binding(
            get: {
                if isAuto {
                    return .auto
                }
                return spotifyOrAppleMusic ? .appleMusic : .spotify
            },
            set: { choice in
                switch choice {
                    case .auto:
                        viewModel.userDefaultStorage.autoSwitchPlayer = true
                        // If the other app is the one playing right now, jump to it
                        viewModel.autoSwitchToPlayingPlayerIfIdle()
                    case .spotify:
                        viewModel.userDefaultStorage.autoSwitchPlayer = false
                        spotifyOrAppleMusic = false
                    case .appleMusic:
                        viewModel.userDefaultStorage.autoSwitchPlayer = false
                        spotifyOrAppleMusic = true
                }
            }
        )
    }
    
    @ViewBuilder
    var permissionDeniedView: some View {
        AnimatedImage(name: "newPermissionMac.gif")
            .resizable()
            .frame(width: 397, height: 340)
        HStack {
            Button("Open Automation Panel", action: {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
                NSWorkspace.shared.open(url)
            })
        }
    }
    
    @ViewBuilder
    var onboardView: some View {
        Image("hi")
            .resizable()
            .frame(width: 150, height: 150, alignment: .center)
                    
        Text("Welcome to Lyric Fever! 🎉")
            .font(.largeTitle)
                    
        Text("Please pick between Spotify and Apple Music")
            .font(.title)
    }
    
    @ViewBuilder
    var permissionsOrNextButton: some View {
        if error == .authorized {
            NavigationLink("Next", destination: ApiView())
                .font(.headline)
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
        } else {
            HStack {
                Button("Give Spotify Permissions") {
                    hasCheckedPermissions = true
                    if !viewModel.spotifyPlayer.isRunning {
                        print("Spotify not running")
                        error = .openSpotify
                    } else if !viewModel.spotifyPlayer.isAuthorized {
                        error = .openSpotify
                        permissionDenied = true
                    } else {
                        permissionDenied = false
                        error = .authorized
                    }
                }
                // In Auto both apps can be set up
                .disabled(!viewModel.userDefaultStorage.autoSwitchPlayer && viewModel.currentPlayer == .appleMusic)
                
                Button("Give Apple Music Permissions") {
                    hasCheckedPermissions = true
                    if !viewModel.appleMusicPlayer.isRunning {
                        error = .openAppleMusic
                    } else if !viewModel.appleMusicPlayer.isAuthorized {
                        error = .openAppleMusic
                        permissionDenied = true
                    } else {
                        permissionDenied = false
                        error = .authorized
                    }
                }
                .disabled(!viewModel.userDefaultStorage.autoSwitchPlayer && viewModel.currentPlayer == .spotify)
            }
        }
    }
    
    var body: some View {
        @Bindable var viewmodel = viewModel
        let isAuto = viewModel.userDefaultStorage.autoSwitchPlayer
        NavigationStack {
            VStack(alignment: .center, spacing: 20) {
                Group {
                    if permissionDenied {
                        permissionDeniedView
                    } else {
                        onboardView
                    }
                }
                .transition(.fade)
                
                Picker("", selection: playerChoiceBinding(isAuto: isAuto)) {
                    VStack {
                        Image("spotify")
                            .resizable()
                            .frame(width: 70.0, height: 70.0)
                        Text("Spotify")
                    }.tag(PlayerChoice.spotify)
                    VStack {
                        Image("music")
                            .resizable()
                            .frame(width: 70.0, height: 70.0)
                        Text("Apple Music")
                    }.tag(PlayerChoice.appleMusic)
                    VStack {
                        // Both app icons overlapping: "whichever is playing"
                        ZStack {
                            Image("spotify")
                                .resizable()
                                .frame(width: 46.0, height: 46.0)
                                .offset(x: -12, y: -12)
                            Image("music")
                                .resizable()
                                .frame(width: 46.0, height: 46.0)
                                .offset(x: 12, y: 12)
                        }
                        .frame(width: 70.0, height: 70.0)
                        Text("Auto")
                    }
                    .help("Show lyrics for whichever app is playing")
                    .tag(PlayerChoice.auto)
                }
                .font(.title2)
                .frame(width: 500)
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
                            
                Group {
                    if isAuto && !hasCheckedPermissions {
                        Text("Auto shows lyrics for whichever app is playing. Give permissions for the apps you use.")
                    } else {
                        Text(error.description)
                    }
                }
                    .transition(.opacity)
                            
                permissionsOrNextButton
                    .frame(height: 40)
                
                VStack {
                    Text("Email me at [aviwad@gmail.com](mailto:aviwad@gmail.com) for any support")
                    Text(verbatim: "⚠️ Disclaimer: I do not own the rights to Spotify or the lyric content presented.\nMusixmatch and Spotify own all rights to the lyrics.\nTranslations by InTheManXG and ARui-tw")
                    Text("[Lyric Fever GitHub](https://github.com/aviwad/LyricFever)\nVersion 3.3")
                }
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .padding(.top, 10)
                    .frame(alignment: .bottom)
            }
            .animation(.bouncy, value: permissionDenied)
            .animation(.bouncy, value: error)
            .onChange(of: viewModel.currentPlayer) {
                // In Auto the app changes by itself; keep whatever the permission buttons last reported
                guard !viewModel.userDefaultStorage.autoSwitchPlayer else {
                    return
                }
                print("Updating permission booleans based on media player change")
                switch viewModel.currentPlayer {
                case .appleMusic:
                        error = .openAppleMusic
                case .spotify:
                        error = .openSpotify
                }
            }
        }
    }
}

