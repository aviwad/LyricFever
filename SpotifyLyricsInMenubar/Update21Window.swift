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
                
                Text(verbatim:"Thanks for updating to Lyric Fever 2.1! 🎉")
                    .font(.title)
            }
            
            Text(verbatim:"**If lyrics aren't loading, please log out and log back in.**")
                .font(.title2)
                .foregroundStyle(.pink)
            ScrollView {
                VStack(spacing: 3) {
                    Text(verbatim:"**2.1 Changes**")
                    Text(verbatim:"Customizable karaoke mode, with font, color settings")
                    Text(verbatim:"New options: hide karaoke mode on hover, display multilingual lyrics (original + translation)")
                    Text(verbatim:"Correctly translate to user's locale")
                    Text(verbatim:"Can hide song details and only show icon in menubar")
                    Text(verbatim:"New Romanization option")
                    Text(verbatim:"Local LRC File Support")
                    Text(verbatim:"NetEase used as 3rd provider")
                    Text(verbatim:"Deal with new Spotify login mechanism (a cat and mouse chase...)")
                    Text(verbatim:"Better Apple Music support")
                    Text(verbatim:"Apple Music fullscreen support")
                    Text(verbatim:"Better local file support (for both Apple Music and Spotify)")
                    Text(verbatim:"Display local file album art using MusicBrainz")
                    Text(verbatim:"Remember whether to translate on startup")
                    Text(verbatim:"Improve fullscreen mode animations")
                    Text(verbatim:"Many minor bug fixes")
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
