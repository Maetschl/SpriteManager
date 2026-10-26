import Testing
@testable import SpriteManager

@Suite("PixelBuffer+Constants")
struct PixelBufferConstantsTests {
    @Test func definesRGBAChannelLayout() {
        #expect(PixelBuffer.bytesPerPixel == 4)
        #expect(PixelBuffer.alphaChannelOffset == PixelBuffer.bytesPerPixel - 1)
    }
}
