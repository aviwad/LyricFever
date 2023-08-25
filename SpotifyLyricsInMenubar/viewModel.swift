//
//  viewModel.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 14/08/23.
//

import Foundation
import ScriptingBridge
import CoreData
import AmplitudeSwift
import Sparkle

@MainActor class viewModel: ObservableObject {
    let decoder = JSONDecoder()
    static let shared = viewModel()
    @Published var currentlyPlaying: String?
    @Published var currentlyPlayingName: String?
    @Published var currentlyPlayingLyrics: [LyricLine] = []
    @Published var currentlyPlayingLyricsIndex: Int?
    @Published var isPlaying: Bool = false
    var spotifyScript: SpotifyApplication? = SBApplication(bundleIdentifier: "com.spotify.client")
    let coreDataContainer: NSPersistentContainer
    let amplitude = Amplitude(configuration: .init(apiKey: amplitudeKey))
    let updaterController: SPUStandardUpdaterController
    @Published var canCheckForUpdates = false
    private var currentFetchTask: Task<[LyricLine], Error>?
    private var currentLyricsUpdaterTask: Task<Void,Error>?
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        coreDataContainer = NSPersistentContainer(name: "Lyrics")
        coreDataContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
            self.coreDataContainer.viewContext.mergePolicy = NSMergePolicy.overwrite
        }
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = coreDataContainer.viewContext
        print("Application just started. lets check whats playing")
        if spotifyScript?.playerState == .playing {
            isPlaying = true
        }
    }
    
    func lyricUpdater() async throws {
        repeat {
            guard let playerPosition = spotifyScript?.playerPosition else {
                print("no player position hence stopped")
                // pauses the timer bc there's no player position
                stopLyricUpdater()
                return
            }
            let currentTime = playerPosition * 1000
            guard let lastIndex: Int = {
                if let currentlyPlayingLyricsIndex {
                    let newIndex = currentlyPlayingLyricsIndex + 1
                    if newIndex >= currentlyPlayingLyrics.count {
                        // we've reached the end of the song, we're past the last lyric
                        // so we set the timer till the duration of the song, in case the user skips ahead or forward
                        return nil
                    }
                    else if  currentTime > currentlyPlayingLyrics[currentlyPlayingLyricsIndex].startTimeMS, currentTime < currentlyPlayingLyrics[newIndex].startTimeMS {
                        print("just the next lyric")
                        return newIndex
                    }
                }
                // linear search through the array to find the first lyric that's right after the current time
                // done on first lyric update for the song, as well as post-scrubbing
                return currentlyPlayingLyrics.firstIndex(where: {$0.startTimeMS > currentTime})
            }() else {
                stopLyricUpdater()
                return
            }
    //        guard let lastIndex = currentlyPlayingLyrics.firstIndex(where: {$0.startTimeMS > currentTime}) else {
    //            print("no lyric index hence stopped")
    //            // pauses the timer because the index is nil
    //            // this only happens near the end of the song (we pass the last lyric)
    //            // or (more usually) when we skip songs and lyricUpdater is called before the new song's lyrics are loaded
    //            // loading new song immediately sets lyrics to [] and index to nil
    //            stopLyricUpdater()
    //            return
    //        }
            let nextTimestamp = currentlyPlayingLyrics[lastIndex].startTimeMS
            let diff = nextTimestamp - currentTime
            print("current time: \(currentTime)")
            print("next time: \(nextTimestamp)")
            print("the difference is \(diff)")
            try await Task.sleep(nanoseconds: 1000000*UInt64(diff))
            print("lyrics exist: \(!currentlyPlayingLyrics.isEmpty)")
            if currentlyPlayingLyrics.count > lastIndex {
                currentlyPlayingLyricsIndex = lastIndex
            } else {
                currentlyPlayingLyricsIndex = nil
            }
            print(currentlyPlayingLyricsIndex ?? "nil")
        } while !Task.isCancelled
       // try await lyricUpdater()
    }
    
    func startLyricUpdater() {
        if !isPlaying, currentlyPlayingLyrics.isEmpty {
            return
        }
        currentLyricsUpdaterTask?.cancel()
        currentLyricsUpdaterTask = Task {
            do {
                try await lyricUpdater()
            } catch {
                print("lyrics were canceled \(error)")
            }
        }
        Task {
            try await currentLyricsUpdaterTask?.value
        }
        
    }
    
    func stopLyricUpdater() {
        print("stop called")
        currentLyricsUpdaterTask?.cancel()
    }
    
    func saveCoreData() {
        let context = coreDataContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("core data error \(error)")
                // Show some error here
            }
        }
    }
    
    func fetch(for trackID: String, _ trackName: String) async -> [LyricLine]? {
        currentFetchTask?.cancel()
        let newFetchTask = Task {
            try await self.fetchLyrics(for: trackID, trackName)
        }
        currentFetchTask = newFetchTask
        do {
            return try await newFetchTask.value
        } catch {
            print("error \(error)")
            return nil
        }
    }
    
    private func fetchLyrics(for trackID: String, _ trackName: String) async throws -> [LyricLine] {
        if let lyrics = fetchFromCoreData(for: trackID) {
            print("got lyrics from core data :D \(trackID) \(trackName)")
            try Task.checkCancellation()
            amplitude.track(eventType: "CoreData Fetch")
            return lyrics
        }
        print("no lyrics from core data, going to download from internet \(trackID) \(trackName)")
        return try await fetchNetworkLyrics(for: trackID, trackName)
    }
    
    func fetchNetworkLyrics(for trackID: String, _ trackName: String) async throws -> [LyricLine] {
        decoder.userInfo[CodingUserInfoKey.trackID] = trackID
        decoder.userInfo[CodingUserInfoKey.trackName] = trackName
        if let url = URL(string: "https://spotify-lyric-api.herokuapp.com/?trackid=\(trackID)") {
            let urlResponseAndData = try await URLSession.shared.data(from: url)
            let songObject = try decoder.decode(SongObject.self, from: urlResponseAndData.0)
            print("downloaded from internet successfully \(trackID) \(trackName)")
            saveCoreData()
            print("SAVED TO COREDATA \(trackID) \(trackName)")
            let lyricsArray = zip(songObject.lyricsTimestamps, songObject.lyricsWords).map { LyricLine(startTime: $0, words: $1) }
            try Task.checkCancellation()
            amplitude.track(eventType: "Network Fetch")
            return lyricsArray
        }
        return []
    }
    
    func fetchFromCoreData(for trackID: String) -> [LyricLine]? {
        let fetchRequest: NSFetchRequest<SongObject> = SongObject.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", trackID) // Replace trackID with the desired value

        do {
            let results = try coreDataContainer.viewContext.fetch(fetchRequest)
            if let songObject = results.first {
                // Found the SongObject with the matching trackID
                let lyricsArray = zip(songObject.lyricsTimestamps, songObject.lyricsWords).map { LyricLine(startTime: $0, words: $1) }
                print("Found SongObject with ID:", songObject.id)
                return lyricsArray
            } else {
                // No SongObject found with the given trackID
                print("No SongObject found with the provided trackID. \(trackID)")
            }
        } catch {
            print("Error fetching SongObject:", error)
        }
        return nil
    }
}
