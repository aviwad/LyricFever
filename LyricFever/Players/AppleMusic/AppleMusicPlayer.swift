//
//  AppleMusicPlayer.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-18.
//

import ScriptingBridge
import MusicKit
import AppKit

class AppleMusicPlayer: Player {
    var appleMusicScript: MusicApplication? = SBApplication(bundleIdentifier: "com.apple.Music")
    var persistentID: String? {
        appleMusicScript?.currentTrack?.persistentID
    }
    var alternativeID: String? {
        let baseID = (appleMusicScript?.currentTrack?.artist ?? "") + (appleMusicScript?.currentTrack?.name ?? "")
        return baseID.count == 22 ? baseID + "_" : baseID
    }
    
    var albumName: String? {
        appleMusicScript?.currentTrack?.album
    }
    var artistName: String? {
        appleMusicScript?.currentTrack?.artist
    }
    var trackName: String? {
        appleMusicScript?.currentTrack?.name
    }
    
    @MainActor
    var currentTime: TimeInterval? {
        guard let playerPosition = appleMusicScript?.playerPosition else {
            return nil
        }
        let viewmodel = ViewModel.shared
        return playerPosition * 1000 + 400 + (viewmodel.animatedDisplay ? 400 : 0) + (viewmodel.airplayDelay ?  -2000 : 0)
    }
    var duration: Int? {
        appleMusicScript?.currentTrack?.duration.map(Int.init)
    }
    
    var isAuthorized: Bool {
        guard isRunning else {
            return false
        }
        if appleMusicScript?.playerState?.rawValue == 0 {
            return false
        }
        return true
    }
    var isPlaying: Bool {
        appleMusicScript?.playerState == .playing
    }
    var isRunning: Bool {
        if NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").first != nil {
            return true
        } else {
            return false
        }
    }
    
    var volume: Int {
        appleMusicScript?.soundVolume ?? 0
    }
    
    func decreaseVolume() {
        guard let soundVolume = appleMusicScript?.soundVolume else {
            return
        }
        appleMusicScript?.setSoundVolume?(soundVolume-5)
    }
    func increaseVolume() {
        guard let soundVolume = appleMusicScript?.soundVolume else {
            return
        }
        appleMusicScript?.setSoundVolume?(soundVolume+5)
    }
    func setVolume(to newVolume: Double) {
        appleMusicScript?.setSoundVolume?(Int(newVolume))
    }
    func togglePlayback() {
        appleMusicScript?.playpause?()
    }
    func rewind() {
        appleMusicScript?.previousTrack?()
    }
    func forward() {
        appleMusicScript?.nextTrack?()
    }
    
    var artworkImage: NSImage? {
        guard let artworkImage = (appleMusicScript?.currentTrack?.artworks?().firstObject as? MusicArtwork)?.data else {
            print("AppleMusicPlayer artworkImage: nil data")
            return nil
        }
        return artworkImage
    }
    
    func activate() {
        appleMusicScript?.activate()
    }
}
