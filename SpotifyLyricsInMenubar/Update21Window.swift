//
//  Update21Window.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-03-19.
//

import SwiftUI

struct Update21Window: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 25) {
            HStack {
                Image("hi")
                    .resizable()
                    .frame(width: 70, height: 70, alignment: .center)
                
                Text("Thanks for updating to Lyric Fever 2.1! 🎉")
                    .font(.title)
            }
            
            Text("**If lyrics aren't loading, please log out and log back in.**")
                .font(.title2)
                .foregroundStyle(.pink)
            ScrollView {
                VStack(spacing: 3) {
                    Text("**2.1 Changes**")
                    Text("Customizable karaoke mode, with font, color settings")
                    Text("New options: hide karaoke mode on hover, display multilingual lyrics (original + translation)")
                    Text("Correctly translate to user's locale")
                    Text("Can hide song details and only show icon in menubar")
                    Text("New Romanization option")
                    Text("Local LRC File Support")
                    Text("NetEase used as 3rd provider")
                    Text("Deal with new Spotify login mechanism (a cat and mouse chase...)")
                    Text("Better Apple Music support")
                    Text("Apple Music fullscreen support")
                    Text("Better local file support (for both Apple Music and Spotify)")
                    Text("Display local file album art using MusicBrainz")
                    Text("Remember whether to translate on startup")
                    Text("Improve fullscreen mode animations")
                    Text("Many minor bug fixes")
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

#Preview {
    Update21Window()
}
