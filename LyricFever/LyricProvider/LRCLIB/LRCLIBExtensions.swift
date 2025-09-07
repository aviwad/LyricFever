//
//  Extensions.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-05.
//

import Foundation


// https://stackoverflow.com/questions/35407212/how-to-parse-string-to-nstimeinterval
extension String {
    func convertToTimeInterval() -> TimeInterval {
        guard self != "" else {
            return 0
        }

        var interval: Double = 0

        let parts = self.components(separatedBy: ":")
        for (index, part) in parts.reversed().enumerated() {
            interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
        }

        return interval * 1000 // Convert seconds to milliseconds
    }
}

struct AnyCodable: Codable {}

struct PluralLRCLIBLyrics: Decodable {
    var lyrics: [LRCLIBLyrics]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var decoded: [LRCLIBLyrics] = []
        // Iterate the top-level array, attempting to decode each element.
        // If an element fails to decode as LRCLIBLyrics, consume/skip it so we can continue.
        while !container.isAtEnd {
            if let lyric = try? container.decode(LRCLIBLyrics.self) {
                decoded.append(lyric)
            } else {
                // Consume one element to advance; try decoding as a generic value to skip.
                _ = try? container.decode(AnyCodable.self)
                // If that still failed (some malformed token), try moving past it using a superDecoder.
                // This ensures we don't get stuck in an infinite loop.
                _ = try? container.superDecoder()
                print("PluralLRCLIBLyrics: Skipped one malformed LRCLIBLyrics element")
            }
        }
        self.lyrics = decoded
    }

    // Provide an encoder to keep Codable conformance symmetrical if needed later.
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.unkeyedContainer()
//        for lyric in lyrics {
//            try container.encode(lyric)
//        }
//    }
}

