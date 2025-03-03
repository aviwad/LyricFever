//
//  LyricsParser.swift
//  SpotlightLyrics
//
//  Created by Scott Rong on 2017/4/2.
//  Copyright © 2017 Scott Rong. All rights reserved.
//

import Foundation

public class LyricsParser {
    
    public var header: LyricsHeader
    var lyrics: [LyricLine] = []
    
    // MARK: Initializers
    
    public init(lyrics: String) {
        header = LyricsHeader()
        commonInit(lyrics: lyrics)
    }
    
    
    private func commonInit(lyrics: String) {
        header = LyricsHeader()
        parse(lyrics: lyrics)
    }
    
    
    // MARK: Privates
    
    private func parse(lyrics: String) {
        let lines = lyrics
            .replacingOccurrences(of: "\\n", with: "\n")
            .trimmingCharacters(in: .quotes)
            .trimmingCharacters(in: .newlines)
            .components(separatedBy: .newlines)
        
        for line in lines {
            parseLine(line: line)
        }
        
        // sort by time
        self.lyrics.sort{ $0.startTimeMS < $1.startTimeMS }
        
        // parse header into lyrics
        // insert header distribute by averge time intervals
//        if self.lyrics.count > 0 {
//            var headers: [String] = []
//            
//            if let title = header.title {
//                headers.append(title)
//            }
//            
//            if let author = header.author {
//                headers.append(author)
//            }
//            if let album = header.album {
//                headers.append(album)
//            }
//            if let by = header.by {
//                headers.append(by)
//            }
//            if let editor = header.editor {
//                headers.append(editor)
//            }
//            
////            let intervalPerHeader = self.lyrics[0].time / TimeInterval(headers.count)
//            
////            var headerLyrics: [LyricsItem] = headers.enumerated().map { LyricsItem(time: intervalPerHeader * TimeInterval($0.offset), text: $0.element) }
////            if (headerLyrics.count > 0) {
////                headerLyrics.append(LyricsItem(time: intervalPerHeader * TimeInterval(headerLyrics.count), text: ""))
////            }
////            
////            self.lyrics.insert(contentsOf: headerLyrics, at: 0)
//        }
        
    }
    
    private func parseLine(line: String) {
        guard let line = line.blankToNil() else {
            return
        }

//        if let title = parseHeader(prefix: "ti", line: line) {
//            header.title = title
//            return
//        }
//        if let author = parseHeader(prefix: "ar", line: line) {
//            header.author = author
//            return
//        }
//        if let album = parseHeader(prefix: "al", line: line) {
//            header.album = album
//            return
//        }
//        if let by = parseHeader(prefix: "by", line: line) {
//            header.by = by
//            return
//        }
        if let offset = parseHeader(prefix: "offset", line: line) {
            header.offset = TimeInterval(offset) ?? 0
            return
        }
        if !line.hasSuffix("]") {
            lyrics += parseLyric(line: line)
        }
//        if let editor = parseHeader(prefix: "re", line: line) {
//            header.editor = editor
//            return
//        }
//        if let version = parseHeader(prefix: "ve", line: line) {
//            header.version = version
//            return
//        }
        
    }
    
    private func parseHeader(prefix: String, line: String) -> String? {
        if line.hasPrefix("[" + prefix + ":") && line.hasSuffix("]") {
            let startIndex = line.index(line.startIndex, offsetBy: prefix.count + 2)
            let endIndex = line.index(line.endIndex, offsetBy: -1)
            return String(line[startIndex..<endIndex])
        } else {
            return nil
        }
    }
    
    private func parseLyric(line: String) -> [LyricLine] {
        var cLine = line
        var items : [LyricLine] = []
        while(cLine.hasPrefix("[")) {
            guard let closureIndex = cLine.range(of: "]")?.lowerBound else {
                break
            }
            
            let startIndex = cLine.index(cLine.startIndex, offsetBy: 1)
            let endIndex = cLine.index(closureIndex, offsetBy: -1)
            let amidString = String(cLine[startIndex..<endIndex])
            
            let amidStrings = amidString.components(separatedBy: ":")
            var hour:TimeInterval = 0
            var minute: TimeInterval = 0
            var second: TimeInterval = 0
            if amidStrings.count >= 1 {
                second = TimeInterval(amidStrings[amidStrings.count - 1]) ?? 0
            }
            if amidStrings.count >= 2 {
                minute = TimeInterval(amidStrings[amidStrings.count - 2]) ?? 0
            }
            if amidStrings.count >= 3 {
                hour = TimeInterval(amidStrings[amidStrings.count - 3]) ?? 0
            }

//            items.append(LyricLine(startTime: 1000*(hour * 3600 + minute * 60 + second + header.offset), words: <#T##String#>))
//            
//            cLine.removeSubrange(line.startIndex..<cLine.index(closureIndex, offsetBy: 1))
            cLine.removeSubrange(cLine.startIndex..<cLine.index(closureIndex, offsetBy: 1))
            cLine = cLine.trimmingCharacters(in: .whitespaces)
                    // Create a LyricLine with the calculated start time and the remaining line as the words
            let lyricLine = LyricLine(startTime: 1000*(hour * 3600 + minute * 60 + second + header.offset), words: cLine)
            items.append(lyricLine)
        }
        
//        if items.count == 0 {
//            items.append(LyricsItem(time: 0, text: line))
//        }

//        items.forEach{ $0.text = cLine }
        return items
    }
}
