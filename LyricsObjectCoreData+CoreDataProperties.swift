//
//  LyricsObjectCoreData+CoreDataProperties.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 05/08/23.
//
//

import Foundation
import CoreData


extension LyricsObjectCoreData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LyricsObjectCoreData> {
        return NSFetchRequest<LyricsObjectCoreData>(entityName: "LyricsObjectCoreData")
    }

    @NSManaged public var trackID: UUID?
    @NSManaged public var lyrics: [LyricsLineCoreData]?

}

extension LyricsObjectCoreData : Identifiable {

}
