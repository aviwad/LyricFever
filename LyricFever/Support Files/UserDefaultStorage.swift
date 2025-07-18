//
//  UserDefaultStorage.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-17.
//

import Combine
import SwiftUI

class UserDefaultStorage: ObservableObject {
    @AppStorage("karaoke") var karaoke: Bool = false
    @AppStorage("translate") var translate: Bool = false
    @AppStorage("showSongDetailsInMenubar") var showSongDetailsInMenubar: Bool = true
    @AppStorage("blurFullscreen") var blurFullscreen: Bool = true
    @AppStorage("animateOnStartupFullscreen") var animateOnStartupFullscreen: Bool = true
    @AppStorage("romanize") var romanize: Bool = false
    @AppStorage("spotifyConnectDelayCount") var spotifyConnectDelayCount: Int = 400
    @AppStorage("hasMigrated") var hasMigrated: Bool = false
    
    // User setting: use album art color or user-set currentBackground
    @AppStorage("karaokeUseAlbumColor") var karaokeUseAlbumColor: Bool = true
    @AppStorage("karaokeShowMultilingual") var karaokeShowMultilingual: Bool = true
    @AppStorage("karaokeTransparency") var karaokeTransparency: Double = 50
    @AppStorage("fixedKaraokeColorHex") var fixedKaraokeColorHex: String = "#2D3CCC"
    
    // User setting: hide karaoke on hover
    @AppStorage("karaokeModeHoveringSetting") var karaokeModeHoveringSetting: Bool = false
    
    @AppStorage("spDcCookie") var cookie: String = ""
    
    // True: means Apple Music, False: Spotify
    @AppStorage("spotifyOrAppleMusic") var spotifyOrAppleMusic: Bool = false
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @AppStorage("hasUpdated22") var hasUpdated22: Bool = false
    @AppStorage("hasTranslated") var hasTranslated: Bool = false
    @AppStorage("truncationLength") var truncationLength: Int = 40
}
