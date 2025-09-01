//
//  MenubarButtonHighlight.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-15.
//

enum MenubarButtonHighlight: CustomStringConvertible {
    case activateMusicPlayer
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
    case upload
    case delete
    case quit
    
    case none
    
    
    var description: String {
        switch self {
            case .activateMusicPlayer:
                "Open Spotify"
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
                "Click to Enable Lyrics"
            case .disableLyrics:
                "Click to Disable Lyrics"
            case .unavailableLyrics:
                "Lyrics are unavailable."
            case .enableFullscreen:
                "Click to open fullscreen"
            case .enableKaraoke:
                "Click to enable karaoke"
            case .disableKaraoke:
                "Click to disable karaoke"
            case .unavailableKaraoke:
                "Karaoke is unavailable"
            case .refreshLyrics:
                "Refresh lyrics from internet"
            case .refreshingLyrics:
                "Currently refreshing lyrics..."
            case .search:
                "Click to search for lyrics"
            case .translate:
                "Click to translate"
            case .translateEnabled:
                "Translate is enabled"
            case .upload:
                "Click to use LRC file"
            case .delete:
                "Delete these lyrics"
            case .quit:
                "Quit Lyric Fever (⌘ + Q)"
            case .none:
                ""
        }
    }
}
