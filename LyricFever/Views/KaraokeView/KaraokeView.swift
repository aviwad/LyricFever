//
//  KaraokeView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2024-10-08.
//

import SwiftUI
import SDWebImage
import ColorKit
import Combine

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()

        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        //
        nsView.material = .hudWindow
        nsView.blendingMode = .behindWindow
    }
}

struct KaraokeView: View {
    @Environment(ViewModel.self) var viewmodel
    // Set by FloatingPanel: used to resize the panel when the line mode or font size changes
    @Environment(\.floatingPanel) var floatingPanel
    @AppStorage("karaokeTransparency") var karaokeTransparency: Double = 50
    @AppStorage("karaokeShowMultilingual") var karaokeShowMultilingual: Bool = true
    @AppStorage("karaokeUseAlbumColor") var karaokeUseAlbumColor: Bool = true
    @AppStorage("fixedKaraokeColorHex") var fixedKaraokeColorHex: String = "#2D3CCC"
    @AppStorage("karaokeLineMode") var karaokeLineMode: KaraokeLineMode = .single

    // Panel content width, matching FloatingPanel's default contentRect
    static let panelWidth: CGFloat = 800
    // Panel height in single-line mode. Unchanged from the original layout.
    static let singleLinePanelHeight: CGFloat = 100
    static let lineSpacing: CGFloat = 8
    // Gap between the original and its translation, matching multilingualView's VStack spacing
    static let translationSpacing: CGFloat = 6
    // Rough line height multiplier used to reserve panel height for a line of text
    static let lineHeightRatio: CGFloat = 1.3
    // Translations render slightly smaller than the line they belong to
    static let translationFontScale: CGFloat = 0.9

    // Both two-line modes render every row at the same font size. Shrinking the upcoming line would
    // make it visibly grow as it became current — a jump in .alternating, where the line must not
    // move at all, and a distortion mid-slide in .upcoming. Weight and brightness separate them.
    static let idleRowOpacity: Double = 0.55
    // Long lines shrink to fit one row rather than wrapping, since a wrapped row would change row
    // heights and shove every other row out of place. Well below the 0.9 used in single-line mode:
    // a smaller line still reads, a moving one breaks what these modes promise.
    static let twoLineMinimumScale: CGFloat = 0.5
    static let scrollAnimation: Animation = .easeInOut(duration: 0.35)

    // MARK: - Lyric text lookup
    //
    // The romanized and Chinese-converted arrays are built with compactMap over the lyrics (see
    // ViewModel.romanizeDidChange and chinesePreferenceDidChange), so a line that fails to convert is
    // dropped rather than left blank — a short array is a *shifted* array, and index i no longer
    // refers to line i. Indexing it would silently show the wrong line's text, which is worse than
    // not showing it at all. So a converted array is only used when its length matches the lyrics
    // exactly; otherwise the whole song falls back to the original words. translatedLyric is already
    // length-checked where it's assigned, but goes through the same guard so every array on screen is
    // vouched for the same way. The two-line modes make this necessary regardless, since they read
    // beyond the current index.

    // The isEmpty guard is not redundant with the count check: changing songs clears the lyrics and
    // the converted arrays together, and while both are empty their counts trivially match. Without
    // it, an empty translation reads as "usable" for that moment, rowHeight reserves space for a
    // translation block, and the panel visibly changes height mid-song-change.
    private func aligned(_ array: [String]) -> [String]? {
        guard !array.isEmpty, array.count == viewmodel.currentlyPlayingLyrics.count else {
            return nil
        }
        return array
    }

    private var alignedRomanized: [String]? { aligned(viewmodel.romanizedLyrics) }
    private var alignedChineseConversion: [String]? { aligned(viewmodel.chineseConversionLyrics) }
    private var alignedTranslation: [String]? { aligned(viewmodel.translatedLyric) }

    // Stricter than viewmodel.translationExists, which only checks for a non-empty array: a partial
    // translation would make one line render translated while the other fell back to the original,
    // mixing sources within one panel.
    var translationIsUsable: Bool { alignedTranslation != nil }

    private func originalWords(for index: Int) -> String {
        viewmodel.currentlyPlayingLyrics.indices.contains(index)
            ? viewmodel.currentlyPlayingLyrics[index].words
            : ""
    }

    private func translation(for index: Int) -> String? {
        guard let alignedTranslation, alignedTranslation.indices.contains(index) else {
            return nil
        }
        return alignedTranslation[index]
    }

    func currentWords(for currentlyPlayingLyricsIndex: Int) -> String {
        if let alignedRomanized, alignedRomanized.indices.contains(currentlyPlayingLyricsIndex) {
            return alignedRomanized[currentlyPlayingLyricsIndex]
        }
        if let alignedChineseConversion, alignedChineseConversion.indices.contains(currentlyPlayingLyricsIndex) {
            return alignedChineseConversion[currentlyPlayingLyricsIndex]
        }
        return originalWords(for: currentlyPlayingLyricsIndex)
    }

    func originalAndTranslationAreDifferent(for currentlyPlayingLyricsIndex: Int) -> Bool {
        guard let translation = translation(for: currentlyPlayingLyricsIndex) else {
            return false
        }
        return originalWords(for: currentlyPlayingLyricsIndex) != translation
    }

    // True when a line is shown as original + translation stacked together
    func showsMultilingual(for index: Int) -> Bool {
        translationIsUsable
            && karaokeShowMultilingual
            && originalAndTranslationAreDifferent(for: index)
    }

    // The line's leading text: what the user reads first. In multilingual mode that is the original
    // (the translation sits underneath); otherwise the translation replaces it outright.
    // Every mode reuses this so all lines on screen always come from the same source.
    func primaryText(for index: Int) -> String {
        if translationIsUsable, !showsMultilingual(for: index),
           let translation = translation(for: index) {
            return translation
        }
        return currentWords(for: index)
    }

    // MARK: - Shared line rendering

    func multilingualView(_ currentlyPlayingLyricsIndex: Int, alignment: HorizontalAlignment = .center) -> some View {
        VStack(alignment: alignment, spacing: Self.translationSpacing) {
            Text(verbatim: currentWords(for: currentlyPlayingLyricsIndex))
            Text(verbatim: translation(for: currentlyPlayingLyricsIndex) ?? "")
                .font(.custom(viewmodel.karaokeFont.fontName, size: Self.translationFontScale*(viewmodel.karaokeFont.pointSize)))
                .opacity(0.85)
        }
    }

    @ViewBuilder
    func lineContent(_ currentlyPlayingLyricsIndex: Int, alignment: HorizontalAlignment = .center) -> some View {
        if showsMultilingual(for: currentlyPlayingLyricsIndex) {
            multilingualView(currentlyPlayingLyricsIndex, alignment: alignment)
        } else {
            Text(verbatim: primaryText(for: currentlyPlayingLyricsIndex))
        }
    }

    // A non-breaking space, not an empty string, when a row has nothing to show: the row keeps
    // occupying its space so nothing else shifts. NBSP rather than a plain space, which layout can
    // collapse to zero width.
    static let emptyRowPlaceholder = "\u{00A0}"

    // Every row in both two-line modes is this tall, regardless of content. Whether a line carries a
    // translation is decided per line (see showsMultilingual), so content-sized rows would change
    // height as neighbouring lines came and went — which would shove the line being sung out of
    // place, and make .upcoming's slide offsets impossible to compute up front.
    var rowHeight: CGFloat {
        let pointSize = viewmodel.karaokeFont.pointSize
        // The union of "translation is switched on" and "a usable translation is actually loaded",
        // because those can disagree: the setting alone keeps the height steady while a translation
        // is still being fetched, and translationIsUsable covers a translation that outlives the
        // setting being turned off — which showsMultilingual would still render, into a row too
        // short for it, and clipped() would cut in half.
        let showsTranslationBlock = (viewmodel.userDefaultStorage.translate || translationIsUsable)
            && karaokeShowMultilingual
        return showsTranslationBlock
            ? pointSize * Self.lineHeightRatio
                + pointSize * Self.translationFontScale * Self.lineHeightRatio
                + Self.translationSpacing
            : pointSize * Self.lineHeightRatio
    }

    var twoLineContentHeight: CGFloat {
        rowHeight * 2 + Self.lineSpacing
    }

    // MARK: - .upcoming mode
    //
    // Rows are positioned by their offset from the current line rather than stacked, so advancing a
    // line just shifts every row's offset by one row and SwiftUI animates them sliding upward: the
    // previewed line rises into the current slot instead of teleporting there, and the line after it
    // slides in from below. The rows immediately above and below the visible pair stay mounted (and
    // clipped) so they slide in and out rather than popping into place.

    // A synthetic row sitting just above line 0, carrying the song title instead of a lyric. During
    // an intro the current-line slot would otherwise be blank, which reads as something being broken
    // rather than as "nothing is being sung yet". It scrolls away like any other row once the first
    // line arrives, and echoes the "Now Playing" line the lyrics already end with (see
    // NetworkFetchReturn.processed) — the artist is appended here when there is one, so the two
    // aren't always word for word, but the song opens and closes on the same phrase.
    static let nowPlayingRowIndex = -1

    var nowPlayingText: String? {
        guard let currentlyPlayingName = viewmodel.currentlyPlayingName else {
            return nil
        }
        guard let currentlyPlayingArtist = viewmodel.currentlyPlayingArtist else {
            return NetworkFetchReturn.nowPlayingText(songName: currentlyPlayingName)
        }
        // The menubar's existing localized string rather than a new one to translate
        return String(localized: "Now Playing: \(currentlyPlayingName) - \(currentlyPlayingArtist)")
    }

    // The row sitting in the current-line slot. -1 before playback reaches the first line, which
    // puts the "Now Playing" row there and parks line 0 in the preview slot — during an intro, that
    // preview is the entire point.
    func upcomingAnchor(_ currentIndex: Int?) -> Int {
        currentIndex ?? Self.nowPlayingRowIndex
    }

    func upcomingRowExists(_ rowIndex: Int) -> Bool {
        if rowIndex == Self.nowPlayingRowIndex {
            // Without a song title there's nothing to put there; the slot goes back to being blank
            return nowPlayingText != nil
        }
        return viewmodel.currentlyPlayingLyrics.indices.contains(rowIndex)
    }

    func upcomingRowIndices(anchor: Int) -> [Int] {
        (anchor - 1...anchor + 2).filter { upcomingRowExists($0) }
    }

    @ViewBuilder
    func upcomingRowContent(_ rowIndex: Int) -> some View {
        if rowIndex == Self.nowPlayingRowIndex {
            Text(verbatim: nowPlayingText ?? "")
        } else {
            lineContent(rowIndex)
        }
    }

    func upcomingRow(_ rowIndex: Int, isCurrent: Bool) -> some View {
        upcomingRowContent(rowIndex)
            .fontWeight(isCurrent ? .bold : .regular)
            .opacity(isCurrent ? 1 : Self.idleRowOpacity)
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .top)
    }

    func upcomingView(_ currentIndex: Int?) -> some View {
        let anchor = upcomingAnchor(currentIndex)
        return ZStack(alignment: .top) {
            ForEach(upcomingRowIndices(anchor: anchor), id: \.self) { rowIndex in
                // Against the anchor, not currentIndex: they're the same during playback, but in an
                // intro this is what gives the "Now Playing" row the current row's emphasis to match
                // the position it occupies. Handing that emphasis over to line 1 as it slides up is
                // the visual cue that singing has started.
                upcomingRow(rowIndex, isCurrent: rowIndex == anchor)
                    .offset(y: CGFloat(rowIndex - anchor) * (rowHeight + Self.lineSpacing))
            }
        }
        .frame(maxWidth: .infinity, minHeight: twoLineContentHeight, maxHeight: twoLineContentHeight, alignment: .top)
        // Rows parked above and below the visible pair must not paint outside the panel
        .clipped()
        .lineLimit(1)
        .minimumScaleFactor(Self.twoLineMinimumScale)
        .animation(Self.scrollAnimation, value: anchor)
    }

    // MARK: - .alternating mode
    //
    // Slot 0 holds every even-numbered line, slot 1 every odd-numbered one, so a line enters its
    // slot as the preview and is still sitting there — same slot, same alignment, same size — when
    // it becomes the line being sung. Finishing a line moves the highlight, not the text. The slot
    // that just went idle picks up the line after next straight away.
    //
    // Slots are aligned to opposite edges, the way a karaoke machine staggers its two lines: it
    // tells them apart without relying on colour, and it pins each slot's alignment to one edge so
    // the bold/regular weight change can only move the *other* end of the line.

    func alternatingSlotIsCurrent(slot: Int, currentIndex: Int?) -> Bool {
        guard let currentIndex else {
            return false
        }
        return slot == currentIndex % 2
    }

    func alternatingLineIndex(slot: Int, currentIndex: Int?) -> Int? {
        guard let currentIndex else {
            // Before the first line: preload the opening two lines into the slots they belong to,
            // neither highlighted. Line 0 lands in slot 0 — the very slot it will occupy once it's
            // being sung — so playback starting only lights it up, it doesn't move it.
            return viewmodel.currentlyPlayingLyrics.indices.contains(slot) ? slot : nil
        }
        let index = alternatingSlotIsCurrent(slot: slot, currentIndex: currentIndex)
            ? currentIndex
            : currentIndex + 1
        return viewmodel.currentlyPlayingLyrics.indices.contains(index) ? index : nil
    }

    // Top-aligned so both slots' primary lines sit at the same height even when only one of them
    // carries a translation underneath.
    func alternatingFrameAlignment(slot: Int) -> Alignment {
        slot == 0 ? .topLeading : .topTrailing
    }

    func alternatingTextAlignment(slot: Int) -> TextAlignment {
        slot == 0 ? .leading : .trailing
    }

    func alternatingStackAlignment(slot: Int) -> HorizontalAlignment {
        slot == 0 ? .leading : .trailing
    }

    @ViewBuilder
    func alternatingSlotView(slot: Int, currentIndex: Int?) -> some View {
        if let lineIndex = alternatingLineIndex(slot: slot, currentIndex: currentIndex) {
            lineContent(lineIndex, alignment: alternatingStackAlignment(slot: slot))
                // Keyed on the line, not the playback index: the slot holding the line that just
                // became current keeps the same id across the change, so it animates its weight and
                // brightness in place instead of being torn down and faded back in.
                .id(lineIndex)
                .fontWeight(alternatingSlotIsCurrent(slot: slot, currentIndex: currentIndex) ? .bold : .regular)
                .opacity(alternatingSlotIsCurrent(slot: slot, currentIndex: currentIndex) ? 1 : Self.idleRowOpacity)
                .multilineTextAlignment(alternatingTextAlignment(slot: slot))
                // maxHeight rather than the content's own height, so the two slots split the panel
                // evenly and each keeps a constant height whatever the other one is showing
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alternatingFrameAlignment(slot: slot))
        } else {
            // Past the end of the song: hold the slot open so the other one doesn't move.
            Text(verbatim: Self.emptyRowPlaceholder)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alternatingFrameAlignment(slot: slot))
        }
    }

    func alternatingView(_ currentIndex: Int?) -> some View {
        VStack(spacing: Self.lineSpacing) {
            alternatingSlotView(slot: 0, currentIndex: currentIndex)
            alternatingSlotView(slot: 1, currentIndex: currentIndex)
        }
        .frame(maxHeight: .infinity)
        .lineLimit(1)
        .minimumScaleFactor(Self.twoLineMinimumScale)
    }

    // MARK: - Layout

    @ViewBuilder
    func lyricsView() -> some View {
        switch karaokeLineMode {
        case .single:
            // Nothing to show before the first line, and ViewModel.karaokeHasContent keeps the panel
            // closed until then, so this is the original behaviour untouched.
            if let currentlyPlayingLyricsIndex = viewmodel.currentlyPlayingLyricsIndex {
                lineContent(currentlyPlayingLyricsIndex)
                    .id(currentlyPlayingLyricsIndex)
            } else {
                Text("")
            }
        case .upcoming:
            upcomingView(viewmodel.currentlyPlayingLyricsIndex)
        case .alternating:
            alternatingView(viewmodel.currentlyPlayingLyricsIndex)
        }
    }

    // Fixed rather than content-driven: lyric lines vary in length, so an auto-sizing panel would
    // jump on every line change. Sized for the worst case instead — leaving the panel part-empty on
    // short lines is cosmetic, clipping a lyric is not.
    //
    // rowHeight counts the translate setting as enough on its own to reserve the translation block,
    // so the panel keeps its height when a song without a translation comes on. It still grows if a
    // translation outlives the setting being switched off — that row genuinely needs the space.
    var panelHeight: CGFloat {
        switch karaokeLineMode {
        case .single:
            return Self.singleLinePanelHeight
        case .upcoming, .alternating:
            // 20 = the vertical .padding(10) applied below
            return ceil(twoLineContentHeight + 20)
        }
    }

    @ViewBuilder
    var finalKaraokeView: some View {
        lyricsView()
            .lineLimit(2)
            .foregroundStyle(.white)
            .minimumScaleFactor(0.9)
            .font(.custom(viewmodel.karaokeFont.fontName, size: viewmodel.karaokeFont.pointSize))
            .padding(10)
            .padding(.horizontal, 10)
            .background {
               currentAlbumArt
               .transition(.opacity)
               .opacity(karaokeTransparency/100)
           }
//           .drawingGroup()
           .background(
               VisualEffectView().ignoresSafeArea()
           )
           .cornerRadius(16)
            .onHover { hover in
                if viewmodel.userDefaultStorage.karaokeModeHoveringSetting {
                    viewmodel.karaokeModeHovering = hover
                }
            }
            .multilineTextAlignment(.center)
            .frame(minWidth: Self.panelWidth, maxWidth: Self.panelWidth, minHeight: panelHeight, maxHeight: panelHeight, alignment: .center)
            // The panel is a fixed-size NSPanel, so SwiftUI's frame alone won't resize it.
            // setFrame with the existing origin rather than setContentSize: which corner AppKit
            // pins during setContentSize isn't contractual, and here it has to be the bottom-left
            // one. The panel sits low on screen, so it must grow upwards and leave the position
            // the user dragged it to untouched.
            .onChange(of: panelHeight, initial: true) { _, newHeight in
                guard let panel = floatingPanel else { return }
                let contentRect = NSRect(origin: panel.frame.origin,
                                         size: NSSize(width: Self.panelWidth, height: newHeight))
                var frame = panel.frameRect(forContentRect: contentRect)
                // Growing upwards runs the panel off the top of the display if the user has dragged
                // it up there. Nudge it back down instead: a panel that moves is a smaller problem
                // than a line being sung that's half off-screen.
                if let visibleFrame = (panel.screen ?? NSScreen.main)?.visibleFrame,
                   frame.maxY > visibleFrame.maxY {
                    frame.origin.y = max(visibleFrame.minY, visibleFrame.maxY - frame.height)
                }
                panel.setFrame(frame, display: true)
            }
    }

    var currentAlbumArt: Color {
        // ensure user wants to use album-derived color, and album-derived color exists
        guard karaokeUseAlbumColor, let currentBackground = viewmodel.currentBackground else {
            return Color(NSColor(hexString: fixedKaraokeColorHex)!)
        }
        return currentBackground
    }

    var body: some View {
        finalKaraokeView
    }
}
