import Testing
@testable import SpriteManager

@Suite("ProjectDocument")
@MainActor
struct ProjectDocumentTests {
    @Test func startsWithCurrentProjectSchema() {
        #expect(ProjectDocument().project.schemaVersion == SpriteProject.currentSchemaVersion)
    }
}
