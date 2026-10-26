import Testing
@testable import SpriteManager

@Suite("SpriteInspectorViewModel")
@MainActor
struct SpriteInspectorViewModelTests {
    @Test func createsForDocument() {
        let viewModel = SpriteInspectorViewModel(document: ProjectDocument())
        #expect(viewModel.document.project.sheets.isEmpty)
    }
}
