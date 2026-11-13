//
//  SearchResultsNSTableView.swift
//  Lyric Fever
//
//  Created by Salman Navroz on 4/2/26.
//

import SwiftUI

struct SearchResultsNSTableView: NSViewRepresentable {
    let results: [SongResult]
    @Binding var selectedID: UUID?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let tableView = NSTableView()

        for (id, title) in [
            ("provider", String(localized: "Lyric Provider")),
            ("song", String(localized: "Song Name")),
            ("album", String(localized: "Album Name")),
            ("artist", String(localized: "Artist Name"))
        ] {
            let col = NSTableColumn(identifier: .init(id))
            col.title = title
            col.resizingMask = .autoresizingMask
            tableView.addTableColumn(col)
        }

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.allowsMultipleSelection = false
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.style = .inset

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let c = context.coordinator
        c.results = results
        c.parent = self

        guard let tableView = nsView.documentView as? NSTableView else { return }
        tableView.reloadData()

        if let selectedID, let idx = results.firstIndex(where: { $0.id == selectedID }) {
            tableView.selectRowIndexes(IndexSet(integer: idx), byExtendingSelection: false)
        } else {
            tableView.deselectAll(nil)
        }
    }

    class Coordinator: NSObject {
        var parent: SearchResultsNSTableView
        var results: [SongResult] = []

        init(_ parent: SearchResultsNSTableView) {
            self.parent = parent
        }
    }
}

extension SearchResultsNSTableView.Coordinator: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        results.count
    }
}
extension SearchResultsNSTableView.Coordinator: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < results.count else { return nil }
        let result = results[row]
        let text: String
        switch tableColumn?.identifier.rawValue {
        case "provider":
            text = result.lyricType
        case "song":
            text = result.songName
        case "album":
            text = result.albumName
        case "artist":
            text = result.artistName
        default:         
            text = ""
        }
        let cell = NSTextField(labelWithString: text)
        cell.lineBreakMode = .byTruncatingTail
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tv = notification.object as? NSTableView else { return }
        let row = tv.selectedRow
        if row >= 0, row < results.count {
            parent.selectedID = results[row].id
        } else {
            parent.selectedID = nil
        }
    }
}
