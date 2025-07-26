//
//  TOTPGenerator.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-18.
//

import SwiftOTP

// Thanks to Mx-lris
enum TOTPGenerator {
     static func generate(serverTimeSeconds: Int) -> String? {
         let secretCipher = [12, 56, 76, 33, 88, 44, 88, 33, 78, 78, 11, 66, 22, 22, 55, 69, 54]
 
         var processed = [UInt8]()
         for (i, byte) in secretCipher.enumerated() {
             processed.append(UInt8(byte ^ (i % 33 + 9)))
         }
 
         let processedStr = processed.map { String($0) }.joined()
 
         guard let utf8Bytes = processedStr.data(using: .utf8) else {
             return nil
         }
 
         let secretBase32 = utf8Bytes.base32EncodedString
 
         guard let secretData = base32DecodeToData(secretBase32) else {
             return nil
         }
 
         guard let totp = TOTP(secret: secretData, digits: 6, timeInterval: 30, algorithm: .sha1) else {
             return nil
         }
 
         return totp.generate(secondsPast1970: serverTimeSeconds)
     }
 }
