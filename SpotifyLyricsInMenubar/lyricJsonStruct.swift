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
    let lines: [LyricLine]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.error = try container.decode(Bool.self, forKey: .error)
        self.syncType = try container.decode(String.self, forKey: .syncType)
        if error {
            self.lines = nil
        } else {
            self.lines = try container.decode([LyricLine].self, forKey: .lines)
        }
    }
}

// MARK: - Line
struct LyricLine: Codable {
    let startTimeMS: TimeInterval
    let words: String
  //  let syllables: [String]
    //let endTimeMS: TimeInterval

    enum CodingKeys: String, CodingKey {
        case startTimeMS = "startTimeMs"
        case words//, syllables
   //     case endTimeMS = "endTimeMs"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.startTimeMS = TimeInterval(try container.decode(String.self, forKey: .startTimeMS))!
        self.words = try container.decode(String.self, forKey: .words)
 //       self.syllables = []
   //     self.endTimeMS = TimeInterval(try container.decode(String.self, forKey: .endTimeMS))!
    }
}

struct Song: Identifiable {
    let title: String
    let id: String
    let lyrics: [LyricLine]
}
