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
import WebKit
import UniformTypeIdentifiers
import SwiftOTP
import NaturalLanguage

@MainActor class viewModel: ObservableObject {
    // View Model
    static let shared = viewModel()
    
    // Karaoke Font
    @Published var karaokeFont: NSFont
    
    // nil to deal with previously saved songs that don't have lang saved with them
    // or for LRCLIB
    @Published var currentBackground: Color? = nil
    @Published var fullscreenInProgress = true
    var appleMusicStorePlaybackID: String? = nil
    @Published var currentlyPlaying: String?
    
    var animatedDisplay: Bool {
        get {
            displayKaraoke || fullscreen
        }
        set {
            
        }
    }
    
    var displayKaraoke: Bool {
        get {
            showLyrics && isPlaying && karaoke && !karaokeModeHovering && (currentlyPlayingLyricsIndex != nil)
        }
        set {
            
        }
    }
    var displayFullscreen: Bool {
        get {
            fullscreen
        }
        set {
            if fullscreen {
                NSApp.windows.first {$0.identifier?.rawValue == "fullscreen"}?.makeKeyAndOrderFront(self)
                NSApplication.shared.activate(ignoringOtherApps: true)
            } else {
                fullscreen = true
                NSApp.setActivationPolicy(.regular)
            }
        }
    }
    var currentlyPlayingName: String?
    var currentlyPlayingArtist: String?
    @Published var currentlyPlayingLyrics: [LyricLine] = []
    @Published var currentlyPlayingLyricsIndex: Int?
    @Published var currentlyPlayingAppleMusicPersistentID: String? = nil
    @Published var isPlaying: Bool = false
    @AppStorage("translate") var translate = false
    @AppStorage("romanize") var romanize = false
    @AppStorage("hasMigrated") var hasMigrated = false
    @Published var translatedLyric: [String] = []
    @Published var showLyrics = true
    @AppStorage("showSongDetailsInMenubar") var showSongDetailsInMenubar = true
    @Published var fullscreen = false
    @AppStorage("karaoke") var karaoke = false
    @Published var spotifyConnectDelay: Bool = false
    var translateAndExists: Bool { translate && !translatedLyric.isEmpty}
    @AppStorage("spotifyConnectDelayCount") var spotifyConnectDelayCount: Int = 400
    var spotifyScript: SpotifyApplication? = SBApplication(bundleIdentifier: "com.spotify.client")
    var appleMusicScript: MusicApplication? = SBApplication(bundleIdentifier: "com.apple.Music")
    
    // CoreData container (for saved lyrics)
    let coreDataContainer: NSPersistentContainer
    
    // Logging / Analytics
    let amplitude = Amplitude(configuration: .init(apiKey: amplitudeKey))
    
    // Sparkle / Update Controller
    let updaterController: SPUStandardUpdaterController
    
    // Async Tasks (Lyrics fetch, Apple Music -> Spotify ID fetch, Lyrics Updater)
    private var currentFetchTask: Task<[LyricLine], Error>?
    private var currentLyricsUpdaterTask: Task<Void,Error>?
    private var currentLyricsDriftFix: Task<Void,Error>?
    private var currentAppleMusicFetchTask: Task<Void,Error>?
    
    // Apple Music APIs
    // Private API to get track ID
    let MRMediaRemoteGetNowPlayingInfo: @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    // Official MusicKit API Auth status to
    var status: MusicAuthorization.Status = .notDetermined
    
    // Authentication tokens
    var accessToken: accessTokenJSON?
    @AppStorage("spDcCookie") var cookie = ""
    let decoder = JSONDecoder()
    
    // Fake Spotify User Agent
    // Spotify's started blocking my app's useragent. A win honestly 🤣
    let fakeSpotifyUserAgentconfig = URLSessionConfiguration.default
    let fakeSpotifyUserAgentSession: URLSession
    
    // LRCLIB User Agent
    let LRCLIBUserAgentConfig = URLSessionConfiguration.default
    let LRCLIBUserAgentSession: URLSession
    
    // Songs are translated to user locale
    let userLocaleLanguage: Locale
    let userLocaleLanguageString: String
    
    // Override menubar with an update message
    @Published var mustUpdateUrgent: Bool = false
    
    // Delayed variable to hook onto for fullscreen (whether to display lyrics or not)
    // Prevents flickering that occurs when we directly bind to currentlyPlayingLyrics.isEmpty()
    @Published var lyricsIsEmptyPostLoad: Bool = true
    
    // User setting: hide karaoke on hover
    @AppStorage("karaokeModeHoveringSetting") var karaokeModeHoveringSetting: Bool = false
    
    // UI element used to hide if karaokeModeHoveringSetting is true
    @Published var karaokeModeHovering: Bool = false
    
    // User setting: use album art color or user-set currentBackground
    @AppStorage("karaokeUseAlbumColor") var karaokeUseAlbumColor: Bool = true
    @AppStorage("karaokeShowMultilingual") var karaokeShowMultilingual: Bool = true
    @AppStorage("karaokeTransparency") var karaokeTransparency: Double = 50
    @AppStorage("fixedKaraokeColorHex") var fixedKaraokeColorHex: String = "#2D3CCC"
    var colorBinding: Binding<Color> {
        Binding<Color> {
            Color(NSColor(hexString: self.fixedKaraokeColorHex)!)
        } set: { newValue in
            self.fixedKaraokeColorHex = NSColor(newValue).hexString!
        }
    }

    
    init() {
        // Load Apple Music private api framework
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))
        let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString)!
        MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: (@convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void).self)
        
        // Setup Sparkle updater service
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    
        
        // Set user agents for Spotify and LRCLIB
        fakeSpotifyUserAgentconfig.httpAdditionalHeaders = ["User-Agent": "Spotify/121000760 Win32/0 (PC laptop)"]
        fakeSpotifyUserAgentSession = URLSession(configuration: fakeSpotifyUserAgentconfig)
        LRCLIBUserAgentConfig.httpAdditionalHeaders = ["User-Agent": "Lyric Fever v2.1 (https://github.com/aviwad/LyricFever)"]
        LRCLIBUserAgentSession = URLSession(configuration: LRCLIBUserAgentConfig)
        
        // Set our user locale for translation language
        userLocaleLanguage = Locale.preferredLocale()
        userLocaleLanguageString = Locale.preferredLocaleString() ?? ""
        
        // Generate user-saved font and load it
        let karaokeFontSize: Double = UserDefaults.standard.double(forKey: "karaokeFontSize")
        let karaokeFontName: String? = UserDefaults.standard.string(forKey: "karaokeFontName")
        if let karaokeFontName, karaokeFontSize != 0, let ourKaraokeFont = NSFont(name: karaokeFontName, size: karaokeFontSize) {
            karaokeFont = ourKaraokeFont
        } else {
            karaokeFont = NSFont.boldSystemFont(ofSize: 30)
        }
        
        // Load our CoreData container for Lyrics
        coreDataContainer = NSPersistentContainer(name: "Lyrics")
        coreDataContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
            self.coreDataContainer.viewContext.mergePolicy = NSMergePolicy.overwrite
        }
        decoder.userInfo[CodingUserInfoKey.managedObjectContext] = coreDataContainer.viewContext
        migrateTimestampsIfNeeded(context: coreDataContainer.viewContext)
        
        // Check if user must urgently update (overrides menubar)
        Task {
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let url = URL(string: "https://raw.githubusercontent.com/aviwad/LyricFeverHomepage/master/urgentUpdateVersion.md")  {
                let request = URLRequest(url: url)
                let urlResponseAndData = try await URLSession(configuration: .ephemeral).data(for: request)
                if let internetUrgentVersionString = String(bytes:urlResponseAndData.0, encoding: .utf8), let internetUrgentVersion = Double(internetUrgentVersionString), let currentVersion = Double(version) {
                    print("current version is \(currentVersion), internet urgent version is \(internetUrgentVersion)")
                    if currentVersion < internetUrgentVersion {
                     print("NOT EQUAL")
                     mustUpdateUrgent = true
                 } else {
                     print("EQUAL")
                 }
                }
            }
        }
    }
    
    // Run only on first 2.1 run. Strips whitespace from saved lyrics, and extends final timestamp to prevent karaoke mode racecondition (as well as song on loop race condition)
    func migrateTimestampsIfNeeded(context: NSManagedObjectContext) {
        if !hasMigrated {
            let fetchRequest: NSFetchRequest<SongObject> = SongObject.fetchRequest()
            do {
                let objects = try context.fetch(fetchRequest)
//                for object in objects {
//                    if object.lyricsWords.count != object.lyricsTimestamps.count {
//                        context.delete(object)
//                    }
//                }
//                do {
//                    try context.save() // Persist the deletions
//                } catch {
//                    print("Error saving after deletion: \(error)")
//                }
                for object in objects {
                    var timestamps = object.lyricsTimestamps
                    if let lastIndex = timestamps.indices.last {
                        timestamps[lastIndex] = timestamps[lastIndex] + 5000
                        object.lyricsTimestamps = timestamps
                    }
                    var strings = object.lyricsWords
                    let indicesToRemove = strings.indices.filter { strings[$0].isEmpty }
                    strings.removeAll { $0.isEmpty }
                    for index in indicesToRemove.reversed() {
                        timestamps.remove(at: index)
                    }

                    // Update the object properties
                    object.lyricsWords = strings
                    object.lyricsTimestamps = timestamps
                }
                try context.save()
                
                // Mark migration as done
                hasMigrated = true
            } catch {
                print("Error migrating data: \(error)")
            }
        }
    }
    
    // Runs once user has completed Spotify log-in. Attempt to extract cookie
    func checkIfLoggedIn() {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            if let temporaryCookie = cookies.first(where: {$0.name == "sp_dc"}) {
                print("found the sp_dc cookie")
                self.cookie = temporaryCookie.value
                NotificationCenter.default.post(name: Notification.Name("didLogIn"), object: nil)
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
                // we've reached the end of the song, we're past the last lyric
                //TODO: remove these
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
    
    
    // A little hack to fix Spotify's playbackPosition() drift on songs autoplaying
    // Why the async 1 second delay? Because Spotify ignores the play command if it's lesser than a second away from another play command
    // Harmless and fixes the sync
    func fixSpotifyLyricDrift() async throws {
        try await Task.sleep(nanoseconds: 2000000000)
        if isPlaying {
            print("LYRIC UPDATER'S LYRIC DRIFT FIX CALLED")
            spotifyScript?.play?()
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
            let currentTime = playerPosition * 1000 + (spotifyConnectDelay ? Double(spotifyConnectDelayCount) : 0) + (animatedDisplay ? 400 : 0)
            guard let lastIndex: Int = upcomingIndex(currentTime) else {
                stopLyricUpdater()
                return
            }
            // If there is no current index (perhaps lyric updater started late and we're mid-way of the first lyric, or the user scrubbed and our index is expired)
            // Then we set the current index to the one before our anticipated index
            if currentlyPlayingLyricsIndex == nil && lastIndex > 0 {
                withAnimation {
                    currentlyPlayingLyricsIndex = lastIndex-1
                }
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
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentlyPlayingLyricsIndex = lastIndex
                }
            } else {
                currentlyPlayingLyricsIndex = nil
                
            }
            print(currentlyPlayingLyricsIndex ?? "nil")
        } while !Task.isCancelled
    }
    
    func startLyricUpdater(appleMusicOrSpotify: Bool) {
        currentLyricsUpdaterTask?.cancel()
        if !isPlaying || currentlyPlayingLyrics.isEmpty || mustUpdateUrgent {
            return
        }
        // If an index exists, we're unpausing: meaning we must instantly find the current lyric
        if currentlyPlayingLyricsIndex != nil {
            if appleMusicOrSpotify {
                guard let playerPosition = appleMusicScript?.playerPosition else {
                    print("no player position hence stopped")
                    // pauses the timer bc there's no player position
                    stopLyricUpdater()
                    return
                }
                // add a 700 (milisecond?) delay to offset the delta between spotify lyrics and apple music songs (or maybe the way apple music delivers playback position)
                // No need for Spotify Connect delay or fullscreen, this is APPLE MUSIC
                let currentTime = playerPosition * 1000 + 400
                guard let lastIndex: Int = upcomingIndex(currentTime) else {
                    stopLyricUpdater()
                    return
                }
                // If there is no current index (perhaps lyric updater started late and we're mid-way of the first lyric, or the user scrubbed and our index is expired)
                // Then we set the current index to the one before our anticipated index
                if lastIndex > 0 {
                    withAnimation {
                        currentlyPlayingLyricsIndex = lastIndex-1
                    }
                }
            } else {
                guard let playerPosition = spotifyScript?.playerPosition else {
                    print("no player position hence stopped")
                    // pauses the timer bc there's no player position
                    stopLyricUpdater()
                    return
                }
                let currentTime = playerPosition * 1000 + (spotifyConnectDelay ? Double(spotifyConnectDelayCount) : 0) + (animatedDisplay ? 400 : 0)
                guard let lastIndex: Int = upcomingIndex(currentTime) else {
                    stopLyricUpdater()
                    return
                }
                // If there is no current index (perhaps lyric updater started late and we're mid-way of the first lyric, or the user scrubbed and our index is expired)
                // Then we set the current index to the one before our anticipated index
                if lastIndex > 0 {
                    withAnimation {
                        currentlyPlayingLyricsIndex = lastIndex-1
                    }
                }
            }
        } else if !appleMusicOrSpotify {
            currentLyricsDriftFix?.cancel()
            currentLyricsDriftFix =             // Only run drift fix for new songs
            Task {
                try await fixSpotifyLyricDrift()
            }
            Task {
                try await currentLyricsDriftFix?.value
            }
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
    
    func intToRGB(_ value: Int32) -> Color {//(red: Int, green: Int, blue: Int) {
        // Convert negative numbers to an unsigned 32-bit representation
        let unsignedValue = UInt32(bitPattern: value)
        
        // Extract RGB components
        let red = Double((unsignedValue >> 16) & 0xFF)
        let green = Double((unsignedValue >> 8) & 0xFF)
        let blue = Double(unsignedValue & 0xFF)
        return Color(red: red/255, green: green/255, blue: blue/255) //(red, green, blue)
    }
    
    func fetchBackgroundColor() {
        guard let currentlyPlaying else {
            return
        }
        let fetchRequest: NSFetchRequest<IDToColor> = IDToColor.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", currentlyPlaying) // Replace trackID with the desired value

        do {
            let results = try coreDataContainer.viewContext.fetch(fetchRequest)
            if let idToColor = results.first {
                self.currentBackground = intToRGB(idToColor.songColor)
            } else {
                self.currentBackground = nil
            }
        } catch {
            print("Error fetching SongObject:", error)
        }
//        return nil
    }
    
    @MainActor
    func selectLRC() async -> URL? {
        defer {
            NSApp.setActivationPolicy(.accessory)
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        let folderChooserPoint = CGPoint(x: 0, y: 0)
        let folderChooserSize = CGSize(width: 500, height: 600)
        let folderChooserRectangle = CGRect(origin: folderChooserPoint, size: folderChooserSize)
        NSApp.setActivationPolicy(.regular)
        let folderPicker =  NSOpenPanel(contentRect: folderChooserRectangle, styleMask: .resizable, backing: .buffered, defer: true)
        folderPicker.title = "Select an LRC File for \(currentlyPlayingName ?? "")"
        let lrcType = UTType(filenameExtension: "lrc")!
        folderPicker.allowedContentTypes = [lrcType] // Only allow .lrc files
        folderPicker.allowsMultipleSelection = false // Only allow a single selection
        folderPicker.canChooseFiles = true // Allow file selection
        folderPicker.canChooseDirectories = false // Disallow directory selection
        let response = await folderPicker.begin()
        if response == .OK {
            return folderPicker.url
        }
        return nil
    }
    
    func findMbid(albumName: String, artistName: String) async -> String? {
//        https://musicbrainz.org/ws/2/release/?query=artist:charli%20xcx%20AND%20album:super%20ultra&fmt=json
        if let mbidUrl = URL(string: "https://musicbrainz.org/ws/2/release/?query=artist:\(artistName) AND album:\(albumName)&fmt=json"), let mbidData = try? await URLSession.shared.data(from: mbidUrl), let mbidResponse = try? decoder.decode(MusicBrainzReply.self, from: mbidData.0), let mbid = mbidResponse.releases.first?.id {
            print(mbid)
            return mbid
        }
        
        return nil
    }
    
    func mbidAlbumArt(_ mbid: String) -> URL? {
        return URL(string:"https://coverartarchive.org/release/\(mbid)/front")
    }

    
    func localFetch(for trackID: String, _ trackName: String, _ spotifyOrAppleMusic: Bool) async throws -> [LyricLine] {
        guard let intDuration = spotifyOrAppleMusic ? appleMusicScript?.currentTrack?.duration.map(Int.init) : spotifyScript?.currentTrack?.duration else {
            throw CancellationError()
        }
        if let fileUrl = await selectLRC(), let lyricText = try? String(contentsOf: fileUrl, encoding: .utf8) {
            let parser = LyricsParser(lyrics: lyricText)
            print(parser.lyrics)
            if !parser.lyrics.isEmpty {
                _ = SongObject(from: parser.lyrics, with: coreDataContainer.viewContext, trackID: trackID, trackName: trackName, duration: TimeInterval(intDuration+1000))
                saveCoreData()
                if spotifyOrAppleMusic {
                    if let artwork = (appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data {
                        SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: artwork.findAverageColor())
                    } else if let artistName = currentlyPlayingArtist, let albumName = appleMusicScript?.currentTrack?.album,  let mbid = await findMbid(albumName: albumName, artistName: artistName), let artworkUrl = mbidAlbumArt(mbid), let imageData = try? await URLSession.shared.data(from: artworkUrl), let image = NSImage(data: imageData.0) {
                        SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: image.findAverageColor())
                    }
                } else {
                    if let artworkUrlString = spotifyScript?.currentTrack?.artworkUrl, let artworkUrl = URL(string: artworkUrlString), let imageData = try? await URLSession.shared.data(from: artworkUrl), let image = NSImage(data: imageData.0) {
                        SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: image.findAverageColor())
                    } else if let artistName = currentlyPlayingArtist, let albumName = spotifyScript?.currentTrack?.album,  let mbid = await findMbid(albumName: albumName, artistName: artistName), let artworkUrl = mbidAlbumArt(mbid), let imageData = try? await URLSession.shared.data(from: artworkUrl), let image = NSImage(data: imageData.0) {
                        SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: image.findAverageColor())
                    }
                }
//                if let artworkUrlString = spotifyScript?.currentTrack?.artworkUrl, let artworkUrl = URL(string: artworkUrlString), let imageData = try? await URLSession.shared.data(from: artworkUrl), let image = NSImage(data: imageData.0) {
//                    // Just instantiates a SpotifyColorData class to save it to CoreData haha....
//                    SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: image.findAverageColor())
//                } else if let artistName = currentlyPlayingArtist, let albumName = spotifyScript?.currentTrack?.album,  let mbid = await findMbid(albumName: albumName, artistName: artistName), let artworkUrl = mbidAlbumArt(mbid), let imageData = try? await URLSession.shared.data(from: artworkUrl), let image = NSImage(data: imageData.0) {
//                    // Just instantiates a SpotifyColorData class to save it to CoreData haha....
//                    SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: image.findAverageColor())
//                }
            }
            try Task.checkCancellation()
            return parser.lyrics
        }
        try Task.checkCancellation()
        return []
    }
    
    func fetchLyrics(for trackID: String, _ trackName: String, _ spotifyOrAppleMusic: Bool) async throws -> [LyricLine] {
        if let lyrics = fetchFromCoreData(for: trackID) {
            print("got lyrics from core data :D \(trackID) \(trackName)")
            try Task.checkCancellation()
            amplitude.track(eventType: "CoreData Fetch")
            return lyrics
        }
        print("no lyrics from core data, going to download from internet \(trackID) \(trackName)")
        return try await fetchNetworkLyrics(for: trackID, trackName, spotifyOrAppleMusic)
    }
    
    // Thanks to Mx-lris
    enum TOTPGenerator {
         static func generate(serverTimeSeconds: Int) -> String? {
             let secretCipher = [12, 56, 76, 33, 88, 44, 88, 33, 78, 78, 11, 66, 22, 22, 55, 69, 54]
     
             var processed = [UInt8]()
             for (i, byte) in secretCipher.enumerated() {
                 processed.append(UInt8(byte ^ (i % 33 + 9)))
             }
     
             let processedStr = processed.map { String($0) }.joined()
     
             guard let utf8Bytes = processedStr.data(using: .utf8) else {
                 return nil
             }
     
             let secretBase32 = utf8Bytes.base32EncodedString
     
             guard let secretData = base32DecodeToData(secretBase32) else {
                 return nil
             }
     
             guard let totp = TOTP(secret: secretData, digits: 6, timeInterval: 30, algorithm: .sha1) else {
                 return nil
             }
     
             return totp.generate(secondsPast1970: serverTimeSeconds)
         }
     }
    
    func generateAccessToken() async throws {
        
        // NEW: generate TOTP
        // Thanks to Mxlris-LyricsX-Project
        
        /*
         check if saved access token is bigger than current time, then continue with lyric fetch
         else
         check if we have spdc cookie, then access token stuff
            then save access token in this observable object
                then continue with lyric fetch
         otherwise []
         */
        
        if accessToken == nil || (accessToken!.accessTokenExpirationTimestampMs <= Date().timeIntervalSince1970*1000) {
            repeat {
                let serverTimeRequest = URLRequest(url: .init(string: "https://open.spotify.com/server-time")!)
                let serverTimeData = try await fakeSpotifyUserAgentSession.data(for: serverTimeRequest).0
                let serverTime = try JSONDecoder().decode(SpotifyServerTime.self, from: serverTimeData).serverTime
                if let totp = TOTPGenerator.generate(serverTimeSeconds: serverTime), let url = URL(string: "https://open.spotify.com/get_access_token?reason=transport&productType=web_player&totpVer=5&ts=\(Int(Date().timeIntervalSince1970))&totp=\(totp)"), cookie != "" {
                    var request = URLRequest(url: url)
                    request.setValue("sp_dc=\(cookie)", forHTTPHeaderField: "Cookie")
                    let accessTokenData = try await fakeSpotifyUserAgentSession.data(for: request)
                    print(String(decoding: accessTokenData.0, as: UTF8.self))
                    do {
                        accessToken = try JSONDecoder().decode(accessTokenJSON.self, from: accessTokenData.0)
                        print("ACCESS TOKEN IS SAVED")
                    } catch {
                        do {
                            let errorWrap = try JSONDecoder().decode(ErrorWrapper.self, from: accessTokenData.0)
                            if errorWrap.error.code == 401 {
                                UserDefaults().set(false, forKey: "hasOnboarded")
                            }
                        } catch {
                            // silently fail
                        }
                        print("json error decoding the access token, therefore bad cookie therefore un-onboard")
                    }
                    
                }
            } while accessToken?.accessToken.range(of: "[-_]", options: .regularExpression) == nil
        }
    }
    
    func fetchNetworkLyrics(for trackID: String, _ trackName: String, _ spotifyOrAppleMusic: Bool) async throws -> [LyricLine] {
        guard let intDuration = spotifyOrAppleMusic ? appleMusicScript?.currentTrack?.duration.map(Int.init) : spotifyScript?.currentTrack?.duration else {
            throw CancellationError()
        }
        decoder.userInfo[CodingUserInfoKey.trackID] = trackID
        decoder.userInfo[CodingUserInfoKey.trackName] = trackName
        decoder.userInfo[CodingUserInfoKey.duration] = spotifyOrAppleMusic ? TimeInterval((intDuration*1000) + 1000) : TimeInterval(intDuration+10)
        
        // Local file giveaway
        if trackID.count != 22 {
            let lrc = (try? await fetchLRCLIBNetworkLyrics( trackName: trackName, spotifyOrAppleMusic: spotifyOrAppleMusic, trackID: trackID)) ?? []
            if lrc == [] {
                let netease = (try? await fetchNetEaseLyrics( trackName: trackName, spotifyOrAppleMusic: spotifyOrAppleMusic, trackID: trackID)) ?? []
                try Task.checkCancellation()
                return netease
            } else {
                try Task.checkCancellation()
                return lrc
            }
        }
        
        try await generateAccessToken()
        if let accessToken, let url = URL(string: "https://spclient.wg.spotify.com/color-lyrics/v2/track/\(trackID)?format=json&vocalRemoval=false") {
            var request = URLRequest(url: url)
            request.addValue("WebPlayer", forHTTPHeaderField: "app-platform")
            print("the access token is \(accessToken.accessToken)")
            request.addValue("Bearer \(accessToken.accessToken)", forHTTPHeaderField: "authorization")
            print("Requesting Spotify lyric data")
            try Task.checkCancellation()
            let urlResponseAndData = try await fakeSpotifyUserAgentSession.data(for: request)
            
            // Song lyrics don't exist on Spotify
            if urlResponseAndData.0.isEmpty {
                print("Empty Response from Spotify: Either the song lyrics don't exist or the access token is faulty.")
                try Task.checkCancellation()
                let lrc = (try? await fetchLRCLIBNetworkLyrics( trackName: trackName, spotifyOrAppleMusic: spotifyOrAppleMusic, trackID: trackID)) ?? []
                if lrc == [] {
                    try Task.checkCancellation()
                    let netease = (try? await fetchNetEaseLyrics( trackName: trackName, spotifyOrAppleMusic: spotifyOrAppleMusic, trackID: trackID)) ?? []
                    try Task.checkCancellation()
                    return netease
                } else {
                    try Task.checkCancellation()
                    return lrc
                }
            }
            print(String(decoding: urlResponseAndData.0, as: UTF8.self))
            if String(decoding: urlResponseAndData.0, as: UTF8.self) == "too many requests" {
                try Task.checkCancellation()
                let lrc = (try? await fetchLRCLIBNetworkLyrics( trackName: trackName, spotifyOrAppleMusic: spotifyOrAppleMusic, trackID: trackID)) ?? []
                if lrc == [] {
                    let netease = (try? await fetchNetEaseLyrics( trackName: trackName, spotifyOrAppleMusic: spotifyOrAppleMusic, trackID: trackID)) ?? []
                    try Task.checkCancellation()
                    return netease
                } else {
                    try Task.checkCancellation()
                    return lrc
                }
            }
            let songObject = try decoder.decode(SongObjectParent.self, from: urlResponseAndData.0)
            if !songObject.lyrics.lyricsTimestamps.isEmpty {
                print("downloaded from Spotify successfully \(trackID) \(trackName)")
                saveCoreData()
                let lyricsArray = zip(songObject.lyrics.lyricsTimestamps, songObject.lyrics.lyricsWords).map { LyricLine(startTime: $0, words: $1) }
                
                try Task.checkCancellation()
                amplitude.track(eventType: "Network Fetch")
                return lyricsArray
            } else {
                print("F (no time synced lyrics)")
                try Task.checkCancellation()
                let lrc = (try? await fetchLRCLIBNetworkLyrics( trackName: trackName, spotifyOrAppleMusic: spotifyOrAppleMusic, trackID: trackID)) ?? []
                if lrc == [] {
                    let netease = (try? await fetchNetEaseLyrics( trackName: trackName, spotifyOrAppleMusic: spotifyOrAppleMusic, trackID: trackID)) ?? []
                    try Task.checkCancellation()
                    return netease
                } else {
                    try Task.checkCancellation()
                    return lrc
                }
            }
        }
        return []
    }
    
    func fetchNetEaseLyrics(trackName: String, spotifyOrAppleMusic: Bool, trackID: String) async throws -> [LyricLine] {
//        let artistEncoded = currentlyPlayingArtist?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: "&", with: "%26")
        let album = spotifyOrAppleMusic ? appleMusicScript?.currentTrack?.album : spotifyScript?.currentTrack?.album
        let albumEncoded = album?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: "&", with: "%26")
//        let trackNameEncoded = trackName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: "&", with: "%26")
//        guard let intDuration = spotifyOrAppleMusic ? appleMusicScript?.currentTrack?.duration.map(Int.init) : spotifyScript?.currentTrack?.duration else {
//            throw CancellationError()
//        }
        // fetch lrc lyrics
//        if let artist, let album, let url = URL(string: "https://lrclib.net/api/get?artist_name=\(artist)&track_name=\(trackName)&album_name=\(album)&duration=\(spotifyOrAppleMusic ? intDuration : intDuration / 1000)") {
        
        if let currentlyPlayingArtist, let album, let url = URL(string: "https://neteasecloudmusicapi-ten-wine.vercel.app/search?keywords=\(trackName.replacingOccurrences(of: "&", with: "%26")) \(album) \(currentlyPlayingArtist.replacingOccurrences(of: "&", with: "%26"))&limit=1") {
            print("the netease search call is \(url.absoluteString)")
            let request = URLRequest(url: url)
            let urlResponseAndData = try await fakeSpotifyUserAgentSession.data(for: request)
            let neteasesearch = try decoder.decode(NetEaseSearch.self, from: urlResponseAndData.0)
            print(neteasesearch)
            guard let neteaseId = neteasesearch.result.songs.first?.id else {
                return []
            }
            print("Similarity index: for track \(trackName) and netease reply \(neteasesearch.result.songs.first?.name) is ")
//            print("Similarity index: for album \(album) and netease reply \(neteasesearch.result.songs.first?.album.name) is ")
            print("Similarity index: for artist \(currentlyPlayingArtist) and netease reply \(neteasesearch.result.songs.first?.artists.first?.name) is ")
            let lyricRequest = URLRequest(url: URL(string: "https://neteasecloudmusicapi-ten-wine.vercel.app/lyric?id=\(neteaseId)")!)
            let urlResponseAndDataLyrics = try await fakeSpotifyUserAgentSession.data(for: lyricRequest)
            let neteaseLyrics = try decoder.decode(NetEaseLyrics.self, from: urlResponseAndDataLyrics.0)
            guard let neteaselrc = neteaseLyrics.lrc, let neteaseLrcString = neteaselrc.lyric else {
                return []
            }
            let parser = LyricsParser(lyrics: neteaseLrcString)
            print(parser.lyrics)
            // NetEase incorrectly advertises lyrics for EVERY song when it only has the name, artist, composer at 0.0 *sigh*
            if parser.lyrics.last?.startTimeMS == 0.0 {
                return []
            }
            let songObject = SongObject(from: parser.lyrics, with: coreDataContainer.viewContext, trackID: trackID, trackName: trackName, duration: decoder.userInfo[CodingUserInfoKey.duration] as! TimeInterval)
            saveCoreData()
            amplitude.track(eventType: "NetEase Fetch")
            if spotifyOrAppleMusic {
                if let artwork = (appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data {
                    SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: artwork.findAverageColor())
                } else if let albumName = appleMusicScript?.currentTrack?.album,  let mbid = await findMbid(albumName: albumName, artistName: currentlyPlayingArtist), let artworkUrl = mbidAlbumArt(mbid), let imageData = try? await URLSession.shared.data(from: artworkUrl), let image = NSImage(data: imageData.0) {
                    SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: image.findAverageColor())
                }
            } else {
                if let artworkUrlString = spotifyScript?.currentTrack?.artworkUrl, let artworkUrl = URL(string: artworkUrlString), let imageData = try? await URLSession.shared.data(from: artworkUrl), let image = NSImage(data: imageData.0) {
                    SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: image.findAverageColor())
                } else if let albumName = spotifyScript?.currentTrack?.album,  let mbid = await findMbid(albumName: albumName, artistName: currentlyPlayingArtist), let artworkUrl = mbidAlbumArt(mbid), let imageData = try? await URLSession.shared.data(from: artworkUrl), let image = NSImage(data: imageData.0) {
                    SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: image.findAverageColor())
                }
            }
            try Task.checkCancellation()
            return parser.lyrics
        }
        // and then custom spotify album call to get the color for karaoke mode
        
        // check if not cancelled
        // save SongObject and IDToColor
        
        return []
    }
    
    func fetchLRCLIBNetworkLyrics(trackName: String, spotifyOrAppleMusic: Bool, trackID: String) async throws -> [LyricLine] {
        let artist = currentlyPlayingArtist?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: "&", with: "%26")
        let album = spotifyOrAppleMusic ? appleMusicScript?.currentTrack?.album?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: "&", with: "%26") : spotifyScript?.currentTrack?.album?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: "&", with: "%26")
        let trackName = trackName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)?.replacingOccurrences(of: "&", with: "%26")
//        guard let intDuration = spotifyOrAppleMusic ? appleMusicScript?.currentTrack?.duration.map(Int.init) : spotifyScript?.currentTrack?.duration else {
//            throw CancellationError()
//        }
        // fetch lrc lyrics
//        if let artist, let album, let url = URL(string: "https://lrclib.net/api/get?artist_name=\(artist)&track_name=\(trackName)&album_name=\(album)&duration=\(spotifyOrAppleMusic ? intDuration : intDuration / 1000)") {
        if let trackName, let artist = artist, let album = album, let url = URL(string: "https://lrclib.net/api/get?artist_name=\(artist)&track_name=\(trackName)&album_name=\(album)") {
            print("the lrclib call is \(url.absoluteString)")
            let request = URLRequest(url: url)
            let urlResponseAndData = try await LRCLIBUserAgentSession.data(for: request)
            print(String(describing: urlResponseAndData.0))
            let lrcLyrics = try decoder.decode(LRCLyrics.self, from: urlResponseAndData.0)
            print(lrcLyrics)
            
            let songObject = SongObject(from: lrcLyrics, with: coreDataContainer.viewContext, trackID: trackID, trackName: trackName, duration: decoder.userInfo[CodingUserInfoKey.duration] as! TimeInterval)
            saveCoreData()
            amplitude.track(eventType: "LRC Fetch")
            if spotifyOrAppleMusic {
                if let artwork = (appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data {
                    SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: artwork.findAverageColor())
                } else if let artistName = currentlyPlayingArtist, let albumName = appleMusicScript?.currentTrack?.album,  let mbid = await findMbid(albumName: albumName, artistName: artistName), let artworkUrl = mbidAlbumArt(mbid), let imageData = try? await URLSession.shared.data(from: artworkUrl), let image = NSImage(data: imageData.0) {
                    SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: image.findAverageColor())
                }
            } else {
                if let artworkUrlString = spotifyScript?.currentTrack?.artworkUrl, let artworkUrl = URL(string: artworkUrlString), let imageData = try? await URLSession.shared.data(from: artworkUrl), let image = NSImage(data: imageData.0) {
                    SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: image.findAverageColor())
                } else if let artistName = currentlyPlayingArtist, let albumName = spotifyScript?.currentTrack?.album,  let mbid = await findMbid(albumName: albumName, artistName: artistName), let artworkUrl = mbidAlbumArt(mbid), let imageData = try? await URLSession.shared.data(from: artworkUrl), let image = NSImage(data: imageData.0) {
                    SpotifyColorData(trackID: trackID, context: coreDataContainer.viewContext, background: image.findAverageColor())
                }
            }
            try Task.checkCancellation()
            return lrcLyrics.lyrics
//            let lyricsArray = zip(songObject., songObject.lyrics.lyricsWords).map { LyricLine(startTime: $0, words: $1) }
            
//            if urlResponseAndData.0.isEmpty {
//                print("F")
//                return try await fetchLRCLIBNetworkLyrics( trackName: trackName, spotifyOrAppleMusic: spotifyOrAppleMusic, trackID: trackID)
////                return []
//            }
        }
        // and then custom spotify album call to get the color for karaoke mode
        
        // check if not cancelled
        // save SongObject and IDToColor
        
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
    
    func requestMusicKitAuthorization() async -> MusicKit.MusicAuthorization.Status {
        let status = await MusicAuthorization.request()
        return status
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
    
    func base62ToHex(_ base62Str: String) throws -> String {
        let characters = Array("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var decimalValue = 0
        
        for char in base62Str {
            guard let index = characters.firstIndex(of: char) else {
                throw NSError(domain: "Invalid character in base62 string", code: 1, userInfo: nil)
            }
            decimalValue = decimalValue * 62 + index
        }
        
        var hexValue = String(decimalValue, radix: 16)
        hexValue = String(repeating: "0", count: max(0, 32 - hexValue.count)) + hexValue
        return hexValue
    }
    
    func appleMusicNetworkFetch() async throws {
        
        // coredata didn't get us anything
        
        // Get song info
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.global(), { (information) in
            self.appleMusicStorePlaybackID =  information["kMRMediaRemoteNowPlayingInfoContentItemIdentifier"] as? String
        })

        try await generateAccessToken()
        
        // check for musickit auth
        print("status of MusicKit auth: \(MusicAuthorization.currentStatus)")
        print("status of apple music store playback ID: \(appleMusicStorePlaybackID)")
        
//        guard let appleMusicStorePlaybackID else {
//            print("no playback store id, giving up")
//            return
//        }
        let isrc = await {
            if let appleMusicStorePlaybackID, let response = try? await MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: .init(appleMusicStorePlaybackID)).response(), let song = response.items.first
            {
                return song.isrc
            }
            return nil
        }()
//        let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: .init(appleMusicStorePlaybackID))
//        guard let response = try? await request.response(), let song = response.items.first, let isrc = song.isrc else { return }
        print("playback ID is \(appleMusicStorePlaybackID) and ISRC is \(isrc)")
        
        // get equivalent spotify ID
        let appleMusicHelperSpotifyConversion = try await musicToSpotifyHelper(accessToken: accessToken, isrc: isrc)
        var alternativeID = (appleMusicScript?.currentTrack?.artist ?? "") + (appleMusicScript?.currentTrack?.name ?? "")
        // Ensure only Spotify tracks have track ID of length 22
        if alternativeID.count == 22 {
            alternativeID.append("_")
        }
        // Task cancelled means we're working with old song data, so dont update Spotify ID with old song's ID
        if !Task.isCancelled {
            if let appleMusicHelperSpotifyConversion {
                self.currentlyPlayingName = appleMusicHelperSpotifyConversion.SpotifyName
                self.currentlyPlayingArtist = appleMusicHelperSpotifyConversion.SpotifyArtist
                self.currentlyPlaying = appleMusicHelperSpotifyConversion.SpotifyID
            } else if alternativeID != "" {
                self.currentlyPlaying = alternativeID
            } else {
                lyricsIsEmptyPostLoad = true
            }
            
            if let currentlyPlayingAppleMusicPersistentID, let currentlyPlaying {
                print("both persistent ID and spotify ID are non nill, so we attempt to save to coredata")
                // save the mapping into coredata persistentIDToSpotify
                let newPersistentIDToSpotifyIDMapping = PersistentIDToSpotify(context: coreDataContainer.viewContext)
                newPersistentIDToSpotifyIDMapping.persistentID = currentlyPlayingAppleMusicPersistentID
                newPersistentIDToSpotifyIDMapping.spotifyID = currentlyPlaying
                saveCoreData()
            }
        }
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
            // No need for Spotify Connect delay or fullscreen, this is APPLE MUSIC 
            let currentTime = playerPosition * 1000 + 400
            guard let lastIndex: Int = upcomingIndex(currentTime) else {
                stopLyricUpdater()
                return
            }
            // If there is no current index (perhaps lyric updater started late and we're mid-way of the first lyric, or the user scrubbed and our index is expired)
            // Then we set the current index to the one before our anticipated index
            if currentlyPlayingLyricsIndex == nil && lastIndex > 0 {
                withAnimation {
                    currentlyPlayingLyricsIndex = lastIndex-1
                }
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
                withAnimation {
                    currentlyPlayingLyricsIndex = lastIndex
                }
            } else {
                currentlyPlayingLyricsIndex = nil
            }
            print("current lyrics index is now \(currentlyPlayingLyricsIndex?.description ?? "nil")")
        } while !Task.isCancelled
    }
    
    struct AppleMusicHelper {
        let SpotifyID: String
        let SpotifyName: String
        let SpotifyArtist: String
    }
    
    private func musicToSpotifyHelper(accessToken: accessTokenJSON?, isrc: String?) async throws -> AppleMusicHelper? {
        if let accessToken {
            print("AM to Spotify: access token found")
            // Attempt to find Spotify ID using ISRC
            if let isrc, let url = URL(string: "https://api.spotify.com/v1/search?q=isrc:\(isrc)&type=track&limit=1") {
                var request = URLRequest(url: url)
                request.addValue("WebPlayer", forHTTPHeaderField: "app-platform")
                print("the access token is \(accessToken.accessToken)")
                request.addValue("Bearer \(accessToken.accessToken)", forHTTPHeaderField: "authorization")
                // Invalidate this request if cancelled (means this song is old, user rapidly skipped)
                guard !Task.isCancelled else {return nil}
                let urlResponseAndData = try await fakeSpotifyUserAgentSession.data(for: request)
                if urlResponseAndData.0.isEmpty {
                    return nil
                }
                let response = try decoder.decode(SpotifyResponse.self, from: urlResponseAndData.0)
                if let track = response.tracks.items.first, let firstArtistName = track.firstArtistName {
                    print("Got ID with ISRC conversion")
                    return AppleMusicHelper(SpotifyID: track.id, SpotifyName: track.name, SpotifyArtist: firstArtistName)
                }
            }
            // Manually search song name, artist name
            else {
                if let artist = self.appleMusicScript?.currentTrack?.artist, let track = self.currentlyPlayingName, let url = URL(string: "https://api.spotify.com/v1/search?q=track:\(track)+artist:\(artist)+&type=track&limit=1") {
                    var request = URLRequest(url: url)
                    request.addValue("WebPlayer", forHTTPHeaderField: "app-platform")
                    request.addValue("Bearer \(accessToken.accessToken)", forHTTPHeaderField: "authorization")
                    guard !Task.isCancelled else {return nil}
                    if let searchData = try? await fakeSpotifyUserAgentSession.data(for: request), !searchData.0.isEmpty, let searchResponse = try? self.decoder.decode(SpotifyResponse.self, from: searchData.0), let track = searchResponse.tracks.items.first, let firstArtistName = track.firstArtistName {
                        print("Got ID with manual search")
                        return AppleMusicHelper(SpotifyID: track.id, SpotifyName: track.name, SpotifyArtist: firstArtistName)
                    }
                }
            }
        }
        return nil
    }
    
    func findRealLanguage() -> Locale.Language? {
        var langCount: [Locale.Language: Int] = [:]
        let recognizer = NLLanguageRecognizer()
        for lyric in currentlyPlayingLyrics {
            recognizer.reset()
            recognizer.processString(lyric.words)
            
          //  if recognizer.dominantLanguage !=
            if let dominantLanguage = recognizer.dominantLanguage {
                let value: Locale.Language = .init(identifier: dominantLanguage.rawValue)
                if value != Locale.Language.systemLanguages.first! {
                    langCount[value, default: 0] += 1
                }
                print(value)
            }
        }
        if let lol =  langCount.sorted( by: { $1.value < $0.value}).first {
            if lol.value >= 3 {
                return lol.key
            }
        }
        return nil
    }
}

// credits: Christian Selig https://christianselig.com/2021/04/efficient-average-color/

extension NSImage {
    
    func findAverageColor() -> Int32 {
        guard let cgImage = cgImage else { return 0 }
        
        let size = CGSize(width: 40, height: 40)
        
        let width = Int(size.width)
        let height = Int(size.height)
        let totalPixels = width * height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // ARGB format
        let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        
        // 8 bits for each color channel, we're doing ARGB so 32 bits (4 bytes) total, and thus if the image is n pixels wide, and has 4 bytes per pixel, the total bytes per row is 4n. That gives us 2^8 = 256 color variations for each RGB channel or 256 * 256 * 256 = ~16.7M color options in total. That seems like a lot, but lots of HDR movies are in 10 bit, which is (2^10)^3 = 1 billion color options!
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo) else { return 0 }

        // Draw our resized image
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        guard let pixelBuffer = context.data else { return 0 }
        
        // Bind the pixel buffer's memory location to a pointer we can use/access
        let pointer = pixelBuffer.bindMemory(to: UInt32.self, capacity: width * height)

        // Keep track of total colors (note: we don't care about alpha and will always assume alpha of 1, AKA opaque)
        var totalRed = 0
        var totalBlue = 0
        var totalGreen = 0
        
        // Column of pixels in image
        for x in 0 ..< width {
            // Row of pixels in image
            for y in 0 ..< height {
                // To get the pixel location just think of the image as a grid of pixels, but stored as one long row rather than columns and rows, so for instance to map the pixel from the grid in the 15th row and 3 columns in to our "long row", we'd offset ourselves 15 times the width in pixels of the image, and then offset by the amount of columns
                let pixel = pointer[(y * width) + x]
                
                let r = red(for: pixel)
                let g = green(for: pixel)
                let b = blue(for: pixel)

                totalRed += Int(r)
                totalBlue += Int(b)
                totalGreen += Int(g)
            }
        }
        
        let averageRed: CGFloat
        let averageGreen: CGFloat
        let averageBlue: CGFloat
        
        averageRed = CGFloat(totalRed) / CGFloat(totalPixels)
        averageGreen = CGFloat(totalGreen) / CGFloat(totalPixels)
        averageBlue = CGFloat(totalBlue) / CGFloat(totalPixels)
        
        // Convert from [0 ... 255] format to the [0 ... 1.0] format UIColor wants
//        return NSColor(red: averageRed / 255.0, green: averageGreen / 255.0, blue: averageBlue / 255.0, alpha: 1.0)
        // Convert CGFloat values to UInt8 (0-255 range)
        let red = Int(averageRed)
        let green = Int(averageGreen)
        let blue = Int(averageBlue)

        // Pack into a single UInt32
        
//        return (UInt32(red) << 16) | (UInt32(green) << 8) | UInt32(blue)
        print("Find average color: red is \(red), green is \(green), blue is \(blue)")
        let combinedValue = (red << 16) | (green << 8) | blue
        return Int32(bitPattern: UInt32(combinedValue))
    }
    
    private func red(for pixelData: UInt32) -> UInt8 {
        return UInt8((pixelData >> 16) & 255)
    }

    private func green(for pixelData: UInt32) -> UInt8 {
        return UInt8((pixelData >> 8) & 255)
    }

    private func blue(for pixelData: UInt32) -> UInt8 {
        return UInt8((pixelData >> 0) & 255)
    }
}

extension NSColor {
    var hexString: String? {
        guard let rgbColor = self.usingColorSpace(.sRGB) else {
            return nil
        }
        let red = Int(rgbColor.redComponent * 255)
        let green = Int(rgbColor.greenComponent * 255)
        let blue = Int(rgbColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    convenience init?(hexString hex: String) {
        if hex.count != 7 { // The '#' included
            return nil
        }
            
        let hexColor = String(hex.dropFirst())
        
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0
        
        if !scanner.scanHexInt64(&hexNumber) {
            return nil
        }
        
        let r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
        let g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
        let b = CGFloat(hexNumber & 0x0000ff) / 255
        
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
