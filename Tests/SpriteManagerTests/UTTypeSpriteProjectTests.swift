import Testing
import UniformTypeIdentifiers
@testable import SpriteManager

@Suite("Sprite project UTTypes")
struct UTTypeSpriteProjectTests {
    @Test func usesPixprojIdentifier() {
        #expect(UTType.spritesProject.identifier == "com.spritesmanager.pixproj")
        #expect(UTType.legacySpritesProject.identifier == "com.spritesmanager.project")
    }
}

