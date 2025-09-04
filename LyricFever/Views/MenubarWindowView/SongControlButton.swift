//
//  SongControlButton.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-05.
//

import SwiftUI

struct SongControlButton: View {
    let systemImage: String
    var wiggle: Bool = true
    let action: () -> Void
    @State private var toggled = false
    @State private var isHovering = false
    
    var body: some View {
        Button {
            toggled.toggle()
            action()
        } label: {
            Image(systemName: systemImage)
//                .frame(width: 25, height: 18)
        }
//        .background {
//            RoundedRectangle(cornerRadius: 10)
//                .fill(.gray.opacity(isHovering ? 0.5 : 0.0))
//        }
//        .onHover { hovering in
//            isHovering = hovering
//        }
        .buttonStyle(.accessoryBar)
//        .tint(.secondary)
        .symbolEffect(.bounce.down.byLayer, value: wiggle ? toggled : false)
//        .padding(2) // small outer padding to match accessory bar spacing
    }
}
