//
//  TTMLParser.swift
//  Lyric Fever
//

import Foundation

enum TTMLParserError: Error {
    case invalidXML
    case missingBody
}

struct TTMLParser {
    /// Parse Apple's TTML lyric document into LyricLine values. Synced timestamps
    /// when present; otherwise startTimeMS == 0 for every line (caller can decide
    /// to display them as a static block).
    static func parse(_ data: Data) throws -> [LyricLine] {
        let doc: XMLDocument
        do {
            doc = try XMLDocument(data: data)
        } catch {
            throw TTMLParserError.invalidXML
        }

        // local-name() so we don't fight the TTML namespace prefix
        let paragraphs = try doc.nodes(forXPath: "//*[local-name()='p']")
        guard !paragraphs.isEmpty else { throw TTMLParserError.missingBody }

        return paragraphs.compactMap { node -> LyricLine? in
            guard let el = node as? XMLElement else { return nil }
            let beginAttr = el.attribute(forName: "begin")?.stringValue
            let startMS = beginAttr.flatMap { parseTimecode($0) } ?? 0
            let text = (el.stringValue ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            return LyricLine(startTime: TimeInterval(startMS), words: text)
        }
    }

    /// Parse `HH:MM:SS.mmm`, `MM:SS.mmm`, or `S.mmm` → milliseconds.
    static func parseTimecode(_ s: String) -> Int? {
        let parts = s.split(separator: ":").map(String.init)
        let secondsStr: String
        var hours = 0, minutes = 0
        switch parts.count {
        case 1: secondsStr = parts[0]
        case 2: minutes = Int(parts[0]) ?? 0; secondsStr = parts[1]
        case 3: hours = Int(parts[0]) ?? 0; minutes = Int(parts[1]) ?? 0; secondsStr = parts[2]
        default: return nil
        }
        guard let seconds = Double(secondsStr) else { return nil }
        let total = Double(hours) * 3_600_000 + Double(minutes) * 60_000 + seconds * 1000
        return Int(total.rounded())
    }
}
