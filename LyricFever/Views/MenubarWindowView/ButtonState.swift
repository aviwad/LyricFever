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

    var foregroundColor: Color {
        switch self {
            case .enabled:
                return ViewModel.shared.currentBackground == nil ? .primary : .white
            case .disabled:
                return .secondary
            case .loading, .clickable, .missing:
                return .primary
        }
    }
    
    var fillStyle: AnyShapeStyle {
        switch self {
            case .enabled:
                if let bg = ViewModel.shared.currentBackground {
                    // Use the color with desired opacity
                    return AnyShapeStyle(bg.opacity(0.8))
                } else {
                    return AnyShapeStyle(.regularMaterial)
                }
            case .disabled:
                return AnyShapeStyle(.ultraThinMaterial)
            case .clickable, .loading, .missing:
                return AnyShapeStyle(.ultraThinMaterial)
        }
    }
}
