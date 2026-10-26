import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct PixelBuffer: Sendable {
    let width: Int
    let height: Int
    var pixels: [UInt8]

    init(width: Int, height: Int, pixels: [UInt8]) throws {
        guard width > 0, height > 0, pixels.count == width * height * Self.bytesPerPixel else {
            throw SpriteManagerError.invalidPNG("invalid pixel dimensions")
        }
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    init(pngData: Data) throws {
        guard let source = CGImageSourceCreateWithData(pngData as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw SpriteManagerError.invalidPNG("data")
        }
        try self.init(image: image)
    }

    init(image: CGImage) throws {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: Self.transparentAlpha, count: width * height * Self.bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * Self.bytesPerPixel,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw SpriteManagerError.invalidPNG("cannot create pixel context")
        }
        context.setBlendMode(.copy)
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        try self.init(width: width, height: height, pixels: pixels)
    }

    func pngData() throws -> Data {
        var mutablePixels = pixels
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &mutablePixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * Self.bytesPerPixel,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let image = context.makeImage() else {
            throw SpriteManagerError.invalidPNG("cannot encode PNG")
        }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw SpriteManagerError.invalidPNG("cannot encode PNG")
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw SpriteManagerError.invalidPNG("cannot finalize PNG")
        }
        return data as Data
    }

    func cgImage() throws -> CGImage {
        var mutablePixels = pixels
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &mutablePixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * Self.bytesPerPixel,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let image = context.makeImage() else {
            throw SpriteManagerError.invalidPNG("cannot create image")
        }
        return image
    }

    func shifted(dx: Int, dy: Int) -> PixelBuffer {
        var result = [UInt8](repeating: 0, count: pixels.count)
        for y in 0..<height {
            for x in 0..<width {
                let targetX = x + dx
                let targetY = y + dy
                guard targetX >= 0, targetX < width, targetY >= 0, targetY < height else { continue }
                let sourceIndex = (y * width + x) * Self.bytesPerPixel
                let targetIndex = (targetY * width + targetX) * Self.bytesPerPixel
                result[targetIndex..<targetIndex + 4] = pixels[sourceIndex..<sourceIndex + 4]
            }
        }
        return try! PixelBuffer(width: width, height: height, pixels: result)
    }

    func applying(_ palette: ColorPalette) -> PixelBuffer {
        var result = pixels
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * Self.bytesPerPixel
                guard pixels[index + 3] == Self.opaqueAlpha else { continue }
                let source = PaletteRGBColor(r: pixels[index], g: pixels[index + 1], b: pixels[index + 2])
                guard let output = palette.outputColor(for: source) else { continue }
                result[index] = output.r
                result[index + 1] = output.g
                result[index + 2] = output.b
            }
        }
        return try! PixelBuffer(width: width, height: height, pixels: result)
    }

    func withInternalOutline(color: RGBAColor, thickness: Int = 1) -> PixelBuffer {
        guard thickness > 0 else { return self }
        var result = pixels
        let colorBytes = [
            UInt8(max(Int(Self.transparentAlpha), min(Int(Self.opaqueAlpha), Int(color.r * Double(Self.opaqueAlpha))))),
            UInt8(max(Int(Self.transparentAlpha), min(Int(Self.opaqueAlpha), Int(color.g * Double(Self.opaqueAlpha))))),
            UInt8(max(Int(Self.transparentAlpha), min(Int(Self.opaqueAlpha), Int(color.b * Double(Self.opaqueAlpha))))),
            UInt8(max(Int(Self.transparentAlpha), min(Int(Self.opaqueAlpha), Int(color.a * Double(Self.opaqueAlpha)))))
        ]

        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * Self.bytesPerPixel
                guard pixels[index + 3] == Self.transparentAlpha else { continue }
                var nearOpaque = false
                for offsetY in -thickness...thickness {
                    for offsetX in -thickness...thickness {
                        if offsetX == 0 && offsetY == 0 { continue }
                        let neighborX = x + offsetX
                        let neighborY = y + offsetY
                        guard neighborX >= 0, neighborX < width, neighborY >= 0, neighborY < height else { continue }
                        let neighborIndex = (neighborY * width + neighborX) * Self.bytesPerPixel
                        if pixels[neighborIndex + 3] > Self.transparentAlpha {
                            nearOpaque = true
                        }
                    }
                }
                if nearOpaque {
                    result[index] = colorBytes[0]
                    result[index + 1] = colorBytes[1]
                    result[index + 2] = colorBytes[2]
                    result[index + 3] = colorBytes[3]
                }
            }
        }
        return try! PixelBuffer(width: width, height: height, pixels: result)
    }

    subscript(x: Int, y: Int) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        let index = (y * width + x) * Self.bytesPerPixel
        return (pixels[index], pixels[index + 1], pixels[index + 2], pixels[index + 3])
    }
}
