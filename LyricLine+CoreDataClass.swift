//
//  LyricLine+CoreDataClass.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 05/08/23.
//
//

import Foundation
import CoreData

@objc(LyricLine)
public class LyricLine: NSManagedObject, Decodable {
        enum CodingKeys: String, CodingKey {
            case startTimeMS = "startTimeMs"
            case words
        }
    
        public required convenience init(from decoder: Decoder) throws {
            guard let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as? NSManagedObjectContext else {
                fatalError()
            }

            self.init(context: context)
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.startTimeMS = TimeInterval(try container.decode(String.self, forKey: .startTimeMS))!
            self.words = try container.decode(String.self, forKey: .words)
        }
}
