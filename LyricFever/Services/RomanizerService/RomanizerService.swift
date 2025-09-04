//
//  RegularRomanizer.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//


//
//  RegularRomanizer.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-18.
//

import NaturalLanguage
import Mecab_Swift
import IPADic

class RomanizerService {
    private static func generateJapaneseRomanizedLyric(_ lyric: LyricLine) -> String? {
        let ipadic=IPADic()
        let ipadicTokenizer = try? Tokenizer(dictionary: ipadic)
        guard let romajiTokens = ipadicTokenizer?.tokenize(text: lyric.words, transliteration: .romaji) else {
            return nil
        }
        let romanized = romajiTokens.map{$0.reading}.joined()
        //hachimitsu ha kuma no dai kōbutsu desu 。
        return romanized
    }
    static func generateRomanizedLyric(_ lyric: LyricLine) -> String? {
        if let language = NLLanguageRecognizer.dominantLanguage(for: lyric.words), language == .japanese {
            return generateJapaneseRomanizedLyric(lyric)
        } else {
            return lyric.words.applyingTransform(.toLatin, reverse: false)
        }
    }
}
