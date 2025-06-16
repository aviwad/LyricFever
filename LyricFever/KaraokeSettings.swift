//
//  KaraokeSettings.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-02-08.
//

import SwiftUI
import AppKit
import CompactSlider
import FontPicker

struct KaraokeSettingsView: View {
    @EnvironmentObject var viewmodel: viewModel
    var body: some View {
        VStack(spacing: 12) {
            
            Text("Karaoke Behaviour")
//                .bold()
                .font(.system(size: 15, weight: .bold))
            Toggle(isOn: $viewmodel.karaokeModeHoveringSetting) {
                Text("Hide Karaoke window when mouse passes by")
            }
            .toggleStyle(.checkbox)
            Toggle(isOn: $viewmodel.karaokeShowMultilingual) {
                Text("Show multilingual lyrics when translating in Karaoke window")
            }
            .toggleStyle(.checkbox)
            .padding(.bottom, 20)
//            Toggle(isOn: $viewmodel.karaokeConstantBackgroundWindow) {
//                Text("Hide Karaoke window when mouse passes by")
//            }
//            .toggleStyle(.checkbox)
            
            Text("Karaoke Background Appearance")
                    .font(.system(size: 15, weight: .bold))
            
            Toggle(isOn: $viewmodel.karaokeUseAlbumColor.animation(.bouncy)) {
                Text("Use album color for Karaoke window")
            }
            .toggleStyle(.checkbox)
            if !viewmodel.karaokeUseAlbumColor {
                ColorPicker("Set a background color", selection: viewmodel.colorBinding, supportsOpacity: false)
            }
            Text("Opacity Level: \(Int(viewmodel.karaokeTransparency))%")
            CompactSlider(value: $viewmodel.karaokeTransparency, in: 1...100, step: 5) {
                Text("Opacity Level:")
                Spacer()
                Text("\(Int(viewmodel.karaokeTransparency))%")
            }
            .frame(width: 300, height: 24)
            .padding(.bottom, 20)
            
            Text("Karaoke Font Appearance")
//                .bold()
                .font(.system(size: 15, weight: .bold))
            FontPicker("Select a Font:", selection: $viewmodel.karaokeFont)
            Text("Font Selected: \(viewmodel.karaokeFont.displayName ?? ""), Size: \(Int(viewmodel.karaokeFont.pointSize))")
                .font(.custom(viewmodel.karaokeFont.fontName, size: 13))
            
            .frame(width: 300, height: 24)
            Button("Reset to default") {
                viewmodel.karaokeModeHoveringSetting = false
                viewmodel.karaokeUseAlbumColor = true
                viewmodel.karaokeShowMultilingual = true
                viewmodel.karaokeTransparency = 50
                viewmodel.karaokeFont = NSFont.boldSystemFont(ofSize: 30)
//                viewmodel.karaokeFontSize = 30
                viewmodel.colorBinding.wrappedValue = Color(.sRGB, red: 0.98, green: 0.0, blue: 0.98)
                
            }
        }
        .padding(.horizontal)
    }
}
