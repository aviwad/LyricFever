//
//  FinalTruncationView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//

import SwiftUI



struct FinalTruncationView: View {
    @Environment(\.dismiss) var dismiss
    //@AppStorage("truncationLength") var truncationLength: Int = 40
    @State var truncationLength: Int = UserDefaults.standard.integer(forKey: "truncationLength")
    @Environment(\.controlActiveState) var controlActiveState
    let allTruncations = Array(stride(from: 30, through: 100, by: 10))
    // Sizes that have a screenshot in Assets (30.png ... 60.png); larger sizes get a drawn preview
    let truncationsWithScreenshot = [30, 40, 50, 60]
    // Made-up sample text, long enough to show the 100-character cut-off
    let sampleLyric = "This is a sample lyric line that shows how much text fits in your menu bar before Lyric Fever cuts it off"
    
    /// A simple menu bar at real size showing the sample line cut to the chosen length
    @ViewBuilder
    var drawnPreview: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [.blue.opacity(0.55), .purple.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing)
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                Text(sampleLyric.trunc(length: truncationLength))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.system(size: 13))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(.black.opacity(0.85))
            Text("Actual size in your menu bar")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.top, 34)
        }
        // Same shape as the screenshots, so the window layout doesn't jump between sizes
        .aspectRatio(1.6, contentMode: .fit)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepView(title: "Set the Lyric Size", description: "This depends on how much free space you have in your menu bar!")
            
            HStack {
                Spacer()
                Group {
                    if truncationsWithScreenshot.contains(truncationLength) {
                        Image("\(truncationLength)")
                            .resizable()
                            .scaledToFit()
                    } else {
                        drawnPreview
                    }
                }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onAppear() {
                        if truncationLength == 0 {
                            truncationLength = 40
                        }
                    }
                Spacer()
            }
            
            HStack {
                Spacer()
                // A row of buttons: eight options don't fit as a vertical radio list in this window
                Picker("Characters:", selection: $truncationLength) {
                    ForEach(allTruncations, id:\.self) { oneThing in
                        Text("\(oneThing)")
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 480)
                Spacer()
            }
            
            HStack {
                Button("Back") {
                    dismiss()
                }
                Spacer()
                Button("Done") {
                    NSApplication.shared.keyWindow?.close()
                    
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 15)
            
        }
        .onChange(of: truncationLength) {
            UserDefaults.standard.set(truncationLength, forKey: "truncationLength")
        }
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { newValue in
            dismiss()
            dismiss()
            dismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willMiniaturizeNotification)) { newValue in
            dismiss()
            dismiss()
            dismiss()
        }
    }
}
