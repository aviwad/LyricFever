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
    case clickable
    
    var fillStyle: AnyShapeStyle {
        switch self {
            case .enabled:
                return AnyShapeStyle(ViewModel.shared.currentAlbumArt)
            case .disabled:
                return AnyShapeStyle(.thickMaterial)
            case .clickable:
                return AnyShapeStyle(.thickMaterial)
        }
    }
}
