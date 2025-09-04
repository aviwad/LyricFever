//
//  NetworkFetchReturn.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-06.
//

struct NetworkFetchReturn {
    let lyrics: [LyricLine]
    let colorData: Int32?
    
    func processed(withSongName songName: String, duration: Int) -> NetworkFetchReturn {
        let filtered = lyrics.filter { !$0.words.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard lyrics.count > 1 else {
            print("FetchLyrics NetworkFetchReturn: count is less than 2. returning myself")
            return self
        }
        
        let nowPlayingLine = LyricLine(startTime: Double(duration + 5000), words: "Now Playing: \(songName)")
        return NetworkFetchReturn(lyrics: filtered + [nowPlayingLine], colorData: colorData)
    }
}

