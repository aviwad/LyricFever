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
    var lyricUpdateWorkItem: DispatchWorkItem?
    var spotifyScript: SpotifyApplication? = SBApplication(bundleIdentifier: "com.spotify.client")
    let coreDataContainer: NSPersistentContainer
    let amplitude = Amplitude(configuration: .init(apiKey: amplitudeKey))
    let updaterController: SPUStandardUpdaterController
    @Published var canCheckForUpdates = false

    
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
    
    func lyricUpdater(_ newIndex: Int) {
        print("lyrics exist: \(!currentlyPlayingLyrics.isEmpty)")
        if currentlyPlayingLyrics.count > newIndex {
            currentlyPlayingLyricsIndex = newIndex
        } else {
            currentlyPlayingLyricsIndex = nil
        }
        print(currentlyPlayingLyricsIndex ?? "nil")
        startLyricUpdater()
    }
    
    func startLyricUpdater() {
        guard let playerPosition = spotifyScript?.playerPosition else {
            stopLyricUpdater()
            return
        }
        let currentTime = playerPosition * 1000
        guard let lastIndex = currentlyPlayingLyrics.firstIndex(where: {$0.startTimeMS > currentTime}) else {
            stopLyricUpdater()
            return
        }
        let nextTimestamp = currentlyPlayingLyrics[lastIndex].startTimeMS
        let diff = nextTimestamp - currentTime
        print("current time: \(currentTime)")
        print("next time: \(nextTimestamp)")
        print("the difference is \(diff)")
        lyricUpdateWorkItem = DispatchWorkItem {
            self.lyricUpdater(lastIndex)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(diff)), execute: lyricUpdateWorkItem!)
    }
    
    func stopLyricUpdater() {
        print("stop called")
        lyricUpdateWorkItem?.cancel()
    }
    
    func saveCoreData() {
        let context = coreDataContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Show some error here
            }
        }
    }
    
    func fetchLyrics(for trackID: String, _ trackName: String) async throws -> [LyricLine] {
        if let lyrics = fetchFromCoreData(for: trackID) {
            amplitude.track(eventType: "CoreData Fetch")
            print("got lyrics from core data :D \(trackID) \(trackName)")
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
