import Testing
@testable import SpriteManager

@Suite("LibraryIndex")
struct LibraryIndexTests {
    @Test func startsEmpty() {
        #expect(LibraryIndex(assets: []).assets.isEmpty)
        #expect(LibraryIndex(assets: []).schemaVersion == LibraryIndex.currentSchemaVersion)
    }
}

