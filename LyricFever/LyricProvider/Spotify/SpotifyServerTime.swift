//
//  SpotifyServerTime.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-05.
//


// Spotify TOTP Login Fix
struct SpotifyServerTime: Decodable {
    let serverTime: Int
}