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
                Text("Email me at [aviwad@gmail.com](mailto:aviwad@gmail.com) for any support")
                    .font(.callout)
                    .padding(.top, 10)
            }
        }
    }
}

struct FirstView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepView(title: "2. Make sure you give Automation permission", description: "We need this permission to read the current song from Spotify, so that we can play the correct lyrics! Watch the following gif to correctly give permission.")
            
            HStack {
                Spacer()
                AnimatedImage(name: "spotifyPermissionMac.gif")
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
    }
}

struct SecondView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepView(title: "3. Make sure you disable crossfades", description: "Because of a glitch within Spotify, crossfades make the lyrics appear out-of-sync on occasion.")
            
            HStack {
                Spacer()
                AnimatedImage(name: "crossfade.gif", bundle: .main)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 430)
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
                    //UserDefaults.standard.bool(forKey: "hasOnboarded") = true
                    NSApplication.shared.keyWindow?.close()
                    dismiss()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
        }
        .padding(.horizontal, 20)
            .navigationBarBackButtonHidden(true)
    }
}

//struct OnboardingWindow2: View {
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 16) {
//                Group {
//                    Text("Welcome to Spotify Lyrics in Menubar! 🎉")
//                        .font(.largeTitle)
//
//                    Text("Here's a few steps to quickly setup Spotify Lyrics in your Menubar.")
//                        .font(.title)
//                }
//
//                Group {
//                    StepView(title: "1. Make sure Spotify is installed on your mac", description: "Please download the [official Spotify Desktop client](https://www.spotify.com/in-en/download/mac/)")
//
//                }
//
//                Group {
//                    StepView(title: "2. Make sure you give Automation permission", description: "We need this permission to read the current song from Spotify, so that we can play the correct lyrics! Watch the following gif to correctly give permission.")
//
//                    AnimatedImage(name: "spotifyPermissionMac.gif")
//    //                Image("spotifyPermissionMac")
//                        .resizable()
//                        //.aspectRatio(contentMode: .fit)
//                        .frame(width: 531, height: 450)
//                        .border(.black)
//
//                    Button("Open Automation Panel", action: {
//                        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
//                        NSWorkspace.shared.open(url)
//                    })
//
//                }
//
//                Group {
//                    StepView(title: "3. Make sure you disable crossfades", description: "Because of a glitch within Spotify, crossfades make the lyrics appear slow on occasion. I've informed them. Till then, the solution is to disable crossfades. Watch the following gif to correctly give permission.")
//
//                    AnimatedImage(name: "crossfade.gif", bundle: .main)
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(height: 600)
//
//                    Button("Open Spotify", action: {
//                        let url = URL(string: "spotify:")!
//                        NSWorkspace.shared.open(url)
//                    })
//                }
//
//                Group {
//                    StepView(title: "4. Check for Lyrics again", description: "If you're sure the playing song has lyrics but for some reason they aren't showing up, click the Check for lyrics again button to retry a download.")
//
//                    Image("checkAgain")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(height: 200)
//                }
////
//                StepView(title: "If all else fails, please shoot me an email", description: "I'd be more than happy to help you. Please email me at [aviwad@gmail.com](mailto:aviwad@gmail.com).")
//            }
//            .padding(20)
//        }
//    }
//}

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
