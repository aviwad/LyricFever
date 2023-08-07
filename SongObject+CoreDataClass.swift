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
        case lines, syncType
    }

    public required convenience init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext, let trackID = decoder.userInfo[CodingUserInfoKey.trackID] as? String, let trackName = decoder.userInfo[CodingUserInfoKey.trackName] as? String else {
            fatalError()
        }

        self.init(context: context)
        self.id = trackID
        self.title = trackName
        self.downloadDate = Date.now
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let syncType = try? container.decode(String.self, forKey: .syncType), syncType == "LINE_SYNCED", let lyrics = try? container.decode([LyricLine].self, forKey: .lines) {
            self.lyricsTimestamps = lyrics.map {$0.startTimeMS}
            self.lyricsWords = lyrics.map {$0.words}
        } else {
            self.lyricsWords = []
            self.lyricsTimestamps = []
        }
    }
    
}
