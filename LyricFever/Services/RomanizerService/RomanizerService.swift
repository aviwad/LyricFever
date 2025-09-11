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
import OpenCC

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
        print("Generating Romanized String for lyric \(lyric.words)")
        if let language = NLLanguageRecognizer.dominantLanguage(for: lyric.words), language == .japanese {
            return generateJapaneseRomanizedLyric(lyric)
        } else {
            return lyric.words.applyingTransform(.toLatin, reverse: false)
        }
    }

    static func generateMainlandTransliteration(_ lyric: LyricLine) -> String? {
        do {
            let converter = try ChineseConverter(options: [.simplify])
            return converter.convert(lyric.words)
        } catch {
            print("RomanizerService: MainlandTransliteration error: \(error)")
            return nil
        }
    }
    
    static func generateTraditionalNeutralTransliteration(_ lyric: LyricLine) -> String? {
        do {
            let converter = try ChineseConverter(options: [.traditionalize])
            return converter.convert(lyric.words)
        } catch {
            print("RomanizerService: MainlandTransliteration error: \(error)")
            return nil
        }
    }
    
    static func generateHongKongTransliteration(_ lyric: LyricLine) -> String? {
        do {
            let converter = try ChineseConverter(options: [.traditionalize, .hkStandard])
            return converter.convert(lyric.words)
        } catch {
            print("RomanizerService: HongKongTransliteration error: \(error)")
            return nil
        }
    }
    
    static func generateTaiwanTransliteration(_ lyric: LyricLine) -> String? {
        do {
            let converter = try ChineseConverter(options: [.traditionalize, .twStandard, .twIdiom])
            return converter.convert(lyric.words)
        } catch {
            print("RomanizerService: TaiwanTransliteration error: \(error)")
            return nil
        }
    }
}
