//
//  UserDefaultStorage.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-17.
//

import Combine
import SwiftUI
//import ObservableDefaults
import ObservableUserDefault


//@ObservableDefaults
@Observable
class UserDefaultStorage {
    @ObservableUserDefault(.init(key: "translate", defaultValue: false, store: .standard))
    @ObservationIgnored var translate: Bool
    @ObservableUserDefault(.init(key: "translationTargetLanguage", store: .standard))
    @ObservationIgnored var translationTargetLanguage: Locale.Language?
//    var furigana = false
    #if os(macOS)
    @ObservableUserDefault(.init(key: "showSongDetailsInMenubar", defaultValue: false, store: .standard))
    @ObservationIgnored var showSongDetailsInMenubar: Bool
    #endif
    @ObservableUserDefault(.init(key: "blurFullscreen", defaultValue: true, store: .standard))
    @ObservationIgnored var blurFullscreen: Bool
    @ObservableUserDefault(.init(key: "animateOnStartupFullscreen", defaultValue: true, store: .standard))
    @ObservationIgnored var animateOnStartupFullscreen: Bool
    @ObservableUserDefault(.init(key: "romanize", defaultValue: false, store: .standard))
    @ObservationIgnored var romanize: Bool
    @ObservableUserDefault(.init(key: "romanizeMetadata", defaultValue: true, store: .standard))
    @ObservationIgnored var romanizeMetadata: Bool
    @ObservableUserDefault(.init(key: "chinesePreference", defaultValue: 0, store: .standard))
    @ObservationIgnored var chinesePreference: Int
    #if os(macOS)
    @ObservableUserDefault(.init(key: "spotifyConnectDelayCount", defaultValue: 400, store: .standard))
    @ObservationIgnored var spotifyConnectDelayCount: Int
    @ObservableUserDefault(.init(key: "hasMigrated", defaultValue: false, store: .standard))
    @ObservationIgnored var hasMigrated: Bool
    
    // User setting: use album art color or user-set currentBackground
    @ObservableUserDefault(.init(key: "karaoke", defaultValue: true, store: .standard))
    @ObservationIgnored var karaoke: Bool
//    var karaokeUseAlbumColor: Bool = true
    @ObservableUserDefault(.init(key: "karaokeShowMultilingual", defaultValue: true, store: .standard))
    @ObservationIgnored var karaokeShowMultilingual: Bool
    @ObservableUserDefault(.init(key: "karaokeTransparency", defaultValue: 50, store: .standard))
    @ObservationIgnored var karaokeTransparency: Double
//    var fixedKaraokeColorHex: String = "#2D3CCC"
    
    // User setting: hide karaoke on hover
    @ObservableUserDefault(.init(key: "karaokeModeHoveringSetting", defaultValue: false, store: .standard))
    @ObservationIgnored var karaokeModeHoveringSetting: Bool
    #endif

//    @DefaultsKey(userDefaultsKey: "spDcCookie")
    @ObservableUserDefault(.init(key: "spDcCookie", defaultValue: "", store: .standard))
    @ObservationIgnored var cookie: String
    
    #if os(macOS)
    // False: Spotify, True: Apple Music
    @ObservableUserDefault(.init(key: "spotifyOrAppleMusic", defaultValue: false, store: .standard))
    @ObservationIgnored var spotifyOrAppleMusic: Bool
    @ObservableUserDefault(.init(key: "latestUpdateWindowShown", defaultValue: 0, store: .standard))
    @ObservationIgnored var latestUpdateWindowShown: Int
    #endif
    @ObservableUserDefault(.init(key: "hasOnboarded", defaultValue: false, store: .standard))
    @ObservationIgnored var hasOnboarded: Bool
    @ObservableUserDefault(.init(key: "hasTranslated", defaultValue: false, store: .standard))
    @ObservationIgnored var hasTranslated: Bool
    @ObservableUserDefault(.init(key: "truncationLength", defaultValue: 40, store: .standard))
    @ObservationIgnored var truncationLength: Int
}
