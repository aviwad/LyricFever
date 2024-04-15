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
import MusicKit
import SwiftUI
import MediaPlayer

@MainActor class viewModel: ObservableObject {
    // View Model
    static let shared = viewModel()
    
    //
    var appleMusicStorePlaybackID: String? = nil
    @Published var currentlyPlaying: String?
    var currentlyPlayingName: String?
    @Published var currentlyPlayingLyrics: [LyricLine] = []
    @Published var currentlyPlayingLyricsIndex: Int?
    @Published var currentlyPlayingAppleMusicPersistentID: String? = nil
    @Published var isPlaying: Bool = false
    var spotifyScript: SpotifyApplication? = SBApplication(bundleIdentifier: "com.spotify.client")
    var appleMusicScript: MusicApplication? = SBApplication(bundleIdentifier: "com.apple.Music")
    
    // CoreData container (for saved lyrics)
    let coreDataContainer: NSPersistentContainer
    
    // Logging / Analytics
    let amplitude = Amplitude(configuration: .init(apiKey: amplitudeKey))
    
    // Sparkle / Update Controller
    let updaterController: SPUStandardUpdaterController
    @Published var canCheckForUpdates = false
    
    // Async Tasks (Lyrics fetch, Apple Music -> Spotify ID fetch, Lyrics Updater)
    private var currentFetchTask: Task<[LyricLine], Error>?
    private var currentLyricsUpdaterTask: Task<Void,Error>?
    private var currentAppleMusicFetchTask: Task<Void,Error>?
    
    let MRMediaRemoteGetNowPlayingInfo: @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    var status: MusicAuthorization.Status = .notDetermined
    
    // Authentication tokens
    var accessToken: accessTokenJSON?
    @AppStorage("spDcCookie") var cookie = ""
    let decoder = JSONDecoder()
    
    // Fake Spotify User Agent
    // Spotify's started blocking my app's useragent. A win honestly 🤣
    let fakeSpotifyUserAgentconfig = URLSessionConfiguration.default
    let fakeSpotifyUserAgentSession: URLSession
    
    @Published var mustUpdateUrgent: Bool = false
    
    init() {
        // Load framework
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

        // Get a Swift function for MRMediaRemoteGetNowPlayingInfo
        let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString)!
        MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: (@convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void).self)
        
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        coreDataContainer = NSPersistentContainer(name: "Lyrics")
        
        fakeSpotifyUserAgentconfig.httpAdditionalHeaders = ["User-Agent": "Spotify/121000760 Win32/0 (PC laptop)"]
        fakeSpotifyUserAgentSession = URLSession(configuration: fakeSpotifyUserAgentconfig)
        
        coreDataContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
            self.coreDataContainer.viewContext.mergePolicy = NSMergePolicy.overwrite
        }
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = coreDataContainer.viewContext
        Task {
            status = await MusicAuthorization.request()
            print(status)
        }
        Task {
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let url = URL(string: "https://raw.githubusercontent.com/aviwad/LyricFeverHomepage/master/urgentUpdateVersion.md")  {
                var request = URLRequest(url: url)
                let urlResponseAndData = try await URLSession(configuration: .ephemeral).data(for: request)
                print("Our version is \(version) and the latest is \(String(bytes:urlResponseAndData.0, encoding: .utf8))")
                if let internetUrgentVersionString = String(bytes:urlResponseAndData.0, encoding: .utf8), let internetUrgentVersion = Int(internetUrgentVersionString), let currentVersion = Int(version), currentVersion < internetUrgentVersion {
                    print("NOT EQUAL")
                    mustUpdateUrgent = true
                } else {
                    print("EQUAL")
                }
            }
        }
    }
    
    
    func upcomingIndex(_ currentTime: Double) -> Int? {
        if let currentlyPlayingLyricsIndex {
            let newIndex = currentlyPlayingLyricsIndex + 1
            if newIndex >= currentlyPlayingLyrics.count {
                print("REACHED LAST LYRIC!!!!!!!!")
                // if current time is before our current index's start time, the user has scrubbed and rewinded
                // reset into linear search mode
                if currentTime < currentlyPlayingLyrics[currentlyPlayingLyricsIndex].startTimeMS {
                    return currentlyPlayingLyrics.firstIndex(where: {$0.startTimeMS > currentTime})
                }
//                spotifyScript?.nextTrack?()
                // we've reached the end of the song, we're past the last lyric
                // so we set the timer till the duration of the song, in case the user skips ahead or forward
                currentlyPlayingAppleMusicPersistentID = nil
                currentlyPlaying = nil
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
            print("last index: \(lastIndex)")
            print("currently playing lryics index: \(currentlyPlayingLyricsIndex)")
            if currentlyPlayingLyrics.count > lastIndex {
                currentlyPlayingLyricsIndex = lastIndex
            } else {
                currentlyPlayingLyricsIndex = nil
            }
            print(currentlyPlayingLyricsIndex ?? "nil")
        } while !Task.isCancelled
    }
    
    func startLyricUpdater(appleMusicOrSpotify: Bool) {
        currentLyricsUpdaterTask?.cancel()
        if !isPlaying || currentlyPlayingLyrics.isEmpty {
            return
        }
        currentLyricsUpdaterTask = Task {
            do {
                try await appleMusicOrSpotify ? lyricUpdaterAppleMusic() : lyricUpdater()
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
                print("Saved CoreData!")
            } catch {
                print("core data error \(error)")
                // Show some error here
            }
        }
    }
    
    func fetch(for trackID: String, _ trackName: String, _ spotifyOrAppleMusic: Bool) async -> [LyricLine]? {
        currentFetchTask?.cancel()
        let newFetchTask = Task {
            try await self.fetchLyrics(for: trackID, trackName, spotifyOrAppleMusic)
        }
        currentFetchTask = newFetchTask
        do {
            return try await newFetchTask.value
        } catch {
            print("error \(error)")
            return nil
        }
    }
    
    private func fetchLyrics(for trackID: String, _ trackName: String, _ spotifyOrAppleMusic: Bool) async throws -> [LyricLine] {
        if let lyrics = fetchFromCoreData(for: trackID) {
            print("got lyrics from core data :D \(trackID) \(trackName)")
            try Task.checkCancellation()
            amplitude.track(eventType: "CoreData Fetch")
            return lyrics
        }
        print("no lyrics from core data, going to download from internet \(trackID) \(trackName)")
        return try await fetchNetworkLyrics(for: trackID, trackName, spotifyOrAppleMusic)
    }
    
    func fetchNetworkLyrics(for trackID: String, _ trackName: String, _ spotifyOrAppleMusic: Bool) async throws -> [LyricLine] {
        guard let intDuration = spotifyOrAppleMusic ? appleMusicScript?.currentTrack?.duration.map(Int.init) : spotifyScript?.currentTrack?.duration else {
            throw CancellationError()
        }
        decoder.userInfo[CodingUserInfoKey.trackID] = trackID
        decoder.userInfo[CodingUserInfoKey.trackName] = trackName
        decoder.userInfo[CodingUserInfoKey.duration] = spotifyOrAppleMusic ? TimeInterval((intDuration*1000) + 1000) : TimeInterval(intDuration+10)
        /*
         check if saved access token is bigger than current time, then continue with lyric fetch
         else
         check if we have spdc cookie, then access token stuff
            then save access token in this observable object
                then continue with lyric fetch
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
            
            let urlResponseAndData = try await fakeSpotifyUserAgentSession.data(for: request)
            print(urlResponseAndData)
            if urlResponseAndData.0.isEmpty {
                print("F")
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

// Apple Music Code
extension viewModel {
    // Similar structure to my other Async functions. Only 1 appleMusicFetch() can run at any given moment
    func appleMusicStarter() async {
        print("apple music test called again, cancelling previous")
        currentAppleMusicFetchTask?.cancel()
        let newFetchTask = Task {
            try await self.appleMusicFetch()
        }
        currentAppleMusicFetchTask = newFetchTask
        do {
            return try await newFetchTask.value
        } catch {
            print("error \(error)")
            return
        }
    }
    
    func appleMusicFetch() async throws {
        // check coredata for apple music persistent id -> spotify id mapping
        if let coreDataSpotifyID = fetchSpotifyIDFromPersistentIDCoreData() {
            if !Task.isCancelled {
                self.currentlyPlaying = coreDataSpotifyID
                return
            }
        }
        
        try await appleMusicNetworkFetch()
    }
    
    func appleMusicNetworkFetch() async throws {
        
        // coredata didn't get us anything
        
        // Get song info
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.global(), { (information) in
            self.appleMusicStorePlaybackID =  information["kMRMediaRemoteNowPlayingInfoContentItemIdentifier"] as? String
        })
        // check for musickit auth
        if status != .authorized || appleMusicStorePlaybackID == nil {
            print("not authorized (or we dont have playback id yet) , lets wait a bit")
            // A little delay to make sure we have musickit auth + storeplayback id by then (most likely)
            try await Task.sleep(nanoseconds: 100000000)
            if status != .authorized {
                print("still not authorized i give up")
            }
        }
        print("authorized")
        guard let appleMusicStorePlaybackID else {
            print("no playback store id, giving up")
            return
        }
        let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: .init(appleMusicStorePlaybackID))
        guard let response = try? await request.response(), let song = response.items.first, let isrc = song.isrc else { return }
        print("playback ID is \(appleMusicStorePlaybackID) and ISRC is \(isrc)")
        if accessToken == nil || (accessToken!.accessTokenExpirationTimestampMs <= Date().timeIntervalSince1970*1000) {
            print("creating new access token from apple music, if this appears multiple times thats suspicious")
            if let url = URL(string: "https://open.spotify.com/get_access_token?reason=transport&productType=web_player") {
                var request = URLRequest(url: url)
                request.setValue("sp_dc=\(cookie)", forHTTPHeaderField: "Cookie")
                let accessTokenData = try await URLSession.shared.data(for: request)
                accessToken = try JSONDecoder().decode(accessTokenJSON.self, from: accessTokenData.0)
                print("ACCESS TOKEN IS SAVED")
            }
        }
        let spotifyID = try await musicToSpotifyHelper(accessToken: accessToken, isrc: isrc)
        // Task cancelled means we're working with old song data, so dont update Spotify ID with old song's ID
        if !Task.isCancelled {
            self.currentlyPlaying = spotifyID
            
            if let currentlyPlayingAppleMusicPersistentID, let currentlyPlaying {
                print("both persistent ID and spotify ID are non nill, so we attempt to save to coredata")
                // save the mapping into coredata persistentIDToSpotify
                let newPersistentIDToSpotifyIDMapping = PersistentIDToSpotify(context: coreDataContainer.viewContext)
                newPersistentIDToSpotifyIDMapping.persistentID = currentlyPlayingAppleMusicPersistentID
                newPersistentIDToSpotifyIDMapping.spotifyID = currentlyPlaying
                saveCoreData()
            }
        }
        // get equivalent spotify ID
    }
    
    func fetchSpotifyIDFromPersistentIDCoreData() -> String? {
        let fetchRequest: NSFetchRequest<PersistentIDToSpotify> = PersistentIDToSpotify.fetchRequest()
        guard let currentlyPlayingAppleMusicPersistentID else {
            print("No persistent ID available. it's nil! should have never happened")
            return nil
        }
        fetchRequest.predicate = NSPredicate(format: "persistentID == %@", currentlyPlayingAppleMusicPersistentID) // Replace persistentID with the desired value

        do {
            let results = try coreDataContainer.viewContext.fetch(fetchRequest)
            if let persistentIDToSpotify = results.first {
                // Found the persistentIDToSpotify object with the matching persistentID
                return persistentIDToSpotify.spotifyID
            } else {
                // No SongObject found with the given trackID
                print("No spotifyID found with the provided persistentID. \(currentlyPlayingAppleMusicPersistentID)")
            }
        } catch {
            print("Error fetching persistentIDToSpotify:", error)
        }
        return nil
    }
    
    func lyricUpdaterAppleMusic() async throws {
        repeat {
            guard let playerPosition = appleMusicScript?.playerPosition else {
                print("no player position hence stopped")
                // pauses the timer bc there's no player position
                stopLyricUpdater()
                return
            }
            // add a 700 (milisecond?) delay to offset the delta between spotify lyrics and apple music songs (or maybe the way apple music delivers playback position)
            let currentTime = playerPosition * 1000 + 400
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
            print("last index: \(lastIndex)")
            print("currently playing lryics index: \(currentlyPlayingLyricsIndex)")
            if currentlyPlayingLyrics.count > lastIndex {
                currentlyPlayingLyricsIndex = lastIndex
            } else {
                currentlyPlayingLyricsIndex = nil
            }
            print("current lyrics index is now \(currentlyPlayingLyricsIndex?.description ?? "nil")")
        } while !Task.isCancelled
    }
    
    private func musicToSpotifyHelper(accessToken: accessTokenJSON?, isrc: String) async throws -> String? {
        if let accessToken {
            // Attempt to find Spotify ID using ISRC
            if let url = URL(string: "https://api.spotify.com/v1/search?q=isrc:\(isrc)&type=track&limit=1") {
                var request = URLRequest(url: url)
                request.addValue("WebPlayer", forHTTPHeaderField: "app-platform")
                print("the access token is \(accessToken.accessToken)")
                request.addValue("Bearer \(accessToken.accessToken)", forHTTPHeaderField: "authorization")
                // Invalidate this request if cancelled (means this song is old, user rapidly skipped)
                guard !Task.isCancelled else {return nil}
                let urlResponseAndData = try await URLSession.shared.data(for: request)
                if urlResponseAndData.0.isEmpty {
                    return nil
                }
                let response = try decoder.decode(SpotifyResponse.self, from: urlResponseAndData.0)
                if let spotifyID = response.tracks.items.first?.id {
                    return spotifyID
                }
            }
            // Manually search song name, artist name
            else {
                if let artist = self.appleMusicScript?.currentTrack?.artist, let track = self.currentlyPlayingName, let url = URL(string: "https://api.spotify.com/v1/search?q=track:\(track)+artist:\(artist)+&type=track&limit=1") {
                    var request = URLRequest(url: url)
                    request.addValue("WebPlayer", forHTTPHeaderField: "app-platform")
                    request.addValue("Bearer \(accessToken.accessToken)", forHTTPHeaderField: "authorization")
                    guard !Task.isCancelled else {return nil}
                    if let searchData = try? await URLSession.shared.data(for: request), !searchData.0.isEmpty, let searchResponse = try? self.decoder.decode(SpotifyResponse.self, from: searchData.0), let firstItem = searchResponse.tracks.items.first {
                        print("GOT ID SEARCHING WITH TRACK AND ARTIST")
                        return firstItem.id
                    }
                    
                    
                }
                
            }
        }
        return nil
    }
}
