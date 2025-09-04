//
//  ButtonState.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-04.
//

import SwiftUI

@MainActor
enum ButtonState {
    case enabled
    case disabled
    case loading
    case clickable
    case missing
    
    var fillStyle: AnyShapeStyle {
        switch self {
            case .enabled:
                if let bg = ViewModel.shared.currentBackground {
                    // Use the color with desired opacity
                    return AnyShapeStyle(bg.opacity(0.8))
                } else {
                    // Fall back to a material; set opacity on the shape usage, not here
                    return AnyShapeStyle(.primary)
                }
            case .disabled:
                return AnyShapeStyle(.thickMaterial)
            case .clickable, .loading, .missing:
                return AnyShapeStyle(.thickMaterial)
        }
    }
}
