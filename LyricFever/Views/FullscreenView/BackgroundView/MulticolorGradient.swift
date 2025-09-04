//
//  MulticolorGradient.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//


//
//  MulticolorGradient.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-19.
//
import SwiftUI

@MainActor
struct MulticolorGradient: View, @MainActor Animatable {
    var points: [ColorSpot]
    var bias: Float = 0.001
    var power: Float = 2
    var noise: Float = 2

    var animatableData: ColorSpots.AnimatableData {
        get { points.animatableData }
        set { points = .init(newValue) }
    }

    var uniforms: Uniforms {
        Uniforms(params: GradientParams(spots: points, bias: bias, power: power, noise: noise))
    }

    var body: some View {
        Rectangle()
            .colorEffect(ShaderLibrary.gradient(.boundingRect, .uniforms(uniforms)))
    }
}

extension Shader.Argument {
    static func uniforms(_ param: Uniforms) -> Shader.Argument {
        var copy = param
        return .data(Data(bytes: &copy, count: MemoryLayout<Uniforms>.stride))
    }
}
