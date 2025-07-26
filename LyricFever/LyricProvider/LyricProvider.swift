//
//  LyricProvider.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-25.
//

protocol LyricProvider {
    var providerName: String { get }
    func fetchNetworkLyrics(trackName: String, trackID: String, currentlyPlayingArtist: String?, currentAlbumName: String? ) async throws -> [LyricLine]
}
