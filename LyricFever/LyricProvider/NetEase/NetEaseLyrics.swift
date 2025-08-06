//
//  NetEaseLyrics.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-05.
//

// From LyricsX: NetEase. Adapted for my needs
struct NetEaseLyrics: Decodable {
    let lrc: Lyric?
    let klyric: Lyric?
    let tlyric: Lyric?
    let lyricUser: User?
    let yrc: Lyric?
    /*
    let sgc: Bool
    let sfy: Bool
    let qfy: Bool
    let code: Int
    let transUser: User
     */
    
    struct User: Decodable {
        let nickname: String
        
        /*
        let id: Int
        let status: Int
        let demand: Int
        let userid: Int
        let uptime: Int
         */
    }
    
    struct Lyric: Decodable {
        let lyric: String?
        
        /*
        let version: Int
         */
    }
}
