//
//  MenubarButtonHighlight.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-15.
//

enum MenubarButtonHighlight: CustomStringConvertible {
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
    case upload
    case delete
    case quit
    
    case none
    
    
    var description: String {
        switch self {
            case .activateSpotify:
                "Open Spotify"
            case .activateAppleMusic:
                "Open Apple Music"
            case .rewind:
                "Rewind"
            case .play:
                "Play"
            case .pause:
                "Pause"
            case .forward:
                "Forward"
            case .heart:
                "Heart"
            case .unheart:
                "Unheart"
            case .enableLyrics:
                "Enable Lyrics"
            case .disableLyrics:
                "Disable Lyrics"
            case .unavailableLyrics:
                "Lyrics unavailable."
            case .enableFullscreen:
                "Open Fullscreen"
            case .enableKaraoke:
                "enable karaoke"
            case .disableKaraoke:
                "disable karaoke"
            case .unavailableKaraoke:
                "Karaoke unavailable"
            case .refreshLyrics:
                "Redownload lyrics"
            case .refreshingLyrics:
                "refreshing lyrics..."
            case .search:
                "Click to search for lyrics"
            case .translate:
                "Translation options"
            case .translateEnabled:
                "Translation enabled"
            case .translationFail:
                "Translation Failure"
            case .translationLoading:
                "Translating..."
            case .upload:
                "Upload lrc file"
            case .delete:
                "Delete lyrics"
            case .quit:
                "Quit Lyric Fever (⌘ + Q)"
            case .none:
                ""
        }
    }
}
