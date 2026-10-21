//
//  AppleMusicPlayer.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-18.
//

import ScriptingBridge
import MusicKit
import AppKit

class AppleMusicPlayer: Player {
    var appleMusicScript: MusicApplication? = SBApplication(bundleIdentifier: "com.apple.Music")
    var persistentID: String? {
        appleMusicScript?.currentTrack?.persistentID
    }
    var alternativeID: String? {
        let baseID = (appleMusicScript?.currentTrack?.artist ?? "") + (appleMusicScript?.currentTrack?.name ?? "")
        return baseID.count == 22 ? baseID + "_" : baseID
    }
    
    var albumName: String? {
        appleMusicScript?.currentTrack?.album
    }
    var artistName: String? {
        appleMusicScript?.currentTrack?.artist
    }
    var trackName: String? {
        appleMusicScript?.currentTrack?.name
    }
    
    @MainActor
    var currentTime: TimeInterval? {
        guard let playerPosition = appleMusicScript?.playerPosition else {
            return nil
        }
        let viewmodel = ViewModel.shared
        return playerPosition * 1000 + 400 + (viewmodel.animatedDisplay ? 400 : 0) + (viewmodel.airplayDelay ?  -2000 : 0)
    }
    var duration: Int? {
        guard let seconds = appleMusicScript?.currentTrack?.duration.map(Int.init) else {
            print("Apple Music Player: Couldn't fetch duration")
            return nil
        }
        return seconds * 1000
    }
    
    var isAuthorized: Bool {
        guard isRunning else {
            return false
        }
        if appleMusicScript?.playerState?.rawValue == 0 {
            return false
        }
        return true
    }
    var isPlaying: Bool {
        appleMusicScript?.playerState == .playing
    }
    var isRunning: Bool {
        if NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").first != nil {
            return true
        } else {
            return false
        }
    }
    
    var volume: Int {
        appleMusicScript?.soundVolume ?? 0
    }
    
    func decreaseVolume() {
        guard let soundVolume = appleMusicScript?.soundVolume else {
            return
        }
        appleMusicScript?.setSoundVolume?(soundVolume-5)
    }
    func increaseVolume() {
        guard let soundVolume = appleMusicScript?.soundVolume else {
            return
        }
        appleMusicScript?.setSoundVolume?(soundVolume+5)
    }
    func setVolume(to newVolume: Double) {
        appleMusicScript?.setSoundVolume?(Int(newVolume))
    }
    func togglePlayback() {
        appleMusicScript?.playpause?()
    }
    func rewind() {
        appleMusicScript?.previousTrack?()
    }
    func forward() {
        appleMusicScript?.nextTrack?()
    }
    
    var artworkImage: NSImage?
    
//    var artworkImage: NSImage? {
//        guard let artworkImage = (appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data else {
//            print("AppleMusicPlayer artworkImage: nil data")
//            return nil
//        }
//        return artworkImage
//    }
    
    func activate() {
        appleMusicScript?.activate()
    }
    var currentHoverItem: MenubarButtonHighlight = .activateAppleMusic

    // MARK: Save lyrics into the track's metadata

    enum LyricsWriteResult: CustomStringConvertible {
        case queued
        case written
        case alreadyHasLyrics
        case trackChanged
        case trackNoLongerInLibrary
        case lyricsDontMatchTrack
        case appleCatalogTrack
        case notAvailable
        case writeFailed

        var description: String {
            switch self {
                case .queued: return "queued, will be written once this song stops playing"
                case .written: return "lyrics written"
                case .alreadyHasLyrics: return "skipped, track already has lyrics"
                case .trackChanged: return "skipped, a different track is now playing"
                case .trackNoLongerInLibrary: return "skipped, track is no longer in the library"
                case .lyricsDontMatchTrack: return "skipped, the matched song's title/artist don't match this track"
                case .appleCatalogTrack: return "skipped, Apple Music streaming track (custom lyrics would replace Apple's synced lyrics)"
                case .notAvailable: return "skipped, couldn't read the current track"
                case .writeFailed: return "Music refused the write (track may not be in your library, or the file type doesn't support lyrics)"
            }
        }
    }

    /// Lyrics checked and ready to write, held until the song is no longer playing:
    /// Music pauses the song that's playing when you change its info.
    struct PendingLyricsWrite {
        /// Reference to the concrete track (not "current track"), so it stays valid after the song ends
        let track: MusicTrack
        let persistentID: String
        let lyricsText: String
        let trackName: String
    }

    /// Tracks we never write lyrics into. Apple Music streaming tracks already get Apple's time-synced lyrics
    /// (AppleScript reports them as empty), and custom lyrics would take over Apple's synced view on every device.
    /// Your own files, including iTunes purchases and iCloud-matched songs, do get lyrics written.
    /// Add .purchased / .matched here to skip those too, or remove .subscription to write to everything.
    static var cloudStatusesWithAppleLyrics: Set<MusicEClS> {
        [.subscription]
    }

    /// Checks whether the current track should get these lyrics: it must still be the track we fetched lyrics for,
    /// its title/artist must match the song the lyrics came from, and it must have no lyrics yet.
    /// Doesn't write anything; returns a pending write to perform once the song stops playing.
    func prepareLyricsWrite(_ lyricsText: String, forPersistentID expectedPersistentID: String, matchedTitle: String?, matchedArtist: String?) -> (pending: PendingLyricsWrite?, result: LyricsWriteResult) {
        guard isRunning,
              let liveTrack = appleMusicScript?.currentTrack,
              // "current track" is re-evaluated on every Apple Event. Resolve it to a reference to the concrete
              // track so a song change can't redirect the write to a different song.
              let resolvedTrack = (liveTrack as? SBObject)?.get() as? SBObject else {
            return (nil, .notAvailable)
        }
        // Use it through the MusicTrack protocol (its properties are optional protocol requirements, not SBObject members)
        let track: MusicTrack = resolvedTrack
        guard track.persistentID == expectedPersistentID else {
            return (nil, .trackChanged)
        }
        // Guard against a wrong Spotify match (or a stale result) permanently landing in the library
        guard MusicLibraryLyricsWriter.looselyMatches(track.name, matchedTitle),
              MusicLibraryLyricsWriter.looselyMatches(track.artist, matchedArtist) else {
            return (nil, .lyricsDontMatchTrack)
        }
        if let cloudStatus = track.cloudStatus, AppleMusicPlayer.cloudStatusesWithAppleLyrics.contains(cloudStatus) {
            return (nil, .appleCatalogTrack)
        }
        let existingLyrics = (track.lyrics ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard existingLyrics.isEmpty else {
            return (nil, .alreadyHasLyrics)
        }
        let pending = PendingLyricsWrite(track: track, persistentID: expectedPersistentID, lyricsText: lyricsText, trackName: track.name ?? "?")
        return (pending, .queued)
    }

    /// Writes a pending lyrics write. Call only when that song isn't playing.
    func performLyricsWrite(_ pending: PendingLyricsWrite) -> LyricsWriteResult {
        guard isRunning else {
            return .notAvailable
        }
        // The track may have been deleted since we queued it
        guard pending.track.persistentID == pending.persistentID else {
            return .trackNoLongerInLibrary
        }
        // You may have added lyrics yourself in the meantime
        let existingLyrics = (pending.track.lyrics ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard existingLyrics.isEmpty else {
            return .alreadyHasLyrics
        }
        pending.track.setLyrics?(pending.lyricsText)
        // Read back to confirm Music accepted it (writes fail silently for e.g. non-library tracks)
        let savedLyrics = (pending.track.lyrics ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return savedLyrics.isEmpty ? .writeFailed : .written
    }
}
