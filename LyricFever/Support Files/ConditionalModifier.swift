//
//  ConditionalModifier.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-04.
//

import SwiftUI

extension View {
    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V { block(self) }
}
