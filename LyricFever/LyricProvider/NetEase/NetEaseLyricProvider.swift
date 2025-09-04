//
//  NetEaseLyricsProvider.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-06-16.
//

import Foundation
import StringMetric

class NetEaseLyricProvider: LyricProvider {
    var providerName = "NetEase Lyric Provider"
    // Fake Spotify User Agent
    // Spotify's started blocking my app's useragent. A win honestly 🤣
    let fakeSpotifyUserAgentconfig = URLSessionConfiguration.default
    let fakeSpotifyUserAgentSession: URLSession
    
    init() {
        // Set user agents for Spotify and LRCLIB
        fakeSpotifyUserAgentconfig.httpAdditionalHeaders = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Safari/605.1.15"]
        fakeSpotifyUserAgentSession = URLSession(configuration: fakeSpotifyUserAgentconfig)
    }
    
    func fetchNetworkLyrics(trackName: String, trackID: String, currentlyPlayingArtist: String?, currentAlbumName: String? ) async throws -> NetworkFetchReturn {
        if let currentlyPlayingArtist, let currentAlbumName, let url = URL(string: "https://neteasecloudmusicapi-ten-wine.vercel.app/search?keywords=\(trackName.replacingOccurrences(of: "&", with: "%26")) \(currentlyPlayingArtist.replacingOccurrences(of: "&", with: "%26"))&limit=1") {
            print("the netease search call is \(url.absoluteString)")
            let request = URLRequest(url: url)
            let urlResponseAndData = try await fakeSpotifyUserAgentSession.data(for: request)
            let neteasesearch = try JSONDecoder().decode(NetEaseSearch.self, from: urlResponseAndData.0)
            print(neteasesearch)
            guard let neteaseResult = neteasesearch.result.songs.first, let neteaseArtist = neteaseResult.artists.first else {
                return NetworkFetchReturn(lyrics: [], colorData: nil)
            }
            let neteaseId = neteaseResult.id
            let conditions = [
                trackName.distance(between: neteaseResult.name) > 0.75,
                currentlyPlayingArtist.distance(between: neteaseArtist.name) > 0.75,
                currentAlbumName.distance(between: neteaseResult.album.name) > 0.75
            ]

            let trueCount = conditions.filter { $0 }.count
            print("Similarity index: for track \(trackName) and netease reply \(neteaseResult.name) is \(trackName.distance(between: neteaseResult.name))")
            print("Similarity index: for album \(currentAlbumName) and netease reply \(neteaseResult.album.name) is \(currentAlbumName.distance(between: neteaseResult.album.name))")
            print("Similarity index: for artist \(currentlyPlayingArtist) and netease reply \(neteaseArtist.name) is \(currentlyPlayingArtist.distance(between: neteaseArtist.name))")
            // I need at least 2 conditions to be met: track name, or album, or artist name, match 75% of the way
            if trueCount < 2 {
                print("similarity conditions passed for NetEase: \(trueCount) is less than 2, therefore failing this NetEase search.")
                return NetworkFetchReturn(lyrics: [], colorData: nil)
            }
            let lyricRequest = URLRequest(url: URL(string: "https://neteasecloudmusicapi-ten-wine.vercel.app/lyric?id=\(neteaseId)")!)
            let urlResponseAndDataLyrics = try await fakeSpotifyUserAgentSession.data(for: lyricRequest)
            let neteaseLyrics = try JSONDecoder().decode(NetEaseLyrics.self, from: urlResponseAndDataLyrics.0)
            guard let neteaselrc = neteaseLyrics.lrc, let neteaseLrcString = neteaselrc.lyric else {
                return NetworkFetchReturn(lyrics: [], colorData: nil)
            }
            
            // Sanitize HTML entities and stray escapes before parsing
            let cleaned = unescapeHTMLEntities(in: neteaseLrcString)
            
            let parser = LyricsParser(lyrics: cleaned)
            print(parser.lyrics)
            // NetEase incorrectly advertises lyrics for EVERY song when it only has the name, artist, composer at 0.0 *sigh*
            if parser.lyrics.last?.startTimeMS == 0.0 {
                return NetworkFetchReturn(lyrics: [], colorData: nil)
            }
            return NetworkFetchReturn(lyrics: parser.lyrics, colorData: nil)
        }
        return NetworkFetchReturn(lyrics: [], colorData: nil)
    }
}

// MARK: - HTML entity unescape
private func unescapeHTMLEntities(in text: String) -> String {
    var s = text
    // Common named entities
    s = s.replacingOccurrences(of: "&apos;", with: "'")
    s = s.replacingOccurrences(of: "&quot;", with: "\"")
    s = s.replacingOccurrences(of: "&amp;", with: "&")
    s = s.replacingOccurrences(of: "&lt;", with: "<")
    s = s.replacingOccurrences(of: "&gt;", with: ">")
    // Common numeric entity often used for apostrophe
    s = s.replacingOccurrences(of: "&#39;", with: "'")
    s = s.replacingOccurrences(of: "&#x27;", with: "'")
    // Normalize stray backslashes that sometimes trail lines from API payloads
    // Keep escaped newlines for LyricsParser to convert, but remove trailing backslashes.
    s = s.replacingOccurrences(of: "\\\n", with: "\n")
    // If payload includes escaped newline markers already, LyricsParser handles "\\n" -> "\n".
    return s
}
