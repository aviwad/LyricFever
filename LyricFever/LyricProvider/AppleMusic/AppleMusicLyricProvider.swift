//
//  AppleMusicLyricProvider.swift
//  Lyric Fever
//
//  Top-tier lyric source for tracks playing through Music.app that have a
//  known Apple Music catalog (Adam) ID. Returns Apple's TTML parsed into
//  LyricLine values via TTMLParser.
//

import Foundation
import MusicKit

@MainActor
final class AppleMusicLyricProvider: LyricProvider {
    let providerName: String = "apple_music"

    /// `trackID` is expected to be the Apple Music catalog ID captured by
    /// AppleMusicMetadataObserver. If empty we return an empty result rather
    /// than throwing, so the ViewModel chain falls through to the next provider.
    func fetchNetworkLyrics(
        trackName: String,
        trackID: String,
        currentlyPlayingArtist: String?,
        currentAlbumName: String?
    ) async throws -> NetworkFetchReturn {
        guard !trackID.isEmpty else {
            print("AppleMusicLyricProvider: no catalog ID, skipping")
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }

        let auth = AppleMusicAuthManager.shared
        guard auth.isAuthorized else {
            print("AppleMusicLyricProvider: not authorized, skipping")
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }

        // MusicDataRequest handles developer token + user token injection.
        // {{storefront}} is substituted by MusicKit with the signed-in user's
        // storefront code (e.g. "us", "jp"). If MusicKit doesn't substitute it,
        // fall back to the literal "us" in the caller-fix path.
        guard let url = URL(string: "https://api.music.apple.com/v1/catalog/{{storefront}}/songs/\(trackID)/lyrics") else {
            print("AppleMusicLyricProvider: could not construct URL for trackID=\(trackID)")
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }

        let request = MusicDataRequest(urlRequest: URLRequest(url: url))
        let response: MusicDataResponse

        do {
            response = try await request.response()
        } catch {
            print("AppleMusicLyricProvider: MusicDataRequest error: \(error)")
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }

        let statusCode = response.urlResponse.statusCode
        guard statusCode == 200 else {
            print("AppleMusicLyricProvider: HTTP \(statusCode) for trackID=\(trackID)")
            if statusCode == 401 || statusCode == 403 {
                auth.invalidate()
            }
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }

        // Apple wraps TTML in: { "data": [ { "attributes": { "ttml": "<?xml..." } } ] }
        struct LyricsEnvelope: Decodable {
            struct Datum: Decodable {
                struct Attributes: Decodable {
                    let ttml: String?
                }
                let attributes: Attributes
            }
            let data: [Datum]
        }

        let envelope: LyricsEnvelope
        do {
            envelope = try JSONDecoder().decode(LyricsEnvelope.self, from: response.data)
        } catch {
            print("AppleMusicLyricProvider: JSON decode error: \(error)")
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }

        guard let ttmlString = envelope.data.first?.attributes.ttml,
              let ttmlData = ttmlString.data(using: .utf8) else {
            print("AppleMusicLyricProvider: no TTML in response for trackID=\(trackID)")
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }

        let lines: [LyricLine]
        do {
            lines = try TTMLParser.parse(ttmlData)
        } catch {
            print("AppleMusicLyricProvider: TTMLParser error: \(error)")
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }

        guard !lines.isEmpty else {
            print("AppleMusicLyricProvider: TTMLParser returned 0 lines (instrumental?) for trackID=\(trackID)")
            return NetworkFetchReturn(lyrics: [], colorData: nil)
        }

        print("AppleMusicLyricProvider: \(lines.count) lines for trackID=\(trackID)")
        return NetworkFetchReturn(lyrics: lines, colorData: nil)
    }

    func search(trackName: String, artistName: String) async throws -> [SongResult] {
        return []
    }
}
