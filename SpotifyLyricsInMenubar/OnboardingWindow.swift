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
                
                Text("Please accept the prompts so that Lyric Fever works properly ☺️.")
                    .font(.title)
                
                Image("hi")
                    .resizable()
                    .frame(width: 250, height: 250, alignment: .center)
                
                VStack(alignment: .center, spacing: 8) {
                    Text("Spotify Users: Make sure Spotify is installed on your mac")
                        .font(.title2)
                        .bold()
                    
                    Text(.init("Please download the [official Spotify Desktop client](https://www.spotify.com/in-en/download/mac/)"))
                        .font(.title3)
                }
                
                
                NavigationLink("Next", destination: ZeroView())
                    .buttonStyle(.borderedProminent)
                Text("Email me at [aviwad@gmail.com](mailto:aviwad@gmail.com) for any support\n⚠️ Disclaimer: I do not own the rights to Spotify or the lyric content presented.\nMusixmatch and Spotify own all rights to the lyrics.\nVersion 1.7")
                    .multilineTextAlignment(.center)
                    .font(.callout)
                    .padding(.top, 10)
            }
        }
    }
}

struct ZeroView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.controlActiveState) var controlActiveState
    @State var isAnimating = true
    @State private var isShowingDetailView = false
    @AppStorage("spDcCookie") var spDcCookie: String = ""
    @State var isLoading = false
    @State var error = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepView(title: "1. Spotify Login Credentials (EVEN IF YOU USE APPLE MUSIC!!!)", description: "We need the cookie to make the relevant Lyric API calls. Even if you're using Apple Music, I still download lyrics from Spotify.")
            
            HStack {
                Spacer()
                AnimatedImage(name: "spotifylogin.gif", isAnimating: $isAnimating)
                    .resizable()
                Spacer()
            }
            
            TextField("Enter your SP_DC Cookie Here :)", text: $spDcCookie)
            
            HStack {
                Button("Back") {
                    dismiss()
                }
                Button("Open Spotify on the Web", action: {
                    let url = URL(string: "https://open.spotify.com")!
                    NSWorkspace.shared.open(url)
                })
                Spacer()
                NavigationLink(destination: BetweenZeroAndFirstView(), isActive: $isShowingDetailView) {EmptyView()}
                    .hidden()
                if error && !isLoading {
                    Text("WRONG SP DC COOKIE TRY AGAIN ⚠️")
                        .foregroundStyle(.red)
                }
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(height: 20)
                }
                Button("Next") {
                    Task {
                        isLoading = true
                        if let url = URL(string: "https://open.spotify.com/get_access_token?reason=transport&productType=web_player") {
                            do {
                                var request = URLRequest(url: url)
                                request.setValue("sp_dc=\(spDcCookie)", forHTTPHeaderField: "Cookie")
                                let accessTokenData = try await URLSession.shared.data(for: request)
                                print(String(decoding: accessTokenData.0, as: UTF8.self))
                                try JSONDecoder().decode(accessTokenJSON.self, from: accessTokenData.0)
                                print("ACCESS TOKEN IS SAVED")
                                error = false
                                isLoading = false
                                isShowingDetailView = true
                            }
                            catch {
                                self.error = true
                                isLoading = false
                            }
                        }
                    }
                    // replace button with spinner
                    // check if the cookie is legit
                   // isLoading = false
                    //isShowingDetailView = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || spDcCookie.count == 0)
            }
            .padding(.vertical, 5)
            
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
//        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { newValue in
//            dismiss()
//        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willMiniaturizeNotification)) { newValue in
            dismiss()
        }
        .onChange(of: controlActiveState) { newState in
            if newState == .inactive {
                isAnimating = false
                print("inactive")
            } else {
                isAnimating = true
            }
        }
    }
}

struct BetweenZeroAndFirstView: View {
    @Environment(\.dismiss) var dismiss
    //@AppStorage("truncationLength") var truncationLength: Int = 50
    @State var truncationLength: Int = UserDefaults.standard.integer(forKey: "truncationLength")
    @Environment(\.controlActiveState) var controlActiveState
    let allTruncations = [30,40,50,60]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepView(title: "2. Set the Lyric Size", description: "This depends on how much free space you have in your menu bar!")
            
            Image("\(truncationLength)")
                .resizable()
                .scaledToFit()
            
            HStack {
                Spacer()
                Picker("Truncation Length", selection: $truncationLength) {
                    ForEach(allTruncations, id:\.self) { oneThing in
                        Text("\(oneThing) Characters")
                    }
                }
                .pickerStyle(.radioGroup)
                Spacer()
            }
            
            HStack {
                Button("Back") {
                    dismiss()
                }
                Spacer()
                NavigationLink("Next", destination: FirstView())
                    .buttonStyle(.borderedProminent)
            }
            
        }
        .onChange(of: truncationLength) { newLength in
            UserDefaults.standard.set(newLength, forKey: "truncationLength")
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
    }
}

struct FirstView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.controlActiveState) var controlActiveState
    @State var isAnimating = true
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepView(title: "3. Make sure you give Automation & Music permission", description: "We need these permissions to read the current song from Spotify & Apple Music, so that we can play the correct lyrics! Watch the following gif to correctly give permission.")
            
            HStack {
                Spacer()
                AnimatedImage(name: "newPermissionMac.gif", isAnimating: $isAnimating)
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
            dismiss()
            dismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willMiniaturizeNotification)) { newValue in
            dismiss()
            dismiss()
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
            StepView(title: "4. Make sure you disable crossfades (Spotify Users Only)", description: "Because of a glitch within Spotify, crossfades make the lyrics appear out-of-sync on occasion.")
            
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
            dismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willMiniaturizeNotification)) { newValue in
            dismiss()
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
