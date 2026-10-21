//
//  PlayerAutoSwitch.swift
//  Lyric Fever
//
//  Automatically follow whichever app (Spotify or Apple Music) is playing,
//  instead of requiring the user to pick one in Settings.
//
//  Rules (only when "Auto-Switch" is on and the user has finished onboarding):
//   1. The other app starts playing                          -> switch to it
//   2. The other app is playing and ours is paused/stopped   -> switch to it
//   3. Our app pauses/stops while the other app is playing   -> switch to it
//  If both apps are playing, track changes in the background app do NOT flip-flop
//  the display; only pressing play in an app pulls Lyric Fever over to it.
//
//  macOS asks "Lyric Fever wants to control <app>" the first time we talk to an app.
//  Only rule 1 (you just pressed play in that app) is allowed to trigger that prompt;
//  every other check first asks macOS silently and skips apps we can't control yet.
//

#if os(macOS)
import Foundation
import CoreServices

extension ViewModel {
    func playerInstance(for type: PlayerType) -> Player {
        switch type {
            case .spotify:
                return spotifyPlayer
            case .appleMusic:
                return appleMusicPlayer
        }
    }

    // MARK: Notification-driven switching

    /// Called at the top of each player's playback notification handler.
    /// - Returns: true if Lyric Fever switched players. The new player's state has already been loaded,
    ///   so the caller should stop processing the notification.
    func autoSwitchPlayerIfNeeded(notifiedBy player: PlayerType, playerState: String?) -> Bool {
        let isNowPlaying = playerState == "Playing"
        let wasPlaying = autoSwitchLastKnownPlaying[player] ?? false
        autoSwitchLastKnownPlaying[player] = isNowPlaying

        guard userDefaultStorage.autoSwitchPlayer, userDefaultStorage.hasOnboarded else {
            return false
        }

        if player != currentPlayer {
            // Rules 1 & 2. `isPlaying` here is the state of the player we're currently showing.
            guard isNowPlaying, !wasPlaying || !isPlaying else {
                return false
            }
            // The user just pressed play in this app, so this is the one place a permission prompt is OK
            guard automationPermission(for: player, askIfNeeded: false) != .denied else {
                print("Auto-Switch: Automation permission for \(player) was denied in System Settings. Not switching.")
                return false
            }
            return switchPlayer(to: player, knownToBePlaying: true)
        } else if !isNowPlaying {
            // Rule 3
            let other = player.other
            guard isPlayingWithoutPrompting(other) else {
                return false
            }
            return switchPlayer(to: other, knownToBePlaying: true)
        }
        return false
    }

    /// Switches the active player without sending the user back through onboarding.
    /// - Parameter knownToBePlaying: pass true when a notification already told us the new player is playing
    ///   (more reliable than asking over AppleScript right away).
    /// - Returns: true if the switch happened.
    @discardableResult
    func switchPlayer(to newPlayer: PlayerType, knownToBePlaying: Bool = false) -> Bool {
        guard newPlayer != currentPlayer else {
            return false
        }
        let newInstance = playerInstance(for: newPlayer)
        // isRunning first: talking to an app over AppleScript launches it if it's closed
        guard newInstance.isRunning, newInstance.isAuthorized else {
            print("Auto-Switch: \(newPlayer) isn't running or Lyric Fever can't control it (Automation permission). Not switching.")
            return false
        }
        print("Auto-Switch: switching from \(currentPlayer) to \(newPlayer)")

        let previousTrackID = currentlyPlaying
        let previousPersistentID = currentlyPlayingAppleMusicPersistentID

        stopLyricUpdater()
        cancelInFlightFetchesForPlayerSwitch()
        autoSwitchedTo = newPlayer
        currentPlayer = newPlayer

        // Clear the previous player's song so its lyrics / artwork don't linger
        currentlyPlaying = nil
        currentlyPlayingName = nil
        currentlyPlayingArtist = nil
        currentAlbumName = nil
        currentlyPlayingAppleMusicPersistentID = nil
        currentlyPlayingLyrics = []
        currentlyPlayingLyricsIndex = nil
        translatedLyric = []
        romanizedLyrics = []
        chineseConversionLyrics = []
        lyricsIsEmptyPostLoad = true
        artworkImage = nil
        currentBackground = nil
        isStopped = false
        isPlaying = knownToBePlaying || newInstance.isPlaying

        // Load whatever the new player is playing (same path as finishing onboarding)
        didOnboard()

        // Lyric + artwork fetches normally fire from SwiftUI seeing the track ID change. If the new player is on
        // the same track ID as before, SwiftUI sees no change, so kick those off ourselves.
        switch newPlayer {
            case .spotify:
                if let currentlyPlaying, currentlyPlaying == previousTrackID {
                    Task {
                        let artwork = await spotifyPlayer.artworkImage
                        if let artwork {
                            artworkImage = artwork
                        }
                        await onCurrentlyPlayingIDChange()
                    }
                }
            case .appleMusic:
                if let currentlyPlayingAppleMusicPersistentID, currentlyPlayingAppleMusicPersistentID == previousPersistentID {
                    Task {
                        await appleMusicStarter()
                        if let currentlyPlaying, currentlyPlaying == previousTrackID {
                            await onCurrentlyPlayingIDChange()
                        }
                    }
                }
                // Apple Music artwork normally arrives on track change; ask for the current one now
                refreshAppleMusicArtwork()
        }
        return true
    }

    /// Returns true (once) if the most recent player change was made by auto-switch rather than by the user.
    func consumeAutoSwitch(to player: PlayerType) -> Bool {
        defer {
            autoSwitchedTo = nil
        }
        return autoSwitchedTo == player
    }

    // MARK: Launch / toggle / onboarding

    /// Record which apps are playing right now, so the next notification can tell
    /// "just started playing" apart from "changed track while already playing".
    func seedAutoSwitchPlayingState() {
        guard userDefaultStorage.autoSwitchPlayer else {
            return
        }
        for type in PlayerType.allCases {
            autoSwitchLastKnownPlaying[type] = isPlayingWithoutPrompting(type)
        }
    }

    /// At launch: if the saved player is idle but the other app is playing, start on the other app.
    /// Called from init, before any views exist, so this doesn't trigger the player-change onboarding reset.
    func selectPlayingPlayerOnLaunch() {
        guard userDefaultStorage.autoSwitchPlayer else {
            return
        }
        seedAutoSwitchPlayingState()
        let other = currentPlayer.other
        guard autoSwitchLastKnownPlaying[currentPlayer] != true,
              autoSwitchLastKnownPlaying[other] == true,
              playerInstance(for: other).isAuthorized else {
            return
        }
        print("Auto-Switch: \(other) is playing at launch, starting with it instead of \(currentPlayer)")
        currentPlayer = other
    }

    /// Used when the user turns the toggle on: jump to the other app right away if it's the one playing.
    func autoSwitchToPlayingPlayerIfIdle() {
        guard userDefaultStorage.autoSwitchPlayer, userDefaultStorage.hasOnboarded else {
            return
        }
        seedAutoSwitchPlayingState()
        if !isPlaying, autoSwitchLastKnownPlaying[currentPlayer.other] == true {
            switchPlayer(to: currentPlayer.other, knownToBePlaying: true)
        }
    }

    // MARK: Helpers

    enum AutomationPermission {
        case granted, denied, wouldPrompt, unknown
    }

    /// Asks macOS whether Lyric Fever may send Apple Events to the player.
    /// With askIfNeeded == false this never shows the "wants to control" dialog.
    func automationPermission(for type: PlayerType, askIfNeeded: Bool) -> AutomationPermission {
        let target = NSAppleEventDescriptor(bundleIdentifier: type.bundleIdentifier)
        let status = AEDeterminePermissionToAutomateTarget(target.aeDesc, AEEventClass(typeWildCard), AEEventID(typeWildCard), askIfNeeded)
        switch status {
            case 0: // noErr
                return .granted
            case -1743: // errAEEventNotPermitted: user said no in System Settings > Privacy & Security > Automation
                return .denied
            case -1744: // errAEEventWouldRequireUserConsent: user hasn't been asked yet
                return .wouldPrompt
            default: // e.g. -600 procNotFound (app not running)
                return .unknown
        }
    }

    /// Is this app running and playing? Never launches the app and never triggers a permission prompt.
    func isPlayingWithoutPrompting(_ type: PlayerType) -> Bool {
        let instance = playerInstance(for: type)
        // isRunning first: talking to a closed app over AppleScript would launch it
        guard instance.isRunning else {
            return false
        }
        switch automationPermission(for: type, askIfNeeded: false) {
            case .granted, .unknown:
                return instance.isPlaying
            case .denied, .wouldPrompt:
                return false
        }
    }

    /// Ask MediaRemote for Music's current artwork (used right after switching to Apple Music mid-song).
    func refreshAppleMusicArtwork() {
        musicController.getTrackInfo { data in
            Task { @MainActor in
                guard self.currentPlayer == .appleMusic,
                      data?.payload.bundleIdentifier == "com.apple.Music" || data?.payload.applicationName == "Music",
                      let artwork = data?.payload.artwork else {
                    return
                }
                self.artworkImage = artwork
            }
        }
    }
}
#endif
