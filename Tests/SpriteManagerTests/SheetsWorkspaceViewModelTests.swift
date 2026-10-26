import Testing
@testable import SpriteManager

@Suite("SheetsWorkspaceViewModel")
@MainActor
struct SheetsWorkspaceViewModelTests {
    @Test func startsWithoutSheets() {
        let viewModel = SheetsWorkspaceViewModel(document: ProjectDocument())
        #expect(viewModel.isEmpty)
        #expect(viewModel.sheetCount == 0)
    }
}
