//
//  RubyTextLabel.swift
//  Lyric Fever
//
//  Created by Toby on 2026/1/10.
//

import SwiftUI
import AppKit

struct RubyTextLabel: NSViewRepresentable {
    var attributedText: NSAttributedString
    var font: NSFont
    var textColor: NSColor
    var textAlignment: NSTextAlignment
    var lineLimit: Int

    init(attributedText: NSAttributedString, 
         font: NSFont = .systemFont(ofSize: 20),
         textColor: NSColor = .white,
         textAlignment: NSTextAlignment = .center,
         lineLimit: Int = 2) {
        self.attributedText = attributedText
        self.font = font
        self.textColor = textColor
        self.textAlignment = textAlignment
        self.lineLimit = lineLimit
    }

    func makeNSView(context: Context) -> NSTextField {
        // NSTextField configured as a label is the AppKit equivalent of UILabel
        let label = NSTextField(labelWithAttributedString: attributedText)
        label.isEditable = false
        label.isSelectable = false
        label.isBezeled = false
        label.drawsBackground = false
        
        // Ensure the label hugs its content horizontally so the SwiftUI background
        // doesn't expand beyond the text width.
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return label
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.attributedStringValue = attributedText
        nsView.font = font
        nsView.textColor = textColor
        nsView.alignment = textAlignment
        
        // Configuration for multi-line support
        if lineLimit == 1 {
            nsView.usesSingleLineMode = true
            nsView.cell?.wraps = false
            nsView.cell?.isScrollable = false
            nsView.maximumNumberOfLines = 1
            nsView.cell?.lineBreakMode = .byTruncatingTail
        } else {
            nsView.usesSingleLineMode = false
            nsView.cell?.wraps = true
            nsView.cell?.isScrollable = false
            nsView.maximumNumberOfLines = lineLimit
            nsView.cell?.lineBreakMode = .byWordWrapping
        }
    }
}
