//
//  NetworkFetchReturn.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-06.
//

struct NetworkFetchReturn {
    let lyrics: [LyricLine]
    let colorData: Int32?

    // Shared with the karaoke panel, which shows this line during an intro when no artist name is
    // available. Keep the two in step so the song opens and closes on the same phrase.
    static func nowPlayingText(songName: String) -> String {
        "Now Playing: \(songName)"
    }

    func processed(withSongName songName: String, duration: Int) -> NetworkFetchReturn {
        let filtered = lyrics.filter { !$0.words.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard lyrics.count > 1 else {
            print("FetchLyrics NetworkFetchReturn: count is less than 2. returning myself")
            return self
        }
        
        let nowPlayingLine = LyricLine(startTime: Double(duration + 5000), words: Self.nowPlayingText(songName: songName))
        return NetworkFetchReturn(lyrics: filtered + [nowPlayingLine], colorData: colorData)
    }
}

