//
//  MusicBrainzArtworkService.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//


//
//  MusicBrainz.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-18.
//

import Foundation
import AppKit

class MusicBrainzArtworkService {
    static func findMbid(albumName: String, artistName: String) async -> String? {
//        https://musicbrainz.org/ws/2/release/?query=artist:charli%20xcx%20AND%20album:super%20ultra&fmt=json
        if let mbidUrl = URL(string: "https://musicbrainz.org/ws/2/release/?query=artist:\(artistName) AND album:\(albumName)&fmt=json"), let mbidData = try? await URLSession.shared.data(from: mbidUrl), let mbidResponse = try? JSONDecoder().decode(MusicBrainzReply.self, from: mbidData.0), let mbid = mbidResponse.releases.first?.id {
            return mbid
        }
        
        return nil
    }
    
    static func artworkUrl(_ mbid: String) -> URL? {
        return URL(string:"https://coverartarchive.org/release/\(mbid)/front")
    }
    
    static func artworkImage(for mbid: String) async -> NSImage? {
        guard let artworkUrl = artworkUrl(mbid) else {
            print("\(#function) failed to url")
            return nil
        }
        do {
            let artwork = try await URLSession.shared.data(for: URLRequest(url: artworkUrl))
            return NSImage(data: artwork.0)
        } catch {
            print("\(#function) failed to download artwork \(error)")
            return nil
        }
    }
}
