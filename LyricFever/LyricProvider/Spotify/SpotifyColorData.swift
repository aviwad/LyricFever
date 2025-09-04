//
//  SpotifyColorData.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-05.
//


struct SpotifyColorData: Codable {
    let background, text, highlightText: Int
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.background = try container.decode(Int.self, forKey: .background)
        self.text = try container.decode(Int.self, forKey: .text)
        self.highlightText = try container.decode(Int.self, forKey: .highlightText)
    }
}
