//
//  LyricPreviewNSTableView.swift
//  Lyric Fever
//
//  Created by Salman Navroz on 4/2/26.
//

import SwiftUI

struct LyricPreviewNSTableView: NSViewRepresentable {
    let lyrics: [LyricLine]

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let tableView = NSTableView()

        let timeCol = NSTableColumn(identifier: .init("time"))
        timeCol.title = ""
        timeCol.width = 50
        timeCol.minWidth = 50
        timeCol.maxWidth = 60
        tableView.addTableColumn(timeCol)

        let wordsCol = NSTableColumn(identifier: .init("words"))
        wordsCol.title = ""
        wordsCol.resizingMask = .autoresizingMask
        tableView.addTableColumn(wordsCol)

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.headerView = nil
        tableView.backgroundColor = .black
        tableView.allowsMultipleSelection = false
        tableView.selectionHighlightStyle = .none
        tableView.intercellSpacing = NSSize(width: 5, height: 2)

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.lyrics = lyrics
        (nsView.documentView as? NSTableView)?.reloadData()
    }

    class Coordinator: NSObject {
        var lyrics: [LyricLine] = []
    }
}

extension LyricPreviewNSTableView.Coordinator: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        lyrics.count
    }
}

extension LyricPreviewNSTableView.Coordinator: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < lyrics.count else { return nil }
        let lyric = lyrics[row]

        let text: String
        switch tableColumn?.identifier.rawValue {
        case "time":
            let totalSeconds = Int(lyric.startTimeMS) / 1000
            let m = totalSeconds / 60
            let s = totalSeconds % 60
            text = String(format: "%d:%02d", m, s)
        case "words":
            text = lyric.words
        default:
            text = ""
        }

        let cell = NSTextField(labelWithString: text)
        cell.lineBreakMode = .byWordWrapping
        cell.textColor = .white
        return cell
    }
}
