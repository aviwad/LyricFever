//
//  Update21Window.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-03-19.
//

import SwiftUI

struct Update22Window: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 25) {
            HStack {
                Image("hi")
                    .resizable()
                    .frame(width: 70, height: 70, alignment: .center)
                
                Text(verbatim:"Thanks for updating to Lyric Fever 2.2! 🎉")
                    .font(.title)
            }
            
            Text(verbatim:"2.2 Changes")
                .font(.title2)
                .foregroundStyle(.green)
            ScrollView {
                VStack(spacing: 3) {
                    Text(verbatim:"Improved Spotify connection: no more silent failures.")
                    Text(verbatim:"Simplified Chinese UI thanks to InTheManXG")
                    Text(verbatim:"Translation bugs fixed")
                    Text(verbatim:"Karaoke color for non-Spotify lyrics should be MUCH better")
                    Text(verbatim:"(to update karaoke color for a song, hit \"Refresh Lyrics\")")
                    Text(verbatim:"Japanese Romanization should be much better")
                    Text(verbatim:"Rapidly skipping through songs has been fixed (stale network requests are properly cancelled)")
                    Text(verbatim:"Fullscreen button and UI improvements")
                    Text(verbatim: "Fullscreen settings for lyric blur, animating on startup")
                    Text(verbatim:"Get rid of flicker on lyric change in karaoke window")
                    Text(verbatim:"Non-English lyric support improved on Apple Music")
                    Text(verbatim:"Better NetEase lyric filter to prevent incorrect lyrics")
                    Text(verbatim:"New Delete Lyrics button)")
                    Text(verbatim:"More robust local file support")
                    Text(verbatim:"Onboarding window touch-ups")
                    Text(verbatim:"New fullscreen window share button")
                    Text(verbatim: "AirPlay delay support")
                    Text(verbatim: "Ensure freshly downloaded lyrics don't disappear on the last lyric")
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
