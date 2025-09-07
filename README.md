# Lyric Fever

<img src="logo.png" alt="Logo" width="15%">

The Best Lyrics Experience for Spotify & Apple Music on macOS. It Just Works.

## Installation

### Manual
Download the DMG file [here](https://github.com/aviwad/LyricFever/releases/download/v2.1/Lyric.Fever.2.1.dmg).

### Homebrew
Run `brew install lyric-fever`

## Screenshots
[lyricfeverad.webm](https://github.com/user-attachments/assets/8881ae23-69d3-4b81-875b-31f12c577fa0)

<img alt="Screenshot of Lyric Fever's menubar window and floating lyric window" src="https://github.com/user-attachments/assets/a890b685-b4b4-45cc-918c-1184aa10d1bd" width="50%"/>

<img src="superShy.gif" alt="First Screenshot" width="50%">
<img src="https://github.com/user-attachments/assets/e3c2c5f1-3d2b-4f7c-9893-d4613340943e" alt="Screenshot 1" width="50%">
<img alt="Screenshot 2025-09-07 at 4 50 35 PM" src="https://github.com/user-attachments/assets/d1ceea06-f56e-44b3-a2db-b66ac6a95d65" width="50%"/>
<img alt="image" src="https://github.com/user-attachments/assets/2aae8faf-74a3-41bb-a8f7-2e9774489f17" width="50%"/>

## Features
- Automatic Lyric Playback on Menubar
- Fullscreen Mode (Modeled after Apple Music’s fullscreen view)
- Karaoke Mode (Lyric popup that stays on screen)
- Karaoke Mode customization (font color, etc)
- Lyric Translation (using Apple’s on device APIs)
- Offline caching! Lyrics are automatically stored offline efficiently using CoreData
- Play some music on the Spotify / Apple Music app and watch the lyrics play on the menu bar automatically.
- Lyrics fetched from Spotify, LRCLIB, and NetEase as a backup lyric provider
- Simplified Chinese language support in app UI, thanks to @InTheManXG

## YouTube Promo Vid:

[![LyricFever Promo Vid]](https://youtu.be/Qgqz43hepQQ)

### Requirements

- macOS Sequoia or higher
- Spotify Desktop Client (if using Spotify)

## Technical Details

- UI is built using SwiftUI.
- The lyrics are updated and fetched using Swift Concurrency and Swift Tasks
- The lyrics are stored into disk using CoreData. 
- I interface with Spotify & Apple Music using their AppleScript methods as well as by subscribing to their playback state change notifications.
- I interface with Spotify and Apple Music's AppleScript methods by using Apple's provided ScriptingBridge interface.
- I additionally use private APIs to get the currently playing Apple Music song's iTunes ID, and use MusicKit to map that to an ISRC code
- I map Apple Music songs to equivalent Spotify ID using ISRC to display Lyrics fetched from Spotify for either platform
- Lyrics are fetched from LRCLIB as a backup when Spotify fails
- I fetch the song “background color” with each lyric, and the color is used for the karaoke mode window background 
- Songs translated using Apple's Translation API. 
- The fullscreen view uses a custom mesh gradient and extracts colors from the album art using ColorKit
- Spiritual successor to LyricsX (95% more efficient, 0.1% CPU usage of Lyric Fever vs 3% of LyricsX)
- Technical write-up coming soon

## Translation Help
[Crowdin Translation website](https://crowdin.com/project/lyric-fever/invite?h=29165351cb7d916e369d00386e37ef602390778)

Please open a GitHub issue request to translate to more languages. Thank you very much.

## Other Contributors
- [InTheManXG](https://github.com/InTheManXG) for Simplified Chinese translations
- [lcandy2](https://github.com/lcandy2) For their [pull request](https://github.com/aviwad/LyricFever/pull/68)

## Acknowledgements / Special Thanks
- [Sparkle:](https://github.com/sparkle-project/Sparkle) For app updates
- [Amplitude:](https://amplitude.com) For app analytics
- [Spotify:](https://spotify.com) The music platform this project depends on! (for playback, for lyrics)
- [Apple MusicKit:](https://developer.apple.com/musickit/) Apple Music API
- [Apple Music:](https://music.apple.com/us/browse) Another platform that this project depends on
- [ColorKit-macOS:](https://github.com/aviwad/ColorKit-macOS) My port of [ColorKit](https://github.com/Boris-Em/ColorKit) for macOS
- Cindori for their blog post on writing an NSPanel view for SwiftUI
- autozimu for https://github.com/autozimu/StringMetric.swift, used to determine how similar NetEase search results are from search query
- [tranxuanthang](https://github.com/tranxuanthang) for [LRCLIB](https://lrclib.net), an open source Lyric library. Used when Spotify fails.
- NetEase for their Lyrics, used when LRCLIB and Spotify fail.
- https://neteasecloudmusicapi-ten-wine.vercel.app for their NetEase API
- [f728743](https://github.com/f728743) for the mesh gradient view.
- [jayasme](https://github.com/jayasme/) for the [LRC Lyric Parser](https://github.com/jayasme/SpotlightLyrics) I used as a base
- MusicBrainz & the CoverArtArchive projects for their MBID and Cover Art APIs (used for non-spotify / local files)
- LyricsX for their Spotify TOTP fix and NetEase lyric provider
- [Mecab-Swift](https://github.com/shinjukunian/Mecab-Swift) by [shinjukunian](https://github.com/shinjukunian) for the excellent Japanese Romanization 
- Christian Selig for his efficient image color averaging technique
- Various StackOverflow snippets
