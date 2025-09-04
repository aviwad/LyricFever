//
//  LocalFileUploadProvider.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//


//
//  LocalFileUploadProvider.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-18.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

class LocalFileUploadProvider {
    @MainActor
    func selectLRC() async -> URL? {
        defer {
            NSApp.setActivationPolicy(.accessory)
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
        let folderChooserPoint = CGPoint(x: 0, y: 0)
        let folderChooserSize = CGSize(width: 500, height: 600)
        let folderChooserRectangle = CGRect(origin: folderChooserPoint, size: folderChooserSize)
        NSApp.setActivationPolicy(.regular)
        let folderPicker =  NSOpenPanel(contentRect: folderChooserRectangle, styleMask: .resizable, backing: .buffered, defer: true)
        folderPicker.title = "Select an LRC File for \(ViewModel.shared.currentlyPlayingName ?? "")"
        let lrcType = UTType(filenameExtension: "lrc")!
        folderPicker.allowedContentTypes = [lrcType] // Only allow .lrc files
        folderPicker.allowsMultipleSelection = false // Only allow a single selection
        folderPicker.canChooseFiles = true // Allow file selection
        folderPicker.canChooseDirectories = false // Disallow directory selection
        let response = await folderPicker.begin()
        if response == .OK {
            return folderPicker.url
        }
        return nil
    }


    func localFetch(for trackID: String, _ trackName: String) async throws -> [LyricLine] {
        if let fileUrl = await selectLRC(), let lyricText = try? String(contentsOf: fileUrl, encoding: .utf8) {
            let parser = LyricsParser(lyrics: lyricText)
            return parser.lyrics
        } else {
            return []
        }
    }
    
}
