//
//  lyricsFetcher.swift
//  SpotifyLyricsInMenubar
//
//  Created by Avi Wadhwa on 02/08/23.
//

import Foundation

actor lyricsFetcher {
    func fetchLyrics(for trackID: String?) async -> [LyricLine]? {
        if let trackID, let url = URL(string: "https://spotify-lyric-api.herokuapp.com/?trackid=\(trackID)"), let urlResponseAndData = try? await URLSession.shared.data(from: url), let lyrics = try? JSONDecoder().decode(LyricJson.self, from: urlResponseAndData.0) {
            return lyrics.lines
        }
        return nil
    }
}
