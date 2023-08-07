//
//  lyricJsonStruct.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 01/08/23.
//

import Foundation
import CoreData

extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
    static let trackID = CodingUserInfoKey(rawValue: "trackID")!
    static let trackName = CodingUserInfoKey(rawValue: "trackName")!
}
// MARK: - Welcome5
//struct LyricJson: Decodable {
//    let error: Bool
//    let syncType: String
//    let lines: [LyricLine]?
//    
//    enum CodingKeys: String, CodingKey {
//        case error, syncType, lines
//    }
//    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.error = try container.decode(Bool.self, forKey: .error)
//        self.syncType = try container.decode(String.self, forKey: .syncType)
//        if error {
//            self.lines = nil
//        } else {
//            self.lines = try container.decode([LyricLine].self, forKey: .lines)
//        }
//    }
//}

struct LyricLine: Decodable {
    let startTimeMS: TimeInterval
    let words: String

    enum CodingKeys: String, CodingKey {
        case startTimeMS = "startTimeMs"
        case words
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.startTimeMS = TimeInterval(try container.decode(String.self, forKey: .startTimeMS))!
        self.words = try container.decode(String.self, forKey: .words)
    }
    
    init(startTime: TimeInterval, words: String) {
        self.startTimeMS = startTime
        self.words = words
    }
}
