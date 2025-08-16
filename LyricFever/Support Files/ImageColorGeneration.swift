//
//  ImageColorGeneration.swift
//  Lyric Fever
//
//  Created by Avi Wadhwa on 2025-08-07.
//

import AppKit


#if os(macOS)
extension NSImage {
    func findWhiteTextLegibleMostSaturatedDominantColor() -> Int32 {
        guard let dominantColors = try? self.dominantColors(with: .best, algorithm: .kMeansClustering).map({self.adjustedColor($0)}).sorted(by: { $0.saturationComponent > $1.saturationComponent }) else {
            return self.findAverageColor()
        }
        for color in dominantColors {
            if color.brightnessComponent > 0.1 {
                let red = Int(color.redComponent * 255)
                let green = Int(color.greenComponent * 255)
                let blue = Int(color.blueComponent * 255)
                
                let combinedValue = (max(0,red) << 16) | (max(0,green) << 8) | max(0,blue)
                return Int32(bitPattern: UInt32(combinedValue))
            }
        }
        return self.findAverageColor()
    }
    // credits: Christian Selig https://christianselig.com/2021/04/efficient-average-color/
    func findAverageColor() -> Int32 {
        guard let cgImage = cgImage else { return 0 }
        
        let size = CGSize(width: 40, height: 40)
        
        let width = Int(size.width)
        let height = Int(size.height)
        let totalPixels = width * height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // ARGB format
        let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        
        // 8 bits for each color channel, we're doing ARGB so 32 bits (4 bytes) total, and thus if the image is n pixels wide, and has 4 bytes per pixel, the total bytes per row is 4n. That gives us 2^8 = 256 color variations for each RGB channel or 256 * 256 * 256 = ~16.7M color options in total. That seems like a lot, but lots of HDR movies are in 10 bit, which is (2^10)^3 = 1 billion color options!
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo) else { return 0 }

        // Draw our resized image
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))

        guard let pixelBuffer = context.data else { return 0 }
        
        // Bind the pixel buffer's memory location to a pointer we can use/access
        let pointer = pixelBuffer.bindMemory(to: UInt32.self, capacity: width * height)

        // Keep track of total colors (note: we don't care about alpha and will always assume alpha of 1, AKA opaque)
        var totalRed = 0
        var totalBlue = 0
        var totalGreen = 0
        
        // Column of pixels in image
        for x in 0 ..< width {
            // Row of pixels in image
            for y in 0 ..< height {
                // To get the pixel location just think of the image as a grid of pixels, but stored as one long row rather than columns and rows, so for instance to map the pixel from the grid in the 15th row and 3 columns in to our "long row", we'd offset ourselves 15 times the width in pixels of the image, and then offset by the amount of columns
                let pixel = pointer[(y * width) + x]
                
                let r = red(for: pixel)
                let g = green(for: pixel)
                let b = blue(for: pixel)

                totalRed += Int(r)
                totalBlue += Int(b)
                totalGreen += Int(g)
            }
        }
        
        let averageRed: CGFloat
        let averageGreen: CGFloat
        let averageBlue: CGFloat
        
        averageRed = CGFloat(totalRed) / CGFloat(totalPixels)
        averageGreen = CGFloat(totalGreen) / CGFloat(totalPixels)
        averageBlue = CGFloat(totalBlue) / CGFloat(totalPixels)
        
        // Convert from [0 ... 255] format to the [0 ... 1.0] format UIColor wants
//        return NSColor(red: averageRed / 255.0, green: averageGreen / 255.0, blue: averageBlue / 255.0, alpha: 1.0)
        // Convert CGFloat values to UInt8 (0-255 range)
        let red = Int(averageRed)
        let green = Int(averageGreen)
        let blue = Int(averageBlue)

        // Pack into a single UInt32
        
//        return (UInt32(red) << 16) | (UInt32(green) << 8) | UInt32(blue)
        print("Find average color: red is \(red), green is \(green), blue is \(blue)")
        let combinedValue = (red << 16) | (green << 8) | blue
        return Int32(bitPattern: UInt32(combinedValue))
    }
    func adjustedColor(_ nsColor: NSColor) -> NSColor {
        // Convert NSColor to HSB components
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Adjust brightness
        brightness = max(brightness - 0.2, 0.1)
        
        if saturation < 0.9 {
            // Adjust contrast
            saturation = max(0.1, saturation * 3)
        }
        
        // Create new NSColor with modified HSB values
        print("Brightness: \(brightness)")
//        print("Saturation: \(saturation)")
        let modifiedNSColor = NSColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        
        return modifiedNSColor
    }
    
    private func red(for pixelData: UInt32) -> UInt8 {
        return UInt8((pixelData >> 16) & 255)
    }

    private func green(for pixelData: UInt32) -> UInt8 {
        return UInt8((pixelData >> 8) & 255)
    }

    private func blue(for pixelData: UInt32) -> UInt8 {
        return UInt8((pixelData >> 0) & 255)
    }
}

extension NSColor {
    var hexString: String? {
        guard let rgbColor = self.usingColorSpace(.sRGB) else {
            return nil
        }
        let red = Int(rgbColor.redComponent * 255)
        let green = Int(rgbColor.greenComponent * 255)
        let blue = Int(rgbColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    convenience init?(hexString hex: String) {
        if hex.count != 7 { // The '#' included
            return nil
        }
            
        let hexColor = String(hex.dropFirst())
        
        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0
        
        if !scanner.scanHexInt64(&hexNumber) {
            return nil
        }
        
        let r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
        let g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
        let b = CGFloat(hexNumber & 0x0000ff) / 255
        
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }
}
#endif

