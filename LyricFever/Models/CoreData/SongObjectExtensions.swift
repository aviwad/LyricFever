//
//  SongObject+CoreDataProperties.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 06/08/23.
//
//

import Foundation
import CoreData


extension SongObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SongObject> {
        return NSFetchRequest<SongObject>(entityName: "SongObject")
    }

    @NSManaged public var downloadDate: Date
    @NSManaged public var id: String
    @NSManaged public var title: String
    @NSManaged public var language: String
    @NSManaged public var lyricsWords: [String]
    @NSManaged public var lyricsTimestamps: [TimeInterval]

}

extension SongObject : Identifiable {

}
