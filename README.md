# Lyric Fever

<img src="logo.png" alt="Logo" width="15%">

The Best Lyrics Experience for Spotify & Apple Music on macOS. It Just Works.

## Downloads
Download [here](https://github.com/aviwad/LyricFever/releases/download/v2.0/Lyric.Fever.2.0.dmg).

Screenshots

<img src="superShy.gif" alt="First Screenshot" width="50%">
<img src="https://github.com/user-attachments/assets/e3c2c5f1-3d2b-4f7c-9893-d4613340943e" alt="Screenshot 1" width="50%">
<img src="https://github.com/user-attachments/assets/8d63d03e-6961-4675-b07a-e29697379c4b" alt="Screenshot 2" width="50%">


Features
- Automatic Lyric Playback on Menubar
- Fullscreen Mode (Modeled after Apple Music’s fullscreen view)
- Karaoke Mode (Lyric popup that stays on screen)
- Lyric Translation (using Apple’s on device APIs)
- Offline caching! Lyrics are automatically stored offline efficiently using CoreData
- Play some music on the Spotify / Apple Music app and watch the lyrics play on the menu bar automatically.
- Lyrics fetched from Spotify, and LRCLIB as a backup lyric provider

YouTube Promo Vid:

[![LyricFever Promo Vid](https://img.youtube.com/vi/Bxc7d-O9-rM/0.jpg)](https://www.youtube.com/watch?v=Bxc7d-O9-rM)

### Requirements

- macOS Ventura or higher (Sonoma required for fullscreen, Sequoia required for translation)
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
- The fullscreen view uses a custom mesh gradient (I have lost the source for the code, cannot attribute it) and extracts colors from the album art using ColorKit
- Spiritual successor to LyricsX (95% more efficient, 0.1% CPU usage of Lyric Fever vs 3% of LyricsX)
- Technical write-up coming soon


## Other Contributors
- [lcandy2](https://github.com/lcandy2) For their [pull request](https://github.com/aviwad/LyricFever/pull/68)

## Acknowledgements / Special Thanks
- [Sparkle:](https://github.com/sparkle-project/Sparkle) For app updates
- [Amplitude:](https://amplitude.com) For app analytics
- [Spotify:](https://spotify.com) The music platform this project depends on! (for playback, for lyrics)
- [Apple MusicKit:](https://developer.apple.com/musickit/) Apple Music API
- [Apple Music:](https://music.apple.com/us/browse) Another platform that this project depends on
- [ColorKit-macOS:](https://github.com/aviwad/ColorKit-macOS) My port of [ColorKit](https://github.com/Boris-Em/ColorKit) for macOS
- Cindori for their blog post on writing an NSPanel view for SwiftUI
- [tranxuanthang](https://github.com/tranxuanthang) for [LRCLIB](https://lrclib.net), an open source Lyric library. Used when Spotify fails.
- Unknown author for the mesh gradient view. I have lost the source.
