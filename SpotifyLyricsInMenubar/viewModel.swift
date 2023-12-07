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
import SwiftUI

@MainActor class viewModel: ObservableObject {
    let decoder = JSONDecoder()
    static let shared = viewModel()
    @Published var currentlyPlaying: String?
    var currentlyPlayingName: String?
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
    var accessToken: accessTokenJSON?
    @AppStorage("spDcCookie") var cookie = ""
    
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
    }
    
    func upcomingIndex(_ currentTime: Double) -> Int? {
        if let currentlyPlayingLyricsIndex {
            let newIndex = currentlyPlayingLyricsIndex + 1
            if newIndex >= currentlyPlayingLyrics.count {
                // if current time is before our current index's start time, the user has scrubbed and rewinded
                // reset into linear search mode
                if currentTime < currentlyPlayingLyrics[currentlyPlayingLyricsIndex].startTimeMS {
                    return currentlyPlayingLyrics.firstIndex(where: {$0.startTimeMS > currentTime})
                }
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
            guard let lastIndex: Int = upcomingIndex(currentTime) else {
                stopLyricUpdater()
                return
            }
            let nextTimestamp = currentlyPlayingLyrics[lastIndex].startTimeMS
            let diff = nextTimestamp - currentTime
            print("current time: \(currentTime)")
            print("next time: \(nextTimestamp)")
            print("the difference is \(diff)")
            try await Task.sleep(nanoseconds: UInt64(1000000*diff))
            print("lyrics exist: \(!currentlyPlayingLyrics.isEmpty)")
            if currentlyPlayingLyrics.count > lastIndex {
                currentlyPlayingLyricsIndex = lastIndex
            } else {
                currentlyPlayingLyricsIndex = nil
            }
            print(currentlyPlayingLyricsIndex ?? "nil")
        } while !Task.isCancelled
    }
    
    func startLyricUpdater() {
        if !isPlaying || currentlyPlayingLyrics.isEmpty || spotifyScript?.playerPosition == 0.0 {
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
        guard let intDuration = spotifyScript?.currentTrack?.duration else {
            throw CancellationError()
        }
        decoder.userInfo[CodingUserInfoKey.trackID] = trackID
        decoder.userInfo[CodingUserInfoKey.trackName] = trackName
        decoder.userInfo[CodingUserInfoKey.duration] = TimeInterval(intDuration+10)
        /*
         check if saved access token is bigger than current time, then continue with url shit
         else
         check if we have spdc cookie, then access token stuff
            then save access token in this observable object
                then continue with url shit
         otherwise []
         */
        if accessToken == nil || (accessToken!.accessTokenExpirationTimestampMs <= Date().timeIntervalSince1970*1000) {
            if let url = URL(string: "https://open.spotify.com/get_access_token?reason=transport&productType=web_player") {
                var request = URLRequest(url: url)
                request.setValue("sp_dc=\(cookie)", forHTTPHeaderField: "Cookie")
                let accessTokenData = try await URLSession.shared.data(for: request)
                print(String(decoding: accessTokenData.0, as: UTF8.self))
                accessToken = try JSONDecoder().decode(accessTokenJSON.self, from: accessTokenData.0)
                print("ACCESS TOKEN IS SAVED")
            }
        }
        if let accessToken, let url = URL(string: "https://spclient.wg.spotify.com/color-lyrics/v2/track/\(trackID)?format=json&vocalRemoval=false") {
            var request = URLRequest(url: url)
            request.addValue("WebPlayer", forHTTPHeaderField: "app-platform")
            print("the access token is \(accessToken.accessToken)")
            request.addValue("Bearer \(accessToken.accessToken)", forHTTPHeaderField: "authorization")
            let urlResponseAndData = try await URLSession.shared.data(for: request)
            if urlResponseAndData.0.isEmpty {
                return []
            }
            print(String(decoding: urlResponseAndData.0, as: UTF8.self))
            let songObject = try decoder.decode(SongObjectParent.self, from: urlResponseAndData.0)
            print("downloaded from internet successfully \(trackID) \(trackName)")
            saveCoreData()
            let lyricsArray = zip(songObject.lyrics.lyricsTimestamps, songObject.lyrics.lyricsWords).map { LyricLine(startTime: $0, words: $1) }
            
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
