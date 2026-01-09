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

typealias FuriganaAnnotation = Annotation

class RomanizerService {
    private static func generateJapaneseRomanizedString(_ string: String) -> String? {
        let ipadic=IPADic()
        let ipadicTokenizer = try? Tokenizer(dictionary: ipadic)
        guard let romajiTokens = ipadicTokenizer?.tokenize(text: string, transliteration: .romaji) else {
            return nil
        }
        let romanized = romajiTokens.map{$0.reading}.joined()
        //hachimitsu ha kuma no dai kōbutsu desu 。
        return romanized
    }
    static func generateRomanizedLyric(_ lyric: LyricLine) -> String? {
        print("Generating Romanized String for lyric \(lyric.words)")
        if let language = NLLanguageRecognizer.dominantLanguage(for: lyric.words), language == .japanese {
            return generateJapaneseRomanizedString(lyric.words)
        } else {
            return lyric.words.applyingTransform(.toLatin, reverse: false)
        }
    }
    
    private static func generateJapaneseFuriganaAnnotations(_ string: String) -> [FuriganaAnnotation]? {
        let ipadic = IPADic()
        let ipadicTokenizer = try? Tokenizer(dictionary: ipadic)
        guard let furigana = ipadicTokenizer?.tokenize(text: string, transliteration: .hiragana) else {
            return nil
        }
        return furigana.filter({$0.base != $0.reading})
    }
    static func generateFuriganaLyric(_ lyric: LyricLine) -> [FuriganaAnnotation]? {
        print("Generating Furigana String for lyric \(lyric.words)")
        guard let language = NLLanguageRecognizer.dominantLanguage(for: lyric.words), language == .japanese else {
            return []
        }
        return generateJapaneseFuriganaAnnotations(lyric.words)
    }

    static func generateRomanizedString(_ string: String) -> String? {
        print("Generating Romanized String for string \(string)")
        if let language = NLLanguageRecognizer.dominantLanguage(for: string), language == .japanese {
            return generateJapaneseRomanizedString(string)
        } else {
            return string.applyingTransform(.toLatin, reverse: false)
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
