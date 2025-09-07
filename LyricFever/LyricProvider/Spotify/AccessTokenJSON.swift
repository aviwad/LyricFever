//
//  accessTokenJSON.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-05.
//

import Foundation


struct AccessTokenJSON: Codable {
    let accessToken: String
    let accessTokenExpirationTimestampMs: TimeInterval
    let isAnonymous: Bool
}
