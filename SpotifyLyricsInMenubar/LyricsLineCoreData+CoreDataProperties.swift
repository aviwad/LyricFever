//
//  LyricsLineCoreData+CoreDataProperties.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 05/08/23.
//
//

import Foundation
import CoreData


extension LyricsLineCoreData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LyricsLineCoreData> {
        return NSFetchRequest<LyricsLineCoreData>(entityName: "LyricsLineCoreData")
    }

    @NSManaged public var startTimeMS: Double
    @NSManaged public var words: String?

}

extension LyricsLineCoreData : Identifiable {

}
