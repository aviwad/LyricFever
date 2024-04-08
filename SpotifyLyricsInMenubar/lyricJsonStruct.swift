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
    static let duration = CodingUserInfoKey(rawValue: "duration")!
}

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

// access token json
struct accessTokenJSON: Codable {
    let accessToken: String
    let accessTokenExpirationTimestampMs: TimeInterval
    let isAnonymous: Bool
}

struct SongObjectParent: Decodable {
    let lyrics: SongObject
}

struct SpotifyResponse: Codable {
    let tracks: Tracks
}

struct Tracks: Codable {
    let items: [Item]
}

struct Item: Codable {
    let type: String
    let id: String
}
