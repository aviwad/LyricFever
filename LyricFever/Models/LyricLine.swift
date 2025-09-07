//
//  LyricLine.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-05.
//

import Foundation

struct LyricLine: Decodable, Hashable {
    let startTimeMS: TimeInterval
    let words: String
    let id = UUID()

    enum CodingKeys: String, CodingKey {
        case startTimeMS = "startTimeMs"
        case words
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.startTimeMS = TimeInterval(try container.decode(String.self, forKey: .startTimeMS))!
        self.words = try container.decode(String.self, forKey: .words)
    }
    
    init(startTime: TimeInterval, words: String) {
        self.startTimeMS = startTime
        self.words = words
    }
}
