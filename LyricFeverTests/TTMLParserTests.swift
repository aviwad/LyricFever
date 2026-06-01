//
//  TTMLParserTests.swift
//  LyricFeverTests
//

import XCTest
@testable import Lyric_Fever

final class TTMLParserTests: XCTestCase {
    private func fixture(_ name: String) -> Data {
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: name, withExtension: nil)!
        return try! Data(contentsOf: url)
    }

    func test_synced_returnsLinesWithCorrectTimestamps() throws {
        let lines = try TTMLParser.parse(fixture("ttml-synced.ttml"))
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].words, "First line of lyrics")
        XCTAssertEqual(lines[0].startTimeMS, 12500)
        XCTAssertEqual(lines[1].startTimeMS, 14500)
        XCTAssertEqual(lines[2].startTimeMS, 16300)
    }

    func test_plain_returnsLinesWithZeroTimestamps() throws {
        let lines = try TTMLParser.parse(fixture("ttml-plain.ttml"))
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0].startTimeMS, 0)
        XCTAssertEqual(lines[1].startTimeMS, 0)
    }

    func test_malformed_throws() {
        XCTAssertThrowsError(try TTMLParser.parse(fixture("ttml-malformed.xml")))
    }
}
