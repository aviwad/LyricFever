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
                return AnyShapeStyle(ViewModel.shared.currentAlbumArt.opacity(0.8))
            case .disabled:
                return AnyShapeStyle(.thickMaterial)
            case .clickable, .loading, .missing:
                return AnyShapeStyle(.thickMaterial)
        }
    }
}
