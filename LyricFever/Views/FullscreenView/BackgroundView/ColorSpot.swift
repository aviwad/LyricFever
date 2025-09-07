//
//  ColorSpot.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-26.
//


//
//  ColorSpot.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-07-19.
//


//
//  ColorStop.swift
//  RandomPathAinmation
//
//  Created by Alexey Vorobyov on 09.09.2023.
//

import SwiftUI

struct ColorSpot: Hashable {
    var position: UnitPoint
    var color: Color
}

extension ColorSpot: Animatable {
    public typealias AnimatableData = AnimatablePair<UnitPoint.AnimatableData, Color.Resolved.AnimatableData>

    public var animatableData: ColorSpot.AnimatableData {
        get {
            .init(position.animatableData, color.resolve(in: .init()).animatableData)
        }
        set {
            position = .init(newValue.first)
            color = .init(newValue.second)
        }
    }
}

private extension ColorSpot {
    static var zero: ColorSpot {
        .init(position: .zero, color: .black)
    }

    init(_ animatableData: ColorSpot.AnimatableData) {
        self.init(
            position: .init(animatableData.first),
            color: .init(animatableData.second)
        )
    }
}

private extension Color {
    init(_ animatableData: Color.Resolved.AnimatableData) {
        var resolvedColor = Color.Resolved(red: 0, green: 0, blue: 0)
        resolvedColor.animatableData = animatableData
        self.init(resolvedColor)
    }
}

private extension UnitPoint {
    static let animatableDataRatio =
        UnitPoint(x: 1, y: 1).animatableData.first / UnitPoint(x: 1, y: 1).x

    init(_ animatableData: UnitPoint.AnimatableData) {
        self.init(
            x: animatableData.first / UnitPoint.animatableDataRatio,
            y: animatableData.second / UnitPoint.animatableDataRatio
        )
    }
}

typealias ColorSpots = [ColorSpot]

extension ColorSpots: @retroactive Animatable {
    public var animatableData: ColorSpotsAnimatableData {
        get { .init(values: map { point in point.animatableData }) }
        set { self = newValue.values.map { .init($0) } }
    }
}

extension ColorSpots {
    init(_ animatableData: ColorSpotsAnimatableData) {
        self = animatableData.values.map { .init($0) }
    }
}

public struct ColorSpotsAnimatableData {
    var values: [ColorSpot.AnimatableData]
}

extension ColorSpotsAnimatableData: VectorArithmetic {
    public static func - (lhs: ColorSpotsAnimatableData, rhs: ColorSpotsAnimatableData) -> ColorSpotsAnimatableData {
        .init(
            values: (0 ..< max(lhs.values.count, rhs.values.count)).map {
                (lhs.values[safe: $0] ?? .zero) - (rhs.values[safe: $0] ?? .zero)
            }
        )
    }

    public static func + (lhs: ColorSpotsAnimatableData, rhs: ColorSpotsAnimatableData) -> ColorSpotsAnimatableData {
        .init(
            values: (0 ..< max(lhs.values.count, rhs.values.count)).map {
                (lhs.values[safe: $0] ?? .zero) + (rhs.values[safe: $0] ?? .zero)
            }
        )
    }

    public mutating func scale(by rhs: Double) {
        values = values.map { $0.scaled(by: rhs) }
    }

    public var magnitudeSquared: Double {
        values.reduce(0) { $0 + $1.magnitudeSquared }
    }

    public static var zero: ColorSpotsAnimatableData {
        .init(values: [.zero])
    }
}
extension ColorSpot {
    static func random(withColor color: SwiftUI.Color) -> ColorSpot {
        .init(
            position: .init(x: CGFloat.random(in: 0 ..< 1), y: CGFloat.random(in: 0 ..< 1)),
            color: color
        )
    }
}
