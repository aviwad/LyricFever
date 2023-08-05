//
//  PersistenceController.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 05/08/23.
//

import Foundation
import CoreData

struct PersistenceController {
    // A singleton for our entire app to use
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    init(){
        container = NSPersistentContainer(name: "Lyrics")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Show some error here
            }
        }
    }
}
