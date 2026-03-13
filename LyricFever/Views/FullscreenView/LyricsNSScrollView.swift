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
                   isCurrentLine: Bool, isLastLine: Bool, blurRadius: CGFloat) {
        primaryLabel.stringValue = primaryText
        if let t = translationText, !t.isEmpty {
            translationLabel.stringValue = t
            translationLabel.isHidden = false
        } else {
            translationLabel.isHidden = true
        }
        alphaValue = isLastLine ? 0 : (isCurrentLine ? 1.0 : 0.8)
        if blurRadius > 0, let f = CIFilter(name: "CIGaussianBlur") {
            f.setValue(blurRadius, forKey: kCIInputRadiusKey)
            layer?.filters = [f]
        } else {
            layer?.filters = []
        }
        layoutLabels()
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
    let translationExists:       Bool
    let blurFullscreen:          Bool
    let padding:                 CGFloat

    // MARK: Coordinator

    class Coordinator: NSObject {
        var scrollView:   NonScrollableScrollView!
        var documentView: LyricsDocumentView!

        // Shadow copies for change detection
        var prevLyrics:            [LyricLine] = []
        var prevIndex:             Int?         = nil
        var prevRomanized:         [String]     = []
        var prevChinese:           [String]     = []
        var prevTranslated:        [String]     = []
        var prevTranslationExists: Bool         = false
        var prevBlur:              Bool         = false
        var prevPadding:           CGFloat      = 0

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

        let lyricsChanged = lyrics != c.prevLyrics
        if lyricsChanged {
            c.prevLyrics = lyrics
            rebuildCells(coordinator: c)
        }

        let needsRefresh = lyricsChanged
            || currentIndex         != c.prevIndex
            || romanizedLyrics      != c.prevRomanized
            || chineseConversionLyrics != c.prevChinese
            || translatedLyric      != c.prevTranslated
            || translationExists    != c.prevTranslationExists
            || blurFullscreen       != c.prevBlur

        if needsRefresh {
            c.prevIndex             = currentIndex
            c.prevRomanized         = romanizedLyrics
            c.prevChinese           = chineseConversionLyrics
            c.prevTranslated        = translatedLyric
            c.prevTranslationExists = translationExists
            c.prevBlur              = blurFullscreen
            refreshCells(coordinator: c)
        }

        // Sync document frame (content height may have changed).
        c.syncDocumentFrame()

        // Scroll after layout has settled.
        let targetIndex = currentIndex
        DispatchQueue.main.async { [c] in
            c.syncDocumentFrame()   // re-check now that real dimensions are known
            if let idx = targetIndex {
                self.scrollToCenter(coordinator: c, index: idx, animated: true)
            } else {
                self.scrollToTop(coordinator: c, animated: true)
            }
        }
    }

    // MARK: Cell management

    private func rebuildCells(coordinator: Coordinator) {
        let dv = coordinator.documentView!
        for v in dv.lyricViews { v.removeFromSuperview() }
        dv.lyricViews = lyrics.map { _ in LyricCellView() }
        for v in dv.lyricViews { dv.addSubview(v) }
        refreshCells(coordinator: coordinator)
    }

    private func refreshCells(coordinator: Coordinator) {
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
            if translationExists, !translatedLyric.isEmpty, i < translatedLyric.count,
               element.words != translatedLyric[i] {
                translation = translatedLyric[i]
            } else {
                translation = nil
            }

            view.configure(
                primaryText:     primary,
                translationText: translation,
                isCurrentLine:   (i == currentIndex),
                isLastLine:      (i == count - 1),
                blurRadius:      blurFullscreen && (i != currentIndex) ? 5.0 : 0.0)
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
        let rawY  = cellY - visH / 2
        let target = NSPoint(x: 0, y: max(0, min(rawY, max(0, docH - visH))))

        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.35
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                sv.contentView.animator().setBoundsOrigin(target)
            }
            sv.reflectScrolledClipView(sv.contentView)
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
