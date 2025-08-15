//
//  MenubarButton.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-04.
//

import SwiftUI

public struct MenubarButton: View {
    let buttonText: String
    let imageText: String
//    let fillStyle: AnyShapeStyle = AnyShapeStyle(.thickMaterial)
    let buttonState: ButtonState
    let onClick: () -> Void
    
    var disabled: Bool {
        buttonState == .disabled
    }
    
    public var body: some View {
        Button {
            onClick()
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Image(systemName: imageText)
                        .bold()
                    if disabled {
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 32, height: 2)
                            .rotationEffect(.degrees(-45))
                    }
                }
            }
            .animation(.bouncy, value: buttonState)
            .frame(minWidth: 50, maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Rectangle()
                    .fill(buttonState.fillStyle)
                    .brightness(disabled ? 0.05 : 0.3)
                    .opacity(disabled ? 1 : 0.7)
                    .clipShape(.rect(cornerRadius: 10))
                    .shadow(radius: disabled ? 0 : 7)
            )
        }
        .disabled(disabled)
        .buttonStyle(.borderless)
    }
}
