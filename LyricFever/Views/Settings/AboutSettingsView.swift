import AppKit
import SwiftUI

struct LyricChillAboutSettingsView: View {
    private var appIcon: NSImage {
        NSImage(named: NSImage.applicationIconName) ?? NSApplication.shared.applicationIconImage
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(spacing: 20) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 88, height: 88)
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("LyricChill")
                        .font(.custom("Syncopate-Bold", size: 24))

                    Text("v\(version)")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Text("A community-maintained lyrics companion.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Links")
                    .font(.headline)

                LyricChillAboutLinkRow(
                    title: "LyricChill on GitHub",
                    url: URL(string: "https://github.com/gitmichaelqiu/LyricChill")!
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Lyrics and rights")
                    .font(.headline)

                Text("Lyrics are provided by third-party services and remain the property of their respective rights holders.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LyricChillAboutLinkRow: View {
    let title: String
    let url: URL

    @State private var isHovering = false

    var body: some View {
        Link(destination: url) {
            HStack(spacing: 4) {
                Text(title)
                    .foregroundColor(isHovering ? .accentColor : .secondary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
