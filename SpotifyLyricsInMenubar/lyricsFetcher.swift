//
//  lyricsFetcher.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 02/08/23.
//

import Foundation
import CoreData

actor lyricsFetcher {
    let decoder = JSONDecoder()
    let persistanceController = PersistenceController.shared
    init() {
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = persistanceController.container.viewContext
    }
    
    func fetchLyrics(for trackID: String, _ trackName: String) async throws -> [LyricLine] {
//        guard let trackID, let trackName else {
//            return []
//        }
        if let lyrics = fetchFromCoreData(for: trackID) {
            print("got lyrics from core data :D")
            return lyrics
        }
        print("no lyrics from core data, going to download from internet")
//        else if let lyrics = fetchFromNetwork(for: trackID, trackName) {
//            print("got lyrics from network :D")
//            return lyrics
//        } else {
//            return []
//        }
        decoder.userInfo[CodingUserInfoKey.trackID] = trackID
        decoder.userInfo[CodingUserInfoKey.trackName] = trackName
        if let url = URL(string: "https://spotify-lyric-api.herokuapp.com/?trackid=\(trackID)") {
            let urlResponseAndData = try await URLSession.shared.data(from: url)
            let songObject = try decoder.decode(SongObject.self, from: urlResponseAndData.0)
            print("downloaded from internet successfully")
            persistanceController.save()
            print("SAVED TO COREDATA")
            let lyricsArray = zip(songObject.lyricsTimestamps, songObject.lyricsWords).map { LyricLine(startTime: $0, words: $1) }
            return lyricsArray
        }
        return []
    }
    
    func fetchFromCoreData(for trackID: String) -> [LyricLine]? {
        let fetchRequest: NSFetchRequest<SongObject> = SongObject.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", trackID) // Replace trackID with the desired value

        do {
            let results = try persistanceController.container.viewContext.fetch(fetchRequest)
            if let songObject = results.first {
                // Found the SongObject with the matching trackID
                let lyricsArray = zip(songObject.lyricsTimestamps, songObject.lyricsWords).map { LyricLine(startTime: $0, words: $1) }
                print("Found SongObject with ID:", songObject.id)
                return lyricsArray
            } else {
                // No SongObject found with the given trackID
                print("No SongObject found with the provided trackID.")
            }
        } catch {
            print("Error fetching SongObject:", error)
        }
        return nil
    }
    
//    func fetchFromNetwork(for trackID: String, _ trackName: String) -> [LyricLine]? {
//        
//    }
    
}
