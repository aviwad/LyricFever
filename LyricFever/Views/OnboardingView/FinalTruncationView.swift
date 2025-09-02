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
    let allTruncations = [30,40,50,60]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StepView(title: "Set the Lyric Size", description: "This depends on how much free space you have in your menu bar!")
            
            HStack {
                Spacer()
                Image("\(truncationLength)")
                    .resizable()
                    .scaledToFit()
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
                Picker("Truncation Length", selection: $truncationLength) {
                    ForEach(allTruncations, id:\.self) { oneThing in
                        Text("\(oneThing) Characters")
                    }
                }
                .pickerStyle(.radioGroup)
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
        .onChange(of: truncationLength) { newLength in
            UserDefaults.standard.set(newLength, forKey: "truncationLength")
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
