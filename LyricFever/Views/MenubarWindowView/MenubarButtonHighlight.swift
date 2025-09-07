//
//  MenubarButtonHighlight.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-15.
//

import SwiftUI

enum MenubarButtonHighlight {
    case activateSpotify
    case activateAppleMusic
    case rewind
    case play
    case pause
    case forward
    case heart
    case unheart
    case enableLyrics
    case disableLyrics
    case unavailableLyrics
    case enableFullscreen
    case enableKaraoke
    case disableKaraoke
    case unavailableKaraoke
    case refreshLyrics
    case refreshingLyrics
    case search
    case translate
    case translateEnabled
    case translationFail
    case translationLoading
    case translationUnavailable
    case upload
    case delete
    case quit
    
    case none
    
    
    var description: LocalizedStringKey {
        switch self {
            case .activateSpotify:
                LocalizedStringKey("Open Spotify")
            case .activateAppleMusic:
                LocalizedStringKey("Open Apple Music")
            case .rewind:
                LocalizedStringKey("Rewind")
            case .play:
                LocalizedStringKey("Play (spacebar)")
            case .pause:
                LocalizedStringKey("Pause (spacebar)")
            case .forward:
                LocalizedStringKey("Forward")
            case .heart:
                LocalizedStringKey("Heart")
            case .unheart:
                LocalizedStringKey("Unheart")
            case .enableLyrics:
                LocalizedStringKey("Enable Lyrics")
            case .disableLyrics:
                LocalizedStringKey("Disable Lyrics")
            case .unavailableLyrics:
                LocalizedStringKey("Lyrics unavailable.")
            case .enableFullscreen:
                LocalizedStringKey("Open Fullscreen")
            case .enableKaraoke:
                LocalizedStringKey("Enable Karaoke")
            case .disableKaraoke:
                LocalizedStringKey("Disable Karaoke")
            case .unavailableKaraoke:
                LocalizedStringKey("Karaoke Unavailable")
            case .refreshLyrics:
                LocalizedStringKey("Redownload lyrics")
            case .refreshingLyrics:
                LocalizedStringKey("Refreshing Lyrics...")
            case .search:
                LocalizedStringKey("Manual lyric search")
            case .translate:
                LocalizedStringKey("Translation options")
            case .translateEnabled:
                LocalizedStringKey("Translation Enabled")
            case .translationFail:
                LocalizedStringKey("Translation Failure")
            case .translationLoading:
                LocalizedStringKey("Translating...")
            case .translationUnavailable:
                LocalizedStringKey("Translation Unavailable")
            case .upload:
                LocalizedStringKey("Upload LRC File")
            case .delete:
                LocalizedStringKey("Delete Lyrics")
            case .quit:
                LocalizedStringKey("Quit Lyric Fever (⌘ + Q)")
            case .none:
                ""
        }
    }
}
