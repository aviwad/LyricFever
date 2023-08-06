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
        case lines
    }

    public required convenience init(from decoder: Decoder) throws {
        guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext, let trackID = decoder.userInfo[CodingUserInfoKey.trackID] as? String else {
            fatalError()
        }

        self.init(context: context)
        self.id = trackID
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lyrics = try container.decode([LyricLine].self, forKey: .lines)
        self.lyricsTimestamps = lyrics.map {$0.startTimeMS}
        self.lyricsWords = lyrics.map {$0.words}
    }
    
}
