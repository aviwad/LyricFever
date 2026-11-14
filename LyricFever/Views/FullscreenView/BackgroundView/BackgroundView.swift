//
//  BackgroundView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//


//
//  BackgroundView.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-19.
//
import SwiftUI

struct BackgroundView: View {
    @Binding var colors: [SwiftUI.Color]
    let isAnimating: Bool
    @Binding var points: ColorSpots

    static let animationDuration: Double = 20
    @State var bias: Float = 0.002
    @State var power: Float = 2.5
    @State var noise: Float = 2

    var body: some View {
        MulticolorGradient(
            points: points,
            bias: bias,
            power: power,
            noise: noise
        )
        .onAppear {
            updatePoints(animated: isAnimating, duration: BackgroundView.animationDuration / 4)
        }
        .onChange(of: colors) {
            updatePoints(animated: isAnimating, duration: BackgroundView.animationDuration / 4)
        }
        .onChange(of: isAnimating) {
            // Replacing the target without an animation also stops an in-flight transition.
            updatePoints(animated: isAnimating, duration: BackgroundView.animationDuration / 4)
        }
        .task(id: isAnimating) {
            guard isAnimating else { return }

            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(BackgroundView.animationDuration * 1_000_000_000))
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                updatePoints(animated: true, duration: BackgroundView.animationDuration)
            }
        }
    }

    @MainActor
    private func updatePoints(animated: Bool, duration: Double) {
        let newPoints = colors.map { ColorSpot.random(withColor: $0) }
        if animated {
            withAnimation(.easeInOut(duration: duration)) {
                points = newPoints
            }
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                points = newPoints
            }
        }
    }
}
