import SwiftUI

struct LyricChillAboutSettingsView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ModularSettingsSection("About LyricChill") {
                ModularSettingsRow("Version") {
                    Text(version)
                        .foregroundStyle(.secondary)
                }

                Divider()

                ModularSettingsRow("Community project") {
                    Link(
                        "GitHub repository",
                        destination: URL(string: "https://github.com/gitmichaelqiu/LyricChill")!
                    )
                }

                Divider()

                ModularSettingsRow("Lyrics and rights") {
                    Text("Lyrics are provided by third-party services and remain the property of their respective rights holders.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 360, alignment: .trailing)
                }
            }
        }
    }
}
