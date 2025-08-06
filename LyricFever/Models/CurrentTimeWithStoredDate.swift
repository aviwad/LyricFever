//
//  CurrentTimeWithStoredDate.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//

import Foundation

struct CurrentTimeWithStoredDate {
    let currentTime: TimeInterval
    let storedDate: Date
    
    init(currentTime: TimeInterval) {
        self.currentTime = currentTime
        self.storedDate = Date()
    }
}
