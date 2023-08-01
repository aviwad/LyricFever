//
//  lyricJsonStruct.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 01/08/23.
//

import Foundation

// MARK: - Welcome5
struct LyricJson: Codable {
    let error: Bool
    let syncType: String
    let lines: [LyricLine]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.error = try container.decode(Bool.self, forKey: .error)
        self.syncType = try container.decode(String.self, forKey: .syncType)
        self.lines = try container.decode([LyricLine].self, forKey: .lines)
    }
}

// MARK: - Line
struct LyricLine: Codable {
//    let startTimeMS, words: String
////    let syllables: [Any?]
//    let endTimeMS: String
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.startTimeMS = try container.decode(String.self, forKey: .startTimeMS)
//        self.words = try container.decode(String.self, forKey: .words)
//        self.endTimeMS = try container.decode(String.self, forKey: .endTimeMS)
//    }
    let startTimeMS, words: String
    let syllables: [String]
    let endTimeMS: String

    enum CodingKeys: String, CodingKey {
        case startTimeMS = "startTimeMs"
        case words, syllables
        case endTimeMS = "endTimeMs"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.startTimeMS = try container.decode(String.self, forKey: .startTimeMS)
        self.words = try container.decode(String.self, forKey: .words)
        self.syllables = []
        self.endTimeMS = try container.decode(String.self, forKey: .endTimeMS)
    }
}
