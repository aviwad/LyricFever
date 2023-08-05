//
//  Song+CoreDataProperties.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 05/08/23.
//
//

import Foundation
import CoreData


extension Song {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Song> {
        return NSFetchRequest<Song>(entityName: "Song")
    }

    @NSManaged public var title: String?
    @NSManaged public var id: UUID?
    @NSManaged public var lyrics: [LyricLine]?

}

extension Song : Identifiable {

}
