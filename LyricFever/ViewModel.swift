//
//  viewModel.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 14/08/23.
//

import Foundation
#if os(macOS)
#endif
@preconcurrency import CoreData
import AmplitudeSwift
import SwiftUI
import MediaPlayer
#if os(macOS)
import WebKit
import Translation
#endif

@MainActor
@Observable class ViewModel {
    static let shared = ViewModel()
    var currentlyPlaying: String?
    
    var currentVolume: Int = 0
    
    var artworkImage: NSImage?
    var currentArtworkURL: URL?

    var duration: Int = 0
    var currentTime = CurrentTimeWithStoredDate(currentTime: 0)
    
    var formattedCurrentTime: String {
        let baseTime = currentTime.currentTime
        let totalSeconds = Int(baseTime) / 1000
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(totalSeconds)) ?? "0:00"
    }
    
    func formattedCurrentTime(for date: Date) -> String {
        let baseTime = currentTime.currentTime
        let delta = date.timeIntervalSince(currentTime.storedDate)
//        print("Formatted Current Time: delta is \(delta)")
        let totalSeconds = Int((baseTime + delta) / 1000)
//        print("total seconds should be \(totalSeconds)")
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(totalSeconds)) ?? "0:00"
    }
    
    var formattedDuration: String {
        let totalSeconds = duration / 1000
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(totalSeconds)) ?? "0:00"
    }
    
    #if os(macOS)
    var updaterService = UpdaterService()
    var appleMusicPlayer = AppleMusicPlayer()
    var spotifyPlayer = SpotifyPlayer()
    #else
    var currentTab = TabType.nowPlaying
    var spotifyPlayer = TVSpotifyPlayer()
    var hasWebApiOnboarded = false
    #endif
    
    var currentPlayerInstance: Player {
        #if os(macOS)
        switch currentPlayer {
            case .appleMusic:
                return appleMusicPlayer
            case .spotify:
                return spotifyPlayer
        }
        #else
        return spotifyPlayer
        #endif
    }
    
    #if os(macOS)
    var translationSessionConfig: TranslationSession.Configuration?
    #endif
    var userDefaultStorage = UserDefaultStorage()
    
    #if os(macOS)
    // Karaoke Font
    var karaokeFont: NSFont
    
    // nil to deal with previously saved songs that don't have lang saved with them
    // or for LRCLIB
    var currentBackground: Color? = nil
    
    var animatedDisplay: Bool {
        get {
            displayKaraoke || fullscreen
        }
        set {
            
        }
    }
    
    var canDisplayLyrics: Bool {
        showLyrics && !lyricsIsEmptyPostLoad
    }

    var displayKaraoke: Bool {
        get {
            showLyrics && isPlaying && userDefaultStorage.karaoke && !karaokeModeHovering && (currentlyPlayingLyricsIndex != nil)
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
    var currentlyPlayingAppleMusicPersistentID: String? = nil
    #endif
    
    var currentlyPlayingName: String?
    var currentlyPlayingArtist: String?
    var currentlyPlayingLyrics: [LyricLine] = []
    var currentlyPlayingLyricsIndex: Int?
    var isPlaying: Bool = false
    var romanizedLyrics: [String] = []
    var translatedLyric: [String] = []
    var showLyrics = true
    #if os(macOS)
    var fullscreen = false
    var spotifyConnectDelay: Bool = false
    var airplayDelay: Bool = false
    #endif
    var isFetchingTranslation = false
    var translationExists: Bool { !translatedLyric.isEmpty}
    
    // CoreData container (for saved lyrics)
    let coreDataContainer: NSPersistentContainer
    
    // Logging / Analytics
    let amplitude = Amplitude(configuration: .init(apiKey: amplitudeKey))
    
    var isHearted = false
    
    // Async Tasks (Lyrics fetch, Apple Music -> Spotify ID fetch, Lyrics Updater)
    private var currentFetchTask: Task<[LyricLine], Error>?
    private var currentLyricsUpdaterTask: Task<Void,Error>?
    private var currentLyricsDriftFix: Task<Void,Error>?
    var isFetching = false
    private var currentAppleMusicFetchTask: Task<Void,Error>?
    
    // Songs are translated to user locale
    let userLocaleLanguage: Locale
    let userLocaleLanguageString: String

    // Override menubar with an update message
    var mustUpdateUrgent: Bool = false

    // Delayed variable to hook onto for fullscreen (whether to display lyrics or not)
    // Prevents flickering that occurs when we directly bind to currentlyPlayingLyrics.isEmpty()
    var lyricsIsEmptyPostLoad: Bool = true
    
    #if os(macOS)
    // UI element used to hide if karaokeModeHoveringSetting is true
    var karaokeModeHovering: Bool = false
    
    var colorBinding: Binding<Color> {
        Binding<Color> {
            Color(NSColor(hexString: self.userDefaultStorage.fixedKaraokeColorHex)!)
        } set: { newValue in
            self.userDefaultStorage.fixedKaraokeColorHex = NSColor(newValue).hexString!
        }
    }
    #endif
    
    var currentAlbumName: String? {
        return currentPlayerInstance.albumName
    }
    #if os(macOS)
    var currentPlayer: PlayerType {
        get {
            if self.userDefaultStorage.spotifyOrAppleMusic {
                return .appleMusic
            } else {
                return .spotify
            }
        } set {
            if newValue == .appleMusic {
                self.userDefaultStorage.spotifyOrAppleMusic = true
            } else {
                self.userDefaultStorage.spotifyOrAppleMusic = false
            }
        }
    }
    #else
    @ObservationIgnored var currentPlayer: Player {
        return spotifyPlayer
    }
    #endif
    
    var currentDuration: Int? {
        currentPlayerInstance.duration
    }
    var isPlayerRunning: Bool {
        currentPlayerInstance.isRunning
    }
    #if os(macOS)
    var currentAlbumArt: Color {
        guard userDefaultStorage.karaokeUseAlbumColor, let currentBackground else {
            return colorBinding.wrappedValue
        }
        return currentBackground
    }
    #endif
    
    var spotifyLyricProvider = SpotifyLyricProvider()
    var lRCLyricProvider = LRCLIBLyricProvider()
    var netEaseLyricProvider = NetEaseLyricProvider()
    #if os(macOS)
    var localFileUploadProvider = LocalFileUploadProvider()
    #endif
    @ObservationIgnored lazy var allNetworkLyricProviders: [LyricProvider] = [spotifyLyricProvider, lRCLyricProvider, netEaseLyricProvider]
    
    var isFirstFetch = true
    
    init() {
        // Set our user locale for translation language
        userLocaleLanguage = Locale.preferredLocale()
        userLocaleLanguageString = Locale.preferredLocaleString() ?? ""
        
        #if os(macOS)
        // Generate user-saved font and load it
        let karaokeFontSize: Double = UserDefaults.standard.double(forKey: "karaokeFontSize")
        let karaokeFontName: String? = UserDefaults.standard.string(forKey: "karaokeFontName")
        if let karaokeFontName, karaokeFontSize != 0, let ourKaraokeFont = NSFont(name: karaokeFontName, size: karaokeFontSize) {
            karaokeFont = ourKaraokeFont
        } else {
            karaokeFont = NSFont.boldSystemFont(ofSize: 30)
        }
        #endif
        // Load our CoreData container for Lyrics
        coreDataContainer = NSPersistentContainer(name: "Lyrics")
        coreDataContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Error: \(error.localizedDescription)")
            }
            self.coreDataContainer.viewContext.mergePolicy = NSMergePolicy.overwrite
        }
        #if os(macOS)
        migrateTimestampsIfNeeded(context: coreDataContainer.viewContext)
        
        
        // Check if user must urgently update (overrides menubar)
        Task {
            mustUpdateUrgent = await updaterService.urgentUpdateExists
        }
        
        // onAppear()
        print("on appear running")
        if userDefaultStorage.latestUpdateWindowShown < 23 {
            return
        }
        #endif
        if userDefaultStorage.cookie.count == 0 {
            print("Setting hasOnboarded to false due to empty cookie")
            userDefaultStorage.hasOnboarded = false
            return
        }
        guard userDefaultStorage.hasOnboarded else {
            return
        }
        guard isPlayerRunning else {
            return
        }
        print("Application just started. lets check whats playing")
        
        isPlaying = currentPlayerInstance.isPlaying
        userDefaultStorage.hasOnboarded = currentPlayerInstance.isAuthorized
        guard userDefaultStorage.hasOnboarded else {
            return
        }
        
    }
    
    @MainActor
    func fetchAllNetworkLyrics() async -> NetworkFetchReturn {
        guard let currentlyPlaying, let currentlyPlayingName else {
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }
        for networkLyricProvider in allNetworkLyricProviders {
            do {
                print("FetchAllNetworkLyrics: fetching from \(networkLyricProvider.providerName)")
                let lyrics = try await networkLyricProvider.fetchNetworkLyrics(trackName: currentlyPlayingName, trackID: currentlyPlaying, currentlyPlayingArtist: currentlyPlayingArtist, currentAlbumName: currentAlbumName)
                if !lyrics.lyrics.isEmpty {
                    print("FetchAllNetworkLyrics: returning lyrics from \(networkLyricProvider.providerName)")
                    //TODO: save lyrics here
                    SongObject(from: lyrics.lyrics, with: coreDataContainer.viewContext, trackID: currentlyPlaying, trackName: currentlyPlayingName)
                    saveCoreData()
                    return lyrics
                } else {
                    print("FetchAllNetworkLyrics: no lyrics from \(networkLyricProvider.providerName)")
                }
            } catch {
                print("Caught exception on \(networkLyricProvider.providerName): \(error)")
            }
        }
        return NetworkFetchReturn(lyrics: [], colorData: nil)
    }
    
    #if os(macOS)
    func refreshLyrics() async throws {
        // todo: romanize
        if currentPlayer == .appleMusic {
            print("Refresh Lyrics: Calling Apple Music Network fetch")
            try await appleMusicNetworkFetch()
        }
        guard let currentlyPlaying, let currentlyPlayingName, let currentDuration = currentPlayerInstance.durationAsTimeInterval else {
            return
        }
        print("Calling refresh lyrics")
        guard let finalLyrics = await self.fetch(for: currentlyPlaying, currentlyPlayingName, checkCoreDataFirst: false) else {
            print("Refresh Lyrics: Failed to run network fetch")
            return
        }
        if finalLyrics.isEmpty {
            currentlyPlayingLyricsIndex = nil
        }
        currentlyPlayingLyrics = finalLyrics
        setBackgroundColor()
        romanizeDidChange()
        reloadTranslationConfigIfTranslating()
        lyricsIsEmptyPostLoad = currentlyPlayingLyrics.isEmpty
        print("HELLOO")
        if isPlaying, !currentlyPlayingLyrics.isEmpty, showLyrics, userDefaultStorage.hasOnboarded {
            startLyricUpdater()
        }
        // we call this in self.fetch
//        callColorDataServiceOnLyricColorOrArtwork(colorData: finalLyrics.colorData)
    }
    
    func callColorDataServiceOnLyricColorOrArtwork(colorData: Int32?) {
        if let currentlyPlaying, let backgroundColor = colorData ?? artworkImage?.findWhiteTextLegibleMostSaturatedDominantColor() {
            ColorDataService.saveColorToCoreData(trackID: currentlyPlaying, songColor: backgroundColor)
            print("ViewModel Refresh Lyrics: New color \(backgroundColor) saved for track \(currentlyPlaying)")
        }
    }
    
    // Run only on first 2.1 run. Strips whitespace from saved lyrics, and extends final timestamp to prevent karaoke mode racecondition (as well as song on loop race condition)
    func migrateTimestampsIfNeeded(context: NSManagedObjectContext) {
        if !userDefaultStorage.hasMigrated {
            let fetchRequest: NSFetchRequest<SongObject> = SongObject.fetchRequest()
            do {
                let objects = try context.fetch(fetchRequest)
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
                userDefaultStorage.hasMigrated = true
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
                self.userDefaultStorage.cookie = temporaryCookie.value
                NotificationCenter.default.post(name: Notification.Name("didLogIn"), object: nil)
            }
        }
    }
    
    func openSettings(_ openWindow: OpenWindowAction) {
        openWindow(id: "onboarding")
        NSApplication.shared.activate(ignoringOtherApps: true)
//        // send notification to check auth
//        NotificationCenter.default.post(name: Notification.Name("didClickSettings"), object: nil)
    }
    #endif
    
    func toggleLyrics() {
        if showLyrics {
            startLyricUpdater()
        } else {
            stopLyricUpdater()
        }
    }
    
    func openTranslationHelpOnFirstRun(_ openURL: OpenURLAction) {
        if !userDefaultStorage.hasTranslated {
            openURL(URL(string: "https://aviwadhwa.com/TranslationHelp")!)
        }
        userDefaultStorage.hasTranslated = true
    }
    
    @MainActor
    func translationTask(_ session: TranslationSession) async {
        isFetchingTranslation = true
        let translationResponse = await TranslationService.translationTask(session, request: currentlyPlayingLyrics.map { TranslationSession.Request(lyric: $0) })
        
        switch translationResponse {
            case .success(let array):
                print("Translation Service: isFetchingTranslation set to false due to success")
                isFetchingTranslation = false
                if currentlyPlayingLyrics.count == array.count {
                    translatedLyric = array.map {
                        $0.targetText
                    }
                }
            case .needsConfigUpdate(let language):
                // TODO: why do i sleep?
                try? await Task.sleep(for: .seconds(1))
                translationSessionConfig = TranslationSession.Configuration(source: language, target: userLocaleLanguage.language)
            case .failure:
                print("Translation Service: isFetchingTranslation set to false due to failure")
                isFetchingTranslation = false
                return
        }
    }
    
    func romanizeDidChange() {
        if userDefaultStorage.romanize {
            print("Romanized Lyrics generated from romanize value change for song \(currentlyPlaying)")
            romanizedLyrics = currentlyPlayingLyrics.compactMap({
                RomanizerService.generateRomanizedLyric($0)
            })
        } else {
            romanizedLyrics = []
        }
    }
    
    #if os(macOS)
    func saveKaraokeFontOnTermination() {
        // This code will be executed just before the app terminates
     UserDefaults.standard.set(karaokeFont.fontName, forKey: "karaokeFontName")
     UserDefaults.standard.set(Double(karaokeFont.pointSize), forKey: "karaokeFontSize")
    }
    
    func appleMusicPlaybackDidChange(_ notification: Notification) {
        guard currentPlayer == .appleMusic else {
            return
        }
        if notification.userInfo?["Player State"] as? String == "Playing" {
            print("is playing")
            isPlaying = true
        } else {
            print("paused. timer canceled")
            isPlaying = false
            // manually cancels the lyric-updater task bc media is paused
        }
        let currentlyPlayingName = (notification.userInfo?["Name"] as? String)
        guard let currentlyPlayingName else {
            self.currentlyPlayingName = nil
            currentlyPlayingArtist = nil
            return
        }
        if currentlyPlayingName == "" {
            self.currentlyPlayingName = nil
            currentlyPlayingArtist = nil
        } else {
            self.currentlyPlayingName = currentlyPlayingName
            currentlyPlayingArtist = (notification.userInfo?["Artist"] as? String)
            if let duration = currentPlayerInstance.duration {
                self.duration = duration
            }
            print("REOPEN: currentlyPlayingName is \(currentlyPlayingName)")
            currentlyPlayingAppleMusicPersistentID = appleMusicPlayer.persistentID
        }
    }
    
    func spotifyPlaybackDidChange(_ notification: Notification) {
        guard currentPlayer == .spotify else {
            return
        }
        if notification.userInfo?["Player State"] as? String == "Playing" {
            print("is playing")
            isPlaying = true
        } else {
            print("paused. timer canceled")
            isPlaying = false
            // manually cancels the lyric-updater task bc media is paused
        }
        print(notification.userInfo?["Track ID"] as? String)
        let currentlyPlaying = (notification.userInfo?["Track ID"] as? String)?.spotifyProcessedUrl()
        let currentlyPlayingName = (notification.userInfo?["Name"] as? String)
        if currentlyPlaying != "", currentlyPlayingName != "", let duration = currentPlayerInstance.duration {
            self.currentlyPlaying = currentlyPlaying
            self.currentlyPlayingName = currentlyPlayingName
            self.currentlyPlayingArtist = spotifyPlayer.artistName
            self.duration = duration
        }
    }
    
    func onAppear(_ openWindow: OpenWindowAction) {
        setCurrentProperties()
    }
    
    func onCurrentlyPlayingIDChange() async {
        currentlyPlayingLyricsIndex = nil
        currentlyPlayingLyrics = []
        translatedLyric = []
        romanizedLyrics = []
        
        if userDefaultStorage.hasOnboarded, let currentlyPlaying = currentlyPlaying, let currentlyPlayingName = currentlyPlayingName, let lyrics = await fetch(for: currentlyPlaying, currentlyPlayingName) {
            currentlyPlayingLyrics = lyrics
            setBackgroundColor()
            romanizeDidChange()
            reloadTranslationConfigIfTranslating()
            lyricsIsEmptyPostLoad = lyrics.isEmpty
            if isPlaying, !currentlyPlayingLyrics.isEmpty, showLyrics, userDefaultStorage.hasOnboarded {
                print("STARTING UPDATER")
                startLyricUpdater()
            }
        }
    }
    
    private func setCurrentProperties() {
        switch currentPlayer {
            case .appleMusic:
                if let currentTrackName = appleMusicPlayer.trackName, let currentArtistName = appleMusicPlayer.artistName, let duration = appleMusicPlayer.duration {
                    // Don't set currentlyPlaying here: the persistentID change triggers the appleMusicFetch which will set spotify's currentlyPlaying
                    if currentTrackName == "" {
                        currentlyPlayingName = nil
                        currentlyPlayingArtist = nil
                    } else {
                        currentlyPlayingName = currentTrackName
                        currentlyPlayingArtist = currentArtistName
                        self.duration = duration
                    }
                    print("ON APPEAR HAS UPDATED APPLE MUSIC SONG ID")
                    currentlyPlayingAppleMusicPersistentID = appleMusicPlayer.persistentID
                }
            case .spotify:
                if let currentTrack = spotifyPlayer.trackID, let currentTrackName = spotifyPlayer.trackName, let currentArtistName =  spotifyPlayer.artistName, currentTrack != "", currentTrackName != "", let duration = spotifyPlayer.duration {
                    currentlyPlaying = currentTrack
                    currentlyPlayingName = currentTrackName
                    currentlyPlayingArtist = currentArtistName
                    self.duration = duration
                    self.currentTime = CurrentTimeWithStoredDate(currentTime: 0)
                    print(currentTrack)
                }
        }
    }
    
    #else
    func setCurrentProperties() {
        currentlyPlaying = spotifyPlayer.currentTrack?.uri?.spotifyProcessedUrl()
        currentlyPlayingName = spotifyPlayer.trackName
        currentlyPlayingArtist = spotifyPlayer.artistName
    }
    #endif

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
                #if os(macOS)
                currentlyPlayingAppleMusicPersistentID = nil
                #endif
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
            guard let currentTime = currentPlayerInstance.currentTime, let lastIndex: Int = upcomingIndex(currentTime) else {
                stopLyricUpdater()
                return
            }
            // If there is no current index (perhaps lyric updater started late and we're mid-way of the first lyric, or the user scrubbed and our index is expired)
            // Then we set the current index to the one before our anticipated index
            if currentlyPlayingLyricsIndex == nil && lastIndex > 0 {
                currentlyPlayingLyricsIndex = lastIndex-1
            }
            let nextTimestamp = currentlyPlayingLyrics[lastIndex].startTimeMS
            let diff = nextTimestamp - currentTime
            print("current time: \(currentTime)")
            self.currentTime = CurrentTimeWithStoredDate(currentTime: currentTime)
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
    
    func startLyricUpdater() {
        currentLyricsUpdaterTask?.cancel()
        if !isPlaying || currentlyPlayingLyrics.isEmpty || mustUpdateUrgent {
            return
        }
        // If an index exists, we're unpausing: meaning we must instantly find the current lyric
        if currentlyPlayingLyricsIndex != nil {
            guard let currentTime = currentPlayerInstance.currentTime, let lastIndex: Int = upcomingIndex(currentTime) else {
                stopLyricUpdater()
                return
            }
            // If there is no current index (perhaps lyric updater started late and we're mid-way of the first lyric, or the user scrubbed and our index is expired)
            // Then we set the current index to the one before our anticipated index
            if lastIndex > 0 {
                currentlyPlayingLyricsIndex = lastIndex-1
            }
        } else {
            #if os(macOS)
            if currentPlayer == .spotify {
                currentLyricsDriftFix?.cancel()
                currentLyricsDriftFix =             // Only run drift fix for new songs
                Task {
                    try await spotifyPlayer.fixSpotifyLyricDrift()
                }
                Task {
                    try await currentLyricsDriftFix?.value
                }
            }
            #endif
        }
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
                print("Saved CoreData!")
            } catch {
                print("core data error \(error)")
                // Show some error here
            }
        } else {
            print("BAD COREDATA CALL!!")
        }
    }
    
    func fetch(for trackID: String, _ trackName: String, checkCoreDataFirst: Bool = true) async -> [LyricLine]? {
        if isFirstFetch {
            isFirstFetch = false
        }
        print("Fetch Called for trackID \(trackID), trackName \(trackName), checkCoreDataFirst: \(checkCoreDataFirst)")
        currentFetchTask?.cancel()
        // i don't set isFetching to true here to prevent "flashes" for CoreData fetches
        defer {
            isFetching = false
        }
        currentFetchTask = Task { try await self.fetchLyrics(for: trackID, trackName, checkCoreDataFirst: checkCoreDataFirst) }
        do {
            return try await currentFetchTask?.value
        } catch {
            print("error \(error)")
            return nil
        }
    }

    #if os(macOS)
    func intToRGB(_ value: Int32) -> Color {//(red: Int, green: Int, blue: Int) {
        // Convert negative numbers to an unsigned 32-bit representation
        let unsignedValue = UInt32(bitPattern: value)
        
        // Extract RGB components
        let red = Double((unsignedValue >> 16) & 0xFF)
        let green = Double((unsignedValue >> 8) & 0xFF)
        let blue = Double(unsignedValue & 0xFF)
        return Color(red: red/255, green: green/255, blue: blue/255) //(red, green, blue)
    }
    
    func setBackgroundColor() {
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
    }
    #endif
    
    func fetchLyrics(for trackID: String, _ trackName: String, checkCoreDataFirst: Bool) async throws -> [LyricLine] {
        if checkCoreDataFirst, let lyrics = fetchFromCoreData(for: trackID) {
            print("ViewModel FetchLyrics: got lyrics from core data :D \(trackID) \(trackName)")
            try Task.checkCancellation()
            amplitude.track(eventType: "CoreData Fetch")
            return lyrics
        } else {
            print("ViewModel FetchLyrics: no lyrics from core data, going to download from internet \(trackID) \(trackName)")
            print("ViewModel FetchLyrics: isFetching set to true")
            isFetching = true
            var networkLyrics: NetworkFetchReturn = await fetchAllNetworkLyrics()
            guard let duration = currentPlayerInstance.duration else {
                print("FetchLyrics: Couldn't access current player duration. Giving up on netwokr fetch")
                return []
            }
            networkLyrics = networkLyrics.processed(withSongName: trackName, duration: duration)
            callColorDataServiceOnLyricColorOrArtwork(colorData: networkLyrics.colorData)
            return networkLyrics.lyrics
        }
    }

    func deleteLyric(trackID: String) {
        do {
            let fetchRequest: NSFetchRequest<SongObject> = SongObject.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", trackID)
            let object = try coreDataContainer.viewContext.fetch(fetchRequest).first
            object?.lyricsTimestamps.removeAll()
            object?.lyricsWords.removeAll()
            try coreDataContainer.viewContext.save()
            currentlyPlayingLyricsIndex = nil
            currentlyPlayingLyrics = []
            if userDefaultStorage.translate {
                translatedLyric = []
                romanizedLyrics = []
            }
            lyricsIsEmptyPostLoad = true
        } catch {
            print("Error deleting data: \(error)")
        }
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
    
    #if os(macOS)
    func reloadTranslationConfigIfTranslating() -> Bool {
        if userDefaultStorage.translate {
            if translationSessionConfig == TranslationSession.Configuration(target: userLocaleLanguage.language) {
                translationSessionConfig?.invalidate()
            } else {
                translationSessionConfig = TranslationSession.Configuration(target: userLocaleLanguage.language)
            }
            return true
        } else {
            return false
        }
    }
    #endif
    
    #if os(macOS)
    @MainActor
    func uploadLocalLRCFile() async throws {
        guard let currentlyPlaying = currentlyPlaying, let currentlyPlayingName = currentlyPlayingName else {
            throw CancellationError()
        }
        try await currentlyPlayingLyrics = localFileUploadProvider.localFetch(for: currentlyPlaying, currentlyPlayingName)
        setBackgroundColor()
        reloadTranslationConfigIfTranslating()
        romanizeDidChange()
        lyricsIsEmptyPostLoad = currentlyPlayingLyrics.isEmpty
        if isPlaying, !currentlyPlayingLyrics.isEmpty, showLyrics, userDefaultStorage.hasOnboarded {
            startLyricUpdater()
        }
    }
    #endif
    
    func stepsToTakeAfterSettingsLyrics() async {
        
    }
    
    func didOnboard() {
        guard isPlayerRunning else {
            isPlaying = false
            currentlyPlaying = nil
            currentlyPlayingName = nil
            currentlyPlayingArtist = nil
            #if os(macOS)
            currentlyPlayingAppleMusicPersistentID = nil
            #endif
            return
        }
        print("Application just started (finished onboarding). lets check whats playing")
        if currentPlayerInstance.isPlaying {
            isPlaying = true
        }
        setCurrentProperties()
        startLyricUpdater()
    }
    #if os(macOS)
    func resetKaraokePrefs() {
        userDefaultStorage.karaokeModeHoveringSetting = false
        userDefaultStorage.karaokeUseAlbumColor = true
        userDefaultStorage.karaokeShowMultilingual = true
        userDefaultStorage.karaokeTransparency = 50
        karaokeFont = NSFont.boldSystemFont(ofSize: 30)
        colorBinding.wrappedValue = Color(.sRGB, red: 0.98, green: 0.0, blue: 0.98)
    }
    #endif
}

#if os(macOS)
// Apple Music Code
extension ViewModel {
    // Similar structure to my other Async functions. Only 1 appleMusic) can run at any given moment
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
                print("Apple Music Fetch: setting currentlyPlaying to \(coreDataSpotifyID)")
                self.currentlyPlaying = coreDataSpotifyID
                return
            }
        }
        
        try await appleMusicNetworkFetch()
    }
    
    func appleMusicNetworkFetch() async throws {
        isFetching = true
        // coredata didn't get us anything
        try await spotifyLyricProvider.generateAccessToken()
        
        // Task cancelled means we're working with old song data, so dont update Spotify ID with old song's ID
        if !Task.isCancelled {
            if let alternativeID = appleMusicPlayer.alternativeID, alternativeID != "" {
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
    
    private func musicToSpotifyHelper(accessToken: AccessTokenJSON?, isrc: String?) async throws -> AppleMusicHelper? {
        // Manually search song name, artist name
        guard let currentlyPlayingArtist, let currentlyPlayingName else {
            print("\(#function) currentlyPlayingName or currentlyPlayingArtist missing")
            return nil
        }
        return await spotifyLyricProvider.searchForTrackForAppleMusic(artist: currentlyPlayingArtist, track: currentlyPlayingName)
    }
}
#endif
