//
//  Untitled.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-17.
//

enum PlayerType: CustomStringConvertible, CaseIterable, Identifiable {
    var id: Self { self }

    var description: String {
        switch self {
            case .spotify:
                return "Spotify"
            case .appleMusic:
                return "Apple Music"
        }
    }
    
    var imageName: String {
        switch self {
            case .spotify:
                return "spotify"
            case .appleMusic:
                return "music"
        }
    }
    case spotify
    case appleMusic
}
