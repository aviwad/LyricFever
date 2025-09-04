//
//  Marquee.swift
//  lym
//
//  Created by Evan Boehs on 11/30/23.
//
// https://gist.github.com/boehs/8f89308a26ec6afc27c3d0beab9ac708#file-marquee-swift

import SwiftUI

public struct MarqueeText : View {
    public var text: String
    public var startDelay: Double
    public var alignment: Alignment
    public var leftFade: CGFloat
    public var rightFade: CGFloat
    
    @Environment(\.font) private var font
    @State private var animate = false
    @State private var textSize: CGSize = .zero
    
    /// Create a scrolling text view.
    public init(_ text: String, startDelay: Double = 3.0, alignment: Alignment? = nil, leftFade: CGFloat = 10, rightFade: CGFloat = 10) {
        self.text = text
        self.startDelay = startDelay
        self.alignment = alignment != nil ? alignment! : .topLeading
        self.leftFade = leftFade
        self.rightFade = rightFade
    }
    
    public var body : some View {
        
        let animation = Animation
            .linear(duration: Double(textSize.width) / 30)
            .delay(startDelay)
            .repeatForever(autoreverses: false)
        
        let nullAnimation = Animation
            .linear(duration: 0)
        
        return ZStack {
            GeometryReader { geo in
                if textSize.width > geo.size.width { // don't use self.animate as conditional here
                    Group {
                        Text(self.text)
                            .lineLimit(1)
                            .offset(x: self.animate ? -textSize.width - textSize.height * 2 : 0)
                            .animation(self.animate ? animation : nullAnimation, value: self.animate)
                            .onAppear {
                                DispatchQueue.main.async {
                                    self.animate = geo.size.width < textSize.width
                                }
                            }
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
                        
                        Text(self.text)
                            .lineLimit(1)
                            .offset(x: self.animate ? 0 : textSize.width + textSize.height * 2)
                            .animation(self.animate ? animation : nullAnimation, value: self.animate)
                            .onAppear {
                                DispatchQueue.main.async {
                                    self.animate = geo.size.width < textSize.width
                                }
                            }
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
                    }
                    .onChange(of: self.text) {
                        self.animate = geo.size.width < textSize.width
                    }
                    .frame(width: geo.size.width)
                    .offset(x: leftFade)
                    .mask(
                        HStack(spacing:0) {
                            Rectangle()
                                .frame(width:2)
                                .opacity(0)
                            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .leading, endPoint: .trailing)
                                .frame(width:leftFade)
                            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]), startPoint: .leading, endPoint: .trailing)
                            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: .leading, endPoint: .trailing)
                                .frame(width:rightFade)
                            Rectangle()
                                .frame(width:2)
                                .opacity(0)
                        })
                    
                } else {
                    Text(self.text)
                        .onChange(of: self.text) {
                            self.animate = geo.size.width < textSize.width
                        }
                    .offset(x: leftFade)
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .overlay {
           Text(self.text)
                .lineLimit(1)
                .fixedSize()
                .CC_measureSize(perform: { size in
                    self.textSize = size
                })
                .hidden()
        }
        .lineLimit(1, reservesSpace: true)
        .onDisappear { self.animate = false }
    }
}

fileprivate struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

fileprivate struct MeasureSizeModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content.background(GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self,
                                   value: geometry.size)
        })
    }
}

fileprivate extension View {
    /// Measures the size of an element and calls the supplied closure.
    func CC_measureSize(perform action: @escaping (CGSize) -> Void) -> some View {
        self.modifier(MeasureSizeModifier())
            .onPreferenceChange(SizePreferenceKey.self, perform: action)
    }
}

#Preview {
   MarqueeText("This is an example which hopefully starts to scroll, otherwise we couldn't demonstrate anything...", leftFade: 10, rightFade: 10)
}
