//
//  SpotifyPlayer.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-18.
//

import ScriptingBridge
import AppKit

class SpotifyPlayer: @MainActor Player {
    var spotifyScript: SpotifyApplication? = SBApplication(bundleIdentifier: "com.spotify.client")
    var trackID: String? {
        spotifyScript?.currentTrack?.spotifyUrl?.spotifyProcessedUrl()
    }
    @MainActor
    func fixSpotifyLyricDrift() async throws {
        try await Task.sleep(nanoseconds: 2000000000)
        if isPlaying {
            print("LYRIC UPDATER'S LYRIC DRIFT FIX CALLED")
            spotifyScript?.play?()
        }
    }
    
    var albumName: String? {
        spotifyScript?.currentTrack?.album
    }
    var artistName: String? {
        spotifyScript?.currentTrack?.artist
    }
    var trackName: String? {
        spotifyScript?.currentTrack?.name
    }
    
    @MainActor
    var currentTime: TimeInterval? {
        guard let playerPosition = spotifyScript?.playerPosition else {
            return nil
        }
        let viewmodel = ViewModel.shared
        return playerPosition * 1000 + (viewmodel.spotifyConnectDelay ? Double(viewmodel.userDefaultStorage.spotifyConnectDelayCount) : 0) + (viewmodel.animatedDisplay ? 400 : 0) + (viewmodel.airplayDelay ?  -2000 : 0)
    }
    
    var duration: Int? {
        spotifyScript?.currentTrack?.duration
    }
    var isRunning: Bool {
        if NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").first != nil {
            return true
        } else {
            return false
        }
    }
    var isPlaying: Bool {
        spotifyScript?.playerState == .playing
    }
    var isAuthorized: Bool {
        guard isRunning else {
            return false
        }
        print("Raw value player state \(spotifyScript?.playerState?.rawValue)")
        if spotifyScript?.playerState?.rawValue == 0 {
            return false
        }
        return true
    }
    
    func decreaseVolume() {
        guard let soundVolume = spotifyScript?.soundVolume else {
            return
        }
        spotifyScript?.setSoundVolume?(soundVolume-5)
    }
    func increaseVolume() {
        guard let soundVolume = spotifyScript?.soundVolume else {
            return
        }
        spotifyScript?.setSoundVolume?(soundVolume+5)
    }
    func togglePlayback() {
        spotifyScript?.playpause?()
    }
    
    var artworkImage: NSImage? {
        get async {
            guard let artworkUrlString = spotifyScript?.currentTrack?.artworkUrl, let artworkUrl = URL(string: artworkUrlString) else {
                print("\(#function) missing artworlUrl")
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
}
