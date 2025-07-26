//
//  UserDefaultStorage.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-17.
//

import Combine
import SwiftUI
import ObservableDefaults

@ObservableDefaults
class UserDefaultStorage {
    var translate: Bool = false
    #if os(macOS)
    var showSongDetailsInMenubar: Bool = true
    #endif
    var blurFullscreen: Bool = true
    var animateOnStartupFullscreen: Bool = true
    var romanize: Bool = false
    #if os(macOS)
    var spotifyConnectDelayCount: Int = 400
    var hasMigrated: Bool = false
    
    // User setting: use album art color or user-set currentBackground
    var karaoke: Bool = false
    var karaokeUseAlbumColor: Bool = true
    var karaokeShowMultilingual: Bool = true
    var karaokeTransparency: Double = 50
    var fixedKaraokeColorHex: String = "#2D3CCC"
    
    // User setting: hide karaoke on hover
    var karaokeModeHoveringSetting: Bool = false
    #endif

    @DefaultsKey(userDefaultsKey: "spDcCookie")
    var cookie: String = ""
    
    #if os(macOS)
    // True: means Apple Music, False: Spotify
    var spotifyOrAppleMusic: Bool = false
    var latestUpdateWindowShown: Int = 0
    #endif
    var hasOnboarded: Bool = false
    var hasTranslated: Bool = false
    var truncationLength: Int = 40
}
