//
//  FullscreenIconStyle.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-05-06.
//

import SwiftUI

// Define a common button style for icons
struct FullscreenButtonIconStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    var ishovering = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? .primary : .gray)
            .background(configuration.isPressed ? Color.gray.opacity(0.4) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .contentShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.2), lineWidth: configuration.isPressed ? 0 : 0)
            )
    }
}

struct HoverableIcon: View {
    let systemName: String
    var sideLength: CGFloat = 32
    @State private var isHovering = false
    var disabled: Bool = false

    var body: some View {
        ZStack {
            Image(systemName: systemName)
            if disabled {
                Capsule()
                    .frame(width: 40, height: 4)
                    .rotationEffect(.degrees(-45))
                    .blendMode(.destinationOut)

                // Actual slash on top
                Capsule()
//                    .fill(Color.white)
                    .frame(width: 32, height: 2)
                    .rotationEffect(.degrees(-45))
            }
        }
        .compositingGroup()
            .frame(width: sideLength, height: sideLength)
//            .padding(6)
            .background(isHovering ? Color.gray.opacity(0.4) : Color.clear)
            .onHover { hover in
                isHovering = hover
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.2), lineWidth: isHovering ? 1 : 0)
            )
    }
}
