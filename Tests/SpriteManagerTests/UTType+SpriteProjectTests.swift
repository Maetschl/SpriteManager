import UniformTypeIdentifiers
import Testing
@testable import SpriteManager

@Suite("UTType+SpriteProject")
struct UTTypeSpriteProjectExtensionTests {
    @Test func definesProjectTypes() {
        #expect(UTType.spritesProject.identifier == "com.spritesmanager.pixproj")
        #expect(UTType.legacySpritesProject.identifier == "com.spritesmanager.project")
    }
}
