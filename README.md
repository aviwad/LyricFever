# Lyric Fever

![Logo](logo.png)

Live Spotify & Apple Music lyrics in your macOS menubar. It Just Works.

## Downloads

Download from [releases](https://github.com/aviwad/SpotifyLyricsInMenubar/releases).

### Requirements

- macOS Ventura or higher
- Spotify Desktop Client (if using Spotify)

## Features

- It Just Works.
- Offline caching! Lyrics are automatically stored offline efficiently using CoreData
- Play some music on the Spotify / Apple Music app and watch the lyrics play on the menu bar automatically.

## Screenshots

![First Screenshot](superShy.gif)

![Second Screenshot](screenshot2.png)

## Technical Details

- UI is built using SwiftUI.
- The lyrics are updated and fetched using Swift Concurrency and Swift Tasks
- The lyrics are stored into disk using CoreData. 
- I interface with Spotify & Apple Music using their AppleScript methods as well as by subscribing to their playback state change notifications.
- I interface with Spotify and Apple Music's AppleScript methods by using Apple's provided ScriptingBridge interface.
- I additionally use private APIs to get the currently playing Apple Music song's iTunes ID, and use MusicKit to map that to an ISRC code
- I map Apple Music songs to equivalent Spotify ID using ISRC to display Lyrics fetched from Spotify for either platform
- Spiritual successor to LyricsX (95% more efficient, 0.1% CPU usage of Lyric Fever vs 3% of LyricsX)
- Technical write-up coming soon


## Acknowledgements / Special Thanks

- [Sparkle:](https://github.com/sparkle-project/Sparkle) For app updates
- [Amplitude:](https://amplitude.com) For app analytics
- [spotify-lyrics-api:](https://github.com/akashrchandran/spotify-lyrics-api) For fetching Spotify lyrics
- [Spotify:](https://spotify.com) The music platform this project depends on! (for playback, for lyrics)
- [Apple MusicKit:](https://developer.apple.com/musickit/) Apple Music API
- [Apple Music:](https://music.apple.com/us/browse) Another platform that this project depends on
