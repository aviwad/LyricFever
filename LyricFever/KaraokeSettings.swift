import AppKit
import SwiftUI
import FontPicker

struct KaraokeSettingsView: View {
    @Environment(ViewModel.self) private var viewModel
    @AppStorage("karaokeUseAlbumColor") private var karaokeUseAlbumColor = true
    @AppStorage("fixedKaraokeColorHex") private var fixedKaraokeColorHex = "#2D3CCC"
    @AppStorage("karaokeModeHoveringSetting") private var karaokeModeHoveringSetting = false
    @AppStorage("karaokeShowMultilingual") private var karaokeShowMultilingual = true
    @AppStorage("karaokeTransparency") private var karaokeTransparency = 50.0

    private var colorBinding: Binding<Color> {
        Binding {
            Color(NSColor(hexString: fixedKaraokeColorHex) ?? .systemBlue)
        } set: { newColor in
            fixedKaraokeColorHex = NSColor(newColor).hexString ?? "#2D3CCC"
        }
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading, spacing: 20) {
            ModularSettingsSection("Behavior") {
                ModularSettingsRow(
                    "Hide when the pointer enters the window",
                    helperText: "Temporarily hides the karaoke window while the pointer is over it.",
                    keywords: ["hover", "mouse"]
                ) {
                    Toggle("Hide when the pointer enters the window", isOn: $karaokeModeHoveringSetting)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                Divider()

                ModularSettingsRow(
                    "Show translated lyrics",
                    helperText: "Show the translation below the original lyric when a translation is available.",
                    keywords: ["translation", "multilingual"]
                ) {
                    Toggle("Show translated lyrics", isOn: $karaokeShowMultilingual)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }

            ModularSettingsSection("Appearance") {
                ModularSettingsRow(
                    "Use album color",
                    helperText: "Use the current album's color as the karaoke window background."
                ) {
                    Toggle("Use album color", isOn: $karaokeUseAlbumColor)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                Divider()

                if !karaokeUseAlbumColor {
                    ModularSettingsRow("Custom background color") {
                        ColorPicker("Custom background color", selection: colorBinding, supportsOpacity: false)
                            .labelsHidden()
                    }
                    Divider()
                }

                ModularSettingsSliderRow(
                    "Background opacity",
                    helperText: "Adjust how strongly the karaoke background shows through.",
                    value: $karaokeTransparency,
                    range: 1.0...100.0,
                    defaultValue: 50.0,
                    step: 5.0,
                    valueString: { "\(Int($0))%" }
                )

                Divider()

                ModularSettingsRow("Font") {
                    FontPicker("Select a font", selection: $viewModel.karaokeFont)
                }

                Divider()

                ModularSettingsRow("Selected font") {
                    Text("\(viewModel.karaokeFont.displayName ?? viewModel.karaokeFont.fontName), \(Int(viewModel.karaokeFont.pointSize)) pt")
                        .font(.custom(viewModel.karaokeFont.fontName, size: 13))
                        .foregroundStyle(.secondary)
                }

                Divider()

                ModularSettingsRow("Reset appearance") {
                    Button("Reset to Defaults") {
                        karaokeUseAlbumColor = true
                        fixedKaraokeColorHex = "#2D3CCC"
                        karaokeTransparency = 50
                        viewModel.karaokeFont = NSFont.boldSystemFont(ofSize: 30)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
