//
//  TTMLParserTests.swift
//  LyricFeverTests
//

import XCTest
@testable import Lyric_Fever

final class TTMLParserTests: XCTestCase {
    private func fixture(_ name: String) throws -> Data {
        let bundle = Bundle(for: type(of: self))
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: nil), "\(name) not found in test bundle")
        return try Data(contentsOf: url)
    }

    func test_synced_returnsLinesWithCorrectTimestamps() throws {
        let lines = try TTMLParser.parse(try fixture("ttml-synced.ttml"))
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].words, "First line of lyrics")
        XCTAssertEqual(lines[0].startTimeMS, 12500)
        XCTAssertEqual(lines[1].startTimeMS, 14500)
        XCTAssertEqual(lines[2].startTimeMS, 16300)
    }

    func test_plain_returnsLinesWithZeroTimestamps() throws {
        let lines = try TTMLParser.parse(try fixture("ttml-plain.ttml"))
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0].startTimeMS, 0)
        XCTAssertEqual(lines[1].startTimeMS, 0)
    }

    func test_malformed_throws() throws {
        XCTAssertThrowsError(try TTMLParser.parse(try fixture("ttml-malformed.xml"))) { error in
            XCTAssertEqual(error as? TTMLParserError, .invalidXML)
        }
    }

    func test_syncedWithSpans_assemblesLineText() throws {
        let lines = try TTMLParser.parse(try fixture("ttml-synced-spans.ttml"))
        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0].startTimeMS, 20000)
        // XMLElement.stringValue concatenates text nodes (including whitespace
        // between spans), so we expect "Hello world again" or similar.
        let text = lines[0].words
        XCTAssertTrue(text.contains("Hello"))
        XCTAssertTrue(text.contains("world"))
        XCTAssertTrue(text.contains("again"))
        XCTAssertFalse(text.contains("<"), "no XML should leak through")
    }
}
