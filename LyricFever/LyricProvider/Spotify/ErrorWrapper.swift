//
//  ErrorWrapper.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-05.
//


struct ErrorWrapper: Codable {
    struct Error: Codable {
        let code: Int
        let message: String
    }

    let error: Error
}
