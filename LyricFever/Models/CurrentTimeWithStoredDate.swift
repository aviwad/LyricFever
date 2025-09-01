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
    
    func adjustedCurrentTime(for date: Date) -> TimeInterval {
        let delta = date.timeIntervalSince(storedDate) * 1000 // convert seconds to milliseconds
        return currentTime + delta
    }
}
