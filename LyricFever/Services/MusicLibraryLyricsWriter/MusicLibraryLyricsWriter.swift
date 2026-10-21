//
//  MusicLibraryLyricsWriter.swift
//  Lyric Fever
//
//  When Lyric Fever shows lyrics for a song playing in Apple Music, also store them
//  (as plain text) in the track's own Lyrics field so they live in your Music library
//  and the file's tags. Tracks that already have lyrics are never touched.
//

#if os(macOS)
import Foundation

enum MusicLibraryLyricsWriter {
    /// Converts Lyric Fever's timed lines into plain text, one lyric per line.
    /// Returns nil when there's nothing worth saving.
    static func plainText(from lyrics: [LyricLine]) -> String? {
        var lines = lyrics.map { $0.words.trimmingCharacters(in: .whitespacesAndNewlines) }
        // Lyric Fever appends a "Now Playing: <song>" line after the song ends; it isn't part of the lyrics
        while let lastLine = lines.last, lastLine.isEmpty || lastLine.hasPrefix("Now Playing: ") {
            lines.removeLast()
        }
        // Drop blank lines and instrumental-break markers like "♪"
        lines = lines.filter { !$0.isEmpty && !isInstrumentalMarker($0) }
        guard !lines.isEmpty else {
            return nil
        }
        return lines.joined(separator: "\n")
    }

    private static func isInstrumentalMarker(_ line: String) -> Bool {
        line.allSatisfy { "♪♫♬♩ .…".contains($0) }
    }

    /// Loose title/artist comparison that tolerates the usual differences between Spotify and Apple Music
    /// metadata: case, accents, punctuation, "(Remastered 2011)", " - Single Version", "feat. X", "A & B" vs "A".
    static func looselyMatches(_ musicValue: String?, _ matchedValue: String?) -> Bool {
        guard let musicValue, let matchedValue else {
            return false
        }
        let a = normalized(musicValue)
        let b = normalized(matchedValue)
        guard !a.isEmpty, !b.isEmpty else {
            // e.g. a title made only of symbols: fall back to a plain comparison
            return musicValue.lowercased() == matchedValue.lowercased()
        }
        if a == b {
            return true
        }
        return min(a.count, b.count) >= 3 && (a.contains(b) || b.contains(a))
    }

    private static func normalized(_ value: String) -> String {
        var text = value.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
        // Drop "(...)" and "[...]" parts
        text = text.replacingOccurrences(of: #"\([^)]*\)|\[[^\]]*\]"#, with: " ", options: .regularExpression)
        // Drop " - Remastered 2011" style suffixes
        if let dashRange = text.range(of: " - ") {
            text = String(text[..<dashRange.lowerBound])
        }
        // Drop "feat. X" / "ft. X" / "featuring X"
        if let featRange = text.range(of: #"\s(feat\.?|ft\.?|featuring)\s"#, options: .regularExpression) {
            text = String(text[..<featRange.lowerBound])
        }
        // Keep letters and digits only (any script)
        return String(text.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }.map(Character.init))
    }
}

extension ViewModel {
    /// Checks the song that just loaded lyrics and, if it should get them, queues the write.
    /// Writing happens later (see flushPendingMusicLyricsWrites) because Music pauses a song when its info changes.
    func saveLyricsToMusicLibraryIfNeeded(_ lyrics: [LyricLine]) {
        guard userDefaultStorage.saveLyricsToMusicLibrary,
              currentPlayer == .appleMusic,
              let persistentID = currentlyPlayingAppleMusicPersistentID,
              let currentlyPlaying,
              // cheap check first, before any database or AppleScript work
              let lyricsText = MusicLibraryLyricsWriter.plainText(from: lyrics) else {
            return
        }
        // These lyrics belong to `currentlyPlaying`. Make sure that's the song Music is on right now
        // (the persistent ID updates a moment before the lyrics for the new song arrive).
        guard fetchSpotifyIDFromPersistentIDCoreData() == currentlyPlaying else {
            print("Save Lyrics to Music: skipped, lyrics don't match the Music track that's playing")
            return
        }
        // currentlyPlayingName / Artist are the details of the song the lyrics were fetched for
        let (pending, result) = appleMusicPlayer.prepareLyricsWrite(lyricsText, forPersistentID: persistentID, matchedTitle: currentlyPlayingName, matchedArtist: currentlyPlayingArtist)
        print("Save Lyrics to Music (\(currentlyPlayingName ?? "?")): \(result)")
        if let pending {
            pendingMusicLyricsWrites[pending.persistentID] = pending
        }
    }
    
    /// Writes queued lyrics for songs that are no longer playing. Called on every Music playback notification
    /// (track change, pause, stop) and when Lyric Fever quits.
    /// - Parameter includePausedCurrentTrack: also write the current song if Music isn't playing it (used at quit).
    func flushPendingMusicLyricsWrites(includePausedCurrentTrack: Bool = false) {
        guard !pendingMusicLyricsWrites.isEmpty else {
            return
        }
        guard appleMusicPlayer.isRunning else {
            // Music quit, so the queued track references are stale. Those songs get re-checked next time they play.
            pendingMusicLyricsWrites.removeAll()
            return
        }
        let currentPersistentID = appleMusicPlayer.persistentID
        let musicIsPlaying = appleMusicPlayer.isPlaying
        for (persistentID, pending) in pendingMusicLyricsWrites {
            if persistentID == currentPersistentID && (musicIsPlaying || !includePausedCurrentTrack) {
                // Still the current song: writing now would pause it
                continue
            }
            let result = appleMusicPlayer.performLyricsWrite(pending)
            print("Save Lyrics to Music (\(pending.trackName)): \(result)")
            pendingMusicLyricsWrites[persistentID] = nil
        }
    }
}
#endif
