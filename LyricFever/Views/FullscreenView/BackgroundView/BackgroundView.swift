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
import Combine

struct BackgroundView: View {
    @Binding var colors: [SwiftUI.Color]
    @Binding var timer: Publishers.Autoconnect<Timer.TimerPublisher>
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
        .onChange(of: colors) {
            print("change color called")
            withAnimation(.easeInOut(duration: BackgroundView.animationDuration/2)){
                points = self.colors.map { .random(withColor: $0) }
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: BackgroundView.animationDuration)) {
                points = self.colors.map { .random(withColor: $0) }
            }
        }
    }
    
}
