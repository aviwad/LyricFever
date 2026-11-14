//
//  MenubarButton.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-04.
//

import SwiftUI

public struct SmallMenubarButtonStyle: ButtonStyle {
    let imageText: String
    let buttonState: ButtonState
    
    var disabled: Bool {
        buttonState == .disabled
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 5) {
            ZStack {
                if buttonState == .loading {
                    ProgressView()
                        .controlSize(.small)
//                        .padding(.vertical, 16)
                } else {
                    HStack(spacing: 2) {
                        Image(systemName: imageText)
                            .controlSize(buttonState == .missing ? .small : .regular)
                            .bold(buttonState != .missing)
                        if buttonState == .missing {
                                Image(systemName: "exclamationmark")
                                .fontWeight(.black)
                        }
                    }
                    if disabled {
                        Capsule()
                            .fill(.secondary)
                            .frame(width: 32, height: 2)
                            .rotationEffect(.degrees(-45))
                    }
                }
            }
            .frame(height: 15)
        }
        .transition(.scale)
        .foregroundStyle(buttonState.foregroundColor)
        .animation(.bouncy, value: buttonState)
        .frame(minWidth: 30, maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(buttonState.fillStyle)
                .brightness(buttonState == .enabled ? 0.3 : 0)
                .opacity(disabled ? 0.4 : 0.55)
                .clipShape(.rect(cornerRadius: 12))
                .shadow(radius: disabled ? 0 : buttonState == .enabled ? 7 : 3)
        )
        .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

public struct SmallMenubarButton: View {
    let buttonText: String
    let imageText: String
    let buttonState: ButtonState
    let onClick: () -> Void
    
    var disabled: Bool {
        buttonState == .disabled
    }
    
    public var body: some View {
        Button {
            onClick()
        } label: {
            EmptyView()
        }
        .buttonStyle(SmallMenubarButtonStyle(imageText: imageText, buttonState: buttonState))
        .disabled(disabled)
        .buttonStyle(.borderless)
    }
}
