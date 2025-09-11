//
//  OnboardingWindow.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 01/09/23.
//

import SwiftUI
import SDWebImage
import ScriptingBridge
import MusicKit
import WebKit

struct OnboardingWindow: View {
    @State var spotifyPermission: Bool = false
    @Environment(\.dismiss) var dismiss
    var body: some View {
        TabView {
            MainSettingsView()
                .tabItem {
                    Label("Main Settings", systemImage: "person.crop.circle")
                }
            KaraokeSettingsView()
                .padding(.horizontal, 100)
                 .tabItem {
                     Label("Karaoke Window", systemImage: "person.crop.circle")
                 }
            GlobalKeyboardShortcutsView()
                .padding(.horizontal, 100)
                 .tabItem {
                     Label("Keyboard Shortcuts", systemImage: "keyboard")
                 }
        }
    }
}
