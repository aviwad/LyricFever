//
//  Player.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-18.
//

import Foundation
import AppKit

protocol Player {
    // track details
    var albumName: String? { get }
    var artistName: String? { get }
    var trackName: String? { get }
    
    // track timing details
    @MainActor
    var currentTime: TimeInterval? { get }
    var duration: Int? { get }
    
    // player details
    var isAuthorized: Bool { get }
    var isPlaying: Bool { get }
    var isRunning: Bool { get }
    
    // fullscreen functions
    func decreaseVolume()
    func increaseVolume()
    func togglePlayback()
    
    // fullscreen album art
    @MainActor
    var artworkImage: NSImage? { get async }
}
