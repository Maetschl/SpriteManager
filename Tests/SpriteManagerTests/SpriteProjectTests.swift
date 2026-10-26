import Testing
@testable import SpriteManager

@Suite("SpriteProject")
struct SpriteProjectTests {
    @Test func usesCurrentSchemaByDefault() {
        #expect(SpriteProject().schemaVersion == SpriteProject.currentSchemaVersion)
    }
}

