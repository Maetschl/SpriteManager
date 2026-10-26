import Foundation
import SwiftUI
import UniformTypeIdentifiers
import AppKit

extension PixelBuffer {
    static func blank(width: Int, height: Int) -> PixelBuffer {
        try! PixelBuffer(
            width: width,
            height: height,
            pixels: [UInt8](repeating: PixelBuffer.transparentAlpha, count: width * height * PixelBuffer.bytesPerPixel)
        )
    }

    mutating func composite(_ source: PixelBuffer, atX x: Int, y: Int) {
        for sourceY in 0..<source.height {
            for sourceX in 0..<source.width {
                let targetX = x + sourceX
                let targetY = y + sourceY
                guard targetX >= 0, targetX < width, targetY >= 0, targetY < height else { continue }
                let sourceIndex = (sourceY * source.width + sourceX) * PixelBuffer.bytesPerPixel
                let targetIndex = (targetY * width + targetX) * PixelBuffer.bytesPerPixel
                let sourceAlpha = Double(source.pixels[sourceIndex + 3]) / Double(PixelBuffer.opaqueAlpha)
                let destinationAlpha = Double(pixels[targetIndex + 3]) / Double(PixelBuffer.opaqueAlpha)
                let outputAlpha = sourceAlpha + destinationAlpha * (1 - sourceAlpha)
                guard outputAlpha > 0 else { continue }
                for channel in 0..<3 {
                    let sourceValue = Double(source.pixels[sourceIndex + channel]) / Double(PixelBuffer.opaqueAlpha)
                    let destinationValue = Double(pixels[targetIndex + channel]) / Double(PixelBuffer.opaqueAlpha)
                    let output = (sourceValue * sourceAlpha + destinationValue * destinationAlpha * (1 - sourceAlpha)) / outputAlpha
                    pixels[targetIndex + channel] = UInt8(
                        max(
                            Int(PixelBuffer.transparentAlpha),
                            min(Int(PixelBuffer.opaqueAlpha), Int(output * Double(PixelBuffer.opaqueAlpha)))
                        )
                    )
                }
                pixels[targetIndex + 3] = UInt8(
                    max(
                        Int(PixelBuffer.transparentAlpha),
                        min(Int(PixelBuffer.opaqueAlpha), Int(outputAlpha * Double(PixelBuffer.opaqueAlpha)))
                    )
                )
            }
        }
    }
}
