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
    var artworkImage: NSImage?
    var duration: Int = 0
    var currentTime = CurrentTimeWithStoredDate(currentTime: 0)
    var formattedCurrentTime: String {
        let baseTime = currentTime.currentTime
        let delta = Date().timeIntervalSince(currentTime.storedDate)
        let totalSeconds = Int((baseTime + delta) / 1000)
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
    var translationExists: Bool { !translatedLyric.isEmpty}
    
    // CoreData container (for saved lyrics)
    let coreDataContainer: NSPersistentContainer
    
    // Logging / Analytics
    let amplitude = Amplitude(configuration: .init(apiKey: amplitudeKey))
    
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
    
    func fetchAllNetworkLyrics() async -> [LyricLine] {
        guard let currentlyPlaying, let currentlyPlayingName else {
            return []
        }
        for networkLyricProvider in allNetworkLyricProviders {
            do {
                let lyrics = try await networkLyricProvider.fetchNetworkLyrics(trackName: currentlyPlayingName, trackID: currentlyPlaying, currentlyPlayingArtist: currentlyPlayingArtist, currentAlbumName: currentAlbumName)
                if !lyrics.isEmpty {
                    return lyrics
                }
            } catch {
                print("Caught exception on \(networkLyricProvider.providerName): \(error)")
            }
        }
        return []
    }
    
    #if os(macOS)
    func refreshLyrics() async throws {
        if userDefaultStorage.spotifyOrAppleMusic {
            try await appleMusicNetworkFetch()
        }
        guard let currentlyPlaying, let currentlyPlayingName else {
            return
        }
        
        let finalLyrics = await fetchAllNetworkLyrics()
        if finalLyrics.isEmpty {
            currentlyPlayingLyricsIndex = nil
        }
        currentlyPlayingLyrics = finalLyrics
        setBackgroundColor()
        reloadTranslationConfigIfTranslating()
        lyricsIsEmptyPostLoad = currentlyPlayingLyrics.isEmpty
        print("HELLOO")
        if isPlaying, !currentlyPlayingLyrics.isEmpty, showLyrics, userDefaultStorage.hasOnboarded {
            startLyricUpdater()
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
        let translationResponse = await TranslationService.translationTask(session, request: currentlyPlayingLyrics.map { TranslationSession.Request(lyric: $0) })
        
        switch translationResponse {
            case .success(let array):
                if currentlyPlayingLyrics.count == array.count {
                    translatedLyric = array.map {
                        $0.targetText
                    }
                }
            case .needsConfigUpdate(let language):
                translationSessionConfig = TranslationSession.Configuration(source: language, target: userLocaleLanguage.language)
            case .failure:
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
        if currentlyPlayingName == "" {
            self.currentlyPlayingName = nil
            currentlyPlayingArtist = nil
        } else {
            self.currentlyPlayingName = currentlyPlayingName
            currentlyPlayingArtist = (notification.userInfo?["Artist"] as? String)
        }
        currentlyPlayingAppleMusicPersistentID = appleMusicPlayer.persistentID
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
            reloadTranslationConfigIfTranslating()
            if userDefaultStorage.romanize {
                print("Romanized Lyrics generated from song change for \(currentlyPlaying)")
                romanizedLyrics = currentlyPlayingLyrics.compactMap({
                    RomanizerService.generateRomanizedLyric($0)
                })
            }
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
                if let currentTrackName = appleMusicPlayer.trackName, let currentArtistName = appleMusicPlayer.artistName {
                    // Don't set currentlyPlaying here: the persistentID change triggers the appleMusicFetch which will set spotify's currentlyPlaying
                    if currentTrackName == "" {
                        currentlyPlayingName = nil
                        currentlyPlayingArtist = nil
                    } else {
                        currentlyPlayingName = currentTrackName
                        currentlyPlayingArtist = currentArtistName
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
            currentLyricsDriftFix?.cancel()
            currentLyricsDriftFix =             // Only run drift fix for new songs
            Task {
                try await spotifyPlayer.fixSpotifyLyricDrift()
            }
            Task {
                try await currentLyricsDriftFix?.value
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
        }
    }
    
    func fetch(for trackID: String, _ trackName: String) async -> [LyricLine]? {
        currentFetchTask?.cancel()
        isFetching = true
        defer {
            isFetching = false
        }
        currentFetchTask = Task { try await self.fetchLyrics(for: trackID, trackName) }
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
    
    func fetchLyrics(for trackID: String, _ trackName: String) async throws -> [LyricLine] {
        if let lyrics = fetchFromCoreData(for: trackID) {
            print("got lyrics from core data :D \(trackID) \(trackName)")
            try Task.checkCancellation()
            amplitude.track(eventType: "CoreData Fetch")
            return lyrics
        }
        print("no lyrics from core data, going to download from internet \(trackID) \(trackName)")
        let networkLyrics = await fetchAllNetworkLyrics()
        //TODO: save lyrics to coredata, fetch background color, run translations
        return networkLyrics
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
                print("Apple Music Fetch: setting currentlyPlaying to \(coreDataSpotifyID)")
                self.currentlyPlaying = coreDataSpotifyID
                return
            }
        }
        
        try await appleMusicNetworkFetch()
    }
    
    func appleMusicNetworkFetch() async throws {
        
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


#if os(macOS)
extension NSImage {
    func findWhiteTextLegibleMostSaturatedDominantColor() -> Int32 {
        guard let dominantColors = try? self.dominantColors(with: .best, algorithm: .kMeansClustering).map({self.adjustedColor($0)}).sorted(by: { $0.saturationComponent > $1.saturationComponent }) else {
            return self.findAverageColor()
        }
        for color in dominantColors {
            if color.brightnessComponent > 0.1 {
                let red = Int(color.redComponent * 255)
                let green = Int(color.greenComponent * 255)
                let blue = Int(color.blueComponent * 255)
                
                let combinedValue = (max(0,red) << 16) | (max(0,green) << 8) | max(0,blue)
                return Int32(bitPattern: UInt32(combinedValue))
            }
        }
        return self.findAverageColor()
    }
    // credits: Christian Selig https://christianselig.com/2021/04/efficient-average-color/
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
    func adjustedColor(_ nsColor: NSColor) -> NSColor {
        // Convert NSColor to HSB components
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Adjust brightness
        brightness = max(brightness - 0.2, 0.1)
        
        if saturation < 0.9 {
            // Adjust contrast
            saturation = max(0.1, saturation * 3)
        }
        
        // Create new NSColor with modified HSB values
        print("Brightness: \(brightness)")
//        print("Saturation: \(saturation)")
        let modifiedNSColor = NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        
        return modifiedNSColor
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
#endif
