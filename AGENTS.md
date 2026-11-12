# Repository Guidelines

## Project Structure & Module Organization

`LyricFever/` contains the Swift app. Keep related code in its existing areas: `Views/` for SwiftUI screens and controls, `Models/` for data and parsing, `Players/` for Apple Music and Spotify integration, `LyricProvider/` for lyric sources, and `Services/` for supporting services. `Support Files/` holds assets, entitlements, and app configuration. The Core Data model is under `Models/CoreData/`. `Localizable.xcstrings` contains app translations. The Xcode project and shared scheme are in `Lyric Fever.xcodeproj/`.

## Build, Test, and Development Commands

- `open "Lyric Fever.xcodeproj"` opens the project in Xcode; select the `SpotifyLyricsInMenubar` scheme to run the app.
- `xcodebuild -project "Lyric Fever.xcodeproj" -scheme SpotifyLyricsInMenubar -configuration Debug build` builds the macOS app from the command line. Xcode resolves Swift Package Manager dependencies during the build.
- There is currently no dedicated test target or test directory. For behavior changes, run the app from Xcode and manually check the affected flow, such as playback detection, lyric fetching, or the relevant view.

## Coding Style & Naming Conventions

Use Swift and SwiftUI patterns already present in neighboring files. Indent with four spaces, keep types and protocols in `UpperCamelCase`, and use `lowerCamelCase` for properties and functions. Name source files after their primary type (for example, `LyricLine.swift` or `SpotifyLyricProvider.swift`) and place them in the matching feature folder. Keep UI, provider, player, and service responsibilities in their existing modules. No formatter or linter is configured; keep changes focused and format consistently with adjacent code.

## Testing Guidelines

No automated test framework or coverage requirement is configured at present. Build the app after code changes and exercise relevant behavior manually. If adding a test target, use XCTest and descriptive names that state the behavior under test.

## Commit & Pull Request Guidelines

Follow the Conventional Commits format documented in `CONTRIBUTING.md`: `feat:`, `fix:`, `docs:`, `refactor:`, `perf:`, `test:`, or `chore:` followed by a concise imperative summary (for example, `fix: handle missing lyric timestamps`). Pull requests should explain the user-visible change, note how it was built or checked, link related issues, and include screenshots or a short recording for UI changes. Update localization and project resources when affected.

## Security & Configuration Tips

Do not commit API credentials, personal tokens, or local signing material. Keep app permissions and signing changes in the existing plist and entitlements files, and explain permission changes in the pull request.
