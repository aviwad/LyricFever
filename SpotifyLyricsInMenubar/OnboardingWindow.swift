//
//  OnboardingWindow.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 01/09/23.
//

import SwiftUI
import SDWebImageSwiftUI
import ScriptingBridge
import MusicKit
import WebKit

struct OnboardingWindow: View {
    @State var spotifyPermission: Bool = false
    @Environment(\.dismiss) var dismiss
    @Environment(\.controlActiveState) var controlActiveState
    @State var appleMusicPermission: Bool = false
    @State var appleMusicLibraryPermission: Bool = false
    @State var permissionMissing: Bool = false
    @State var isAnimating = true
//    @State private var selection: Int? = nil
    @AppStorage("spotifyOrAppleMusic") var spotifyOrAppleMusic: Bool = false
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @State var errorMessage: String = "Please download the [official Spotify desktop client](https://www.spotify.com/in-en/download/mac/)"
    var body: some View {
        TabView {
            
            NavigationStack() {
                VStack(alignment: .center, spacing: 20) {
                    Group {
                        if permissionMissing {
                            Group {
                                AnimatedImage(name: "newPermissionMac.gif", isAnimating: $isAnimating)
                                    .resizable()
                                    .frame(width: 397, height: 340)
                                HStack {
                                    Button("Open Automation Panel", action: {
                                        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
                                        NSWorkspace.shared.open(url)
                                    })
                                    if spotifyOrAppleMusic {
                                        Button("Open Music Panel", action: {
                                            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Media")!
                                            NSWorkspace.shared.open(url)
                                        })
                                    }
                                }
                            }
                        } else {
                            Group {
                                Image("hi")
                                    .resizable()
                                    .frame(width: 150, height: 150, alignment: .center)
                                
                                Text("Welcome to Lyric Fever! 🎉")
                                    .font(.largeTitle)
                                    .onAppear() {
                                        
                                    }
                                
                                Text("Please pick between Spotify and Apple Music")
                                    .font(.title)
                            }
                        }
                    }
                    .transition(.fade)
                    
                    Group {
                        Picker("", selection: $spotifyOrAppleMusic) {
                            VStack {
                                Image("spotify")
                                    .resizable()
                                    .frame(width: 70.0, height: 70.0)
                                Text("Spotify")
                            }.tag(false)
                            VStack {
                                Image("music")
                                    .resizable()
                                    .frame(width: 70.0, height: 70.0)
                                Text("Apple Music")
                            }.tag(true)
                        }
                        .font(.title2)
                        .frame(width: 500)
                        .pickerStyle(.radioGroup)
                        .horizontalRadioGroupLayout()
                        
                    
                        
                        Text(LocalizedStringKey(errorMessage))
                            .transition(.opacity)
                            .id(errorMessage)
                        
                        if spotifyPermission && appleMusicPermission && appleMusicLibraryPermission {
                            NavigationLink("Next", destination: ApiView())
                                .buttonStyle(.borderedProminent)
                        } else {
                            HStack {
                                Button("Give Spotify Permissions") {
                                    
                                    let target = NSAppleEventDescriptor(bundleIdentifier: "com.spotify.client")
                                    // Can cause a freeze if app we're querying for isn't open
                                    // See: https://forums.developer.apple.com/forums/thread/666528
                                    guard let spotify = NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").first else {
                                        withAnimation {
                                            errorMessage = "Please open Spotify!"
                                        }
                                        return
                                    }
                                    let status = AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, true)
                                    switch status {
                                        case -600:
                                            errorMessage = "Please open Spotify!"
                                        case -0:
                                        withAnimation {
                                            permissionMissing = false
                                                spotifyPermission = true
                                            errorMessage = ""
                                        }
                                        default:
                                        withAnimation {
                                            errorMessage = "Please give required permissions!"
                                            permissionMissing = true
                                            isAnimating = true
                                        }
                                    }

                                    }
                                
                                .disabled(spotifyPermission)
                                Button("Give Apple Music Permissions") {
                                    let target = NSAppleEventDescriptor(bundleIdentifier: "com.apple.Music")
                                    guard let music = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").first else {
                                        withAnimation {
                                            errorMessage = "Please open Apple Music!"
                                        }
                                        return
                                    }
                                    let status = AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, true)
                                    switch status {
                                        case -600:
                                        errorMessage = "Please open Apple Music!"
                                        case -0:
                                        withAnimation {
                                            appleMusicPermission = true
                                            permissionMissing = false
                                        }
                                        isAnimating = false
                                        if appleMusicLibraryPermission {
                                            errorMessage = ""
                                        } else {
                                            errorMessage = "Please give us Apple Music Library permissions!"
                                        }
                                        default:
                                        withAnimation {
                                            permissionMissing = true
                                        }
                                        errorMessage = "Please give us required permissions!"
                                        permissionMissing = true
                                        isAnimating = true
                                            // OPEN AUTOMATION PANEL
                                    }

                                }
                                .disabled(appleMusicPermission)
                                Button("Give Apple Music Library Permissions") {
                                    Task {
                                        let status = await MusicKit.MusicAuthorization.request()
                                        
                                        if status == .authorized {
                                            withAnimation {
                                                appleMusicLibraryPermission = true
                                                permissionMissing = false
                                            }
                                            isAnimating = false
                                            if appleMusicPermission {
                                                errorMessage = ""
                                            } else {
                                                errorMessage = "Please give us Apple Music permissions!"
                                            }
                                        }
                                        else {
                                            errorMessage = "Please give us required permissions!"
                                            withAnimation {
                                                permissionMissing = true
                                            }
                                            isAnimating = true
                                        }
                                    }
                                }
                                .disabled(appleMusicLibraryPermission)
                            }
                        }
                        
                        
                        Text("Email me at [aviwad@gmail.com](mailto:aviwad@gmail.com) for any support\n⚠️ Disclaimer: I do not own the rights to Spotify or the lyric content presented.\nMusixmatch and Spotify own all rights to the lyrics.\n [Lyric Fever GitHub](https://github.com/aviwad/LyricFever)\nVersion 2.1")
                            .multilineTextAlignment(.center)
                            .font(.callout)
                            .padding(.top, 10)
                            .frame(alignment: .bottom)
                    }
                    .transition(.fade)
                    
                }
                .onAppear {
                    if spotifyOrAppleMusic {
                        errorMessage = "Please open Apple Music!"
                        spotifyPermission = true
                        appleMusicPermission = false
                        appleMusicLibraryPermission = false
                    } else {
                        errorMessage = "Please download the [official Spotify desktop client](https://www.spotify.com/in-en/download/mac/)"
                        appleMusicPermission = true
                        appleMusicLibraryPermission = true
                        spotifyPermission = false
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("didClickSettings"))) { newValue in
                    if spotifyOrAppleMusic {
                        // first set spotify button to true, because we dont run the spotify or apple music boolean check on window open anymore
                        errorMessage = "Please open Apple Music!"
                        spotifyPermission = true
                        appleMusicPermission = false
                        appleMusicLibraryPermission = false
                        
                        
                        // Check Apple Music Automation permission
                        guard let music = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").first else {
                            withAnimation {
                                errorMessage = "Please open Apple Music!"
                            }
                            return
                        }
                        let target = NSAppleEventDescriptor(bundleIdentifier: "com.apple.Music")
                        let status = AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, true)
                        switch status {
                            case -600:
                            errorMessage = "Please open Apple Music!"
                            case -0:
                            appleMusicPermission = true
                            permissionMissing = false
                            isAnimating = false
                            if appleMusicLibraryPermission {
                                errorMessage = ""
                            } else {
                                errorMessage = "Please give us Apple Music Library permissions!"
                            }
    //                                case -1744:
    //                                Alert(title: Text("Please give permission by going to the Automation panel"))
                            default:
                            withAnimation {
                                permissionMissing = true
                            }
                            errorMessage = "Please give us required permissions!"
                            permissionMissing = true
                            isAnimating = true
                                // OPEN AUTOMATION PANEL
                        }
                        
                        // Check Media Library Permission
                        Task {
                            let status = await MusicKit.MusicAuthorization.request()
                            
                            if status == .authorized {
                                withAnimation {
                                    appleMusicLibraryPermission = true
                                    permissionMissing = false
                                }
                                isAnimating = false
                                if appleMusicPermission {
                                    errorMessage = ""
                                } else {
                                    errorMessage = "Please give us Apple Music permissions!"
                                }
                            }
                            else {
                                errorMessage = "Please give us required permissions!"
                                withAnimation {
                                    permissionMissing = true
                                }
                                isAnimating = true
                            }
                        }
                        
                    } else {
                        errorMessage = "Please download the [official Spotify Desktop client](https://www.spotify.com/in-en/download/mac/)"
                        appleMusicPermission = true
                        appleMusicLibraryPermission = true
                        spotifyPermission = false
                        // Check Spotify
                        guard let spotify = NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").first else {
                            withAnimation {
                                errorMessage = "Please open Spotify!"
                            }
                            return
                        }
                        let target = NSAppleEventDescriptor(bundleIdentifier: "com.spotify.client")
                        let status = AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, true)
                        switch status {
                            case -600:
                                errorMessage = "Please open Spotify!"
                            case -0:
                            withAnimation {
                                permissionMissing = false
                                    spotifyPermission = true
                                errorMessage = ""
                            }
    //                                case -1744:
    //                                Alert(title: Text("Please give permission by going to the Automation panel"))
                            default:
                            withAnimation {
                                errorMessage = "Please give required permissions!"
                                permissionMissing = true
                                isAnimating = true
                            }
                                // OPEN AUTOMATION PANEL
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { newValue in
                    isAnimating = false
                    permissionMissing = false
                }
                .onReceive(NotificationCenter.default.publisher(for: NSWindow.willMiniaturizeNotification)) { newValue in
                    isAnimating = false
                    permissionMissing = false
                }
                .onChange(of: spotifyOrAppleMusic) { newSpotifyOrAppleMusic in
                    print("Updating permission booleans based on media player change")
                    if spotifyOrAppleMusic {
                        errorMessage = "Please open Apple Music!"
                        spotifyPermission = true
                        appleMusicPermission = false
                        appleMusicLibraryPermission = false
                    } else {
                        errorMessage = "Please download the [official Spotify Desktop client](https://www.spotify.com/in-en/download/mac/)"
                        appleMusicPermission = true
                        appleMusicLibraryPermission = true
                        spotifyPermission = false
                    }
                }
                .onChange(of: controlActiveState) { newState in
                    if newState == .inactive {
                        isAnimating = false
                    } else {
                        isAnimating = true
                    }
                }
            }
            .tabItem {
                Label("Main Settings", systemImage: "person.crop.circle")
            }
            KaraokeSettingsView()
                .padding(.horizontal, 100)
                 .tabItem {
                     Label("Karaoke Window", systemImage: "person.crop.circle")
                 }
             
//                 AppearanceSettingsView()
//                     .tabItem {
//                         Label("Appearance", systemImage: "paintpalette")
//                     }
             
//                 PrivacySettingsView()
//                     .tabItem {
//                         Label("Privacy", systemImage: "hand.raised")
//                     }
        }
//        NavigationStack()
    }
}

struct ApiView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.controlActiveState) var controlActiveState
    @State var isAnimating = true
    @State private var isShowingDetailView = false
    @AppStorage("spDcCookie") var spDcCookie: String = ""
    @State var isLoading = false
    @State var error = false
    @StateObject var navigationState = NavigationState()
    @State var loginMethod = true
    @State var loggedIn = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepView(title: "Please log into Spotify", description: "I download lyrics from Spotify (and use LRCLIB and NetEase as backups)")
            
            Picker("", selection: $loginMethod) {
                Text("Spotify Login").tag(true)
                Text("API Key: Advanced").tag(false)
            }
            .pickerStyle(.segmented)
            
            if loginMethod {
                ZStack {
                    // Blurred web view
                    WebView(request: URLRequest(url: URL(string: "https://accounts.spotify.com/en/login?continue=https%3A%2F%2Fopen.spotify.com%2F")!), navigationState: navigationState)
                        .disabled(loggedIn)
                        .brightness(loggedIn ? -0.4 : 0)
                        .blur(radius: loggedIn ? 15 : 0)
                    
                    if loggedIn {
                        VStack {
                            Text("You're Logged In 🙂")
                                .font(.largeTitle)
                            
                            // Next button centered on the web view
                            Button("Next") {
                                Task {
                                    await checkForLogin()
                                }
                                // Handle next button action
                            }
                            .font(.headline)
                            .controlSize(.large)
                            .buttonStyle(.borderedProminent)
                            Button("Log Out") {
                                Task {
                                    loggedIn = false
                                    viewModel.shared.cookie = ""
                                    navigationState.webView.load(URLRequest(url: URL(string: "https://www.spotify.com/logout/")!))
                                    try await Task.sleep(nanoseconds: 2000000000)
                                    navigationState.webView.load(URLRequest(url: URL(string: "https://accounts.spotify.com/en/login?continue=https%3A%2F%2Fopen.spotify.com%2F")!))
                                }
                            }
                            .font(.headline)
                            .controlSize(.large)
                        }
                    }
                }
            } else {
                HStack {
                    Spacer()
                    AnimatedImage(name: "spotifylogin.gif", isAnimating: $isAnimating)
                        .resizable()
                    Spacer()
                }
                
                TextField("Enter your SP_DC Cookie Here", text: $spDcCookie)
            }
            
            HStack {
                Button("Back") {
                    dismiss()
                }
                Button("Open Spotify on the Web", action: {
                    let url = URL(string: "https://open.spotify.com")!
                    NSWorkspace.shared.open(url)
                })
                Spacer()
                NavigationLink(destination: FinalTruncationView(), isActive: $isShowingDetailView) {EmptyView()}
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
                        await checkForLogin()
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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("didLogIn"))) { newValue in
            loggedIn = true
        }
        .onAppear {
            if spDcCookie.count > 0 {
                loggedIn = true
            }
        }
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

    
    func checkForLogin() async {
        isLoading = true
        do {
            let serverTimeRequest = URLRequest(url: .init(string: "https://open.spotify.com/server-time")!)
            let serverTimeData = try await viewModel.shared.fakeSpotifyUserAgentSession.data(for: serverTimeRequest).0
            let serverTime = try JSONDecoder().decode(SpotifyServerTime.self, from: serverTimeData).serverTime
            if let totp = viewModel.TOTPGenerator.generate(serverTimeSeconds: serverTime), let url = URL(string: "https://open.spotify.com/get_access_token?reason=transport&productType=web_player&totpVer=5&ts=\(Int(Date().timeIntervalSince1970))&totp=\(totp)") {
                var request = URLRequest(url: url)
                request.setValue("sp_dc=\(spDcCookie)", forHTTPHeaderField: "Cookie")
                let accessTokenData = try await viewModel.shared.fakeSpotifyUserAgentSession.data(for: request)
                print(String(decoding: accessTokenData.0, as: UTF8.self))
                do {
                    try JSONDecoder().decode(accessTokenJSON.self, from: accessTokenData.0)
                    print("ACCESS TOKEN IS SAVED")
                    // set onboarded to true here, no need to wait for user to finish selecting truncation
                    UserDefaults().set(true, forKey: "hasOnboarded")
                    error = false
                    isLoading = false
                    isShowingDetailView = true
                } catch {
                    self.error = true
                    isLoading = false
//                    do {
                        let errorWrap = try? JSONDecoder().decode(ErrorWrapper.self, from: accessTokenData.0)
                    if errorWrap?.error.code == 401 {
                        loggedIn = false
                        }
//                    } catch {
//                        // silently fail
//                    }
//                    print("json error decoding the access token, therefore bad cookie therefore un-onboard")
                }
                
            }
        } catch {
            self.error = true
            isLoading = false
        }
//        if let url = URL(string: "https://open.spotify.com/get_access_token?reason=transport&productType=web_player"){//&totp=\(getTotp())&totpVer=5&ts=\(getTimestamp())") {
//            do {
//                var request = URLRequest(url: url)
//                request.setValue("sp_dc=\(spDcCookie)", forHTTPHeaderField: "Cookie")
//                let accessTokenData = try await URLSession.shared.data(for: request)
//                print(String(decoding: accessTokenData.0, as: UTF8.self))
//                do {
//                    try JSONDecoder().decode(accessTokenJSON.self, from: accessTokenData.0)
//                    
//                    print("ACCESS TOKEN IS SAVED")
//                    // set onboarded to true here, no need to wait for user to finish selecting truncation
//                    UserDefaults().set(true, forKey: "hasOnboarded")
//                    error = false
//                    isLoading = false
//                    isShowingDetailView = true
//                }
//                catch {
//                    print("JSON ERROR CAUGHT")
//                    self.error = true
//                    isLoading = false
//                }
//            }
//            catch {
//                self.error = true
//                isLoading = false
//            }
//        }
    }
}

struct FinalTruncationView: View {
    @Environment(\.dismiss) var dismiss
    //@AppStorage("truncationLength") var truncationLength: Int = 40
    @State var truncationLength: Int = UserDefaults.standard.integer(forKey: "truncationLength")
    @Environment(\.controlActiveState) var controlActiveState
    let allTruncations = [30,40,50,60]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepView(title: "Set the Lyric Size", description: "This depends on how much free space you have in your menu bar!")
            
            Image("\(truncationLength)")
                .resizable()
                .scaledToFit()
                .onAppear() {
                    if truncationLength == 0 {
                        truncationLength = 40
                    }
                }
            
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
                Button("Done") {
                    NSApplication.shared.keyWindow?.close()
                    
                }
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
            dismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willMiniaturizeNotification)) { newValue in
            dismiss()
            dismiss()
            dismiss()
        }
    }
}


struct StepView: View {
    var title: LocalizedStringKey
    var description: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .bold()
            
            Text(description)
                .font(.title3)
        }
    }
}
