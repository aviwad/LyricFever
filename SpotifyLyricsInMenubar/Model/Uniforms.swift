//
//  Uniforms.swift
//  RandomPathAinmation
//
//  Created by Alexey Vorobyov on 09.09.2023.
//

import simd
import SwiftUI

struct Uniforms {
    let pointCount: simd_int1

    let bias: simd_float1
    let power: simd_float1
    let noise: simd_float1

    let point0: simd_float2
    let point1: simd_float2
    let point2: simd_float2
    let point3: simd_float2
    let point4: simd_float2
    let point5: simd_float2
    let point6: simd_float2
    let point7: simd_float2

    let color0: simd_float3
    let color1: simd_float3
    let color2: simd_float3
    let color3: simd_float3
    let color4: simd_float3
    let color5: simd_float3
    let color6: simd_float3
    let color7: simd_float3
}

extension Uniforms {
    init(params: GradientParams) {
        self.init(
            pointCount: simd_int1(params.spots.count),
            bias: params.bias,
            power: params.power,
            noise: params.noise,
            point0: params.spots[safe: 0]?.position.simd ?? .zero,
            point1: params.spots[safe: 1]?.position.simd ?? .zero,
            point2: params.spots[safe: 2]?.position.simd ?? .zero,
            point3: params.spots[safe: 3]?.position.simd ?? .zero,
            point4: params.spots[safe: 4]?.position.simd ?? .zero,
            point5: params.spots[safe: 5]?.position.simd ?? .zero,
            point6: params.spots[safe: 6]?.position.simd ?? .zero,
            point7: params.spots[safe: 7]?.position.simd ?? .zero,
            color0: params.spots[safe: 0]?.color.simd ?? .zero,
            color1: params.spots[safe: 1]?.color.simd ?? .zero,
            color2: params.spots[safe: 2]?.color.simd ?? .zero,
            color3: params.spots[safe: 3]?.color.simd ?? .zero,
            color4: params.spots[safe: 4]?.color.simd ?? .zero,
            color5: params.spots[safe: 5]?.color.simd ?? .zero,
            color6: params.spots[safe: 6]?.color.simd ?? .zero,
            color7: params.spots[safe: 7]?.color.simd ?? .zero
        )
    }
}

extension UnitPoint {
    var simd: simd_float2 { simd_float2(Float(x), Float(y)) }
}

extension Color {
    var simd: simd_float3 {
        // Convert SwiftUI Color to NSColor
        let nsColor = NSColor(self)
        
        // Convert the color to the sRGB color space
        let rgbColor = nsColor.usingColorSpace(.sRGB) ?? NSColor.white
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        rgbColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        return simd_float3(Float(red), Float(green), Float(blue))
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
