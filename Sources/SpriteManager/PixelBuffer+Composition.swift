import Foundation
import SwiftUI
import UniformTypeIdentifiers
import AppKit

extension PixelBuffer {
    static func blank(width: Int, height: Int) -> PixelBuffer {
        try! PixelBuffer(width: width, height: height, pixels: [UInt8](repeating: 0, count: width * height * 4))
    }

    mutating func composite(_ source: PixelBuffer, atX x: Int, y: Int) {
        for sourceY in 0..<source.height {
            for sourceX in 0..<source.width {
                let targetX = x + sourceX
                let targetY = y + sourceY
                guard targetX >= 0, targetX < width, targetY >= 0, targetY < height else { continue }
                let sourceIndex = (sourceY * source.width + sourceX) * 4
                let targetIndex = (targetY * width + targetX) * 4
                let sourceAlpha = Double(source.pixels[sourceIndex + 3]) / 255
                let destinationAlpha = Double(pixels[targetIndex + 3]) / 255
                let outputAlpha = sourceAlpha + destinationAlpha * (1 - sourceAlpha)
                guard outputAlpha > 0 else { continue }
                for channel in 0..<3 {
                    let sourceValue = Double(source.pixels[sourceIndex + channel]) / 255
                    let destinationValue = Double(pixels[targetIndex + channel]) / 255
                    let output = (sourceValue * sourceAlpha + destinationValue * destinationAlpha * (1 - sourceAlpha)) / outputAlpha
                    pixels[targetIndex + channel] = UInt8(max(0, min(255, Int(output * 255))))
                }
                pixels[targetIndex + 3] = UInt8(max(0, min(255, Int(outputAlpha * 255))))
            }
        }
    }
}
