//
//  SongObject+CoreDataClass.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 06/08/23.
//
//

import Foundation
import CoreData

@objc(SongObject)
public class SongObject: NSManagedObject, Decodable {
    enum CodingKeys: String, CodingKey {
        case lines, language, syncType
    }
    
    convenience init(from LRCLyrics: LRCLyrics, with context: NSManagedObjectContext, trackID: String, trackName: String, duration: TimeInterval) {
        self.init(context: context)
        self.id = trackID
        self.title = trackName
        self.downloadDate = Date.now
        self.language = ""
//        self.duration = duration
        if !LRCLyrics.lyrics.isEmpty {
            var newLyrics = LRCLyrics.lyrics
            newLyrics.append(LyricLine(startTime: duration-1400, words: "Now Playing: \(title)"))
            self.lyricsTimestamps = newLyrics.map {$0.startTimeMS}
            self.lyricsWords = newLyrics.map {$0.words}
        } else {
            self.lyricsTimestamps = []
            self.lyricsWords = []
        }
        
    }

    public required convenience init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext, let trackID = decoder.userInfo[CodingUserInfoKey.trackID] as? String, let trackName = decoder.userInfo[CodingUserInfoKey.trackName] as? String, let duration = decoder.userInfo[CodingUserInfoKey.duration] as? TimeInterval else {
            fatalError()
        }

        self.init(context: context)
        self.id = trackID
        self.title = trackName
        self.downloadDate = Date.now
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.language = (try? container.decode(String.self, forKey: .language)) ?? ""
        if let syncType = try? container.decode(String.self, forKey: .syncType), syncType == "LINE_SYNCED", var lyrics = try? container.decode([LyricLine].self, forKey: .lines) {
            // Dummy lyric at the end to keep the timer going past the last lyric, necessary for someone playing a single song on repeat
            // Spotify doesn't give playback notifications when it's the same song on repeat
            // Apple Music does, but unfortunately has every song slightly longer than it's spotify counterpart so this doesn't help us
            if !lyrics.isEmpty {
                lyrics.append(LyricLine(startTime: duration-1400, words: "Now Playing: \(title)"))
            }
            self.lyricsTimestamps = lyrics.map {$0.startTimeMS}
            self.lyricsWords = lyrics.map {$0.words}
        } else {
            self.lyricsWords = []
            self.lyricsTimestamps = []
        }
    }
    
}
