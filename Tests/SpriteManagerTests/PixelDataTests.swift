import Foundation
import Testing
@testable import SpriteManager

@Suite("PixelData")
struct PixelDataTests {
    @Test func hashIsDeterministic() {
        let data = Data([1, 2, 3])
        #expect(PixelData.sha256(data) == PixelData.sha256(data))
    }
}

