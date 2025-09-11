//
//  ChineseConversion.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-09-08.
//

enum ChineseConversion: Int, CaseIterable, Identifiable {
    case none = 0
    case simplified
    case traditionalNeutral
    case traditionalTaiwan
    case traditionalHK
    
    var id: Self {
        return self
    }
    
    var description: String {
        switch self {
            case .none:
                "None"
            case .simplified:
                "Simplified"
            case .traditionalNeutral:
                "Traditional (Neutral)"
            case .traditionalTaiwan:
                "Traditional (Taiwan)"
            case .traditionalHK:
                "Traditional (HK)"
        }
    }
}
