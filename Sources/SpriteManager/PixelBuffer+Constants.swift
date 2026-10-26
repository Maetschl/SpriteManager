import Foundation

extension PixelBuffer {
    static let bytesPerPixel = 4
    static let redChannelOffset = 0
    static let greenChannelOffset = 1
    static let blueChannelOffset = 2
    static let alphaChannelOffset = 3
    static let transparentAlpha: UInt8 = 0
    static let opaqueAlpha: UInt8 = 255
}
