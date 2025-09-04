//
//  TranslationSessionRequest.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-04.
//

import Translation

extension TranslationSession.Request {
    init(lyric: LyricLine) {
        self.init(sourceText: lyric.words, clientIdentifier: lyric.id.uuidString)
    }
}
