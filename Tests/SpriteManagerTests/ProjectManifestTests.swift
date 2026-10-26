import Testing
@testable import SpriteManager

@Suite("ProjectManifest")
struct ProjectManifestTests {
    @Test func usesCurrentSchemaByDefault() {
        #expect(ProjectManifest(project: SpriteProject(), assets: []).schemaVersion == ProjectManifest.currentSchemaVersion)
    }
}

