//
//  LyricLine+CoreDataProperties.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 05/08/23.
//
//

import Foundation
import CoreData


extension LyricLine {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LyricLine> {
        return NSFetchRequest<LyricLine>(entityName: "LyricLine")
    }

    @NSManaged public var startTimeMS: Double
    @NSManaged public var words: String

}

extension LyricLine : Identifiable {

}
