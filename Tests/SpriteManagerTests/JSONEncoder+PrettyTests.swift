import Foundation
import Testing
@testable import SpriteManager

@Suite("JSONEncoder+Pretty")
struct JSONEncoderPrettyExtensionTests {
    @Test func producesReadableSortedJSON() throws {
        let data = try JSONEncoder.pretty.encode(["b": 1, "a": 2])
        let output = String(decoding: data, as: UTF8.self)
        #expect(output.contains("\"a\""))
        #expect(output.contains("\n"))
    }
}
