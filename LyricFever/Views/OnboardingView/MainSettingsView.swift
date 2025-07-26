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
    
    var description: String {
        switch self {
        case .openSpotify:
            return "Please open Spotify!"
        case .openAppleMusic:
            return "Please open Apple Music!"
        case .missingAuthorization:
            return "Please give required permissions!"
        case .authorized:
            return ""
        }
    }
}

struct MainSettingsView: View {
    @Environment(ViewModel.self) var viewModel
    @State var permissionDenied: Bool = false
    @State var error: MainSettingsError = .openSpotify
    
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
    
    var body: some View {
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
                        
                @Bindable var viewModel = viewModel
                Picker("", selection: $viewModel.currentPlayer) {
                    ForEach(PlayerType.allCases) { player in
                        VStack {
                            Image(player.imageName)
                                .resizable()
                                .frame(width: 70.0, height: 70.0)
                            Text(player.description)
                        }
                        .tag(player)
                    }
                }
                .font(.title2)
                .frame(width: 500)
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
                            
                Text(error.description)
                    .transition(.opacity)
                            
                if error == .authorized {
                    NavigationLink("Next", destination: ApiView())
                        .font(.headline)
                        .controlSize(.large)
                        .buttonStyle(.borderedProminent)
                } else {
                    HStack {
                        Button("Give Spotify Permissions") {
                            if !viewModel.spotifyPlayer.isRunning {
                                print("Spotify not running")
                                error = .openSpotify
                            } else if !viewModel.spotifyPlayer.isAuthorized {
                                error = .openSpotify
                                permissionDenied = true
                            } else {
                                error = .authorized
                            }
                        }
                        .disabled(viewModel.currentPlayer == .appleMusic)
                        
                        Button("Give Apple Music Permissions") {
                            if !viewModel.appleMusicPlayer.isRunning {
                                error = .openAppleMusic
                            } else if !viewModel.appleMusicPlayer.isAuthorized {
                                error = .openAppleMusic
                                permissionDenied = true
                            } else {
                                error = .authorized
                            }
                        }
                        .disabled(viewModel.currentPlayer == .spotify)
                    }
                }
                
                Text("Email me at [aviwad@gmail.com](mailto:aviwad@gmail.com) for any support\n⚠️ Disclaimer: I do not own the rights to Spotify or the lyric content presented.\nMusixmatch and Spotify own all rights to the lyrics.\n [Lyric Fever GitHub](https://github.com/aviwad/LyricFever)\nVersion 2.2")
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .padding(.top, 10)
                    .frame(alignment: .bottom)
            }
            .animation(.bouncy, value: permissionDenied)
            .animation(.bouncy, value: error)
            .onChange(of: viewModel.currentPlayer) { newValue in
                print("Updating permission booleans based on media player change")
                switch newValue {
                case .appleMusic:
                        error = .openAppleMusic
                case .spotify:
                        error = .openSpotify
                }
            }
        }
    }
}

