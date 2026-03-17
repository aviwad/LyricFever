//
//  LyricsNSScrollView.swift
//  Lyric Fever
//
//  Custom AppKit lyrics view for the fullscreen view.
//
//  Architecture:
//  • No NSScrollView. LyricsContainerView positions every cell absolutely,
//    clipping cells that fall outside its bounds.
//  • When the current index changes, each cell springs from its previous
//    visual position (read from the presentation layer) to its new computed
//    position.  Cells *below* the active line are delayed by
//    (distance × 45 ms), reproducing the Apple-Music cascade feel.
//  • Blur transitions are driven by CABasicAnimation on the CIGaussianBlur
//    filter's inputRadius, so the active line smoothly unblurs.
//  • All NSTextField labels use frame-based layout
//    (translatesAutoresizingMaskIntoConstraints stays true) to avoid the
//    NSTextField.updateConstraints → SwiftUI hosting-view loop.
//

#if os(macOS)
import AppKit
import SwiftUI

// MARK: - Constants / font helpers

private let primaryFont     = NSFont.boldSystemFont(ofSize: 40)
private let translationFont = NSFont.systemFont(ofSize: 33, weight: .semibold)
private let cellPad:    CGFloat = 20
private let labelGap:   CGFloat = 3
private let trailInset: CGFloat = 100

/// Height of a single wrapped text block at the given max width.
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

// MARK: - Lyric cell view

class LyricCellView: NSView {

    // Frame-based labels — translatesAutoresizingMaskIntoConstraints stays TRUE.
    let primaryLabel     = NSTextField(labelWithString: "")
    let translationLabel = NSTextField(labelWithString: "")

    // Persistent CIFilter so we can animate its inputRadius via CABasicAnimation.
    private var blurFilter: CIFilter?
    private var currentBlurRadius: CGFloat = -1   // −1 = not yet set

    override var isFlipped: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.masksToBounds = false

        // Install the blur filter once.  Give it a stable KVC name so the
        // Core Animation key path "filters.lyricBlur.inputRadius" works.
        if let f = CIFilter(name: "CIGaussianBlur") {
            f.setValue("lyricBlur", forKey: "name")
            f.setValue(0.0, forKey: kCIInputRadiusKey)
            layer?.filters = [f]
            blurFilter = f
        }

        for label in [primaryLabel, translationLabel] {
            label.isBezeled       = false
            label.drawsBackground = false
            label.isEditable      = false
            label.isSelectable    = false
            label.textColor       = .white
            label.maximumNumberOfLines = 0
            label.lineBreakMode   = .byWordWrapping
            label.usesSingleLineMode = false
            addSubview(label)
        }
        primaryLabel.font     = primaryFont
        translationLabel.font = translationFont
        translationLabel.alphaValue = 0.85
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: Frame-based label layout

    override func resizeSubviews(withOldSize _: NSSize) { layoutLabels() }

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

    // MARK: Blur animation

    /// Animate (or snap) the Gaussian blur radius.
    /// - `animated` is ignored on first call (no "from" value yet).
    func setBlur(_ target: CGFloat, animated: Bool) {
        let current = currentBlurRadius
        guard abs(target - max(0, current)) > 0.01 else { return }
        let from = current < 0 ? target : current
        currentBlurRadius = target
        blurFilter?.setValue(target, forKey: kCIInputRadiusKey)
        guard animated, from >= 0, window != nil else { return }

        let anim = CABasicAnimation(keyPath: "filters.lyricBlur.inputRadius")
        anim.fromValue = from
        anim.toValue   = target
        // Becoming active → slow ease-out unblur.  Becoming inactive → quick ease-in.
        anim.duration  = target == 0 ? 0.45 : 0.15
        anim.timingFunction = CAMediaTimingFunction(name: target == 0 ? .easeOut : .easeIn)
        anim.isRemovedOnCompletion = true
        layer?.add(anim, forKey: "blurTransition")
    }

    // MARK: Configure

    func configure(primaryText: String, translationText: String?,
                   isCurrentLine: Bool, isLastLine: Bool,
                   blurRadius: CGFloat, animateBlur: Bool) {
        primaryLabel.stringValue = primaryText
        if let t = translationText, !t.isEmpty {
            translationLabel.stringValue = t
            translationLabel.isHidden = false
        } else {
            translationLabel.isHidden = true
        }
        alphaValue = isLastLine ? 0 : (isCurrentLine ? 1.0 : 0.8)
        setBlur(blurRadius, animated: animateBlur)
        layoutLabels()
    }
}

// MARK: - Container view  (no scroll — cells are positioned absolutely)

class LyricsContainerView: NSView {

    override var isFlipped: Bool { true }

    var lyricViews:   [LyricCellView] = []
    var cellHeights:  [CGFloat]       = []
    var cumulativeYs: [CGFloat]       = []   // cumulativeYs[i] = Σ heights[0..<i]
    var currentIndex: Int             = 0

    // Generation token — incremented at the start of every positionAllCells call.
    // Delayed spring closures compare against this to self-cancel when superseded.
    private var cascadeGeneration = 0
    private var lastLayoutWidth: CGFloat = 0

    // MARK: Metrics

    func computeCellMetrics(width: CGFloat) {
        let cellWidth = width - trailInset
        cumulativeYs = [0]
        cellHeights  = []
        for cell in lyricViews {
            let h = rowHeight(
                primary:     cell.primaryLabel.stringValue,
                translation: cell.translationLabel.isHidden ? nil : cell.translationLabel.stringValue,
                cellWidth:   cellWidth)
            cellHeights.append(h)
            cumulativeYs.append(cumulativeYs.last! + h)
        }
    }

    /// Y origin (in container coords, flipped) for cell i given currentIndex.
    private func targetY(forCell i: Int) -> CGFloat {
        guard i < cumulativeYs.count,
              currentIndex < cumulativeYs.count,
              currentIndex < cellHeights.count else { return 0 }
        let currentMidY = cumulativeYs[currentIndex] + cellHeights[currentIndex] / 2
        return bounds.height / 2 - currentMidY + cumulativeYs[i]
    }

    // MARK: Positioning

    /// Reposition every cell, optionally with the cascade spring animation.
    func positionAllCells(animated: Bool) {
        // Bump generation so any previously-scheduled delayed springs abort.
        cascadeGeneration += 1
        let myGen = cascadeGeneration

        let w = bounds.width
        guard w > 0, !lyricViews.isEmpty, !cellHeights.isEmpty else { return }
        let cellWidth = w - trailInset

        for (i, cell) in lyricViews.enumerated() {
            guard i < cellHeights.count else { break }

            let ty        = targetY(forCell: i)
            let newFrame  = NSRect(x: 0, y: ty, width: cellWidth, height: cellHeights[i])

            // ── No animation path ────────────────────────────────────────────
            guard animated else {
                cell.layer?.removeAnimation(forKey: "cascadePosition")
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                cell.frame = newFrame
                cell.layer?.transform = CATransform3DIdentity
                CATransaction.commit()
                continue
            }

            // ── Animated path ────────────────────────────────────────────────
            // Capture the cell's current *visual* Y (presentation layer when
            // mid-animation, otherwise the model frame).
            let fromY: CGFloat = cell.layer?.presentation()?.frame.origin.y
                                    ?? cell.frame.origin.y
            let deltaY = newFrame.origin.y - fromY

            // Set model to final frame immediately (presentation layer will
            // show the spring overshoot/settle on top of this).
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            cell.frame = newFrame
            if abs(deltaY) > 0.5 {
                // Offset the cell so it visually starts at the old position.
                // In a flipped NSView, positive translation.y moves the cell
                // downward, so we negate deltaY to reproduce the old position.
                cell.layer?.transform = CATransform3DMakeTranslation(0, -deltaY, 0)
            } else {
                cell.layer?.transform = CATransform3DIdentity
            }
            CATransaction.commit()

            guard abs(deltaY) > 0.5 else { continue }

            // Cells more than ~20 rows away are off-screen; snap them.
            let distance = abs(i - currentIndex)
            guard distance <= 20 else {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                cell.layer?.transform = CATransform3DIdentity
                CATransaction.commit()
                continue
            }

            // Cascade delay: cells BELOW the active line arrive later.
            let delay: Double = i > currentIndex
                ? min(Double(i - currentIndex) * 0.045, 0.35)
                : 0

            // Spring parameters: the active line and lines above it use a
            // tighter spring; lines below use a looser one for the wave feel.
            let damping:  CGFloat = i <= currentIndex ? 24 : 20
            let stiffness: CGFloat = i <= currentIndex ? 380 : 280

            let springAction: () -> Void = { [weak self, weak cell] in
                guard let self, let cell,
                      self.cascadeGeneration == myGen else { return }

                let spring = CASpringAnimation(keyPath: "transform.translation.y")
                spring.fromValue       = -deltaY
                spring.toValue         = 0
                spring.damping         = damping
                spring.stiffness       = stiffness
                spring.mass            = 1.0
                spring.initialVelocity = 0
                spring.duration        = spring.settlingDuration
                spring.isRemovedOnCompletion = true
                cell.layer?.add(spring, forKey: "cascadePosition")

                // Set model transform to identity; presentation layer runs the spring.
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                cell.layer?.transform = CATransform3DIdentity
                CATransaction.commit()
            }

            if delay > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: springAction)
            } else {
                springAction()
            }
        }
    }

    // MARK: NSView layout (window resize / first layout)

    override func layout() {
        super.layout()
        let w = bounds.width
        guard w > 0 else { return }
        if abs(w - lastLayoutWidth) > 0.5 {
            lastLayoutWidth = w
            computeCellMetrics(width: w)
        }
        positionAllCells(animated: false)
    }
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

    // MARK: Coordinator

    class Coordinator: NSObject {
        var containerView: LyricsContainerView!

        var prevLyrics:            [LyricLine] = []
        var prevIndex:             Int?         = nil
        var prevRomanized:         [String]     = []
        var prevChinese:           [String]     = []
        var prevTranslated:        [String]     = []
        var prevTranslationExists: Bool         = false
        var prevBlur:              Bool         = false
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: makeNSView

    func makeNSView(context: Context) -> LyricsContainerView {
        let container = LyricsContainerView()
        container.wantsLayer = true
        container.layer?.masksToBounds = true
        context.coordinator.containerView = container
        return container
    }

    // MARK: updateNSView

    func updateNSView(_ nsView: LyricsContainerView, context: Context) {
        let c = context.coordinator

        let lyricsChanged = lyrics != c.prevLyrics
        if lyricsChanged {
            c.prevLyrics = lyrics
            rebuildCells(coordinator: c)
        }

        let indexChanged  = currentIndex != c.prevIndex
        let needsRefresh  = lyricsChanged
            || indexChanged
            || romanizedLyrics         != c.prevRomanized
            || chineseConversionLyrics != c.prevChinese
            || translatedLyric         != c.prevTranslated
            || translationExists       != c.prevTranslationExists
            || blurFullscreen          != c.prevBlur

        if needsRefresh {
            c.prevIndex             = currentIndex
            c.prevRomanized         = romanizedLyrics
            c.prevChinese           = chineseConversionLyrics
            c.prevTranslated        = translatedLyric
            c.prevTranslationExists = translationExists
            c.prevBlur              = blurFullscreen
            // Only animate blur when the index changes (not on a full rebuild).
            refreshCells(coordinator: c, animateBlur: !lyricsChanged && indexChanged)
        }

        // Defer the repositioning until after SwiftUI has applied the view's
        // frame so bounds.height is non-zero.
        let targetIdx      = currentIndex
        let shouldAnimate  = !lyricsChanged && needsRefresh
        DispatchQueue.main.async { [c] in
            let cv = c.containerView!
            guard cv.bounds.width > 0 else { return }
            cv.currentIndex = targetIdx ?? 0
            if cv.cellHeights.isEmpty {
                cv.computeCellMetrics(width: cv.bounds.width)
            }
            cv.positionAllCells(animated: shouldAnimate && targetIdx != nil)
        }
    }

    // MARK: Cell management

    private func rebuildCells(coordinator: Coordinator) {
        let cv = coordinator.containerView!
        for v in cv.lyricViews { v.removeFromSuperview() }
        cv.lyricViews   = lyrics.map { _ in LyricCellView() }
        cv.cellHeights  = []
        cv.cumulativeYs = []
        for v in cv.lyricViews { cv.addSubview(v) }
        refreshCells(coordinator: coordinator, animateBlur: false)
    }

    private func refreshCells(coordinator: Coordinator, animateBlur: Bool) {
        let cv    = coordinator.containerView!
        let count = lyrics.count
        for (i, view) in cv.lyricViews.enumerated() {
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
                blurRadius:      blurFullscreen && (i != currentIndex) ? 5.0 : 0.0,
                animateBlur:     animateBlur)
        }
    }
}
#endif
