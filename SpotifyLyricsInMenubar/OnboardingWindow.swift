//
//  OnboardingWindow.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 01/09/23.
//

import SwiftUI
import SDWebImageSwiftUI
import ScriptingBridge

struct OnboardingWindow: View {
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 16) {
                Text("Welcome to Lyric Fever! 🎉")
                    .font(.largeTitle)
                
                Text("Here's a few steps to quickly setup Lyric Fever in your Menubar.")
                    .font(.title)
                
                Image("hi")
                    .resizable()
                    .frame(width: 250, height: 250, alignment: .center)
                
                StepView(title: "Make sure Spotify is installed on your mac", description: "Please download the [official Spotify Desktop client](https://www.spotify.com/in-en/download/mac/)")
                
                NavigationLink("Next", destination: FirstView())
                    .buttonStyle(.borderedProminent)
                Text("Email me at [aviwad@gmail.com](mailto:aviwad@gmail.com) for any support\n⚠️ Disclaimer: I do not own the rights to Spotify or the lyric content presented.\nMusixmatch and Spotify own all rights to the lyrics.\nVersion 1.0.1")
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .padding(.top, 10)
            }
        }
    }
}

struct FirstView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.controlActiveState) var controlActiveState
    @State var isAnimating = true
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepView(title: "2. Make sure you give Automation permission", description: "We need this permission to read the current song from Spotify, so that we can play the correct lyrics! Watch the following gif to correctly give permission.")
            
            HStack {
                Spacer()
                AnimatedImage(name: "spotifyPermissionMac.gif", isAnimating: $isAnimating)
                    .resizable()
                    .frame(width: 531, height: 450)
                Spacer()
            }
            
            HStack {
                Button("Back") {
                    dismiss()
                }
                Button("Open Automation Panel", action: {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
                    NSWorkspace.shared.open(url)
                })
                Spacer()
                NavigationLink("Next", destination: SecondView())
                    .buttonStyle(.borderedProminent)
            }
            
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { newValue in
            dismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willMiniaturizeNotification)) { newValue in
            dismiss()
        }
        .onChange(of: controlActiveState) { newState in
            if newState == .inactive {
                isAnimating = false
            } else {
                isAnimating = true
            }
        }
    }
}

struct SecondView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.controlActiveState) var controlActiveState
    @State var isAnimating = true
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepView(title: "3. Make sure you disable crossfades", description: "Because of a glitch within Spotify, crossfades make the lyrics appear out-of-sync on occasion.")
            
            HStack {
                Spacer()
                AnimatedImage(name: "crossfade.gif", bundle: .main, isAnimating: $isAnimating)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 470)
                Spacer()
            }
            
            HStack {
                Button("Back") {
                    dismiss()
                }
                Button("Open Spotify", action: {
                    let url = URL(string: "spotify:")!
                    NSWorkspace.shared.open(url)
                })
                Spacer()
                Button("Done") {
                    UserDefaults().set(true, forKey: "hasOnboarded")
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
            }
            
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { newValue in
            dismiss()
            dismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willMiniaturizeNotification)) { newValue in
            dismiss()
            dismiss()
        }
        .onChange(of: controlActiveState) { newState in
            print(newState)
            if newState == .inactive {
                isAnimating = false
            } else {
                isAnimating = true
            }
        }
    }
}

struct StepView: View {
    var title: String
    var description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .bold()
            
            Text(.init(description))
                .font(.title3)
        }
    }
}
