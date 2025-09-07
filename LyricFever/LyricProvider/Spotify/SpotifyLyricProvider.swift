//
//  SpotifyLyricsProvider.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-06-16.
//

import Foundation
import SwiftOTP


struct SpotifyLyrics: Decodable {
    let downloadDate: Date
    let language: String
    let lyrics: [LyricLine]
    
    enum CodingKeys: String, CodingKey {
        case lines, language, syncType
    }
    
    init(from decoder: Decoder) throws {
        self.downloadDate = Date.now
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.language = (try? container.decode(String.self, forKey: .language)) ?? ""
        if let syncType = try? container.decode(String.self, forKey: .syncType), syncType == "LINE_SYNCED", var lyrics = try? container.decode([LyricLine].self, forKey: .lines) {
            self.lyrics = lyrics
        } else {
            self.lyrics = []
        }
    }
}


enum SpotifyLyricError: Error {
    case isLocalFile
    case tooManyTries
}

enum AccessTokenError: Error {
    case badSecret
    case badURL
}
struct SecretVersion: Codable {
    let version: Int
    let secret: [Int]
}


class SpotifyLyricProvider: LyricProvider {
    var providerName = "Spotify Lyric Provider"
    // Authentication tokens
    var accessToken: AccessTokenJSON?
    
    var isAccessTokenAlive: Bool {
        guard let expiration = accessToken?.accessTokenExpirationTimestampMs else { return false }
        return expiration > Date().timeIntervalSince1970 * 1000
    }
    
    // Fake Spotify User Agent
    // Spotify's started blocking my app's useragent. A win honestly 🤣
    let fakeSpotifyUserAgentconfig = URLSessionConfiguration.default
    let fakeSpotifyUserAgentSession: URLSession
    
    init() {
        // Set user agents for Spotify and LRCLIB
        fakeSpotifyUserAgentconfig.httpAdditionalHeaders = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Safari/605.1.15"]
        fakeSpotifyUserAgentSession = URLSession(configuration: fakeSpotifyUserAgentconfig)
    }
    
    @MainActor
    var secretData: [Int] {
        get async throws {
            guard let url = URL(string: "https://github.com/Thereallo1026/spotify-secrets/blob/main/secrets/secretBytes.json?raw=true") else {
                throw URLError(.badURL)
            }
            let (data, _) = try await URLSession.shared.data(from: url)
            let secretVersions = try JSONDecoder().decode([SecretVersion].self, from: data)
            guard let firstSecret = secretVersions.first?.secret else {
                throw NSError(domain: "SpotifyLyricProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "No secret found"])
            }
            print("Secret is \(firstSecret)")
            return firstSecret
        }
    }
    
    @MainActor
    func generateAccessToken() async throws {
        // NEW: generate HOTP for Spotify
        // Thanks to Mxlris-LyricsX-Project and latest info
        if !isAccessTokenAlive {
                // 1. Fetch server time
                let serverTimeRequest = URLRequest(url: .init(string: "https://open.spotify.com/api/server-time")!)
                let serverTimeData = try await fakeSpotifyUserAgentSession.data(for: serverTimeRequest).0
                let serverTime = try JSONDecoder().decode(SpotifyServerTime.self, from: serverTimeData).serverTime

                // 2. Compute counter as (current unix timestamp in seconds / 30).floor
                let currentUnix = Int(Date().timeIntervalSince1970)
                let counter = UInt64(currentUnix / 30)

                // 3. Compute HOTP using same secret as TOTPGenerator
                let secretCipher = try await secretData//[70,60,33,57,92,120,90,33,32,62,62,55,126,93,66,35,108,68]
                var processed = [UInt8]()
                for (i, byte) in secretCipher.enumerated() {
                    processed.append(UInt8(byte ^ (i % 33 + 9)))
                }
                let processedStr = processed.map { String($0) }.joined()
                guard let utf8Bytes = processedStr.data(using: .utf8) else {
                    throw AccessTokenError.badSecret
                }
                let secretBase32 = utf8Bytes.base32EncodedString
                guard let secretData = base32DecodeToData(secretBase32) else {
                    throw AccessTokenError.badSecret
                }
                guard let hotp = HOTP(secret: secretData, digits: 6, algorithm: .sha1)?.generate(counter: counter) else {
                    throw AccessTokenError.badSecret
                }

                // 4. Build URL using new schema (example buildVer/buildDate; update as needed)
                let buildVer = "web-player_2025-06-10_1749524883369_eef30f4"
                let buildDate = "2025-06-10"
                let urlString = "https://open.spotify.com/api/token?reason=init&productType=web-player&totp=\(hotp)&totpServer=\(hotp)&totpVer=5&sTime=\(serverTime)&cTime=\(currentUnix)&buildVer={\"\(buildVer)\"}&buildDate={\"\(buildDate)\"}"
                guard let url = URL(string: urlString) else {
                    throw AccessTokenError.badURL
                }

                var request = URLRequest(url: url)
                request.setValue("sp_dc=\(ViewModel.shared.userDefaultStorage.cookie)", forHTTPHeaderField: "Cookie")
                let accessTokenData = try await fakeSpotifyUserAgentSession.data(for: request)
                print(String(decoding: accessTokenData.0, as: UTF8.self))
                do {
                    accessToken = try JSONDecoder().decode(AccessTokenJSON.self, from: accessTokenData.0)
                    print("ACCESS TOKEN IS SAVED")
                } catch {
                    do {
                        let errorWrap = try JSONDecoder().decode(ErrorWrapper.self, from: accessTokenData.0)
                        if errorWrap.error.code == 401 {
                            UserDefaults().set(false, forKey: "hasOnboarded")
                        }
                    } catch {
                        // silently fail
                    }
                    print("json error decoding the access token, therefore bad cookie therefore un-onboard")
                }
        }
    }
    
//    @MainActor
//    func checkHeartedStatusFor(trackID: String) async throws -> Bool {
//        try await generateAccessToken()
//        if let accessToken, let url = URL(string: "https://api.spotify.com/v1/me/tracks/contains?ids=\(trackID)") {
//            var request = URLRequest(url: url)
////            request.addValue("WebPlayer", forHTTPHeaderField: "app-platform")
//            print("the access token is \(accessToken.accessToken)")
//            request.addValue("Bearer \(accessToken.accessToken)", forHTTPHeaderField: "authorization")
//            print("Requesting Spotify hearted boolean for track ID \(trackID)")
//            try Task.checkCancellation()
//            let urlResponseAndData = try await fakeSpotifyUserAgentSession.data(for: request)
//            print(String(bytes: urlResponseAndData.0, encoding: String.Encoding.utf8))
//            let result = try JSONDecoder().decode([Bool].self, from: urlResponseAndData.0)
//            guard let resultBool = result.first else {
//                print("Spotify hearted status returned an empty bool")
//                return false
//            }
//            return resultBool
//        }
//        return false
//    }

    @MainActor
    func fetchNetworkLyrics(trackName: String, trackID: String, currentlyPlayingArtist: String? = nil, currentAlbumName: String? = nil ) async throws -> NetworkFetchReturn {
//        try? await Task.sleep(for: .seconds(2))
        // Local file giveaway
        if trackID.count != 22 {
            throw SpotifyLyricError.isLocalFile
        }
        
        try await generateAccessToken()
        if let accessToken, let url = URL(string: "https://spclient.wg.spotify.com/color-lyrics/v2/track/\(trackID)?format=json&vocalRemoval=false") {
            var request = URLRequest(url: url)
            request.addValue("WebPlayer", forHTTPHeaderField: "app-platform")
            print("the access token is \(accessToken.accessToken)")
            request.addValue("Bearer \(accessToken.accessToken)", forHTTPHeaderField: "authorization")
            print("Requesting Spotify lyric data")
            try Task.checkCancellation()
            let urlResponseAndData = try await fakeSpotifyUserAgentSession.data(for: request)
            
            // Song lyrics don't exist on Spotify
            if urlResponseAndData.0.isEmpty {
                return NetworkFetchReturn(lyrics: [], colorData: nil)
            }

            if String(decoding: urlResponseAndData.0, as: UTF8.self) == "too many requests" {
                throw SpotifyLyricError.tooManyTries
            }
            let spotifyParent = try JSONDecoder().decode(SpotifyParent.self, from: urlResponseAndData.0)
            print("Successfully fetched Spotify lyric data")
            return NetworkFetchReturn(lyrics: spotifyParent.lyrics.lyrics, colorData: Int32(spotifyParent.colors.background))
        }
        return NetworkFetchReturn(lyrics: [], colorData: nil)
    }
    
    
    func getDetailsFromSpotifyInternalSearchJSON(data: Data) -> AppleMusicHelper? {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let dataDict = json["data"] as? [String: Any],
               let searchV2 = dataDict["searchV2"] as? [String: Any],
               let tracksV2 = searchV2["tracksV2"] as? [String: Any],
               let items = tracksV2["items"] as? [[String: Any]],
               let firstItem = items.first,
               let item = firstItem["item"] as? [String: Any],
               let dataObj = item["data"] as? [String: Any] {
                
                let trackName: String? = dataObj["name"] as? String
                let trackID: String?  = dataObj["id"] as? String
                
                let album = dataObj["albumOfTrack"] as? [String: Any]
                let albumName: String? = album?["name"] as? String
                
                let artistName: String?
                if let artists = dataObj["artists"] as? [String: Any],
                   let artistItems = artists["items"] as? [[String: Any]],
                   let firstArtist = artistItems.first,
                   let profile = firstArtist["profile"] as? [String: Any] {
                    artistName = profile["name"] as? String
                } else {
                    artistName = nil
                }
                
                if let trackID, let trackName, let albumName, let artistName {
                    print("Apple Music Network Fetch: Internal Search Success")
                    print("Track name: \(trackName)")
                    print("Artist name: \(artistName)")
                    print("Album name: \(albumName)")
                    print("Track ID: \(trackID)")
                    return AppleMusicHelper(SpotifyID: trackID, SpotifyName: trackName, SpotifyArtist: artistName, SpotifyAlbum: albumName)
                }
            }
        } catch {
            print("Error parsing JSON: \(error)")
        }
        return nil
    }
    
    func search(trackName: String, artistName: String) async throws -> [SongResult] {
        let appleMusicHelper = try await searchForTrackForAppleMusic(artist: artistName, track: trackName)
        guard let appleMusicHelper else {
            print("MassSearch: SpotifyLyricProvider, couldn't fetch ID for the searchTerm \(trackName) \(artistName)")
            return []
        }
        let spotifyID = appleMusicHelper.SpotifyID
        let lyrics = try await fetchNetworkLyrics(trackName: trackName, trackID: spotifyID)
        if lyrics.lyrics == [] {
            print("MassSearch: SpotifyLyricProvider, empty lyrics")
            return []
        } else {
            let songResult = SongResult(lyricType: "Spotify", songName: appleMusicHelper.SpotifyName, albumName: appleMusicHelper.SpotifyAlbum, artistName: appleMusicHelper.SpotifyArtist, lyrics: lyrics.lyrics)
            return [songResult]
        }
    }
    
    #if os(macOS)
    @MainActor
    func searchForTrackForAppleMusic(artist: String, track: String, album: String? = nil) async throws -> AppleMusicHelper? {
        try await generateAccessToken()
        if let url = URL(string: "https://api-partner.spotify.com/pathfinder/v2/query") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("WebPlayer", forHTTPHeaderField: "app-platform")
            request.addValue("Bearer \(accessToken?.accessToken ?? "")", forHTTPHeaderField: "authorization")
            let searchTerm: String
            if let album {
                searchTerm = "\(track) \(album) \(artist)"
            } else {
                searchTerm = "\(track) \(artist)"
            }
            let body: [String: Any] = [
                "variables": [
                    "searchTerm": searchTerm,
                    "offset": 0,
                    "limit": 1,
                    "numberOfTopResults": 1,
                    "includeAudiobooks": false,
                    "includeArtistHasConcertsField": false,
                    "includePreReleases": false,
                    "includeLocalConcertsField": false,
                    "includeAuthors": false
                ],
                "operationName": "searchDesktop",
                "extensions": [
                    "persistedQuery": [
                        "version": 1,
                        "sha256Hash": "d9f785900f0710b31c07818d617f4f7600c1e21217e80f5b043d1e78d74e6026"
                    ]
                ]
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            try Task.checkCancellation()
            let searchData = try await fakeSpotifyUserAgentSession.data(for: request)
            return getDetailsFromSpotifyInternalSearchJSON(data: searchData.0)
//            if let searchData = try await fakeSpotifyUserAgentSession.data(for: request), !searchData.0.isEmpty, let searchResponse = try? JSONDecoder().decode(SpotifyResponse.self, from: searchData.0), let track = searchResponse.tracks.items.first, let firstArtistName = track.firstArtistName {
//                print("Got ID with manual search")
//                return AppleMusicHelper(SpotifyID: track.id, SpotifyName: track.name, SpotifyArtist: firstArtistName)
//            } else {
//                return nil
//            }
        } else {
            print("\(#function) we expected url")
            return nil
        }
    }
    #endif
}

