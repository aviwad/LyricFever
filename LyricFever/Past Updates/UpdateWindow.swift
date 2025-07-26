//
//  Update21Window.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-03-19.
//

import SwiftUI

struct UpdateWindow: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 25) {
            HStack {
                Image("hi")
                    .resizable()
                    .frame(width: 70, height: 70, alignment: .center)
                
                Text(verbatim:"Thanks for updating to Lyric Fever 2.3! 🎉")
                    .font(.title)
            }
            
            Text(verbatim:"2.3 Changes")
                .font(.title2)
                .foregroundStyle(.green)
            ScrollView {
                VStack(spacing: 3) {
                    ForEach(updateNotes23, id: \.self) { updateNote in
                        Text(verbatim: updateNote)
                    }
                }
                .multilineTextAlignment(.leading)
                .padding(.horizontal,10)
                .padding(.vertical,5)
                .background(Color(nsColor: NSColor.darkGray).cornerRadius(7))
            }
            Button("Close") {
                dismiss()
            }
            .font(.headline)
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 10)
        }
    }
}
