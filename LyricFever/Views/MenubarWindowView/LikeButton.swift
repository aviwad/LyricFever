//
//  LikeButton.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-05.
//

import SwiftUI

struct LikeButton: View {
    @State private var toggled = false
    
    var body: some View {
        Button {
            toggled.toggle()
        } label: {
            Image(systemName: toggled ? "heart.fill" : "heart")
        }
        .contentTransition(.symbolEffect(.replace, options: .default))
        .buttonStyle(.accessoryBar)
    }
}
