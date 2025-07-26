//
//  ApiView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//

import SwiftUI
import SDWebImageSwiftUI

struct ApiView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isShowingDetailView = false
    @AppStorage("spDcCookie") var spDcCookie: String = ""
    @State var isLoading = false
    @State var errorMessage: String?
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
                                checkForLogin()
                                // Handle next button action
                            }
                            .font(.headline)
                            .controlSize(.large)
                            .buttonStyle(.borderedProminent)
                            Button("Log Out") {
                                Task {
                                    loggedIn = false
                                    ViewModel.shared.userDefaultStorage.cookie = ""
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
                    AnimatedImage(name: "spotifylogin.gif")
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
                if let errorMessage, !isLoading {
                    Text("WRONG SP DC COOKIE TRY AGAIN ⚠️")
                        .foregroundStyle(.red)
                }
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(height: 20)
                }
                Button("Next") {
                    checkForLogin()
                    // replace button with spinner
                    // check if the cookie is legit
                   // isLoading = false
                    //isShowingDetailView = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || spDcCookie.count == 0)
            }
            .padding(.vertical, 15)
            
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("didLogIn"))) { newValue in
            loggedIn = true
        }
    }
    
    func checkForLogin() {
        Task {
            do {
                try await ViewModel.shared.spotifyLyricProvider.generateAccessToken()
                isShowingDetailView = true
                errorMessage = nil
                ViewModel.shared.userDefaultStorage.hasOnboarded = true
            } catch {
                print("Failed to generate access token: \(error)")
                errorMessage = String(describing: error)
            }
        }
    }
}
