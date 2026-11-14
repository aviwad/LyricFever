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
    
    init(session: URLSession? = nil) {
//        LRCLIBUserAgentConfig.httpAdditionalHeaders = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_6_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15"]
        LRCLIBUserAgentConfig.httpAdditionalHeaders = ["User-Agent": "Lyric Fever v3.3 (https://github.com/aviwad/LyricFever)"]
        LRCLIBUserAgentSession = session ?? URLSession(configuration: LRCLIBUserAgentConfig)
    }
    
    func fetchNetworkLyrics(trackName: String, trackID: String, currentlyPlayingArtist: String?, currentAlbumName: String?) async throws -> NetworkFetchReturn {
        let duration = ViewModel.shared.duration
        guard let currentlyPlayingArtist, let currentAlbumName else {
            print("artist or album missing")
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }
        guard let url = makeComponents(path: "/api/get", items: [
            URLQueryItem(name: "artist_name", value: currentlyPlayingArtist),
            URLQueryItem(name: "track_name", value: trackName),
            URLQueryItem(name: "album_name", value: currentAlbumName)
        ]).url else {
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }
        print("LRCLIB /api/get: \(url.absoluteString)")
        let req = URLRequest(url: url)
        if let (data, response) = try? await LRCLIBUserAgentSession.data(for: req),
           (response as? HTTPURLResponse)?.statusCode == 200,
           let exact = try? JSONDecoder().decode(LRCLIBLyrics.self, from: data),
           !exact.lyrics.isEmpty {
            return NetworkFetchReturn(lyrics: exact.lyrics, colorData: nil)
        }
        try Task.checkCancellation()
        guard duration > 0,
              let alias = await catalogArtistAlias(track: trackName, artist: currentlyPlayingArtist,
                                                   album: currentAlbumName, duration: Double(duration) / 1000) else {
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }
        try Task.checkCancellation()
        guard let searchURL = makeComponents(path: "/api/search", items: [
            URLQueryItem(name: "track_name", value: trackName),
            URLQueryItem(name: "artist_name", value: alias)
        ]).url else { return NetworkFetchReturn(lyrics: [], colorData: nil) }
        let (data, _) = try await LRCLIBUserAgentSession.data(from: searchURL)
        let candidates = try JSONDecoder().decode(PluralLRCLIBLyrics.self, from: data).lyrics.filter {
            normalized($0.trackName) == normalized(trackName) &&
            normalized($0.artistName) == normalized(alias) &&
            abs($0.duration - Double(duration) / 1000) <= 2 && !$0.lyrics.isEmpty
        }
        // Different recordings with identical metadata should be selected manually.
        guard let first = candidates.first,
              candidates.allSatisfy({ $0.syncedLyrics == first.syncedLyrics }) else {
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }
        return NetworkFetchReturn(lyrics: first.lyrics, colorData: nil)
    }

    private struct CatalogResponse: Decodable {
        let results: [CatalogTrack]
    }

    private struct CatalogTrack: Decodable {
        let trackId: Int?
        let artistId: Int?
        let trackName: String?
        let artistName: String?
        let collectionName: String?
        let trackTimeMillis: Int?
    }

    private func normalized(_ value: String) -> String {
        let simplified = value.applyingTransform(StringTransform("Hant-Hans"), reverse: false) ?? value
        return simplified.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .filter { $0.isLetter || $0.isNumber }
    }

    private func catalogArtistAlias(track: String, artist: String, album: String, duration: Double) async -> String? {
        guard artist.unicodeScalars.contains(where: { (0x3400...0x9FFF).contains($0.value) }) else { return nil }
        func url(path: String, items: [URLQueryItem]) -> URL? {
            var components = URLComponents()
            components.scheme = "https"
            components.host = "itunes.apple.com"
            components.path = path
            components.queryItems = items
            return components.url
        }
        guard let search = url(path: "/search", items: [
            URLQueryItem(name: "term", value: "\(track) \(artist)"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "country", value: "hk"),
            URLQueryItem(name: "limit", value: "50")
        ]) else { return nil }
        do {
            var request = URLRequest(url: search)
            request.timeoutInterval = 8
            let (data, _) = try await LRCLIBUserAgentSession.data(for: request)
            let matches = try JSONDecoder().decode(CatalogResponse.self, from: data).results.filter {
                guard let name = $0.trackName, let singer = $0.artistName, let ms = $0.trackTimeMillis else { return false }
                return normalized(name) == normalized(track) && normalized(singer) == normalized(artist) &&
                    abs(Double(ms) / 1000 - duration) <= 2
            }
            guard !matches.isEmpty, Set(matches.compactMap(\.artistId)).count == 1 else { return nil }
            let match = matches.first(where: { normalized($0.collectionName ?? "") == normalized(album) }) ?? matches[0]
            guard let trackID = match.trackId, let artistID = match.artistId,
                  let lookup = url(path: "/lookup", items: [URLQueryItem(name: "id", value: String(trackID)), URLQueryItem(name: "country", value: "us")]) else { return nil }
            var lookupRequest = URLRequest(url: lookup)
            lookupRequest.timeoutInterval = 8
            let (lookupData, _) = try await LRCLIBUserAgentSession.data(for: lookupRequest)
            guard let resolved = try JSONDecoder().decode(CatalogResponse.self, from: lookupData).results.first,
                  resolved.trackId == trackID, resolved.artistId == artistID,
                  let alias = resolved.artistName, normalized(alias) != normalized(artist) else { return nil }
            return alias
        } catch {
            return nil
        }
    }
    
    func fetchNetworkLyrics2(trackName: String, trackID: String, currentlyPlayingArtist: String?, currentAlbumName: String?) async throws -> NetworkFetchReturn {
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
    
    func search(trackName: String, artistName: String) async throws -> [SongResult] {
        guard let url = makeComponents(path: "/api/search", items: [
            URLQueryItem(name: "track_name", value: trackName),
            URLQueryItem(name: "artist_name", value: artistName)
        ]).url else {
            print("MassSearch: LRCLIB: failed to generate URl")
            return []
        }
        print("LRCLIB /api/search: \(url.absoluteString)")
        let req = URLRequest(url: url)
        print("The request is \(req)")
        let urlResponseAndData = try await LRCLIBUserAgentSession.data(for: req)
        let lrcLyrics = try JSONDecoder().decode(PluralLRCLIBLyrics.self, from: urlResponseAndData.0)
        print("lrc downloaded")
        var results: [SongResult] = []
        for lyric in lrcLyrics.lyrics {
            print("lrc lyric: \(lyric.name)")
            results.append(SongResult(lyricType: "LRCLIB", songName: lyric.trackName, albumName: lyric.albumName, artistName: lyric.artistName, lyrics: lyric.lyrics))
        }
        return results
    }
    
    func makeComponents(path: String, items: [URLQueryItem]) -> URLComponents {
        var comps = URLComponents()
        comps.scheme = "https"
        comps.host = "lrclib.net"
        comps.path = path
        comps.queryItems = items
        return comps
    }
}
