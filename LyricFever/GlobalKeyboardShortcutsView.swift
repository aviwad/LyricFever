import SwiftUI
import KeyboardShortcuts

struct GlobalKeyboardShortcutsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ModularSettingsSection("Global keyboard shortcuts") {
                ModularSettingsRow("Toggle karaoke window", keywords: ["lyrics", "overlay"]) {
                    KeyboardShortcuts.Recorder("", name: .init("karaoke"))
                        .labelsHidden()
                }

                Divider()

                ModularSettingsRow("Toggle menu bar lyrics", keywords: ["show", "hide"]) {
                    KeyboardShortcuts.Recorder("", name: .init("lyrics"))
                        .labelsHidden()
                }

                Divider()

                ModularSettingsRow("Toggle translations") {
                    KeyboardShortcuts.Recorder("", name: .init("translate"))
                        .labelsHidden()
                }

                Divider()

                ModularSettingsRow("Toggle romanization") {
                    KeyboardShortcuts.Recorder("", name: .init("romanize"))
                        .labelsHidden()
                }

                Divider()

                ModularSettingsRow("Open fullscreen lyrics", keywords: ["fullscreen", "karaoke"]) {
                    KeyboardShortcuts.Recorder("", name: .init("fullscreen"))
                        .labelsHidden()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
