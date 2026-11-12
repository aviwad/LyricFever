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
        VStack {
            HStack {
                Image("hi")
                    .resizable()
                    .frame(width: 70, height: 70, alignment: .center)
                
                Text(verbatim:"Thanks for updating to Lyric Fever 3.3! 🎉")
//                    .font(.title)
                    .font(.custom("ChalkboardSE-Regular", size: 30))
            }
            
//            Text(verbatim: "Emergency update to fix Spotify login")
//                .padding(.horizontal, 10)
            
            Text(verbatim:"3.3 Changes")
//                .font(.title2)
                .font(.custom("ChalkboardSE-Regular", size: 30))
                .foregroundStyle(.green)
            ScrollView {
                Text(updateNotes33.map { "- " + $0 }.joined(separator: "\n"))
                    .textSelection(.enabled)
//                VStack(alignment: .leading, spacing: 3) {
//                    ForEach(updateNotes33, id: \.self) { updateNote in
//                        Text(verbatim: "- " + updateNote)
//                    }
//                }
//                .textSelection(.enabled)
                .frame(alignment: .leading)
                .padding(.horizontal,10)
                .padding(.vertical,5)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color(.secondarySystemFill))
                )
//                .background(Color.quaternarySystemFill.cornerRadius(7))
            }
            Button("Close") {
                dismiss()
            }
            .font(.headline)
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 10)
    }
}
