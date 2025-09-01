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
    
    // additional menubar functions
    var volume: Int { get }
    
    // fullscreen functions
    func decreaseVolume()
    func increaseVolume()
    func setVolume(to newVolume: Double)
    func togglePlayback()
    func rewind()
    func forward()
    
    // fullscreen album art
    @MainActor
    var artworkImage: NSImage? { get async }
    
    // menubar behaviour
    func activate()
}

extension Player {
    var durationAsTimeInterval: TimeInterval? {
        if let duration {
            return TimeInterval(duration*1000)
        } else {
            return nil
        }
    }
}
