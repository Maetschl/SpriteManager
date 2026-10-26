import Testing
@testable import SpriteManager

@Suite("ProjectHeaderViewModel")
@MainActor
struct ProjectHeaderViewModelTests {
    @Test func exposesProjectSummary() {
        let viewModel = ProjectHeaderViewModel(document: ProjectDocument())
        #expect(viewModel.projectName == "Untitled Project")
        #expect(viewModel.projectAssetCount == 0)
        #expect(viewModel.sheetCount == 0)
    }
}
