//
//  LRCLIBLyricProvider.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-06-16.
//

import Foundation

class LRCLIBLyricProvider: LyricProvider {
    var providerName = "LRCLIB Lyric Provider"
    // LRCLIB User Agent
    let LRCLIBUserAgentConfig = URLSessionConfiguration.default
    let LRCLIBUserAgentSession: URLSession
    
    init() {
        LRCLIBUserAgentConfig.httpAdditionalHeaders = ["User-Agent": "Lyric Fever v2.3 (https://github.com/aviwad/LyricFever)"]
        LRCLIBUserAgentSession = URLSession(configuration: LRCLIBUserAgentConfig)
    }
    
    func fetchNetworkLyrics(trackName: String, trackID: String, currentlyPlayingArtist: String?, currentAlbumName: String?) async throws -> NetworkFetchReturn {
        let artist = currentlyPlayingArtist?.replacingOccurrences(of: "&", with: "")
        let album = currentAlbumName?.replacingOccurrences(of: "&", with: "")
        let trackName = trackName.replacingOccurrences(of: "&", with: "")
        if let artist = artist, let album = album, let url = URL(string: "https://lrclib.net/api/get?artist_name=\(artist)&track_name=\(trackName)&album_name=\(album)") {
            print("the lrclib call is \(url.absoluteString)")
            let request = URLRequest(url: url)
            let urlResponseAndData = try await LRCLIBUserAgentSession.data(for: request)
            print(String(describing: urlResponseAndData.0))
            let lrcLyrics = try JSONDecoder().decode(LRCLIBLyrics.self, from: urlResponseAndData.0)
            return NetworkFetchReturn(lyrics: lrcLyrics.lyrics, colorData: nil)
        }
        return NetworkFetchReturn(lyrics: [], colorData: nil)
    }
}
