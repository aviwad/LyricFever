//
//  Untitled.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-17.
//

enum PlayerType: CustomStringConvertible {
    var description: String {
        switch self {
            case .appleMusic:
                return "Apple Music"
            case .spotify:
                return "Spotify"
        }
    }
    
    case appleMusic
    case spotify
}
