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
    
    var body: some View {
        Button {
            toggled.toggle()
            action()
        } label: {
            Image(systemName: systemImage)
        }
        .symbolEffect(.bounce.down.byLayer, value: wiggle ? toggled : false)
    }
}
