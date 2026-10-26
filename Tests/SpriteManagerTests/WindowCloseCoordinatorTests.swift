import Testing
@testable import SpriteManager

@Suite("WindowCloseCoordinator")
@MainActor
struct WindowCloseCoordinatorTests {
    @Test func keepsDocumentReference() {
        let document = ProjectDocument()
        let coordinator = WindowCloseCoordinator(document: document)
        #expect(coordinator.document === document)
    }
}
