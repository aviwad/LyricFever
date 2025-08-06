//
//  Extensions.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-05.
//

import Foundation


// https://stackoverflow.com/questions/35407212/how-to-parse-string-to-nstimeinterval
extension String {
    func convertToTimeInterval() -> TimeInterval {
        guard self != "" else {
            return 0
        }

        var interval: Double = 0

        let parts = self.components(separatedBy: ":")
        for (index, part) in parts.reversed().enumerated() {
            interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
        }

        return interval * 1000 // Convert seconds to milliseconds
    }
}
