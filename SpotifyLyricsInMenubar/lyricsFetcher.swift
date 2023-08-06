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
    
    func fetchLyrics(for trackID: String?) async -> [LyricLine]? {
        guard let trackID else {
            return nil
        }
        if let lyrics = fetchFromCoreData(for: trackID) {
            print("got lyrics from core data :D")
            return lyrics
        }
        print("no lyrics from core data, going to download from internet")
        decoder.userInfo[CodingUserInfoKey.trackID] = trackID
        if let url = URL(string: "https://spotify-lyric-api.herokuapp.com/?trackid=\(trackID)"), let urlResponseAndData = try? await URLSession.shared.data(from: url), let songObject = try? decoder.decode(SongObject.self, from: urlResponseAndData.0) {
//            if let lines = lyrics.lines {
//                saveLyricsToCoreData(for: lines)
//            }
            if let startTimesArray = songObject.lyricsTimestamps, let wordsArray = songObject.lyricsWords {
                // Found the SongObject with the matching trackID
                let lyricsArray = zip(startTimesArray, wordsArray).map { LyricLine(startTime: $0, words: $1) }
                persistanceController.save()
                return lyricsArray
            }
        }
        return nil
    }
    
    func fetchFromCoreData(for trackID: String) -> [LyricLine]? {
        let fetchRequest: NSFetchRequest<SongObject> = SongObject.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", trackID) // Replace trackID with the desired value

        do {
            let results = try persistanceController.container.viewContext.fetch(fetchRequest)
            if let songObject = results.first, let startTimesArray = songObject.lyricsTimestamps, let wordsArray = songObject.lyricsWords {
                // Found the SongObject with the matching trackID
                let lyricsArray = zip(startTimesArray, wordsArray).map { LyricLine(startTime: $0, words: $1) }
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
    
    func saveLyricsToCoreData(for lyrics: [LyricLine]) {
        
    }
}
