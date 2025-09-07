//
//  SongResult.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-09-06.
//

import Foundation


struct SongResult: Identifiable {
    let lyricType: String
    let songName: String
    let albumName: String
    let artistName: String
    let id = UUID()
    let lyrics: [LyricLine]
}
