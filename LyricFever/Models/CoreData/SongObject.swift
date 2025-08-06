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
public class SongObject: NSManagedObject {
    enum CodingKeys: String, CodingKey {
        case lines, language, syncType
    }
    
    convenience init(from LRCLyrics: LRCLIBLyrics, with context: NSManagedObjectContext, trackID: String, trackName: String, duration: TimeInterval) {
        self.init(context: context)
        self.id = trackID
        self.title = trackName
        self.downloadDate = Date.now
        self.language = ""
        if !LRCLyrics.lyrics.isEmpty {
            var newLyrics = LRCLyrics.lyrics
            newLyrics.removeAll { $0.words == ""}
            newLyrics.append(LyricLine(startTime: duration+5000, words: "Now Playing: \(title)"))
            self.lyricsTimestamps = newLyrics.map {$0.startTimeMS}
            self.lyricsWords = newLyrics.map {$0.words}
        } else {
            self.lyricsTimestamps = []
            self.lyricsWords = []
        }
        
    }
    
    convenience init(from LocalLyrics: [LyricLine], with context: NSManagedObjectContext, trackID: String, trackName: String, duration: TimeInterval) {
        self.init(context: context)
        self.id = trackID
        self.title = trackName
        self.downloadDate = Date.now
        self.language = ""
        if !LocalLyrics.isEmpty {
            var newLyrics = LocalLyrics
            newLyrics.append(LyricLine(startTime: duration+5000, words: "Now Playing: \(title)"))
            self.lyricsTimestamps = newLyrics.map {$0.startTimeMS}
            self.lyricsWords = newLyrics.map {$0.words}
        } else {
            self.lyricsTimestamps = []
            self.lyricsWords = []
        }
        
    }
}
