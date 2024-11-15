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

struct LyricLine: Decodable, Hashable {
    let startTimeMS: TimeInterval
    let words: String
    let id = UUID()

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
    let colors: SpotifyColorData
}

struct SpotifyColorData: Codable {
    let background, text, highlightText: Int
    
    init(from decoder: any Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext, let trackID = decoder.userInfo[CodingUserInfoKey.trackID] as? String, let trackName = decoder.userInfo[CodingUserInfoKey.trackName] as? String, let duration = decoder.userInfo[CodingUserInfoKey.duration] as? TimeInterval else {
            fatalError()
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.background = try container.decode(Int.self, forKey: .background)
        self.text = try container.decode(Int.self, forKey: .text)
        self.highlightText = try container.decode(Int.self, forKey: .highlightText)
        let newColorMapping = IDToColor(context: context)
        newColorMapping.id = trackID
        newColorMapping.songColor = Int32(background)
        try context.save()
    }
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

struct ErrorWrapper: Codable {
    struct Error: Codable {
        let code: Int
        let message: String
    }

    let error: Error
}

