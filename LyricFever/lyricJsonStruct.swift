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

struct SpotifyUser: Codable {
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
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
    
    init(trackID: String, context: NSManagedObjectContext, background: Int32) {
        self.background = Int(background)
        self.text = 0
        self.highlightText = 0
        let newColorMapping = IDToColor(context: context)
        newColorMapping.id = trackID
        newColorMapping.songColor = background
        print("saving new background as \(background)")
        do {
            try context.save()
        } catch {
            print(error)
        }
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
    let name: String
    let artists: [Artist]
    var firstArtistName: String? {
        return artists.first?.name
    }
    let id: String
}

struct Artist: Codable {
    let name: String
}

struct ErrorWrapper: Codable {
    struct Error: Codable {
        let code: Int
        let message: String
    }

    let error: Error
}

struct LRCLyrics: Decodable {
    let id: Int
    let name, trackName, artistName, albumName: String
    let duration: Int
    let instrumental: Bool
    let plainLyrics, syncedLyrics: String
    let lyrics: [LyricLine]
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case trackName
        case artistName
        case albumName
        case duration
        case instrumental
        case plainLyrics
        case syncedLyrics
//        case lyrics
    }
    
    static func decodeLyrics(input: String) -> [LyricLine] {
        var lyricsArray: [LyricLine] = []
        let lines = input.components(separatedBy: "\n")
        
        for line in lines {
            // Use regex to match the timestamp and the lyrics
            let regex = try! NSRegularExpression(pattern: #"\[(\d{2}:\d{2}\.\d{2})\]\s*(.*)"#)
            let matches = regex.matches(in: line, range: NSRange(line.startIndex..<line.endIndex, in: line))
            
            for match in matches {
                if let timestampRange = Range(match.range(at: 1), in: line),
                   let lyricsRange = Range(match.range(at: 2), in: line) {
                    let timestamp = String(line[timestampRange])
                    let lyrics = String(line[lyricsRange])
                    lyricsArray.append(LyricLine(startTime: timestamp.convertToTimeInterval(), words: lyrics))
                }
            }
        }
        
        return lyricsArray
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.trackName = try container.decode(String.self, forKey: .trackName)
        self.artistName = try container.decode(String.self, forKey: .artistName)
        self.albumName = try container.decode(String.self, forKey: .albumName)
        self.duration = try container.decode(Int.self, forKey: .duration)
        self.instrumental = try container.decode(Bool.self, forKey: .instrumental)
        if instrumental {
            self.plainLyrics = ""
            self.syncedLyrics = ""
            self.lyrics = []
        } else {
            self.plainLyrics = try container.decode(String.self, forKey: .plainLyrics)
            self.syncedLyrics = try container.decode(String.self, forKey: .syncedLyrics)
            self.lyrics = LRCLyrics.decodeLyrics(input: syncedLyrics)
        }
//        self.lyrics = try container.decode([LyricLine].self, forKey: .lyrics)
    }
}


// https://stackoverflow.com/questions/35407212/how-to-parse-string-to-nstimeinterval
extension String {
    func convertToTimeInterval() -> TimeInterval {
        guard self != "" else {
            return 0
        }

        var interval: Double = 0

        let parts = self.components(separatedBy: ":")
        for (index, part) in parts.reversed().enumerated() {
            interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
        }

        return interval * 1000 // Convert seconds to milliseconds
    }
}

struct MusicBrainzReply: Codable {
    let created: String
    let count, offset: Int
    let releases: [MusicBrainzRelease]
    
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.created = try container.decode(String.self, forKey: .created)
            self.count = try container.decode(Int.self, forKey: .count)
            self.offset = try container.decode(Int.self, forKey: .offset)
            
            // Decode all releases and filter out "Bootleg" ones
            let allReleases = try container.decode([MusicBrainzRelease].self, forKey: .releases)
            self.releases = allReleases.filter { $0.status != "Bootleg" }
        }
}

struct MusicBrainzRelease: Codable {
    let id: String
    let status: String?
    
    enum CodingKeys: CodingKey {
        case id,status
    }
    
    init(from decoder: any Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.status = try? container.decode(String.self, forKey: .status)
    }
}

// Spotify TOTP Login Fix
struct SpotifyServerTime: Decodable {
    let serverTime: Int
}


// From LyricsX: NetEase. Adapted for my needs
struct NetEaseSearch: Decodable {
    let result: Result
    let code: Int
    
    struct Result: Decodable {
        let songs: [Song]
        let songCount: Int
        
        struct Song: Decodable {
            let name: String
            let id: Int
            let duration: Int // milliseconds
            let album: Album
            let artists: [Artist]
        }
        
        struct Album: Decodable {
            let name: String
        }
        
        struct Artist: Decodable {
            let name: String
        }
    }
}

struct NetEaseLyrics: Decodable {
    let lrc: Lyric?
    let klyric: Lyric?
    let tlyric: Lyric?
    let lyricUser: User?
    let yrc: Lyric?
    /*
    let sgc: Bool
    let sfy: Bool
    let qfy: Bool
    let code: Int
    let transUser: User
     */
    
    struct User: Decodable {
        let nickname: String
        
        /*
        let id: Int
        let status: Int
        let demand: Int
        let userid: Int
        let uptime: Int
         */
    }
    
    struct Lyric: Decodable {
        let lyric: String?
        
        /*
        let version: Int
         */
    }
}
