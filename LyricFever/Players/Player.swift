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
//    var artworkImageURL: URL? { get }
    
    // menubar behaviour
    func activate()
    var currentHoverItem: MenubarButtonHighlight { get }
}

extension Player {
    var durationAsTimeInterval: TimeInterval? {
        if let duration {
            return TimeInterval(duration*1000)
        } else {
            return nil
        }
    }
    
    func artwork(for artworkURL: URL) async -> NSImage? {
        do {
            let artwork = try await URLSession.shared.data(for: URLRequest(url: artworkURL))
            return NSImage(data: artwork.0)
        } catch {
            print("\(#function) failed to download artwork \(error)")
            return nil
        }
    }
    
    func shareURL(for currentlyPlaying: String?) -> URL? {
        guard let currentlyPlaying, currentlyPlaying.count == 22 else {
            return nil
        }
        return URL(string: "http://open.spotify.com/track/\(currentlyPlaying)")
    }
}
