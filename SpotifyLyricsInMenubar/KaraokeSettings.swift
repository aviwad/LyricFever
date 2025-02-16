//
//  KaraokeSettings.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-02-08.
//

import SwiftUI

struct KaraokeSettingsView: View {
    @EnvironmentObject var viewmodel: viewModel
    var body: some View {
        VStack(spacing: 5) {
            Toggle(isOn: $viewmodel.karaokeModeHoveringSetting) {
                Text("Hide Karaoke window when mouse passes by")
            }
            .toggleStyle(.checkbox)
            Toggle(isOn: $viewmodel.karaokeUseAlbumColor) {
                Text("Use album color for Karaoke window")
            }
            .toggleStyle(.checkbox)
            Toggle(isOn: $viewmodel.karaokeShowMultilingual) {
                Text("Show multilingual lyrics when translating in Karaoke window")
            }
            .toggleStyle(.checkbox)
            if !viewmodel.karaokeUseAlbumColor {
                Text("Please select a background color:")
            }
            Slider(value: $viewmodel.karaokeTransparency, in: 0...1, label: {
                Text("Karaoke Transparency:")
            })
            Text("Select a font size:")
            Text("Select a font:")
            Button("Reset to default") {}
        }
        .padding(.horizontal)
    }
}
