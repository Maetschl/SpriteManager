import Foundation
import Testing
@testable import SpriteManager

@Suite("JSONEncoderPretty")
struct JSONEncoderPrettyTests {
    @Test func enablesStableReadableOutput() {
        #expect(JSONEncoder.pretty.outputFormatting.contains(.prettyPrinted))
        #expect(JSONEncoder.pretty.outputFormatting.contains(.sortedKeys))
    }
}

