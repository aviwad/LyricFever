//
//  LyricsNSScrollView.swift
//  Lyric Fever
//
//  Custom AppKit lyrics list for the fullscreen view.
//  Uses entirely frame-based layout for NSTextFields to avoid the
//  NSTextField.updateConstraints → constraintsDidChangeInEngine → SwiftUI loop.
//

#if os(macOS)
import AppKit
import SwiftUI

// MARK: - Constants / font helpers

private let primaryFont     = NSFont.boldSystemFont(ofSize: 40)
private let translationFont = NSFont.systemFont(ofSize: 33, weight: .semibold)
private let cellPad:     CGFloat = 20
private let labelGap:    CGFloat = 3
private let trailInset:  CGFloat = 100

/// Height of a single wrapped text block at a given width.
private func textHeight(_ text: String, font: NSFont, width: CGFloat) -> CGFloat {
    guard width > 0 else { return ceil(font.pointSize * 1.4) }
    let attrs: [NSAttributedString.Key: Any] = [.font: font]
    let rect = (text as NSString).boundingRect(
        with: NSSize(width: width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: attrs)
    return max(ceil(rect.height), ceil(font.pointSize * 1.2))
}

/// Total height for one lyric cell at the given cell width.
private func rowHeight(primary: String, translation: String?, cellWidth: CGFloat) -> CGFloat {
    let textW = cellWidth - 2 * cellPad
    guard textW > 0 else { return cellPad * 2 + 50 }
    var h = textHeight(primary, font: primaryFont, width: textW) + 2 * cellPad
    if let t = translation, !t.isEmpty {
        h += textHeight(t, font: translationFont, width: textW) + labelGap
    }
    return max(h, 50)
}

// MARK: - Lyric cell view (fully frame-based — NO Auto Layout on labels)

class LyricCellView: NSView {
    // translatesAutoresizingMaskIntoConstraints stays TRUE (the default).
    // This prevents NSTextField from creating internal "content size" constraints
    // whose constant changes would propagate to SwiftUI's hosting view and loop.
    let primaryLabel     = NSTextField(labelWithString: "")
    let translationLabel = NSTextField(labelWithString: "")

    private var lastIsCurrentLine: Bool = false
    private var lastBlurRadius:    CGFloat = 0.0

    override var isFlipped: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.masksToBounds = false
        for label in [primaryLabel, translationLabel] {
            label.isBezeled      = false
            label.drawsBackground = false
            label.isEditable     = false
            label.isSelectable   = false
            label.textColor      = .white
            label.maximumNumberOfLines = 0
            label.lineBreakMode  = .byWordWrapping
            label.usesSingleLineMode = false
            // Do NOT set translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
        }
        primaryLabel.font     = primaryFont
        translationLabel.font = translationFont
        translationLabel.alphaValue = 0.85
    }
    required init?(coder: NSCoder) { fatalError() }

    override func resizeSubviews(withOldSize _: NSSize) {
        layoutLabels()
    }

    func layoutLabels() {
        let textW = bounds.width - 2 * cellPad
        guard textW > 0 else { return }
        var y = cellPad
        let ph = textHeight(primaryLabel.stringValue, font: primaryFont, width: textW)
        primaryLabel.frame = NSRect(x: cellPad, y: y, width: textW, height: ph)
        y += ph
        if !translationLabel.isHidden, !translationLabel.stringValue.isEmpty {
            y += labelGap
            let th = textHeight(translationLabel.stringValue, font: translationFont, width: textW)
            translationLabel.frame = NSRect(x: cellPad, y: y, width: textW, height: th)
        }
    }

    func configure(primaryText: String, translationText: String?,
                   isCurrentLine: Bool, isLastLine: Bool, isPastLine: Bool,
                   blurRadius: CGFloat, animationDelay: Double = 0,
                   skipAnimations: Bool = false) {
        primaryLabel.stringValue = primaryText
        if let t = translationText, !t.isEmpty {
            translationLabel.stringValue = t
            translationLabel.isHidden = false
        } else {
            translationLabel.isHidden = true
        }

        let targetAlpha: CGFloat = (isLastLine || isPastLine) ? 0 : (isCurrentLine ? 1.0 : 0.35)
        let focusChanged = isCurrentLine != lastIsCurrentLine
        lastIsCurrentLine = isCurrentLine

        let fromRadius = lastBlurRadius
        lastBlurRadius = blurRadius

        // Snap instantly when the caller requests no animation (song change, first lyric, etc.).
        // Exception: the currently-focused cell always animates so the unblur transition
        // is visible even on the nil → non-nil index transition.
        if skipAnimations && !isCurrentLine {
            alphaValue = targetAlpha
            applyBlur(radius: blurRadius)
            layoutLabels()
            return
        }

        if focusChanged {
            let animDuration = 0.4
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) { [weak self] in
                guard let self else { return }
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = animDuration
                    ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    self.animator().alphaValue = targetAlpha
                }
                // Only animate blur if there's an actual blur change (respects blurFullscreen pref).
                if fromRadius != blurRadius {
                    self.animateBlur(from: fromRadius, to: blurRadius, duration: animDuration)
                } else {
                    self.applyBlur(radius: blurRadius)
                }
            }
        } else {
            alphaValue = targetAlpha
            if fromRadius != blurRadius {
                animateBlur(from: fromRadius, to: blurRadius, duration: 0.4)
            } else {
                applyBlur(radius: blurRadius)
            }
        }

        layoutLabels()
    }

    private func applyBlur(radius: CGFloat) {
        if radius > 0, let f = CIFilter(name: "CIGaussianBlur") {
            f.setValue(radius, forKey: kCIInputRadiusKey)
            layer?.filters = [f]
        } else {
            layer?.filters = []
        }
    }

    private func animateBlur(from fromRadius: CGFloat, to toRadius: CGFloat, duration: CFTimeInterval) {
        guard let layer = layer else {
            applyBlur(radius: toRadius)
            return
        }
        // Install the destination (or a zero-radius placeholder) so CA has a filter to animate.
        let f = CIFilter(name: "CIGaussianBlur")!
        f.setValue(max(toRadius, 0.0), forKey: kCIInputRadiusKey)
        layer.filters = [f]

        let anim = CABasicAnimation(keyPath: "filters.CIGaussianBlur.inputRadius")
        anim.fromValue = fromRadius
        anim.toValue   = toRadius
        anim.duration  = duration
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        anim.fillMode  = .forwards
        anim.isRemovedOnCompletion = false
        layer.add(anim, forKey: "blurAnim")

        // Once animation completes, clean up and apply final state.
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.layer?.removeAnimation(forKey: "blurAnim")
            self?.applyBlur(radius: toRadius)
        }
    }
}

// MARK: - Document view (positions cells manually, no Auto Layout)

class LyricsDocumentView: NSView {
    override var isFlipped: Bool { true }

    var lyricViews:   [LyricCellView] = []
    var topPadding:    CGFloat = 0
    var bottomPadding: CGFloat = 0

    /// Position every cell vertically within the current bounds width.
    override func layout() {
        super.layout()
        let w = bounds.width     // already accounts for the trailing inset set on frame
        guard w > 0 else { return }
        var y = topPadding
        for cell in lyricViews {
            let h = rowHeight(
                primary:     cell.primaryLabel.stringValue,
                translation: cell.translationLabel.isHidden ? nil : cell.translationLabel.stringValue,
                cellWidth:   w)
            cell.frame = NSRect(x: 0, y: y, width: w, height: h)
            y += h
        }
    }

    /// Total document height for the given clip-view width.
    func computeTotalHeight(clipWidth: CGFloat) -> CGFloat {
        let w = max(0, clipWidth - trailInset)
        var h = topPadding + bottomPadding
        for cell in lyricViews {
            h += rowHeight(
                primary:     cell.primaryLabel.stringValue,
                translation: cell.translationLabel.isHidden ? nil : cell.translationLabel.stringValue,
                cellWidth:   w)
        }
        return h
    }
}

// MARK: - Non-scrollable scroll view

class NonScrollableScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) { /* user scrolling disabled */ }
}

// MARK: - NSViewRepresentable

struct LyricsNSScrollView: NSViewRepresentable {

    let lyrics:                  [LyricLine]
    let currentIndex:            Int?
    let romanizedLyrics:         [String]
    let chineseConversionLyrics: [String]
    let translatedLyric:         [String]
    let blurFullscreen:          Bool
    let padding:                 CGFloat

    // MARK: Coordinator

    class Coordinator: NSObject {
        var scrollView:   NonScrollableScrollView!
        var documentView: LyricsDocumentView!

        // Shadow copies for change detection
        var prevLyrics:            [LyricLine] = []
        var prevIndex:             Int?         = nil
        var prevIndexWasNil:       Bool         = true
        var prevRomanized:         [String]     = []
        var prevChinese:           [String]     = []
        var prevTranslated:        [String]     = []
        var prevBlur:              Bool         = false
        var prevPadding:           CGFloat      = 0
        /// Set when lyrics change so only the first async fires the pre-position logic.
        var pendingPrePosition:    Bool         = false

        /// Sync the document view's frame to match the clip view's current width
        /// and the computed content height.  Call this any time lyrics or clip
        /// width may have changed.
        func syncDocumentFrame() {
            guard let sv = scrollView, let dv = documentView else { return }
            let clipW = sv.contentView.bounds.width
            guard clipW > 0 else { return }
            let h = dv.computeTotalHeight(clipWidth: clipW)
            let newFrame = NSRect(x: 0, y: 0, width: clipW - trailInset, height: h)
            if dv.frame != newFrame {
                dv.frame = newFrame
                dv.needsLayout = true
                sv.reflectScrolledClipView(sv.contentView)
            }
        }

        @objc func clipViewResized(_ note: Notification) {
            syncDocumentFrame()
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: makeNSView

    func makeNSView(context: Context) -> NonScrollableScrollView {
        let scrollView = NonScrollableScrollView()
        scrollView.hasVerticalScroller   = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground       = false
        scrollView.verticalScrollElasticity   = .none
        scrollView.horizontalScrollElasticity = .none

        let documentView = LyricsDocumentView()
        documentView.topPadding    = padding
        documentView.bottomPadding = padding
        // translatesAutoresizingMaskIntoConstraints = true (default) — fully frame-based,
        // no constraints that could propagate to SwiftUI's hosting view.
        scrollView.documentView = documentView

        let c = context.coordinator
        c.scrollView   = scrollView
        c.documentView = documentView

        // Watch clip-view frame changes (window resize) to keep document width in sync.
        scrollView.contentView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(
            c, selector: #selector(Coordinator.clipViewResized(_:)),
            name: NSView.frameDidChangeNotification,
            object: scrollView.contentView)

        return scrollView
    }

    // MARK: updateNSView

    func updateNSView(_ nsView: NonScrollableScrollView, context: Context) {
        let c = context.coordinator

        if padding != c.prevPadding {
            c.prevPadding = padding
            c.documentView.topPadding    = padding
            c.documentView.bottomPadding = padding
        }

        let lyricsChanged      = lyrics != c.prevLyrics
        let indexBecameValid   = c.prevIndexWasNil && currentIndex != nil
        let suppressAnimations = lyricsChanged || indexBecameValid

        if lyricsChanged {
            c.prevLyrics = lyrics
            c.pendingPrePosition = true    // arm the one-shot pre-position
            rebuildCells(coordinator: c)   // always instant inside rebuildCells
        }

        let needsRefresh = lyricsChanged
            || currentIndex         != c.prevIndex
            || romanizedLyrics      != c.prevRomanized
            || chineseConversionLyrics != c.prevChinese
            || translatedLyric      != c.prevTranslated
            || blurFullscreen       != c.prevBlur
        
        // Capture before prevIndex is updated so we know if the index itself moved.
        let indexJustChanged = currentIndex != c.prevIndex && currentIndex != nil

        if needsRefresh {
            c.prevIndex             = currentIndex
            c.prevIndexWasNil       = currentIndex == nil
            c.prevRomanized         = romanizedLyrics
            c.prevChinese           = chineseConversionLyrics
            c.prevTranslated        = translatedLyric
            c.prevBlur              = blurFullscreen
            refreshCells(coordinator: c, animated: !suppressAnimations)
        }

        // Sync document frame (content height may have changed).
        c.syncDocumentFrame()
        
        // For layout-only changes (romanization / translation toggle) correct the scroll
        // position synchronously — before AppKit renders — so the user never sees a jump.
        let layoutOnlyChange = needsRefresh && !indexJustChanged && !lyricsChanged
        if layoutOnlyChange, let idx = currentIndex {
            c.documentView.layoutSubtreeIfNeeded()
            scrollToCenter(coordinator: c, index: idx, animated: false)
        }

        // Scroll after layout has settled.
        let targetIndex = currentIndex
        DispatchQueue.main.async { [c] in
            c.syncDocumentFrame()   // re-check now that real dimensions are known
            if let idx = targetIndex {
                // A lyric is active — clear any pending pre-position and scroll to it.
                c.pendingPrePosition = false
                self.scrollToCenter(coordinator: c, index: idx, animated: true)
            } else if c.pendingPrePosition, !self.lyrics.isEmpty {
                // New song loaded, no lyric active yet.
                // Consume the flag immediately so only THIS async fires the pre-position.
                c.pendingPrePosition = false

                // Compute first cell's midY directly from topPadding + rowHeight so we
                // don't depend on cell.frame being laid out yet.
                let sv  = c.scrollView!
                let dv  = c.documentView!
                sv.layoutSubtreeIfNeeded()
                c.syncDocumentFrame()
                let clipW = sv.contentView.bounds.width
                let docW  = max(0, clipW - trailInset)
                guard docW > 0 else { return }

                let first = self.lyrics[0]
                let primaryText: String
                if !self.romanizedLyrics.isEmpty              { primaryText = self.romanizedLyrics[0] }
                else if !self.chineseConversionLyrics.isEmpty { primaryText = self.chineseConversionLyrics[0] }
                else                                          { primaryText = first.words }
                let translation: String? = (
                    !self.translatedLyric.isEmpty
                    && first.words != self.translatedLyric[0]) ? self.translatedLyric[0] : nil

                let firstH   = rowHeight(primary: primaryText, translation: translation, cellWidth: docW)
                let cellMidY = dv.topPadding + firstH / 2
                let visH     = sv.contentView.bounds.height
                let anchor   = (visH - 150) / 2
                let targetY  = max(0, cellMidY - anchor)
                sv.contentView.scroll(to: NSPoint(x: 0, y: targetY))
                sv.reflectScrolledClipView(sv.contentView)
            }
            // currentIndex == nil but no pending pre-position → keep current scroll position.
        }
    }

    // MARK: Cell management

    private func rebuildCells(coordinator: Coordinator) {
        let dv = coordinator.documentView!
        for v in dv.lyricViews { v.removeFromSuperview() }
        dv.lyricViews = lyrics.map { _ in LyricCellView() }
        for v in dv.lyricViews { dv.addSubview(v) }
        refreshCells(coordinator: coordinator, animated: false)
    }

    private func refreshCells(coordinator: Coordinator, animated: Bool = true) {
        let count = lyrics.count
        for (i, view) in coordinator.documentView.lyricViews.enumerated() {
            guard i < count else { break }
            let element = lyrics[i]

            let primary: String
            if !romanizedLyrics.isEmpty, i < romanizedLyrics.count {
                primary = romanizedLyrics[i]
            } else if !chineseConversionLyrics.isEmpty, i < chineseConversionLyrics.count {
                primary = chineseConversionLyrics[i]
            } else {
                primary = element.words
            }

            let translation: String?
            if !translatedLyric.isEmpty, i < translatedLyric.count,
               element.words != translatedLyric[i] {
                translation = translatedLyric[i]
            } else {
                translation = nil
            }

            let isPastLine = currentIndex.map { i < $0 } ?? false
            let distance   = currentIndex.map { abs(i - $0) } ?? 0
            let animDelay  = isPastLine ? 0 : min(Double(distance) * 0.05, 0.3)

            view.configure(
                primaryText:     primary,
                translationText: translation,
                isCurrentLine:   (i == currentIndex),
                isLastLine:      (i == count - 1),
                isPastLine:      isPastLine,
                blurRadius:      blurFullscreen ? (currentIndex == nil ? 6.0 : min(CGFloat(distance) * 1.5, 6.0)) : 0.0,
                animationDelay:  animDelay,
                skipAnimations:  !animated)
        }
    }

    // MARK: Scrolling

    private func scrollToCenter(coordinator: Coordinator, index: Int, animated: Bool) {
        let dv = coordinator.documentView!
        let sv = coordinator.scrollView!
        guard index < dv.lyricViews.count else { return }

        dv.layoutSubtreeIfNeeded()

        let cell  = dv.lyricViews[index]
        let cellY = cell.frame.midY          // document-view coordinates (flipped, top-down)
        let visH  = sv.contentView.bounds.height
        let docH  = dv.frame.height

        // Anchor the focused lyric at the vertical centre of the album art on the left panel.
        // Left panel layout (FullscreenView): Spacer / albumArt(550pt) / spacing(8) /
        //   titleGroup(35pt) / spacing(8) / buttons(25pt) / spacing(8) / tooltip(20pt) / Spacer
        // belowAlbumArt = 8+35+8+25+8+20 = 104 pt
        // albumArtCentreY = (screenH − 654) / 2 + 275 = (screenH − 104) / 2
        // Since the lyrics scroll view now fills the full panel, visH ≈ screenH, so:
        let belowAlbumArt: CGFloat = 150//104
        let anchor = (visH - belowAlbumArt) / 2

        let rawY  = cellY - anchor
        let targetY = max(0, min(rawY, max(0, docH - visH)))
        let target = NSPoint(x: 0, y: targetY)

        if animated {
            let scrollDelta = targetY - sv.contentView.bounds.origin.y

            // Snap the scroll view instantly to its final position.
            sv.contentView.scroll(to: target)
            sv.reflectScrolledClipView(sv.contentView)

            // Only stagger if there's meaningful movement.
            guard abs(scrollDelta) > 1 else { return }

            let animDuration: CFTimeInterval = 0.42   // slightly longer to let the trail breathe
            let staggerDelay = 0.03

            // Animate only cells near the visible area (index ± 20).
            let lo = max(0, index - 20)
            let hi = min(dv.lyricViews.count - 1, index + 20)
            for i in lo...hi {
                let cellView = dv.lyricViews[i]
                guard let layer = cellView.layer else { continue }

                // Cancel any in-flight stagger.
                layer.removeAnimation(forKey: "staggerTranslation")

                let distance = abs(i - index)
                let delay = min(Double(distance) * staggerDelay, 0.3)

                // Model is already at identity (final state).
                layer.transform = CATransform3DIdentity

                // Animate from old visual position (offset by scrollDelta) to identity.
                let anim = CABasicAnimation(keyPath: "transform.translation.y")
                anim.fromValue = scrollDelta   // where the cell appeared to be before the snap
                anim.toValue   = 0.0
                anim.beginTime = CACurrentMediaTime() + delay
                anim.duration  = animDuration
                // Custom bezier: start velocity = c1y/c1x = 0.8/0.4 = 2×, end velocity = 0 (c2y=1.0).
                // This gives a natural easeOut feel that fully trails to a stop instead of snapping.
                anim.timingFunction = CAMediaTimingFunction(controlPoints: 0.4, 0.8, 0.6, 1.0)
                anim.fillMode  = .backwards    // show fromValue before beginTime
                anim.isRemovedOnCompletion = true
                layer.add(anim, forKey: "staggerTranslation")
            }
        } else {
            sv.contentView.scroll(to: target)
            sv.reflectScrolledClipView(sv.contentView)
        }
    }

    private func scrollToTop(coordinator: Coordinator, animated: Bool) {
        let sv = coordinator.scrollView!
        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.35
                sv.contentView.animator().setBoundsOrigin(.zero)
            }
            sv.reflectScrolledClipView(sv.contentView)
        } else {
            sv.contentView.scroll(to: .zero)
            sv.reflectScrolledClipView(sv.contentView)
        }
    }
}
#endif
