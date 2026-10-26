import Foundation
import Testing
@testable import SpriteManager

@Suite("SpriteManagerError")
struct SpriteManagerErrorTests {
    @Test func describesInvalidProjects() {
        #expect(SpriteManagerError.invalidProject.errorDescription?.contains("valid") == true)
    }
}

