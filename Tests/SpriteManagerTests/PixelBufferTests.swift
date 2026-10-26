import Testing
@testable import SpriteManager

@Suite("PixelBuffer")
struct PixelBufferTests {
    @Test func shiftedBufferKeepsDimensions() throws {
        let buffer = try PixelBuffer(width: 2, height: 1, pixels: [255, 0, 0, 255, 0, 0, 0, 0])
        let shifted = buffer.shifted(dx: 1, dy: 0)
        #expect(shifted.width == buffer.width)
        #expect(shifted.height == buffer.height)
        #expect(shifted[0, 0].a == 0)
    }
}

