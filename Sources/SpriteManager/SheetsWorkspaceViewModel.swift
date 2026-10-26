import Foundation
import SwiftUI

@MainActor
final class SheetsWorkspaceViewModel: ObservableObject {
    let document: ProjectDocument

    @Published var selectedPlacementID: UUID?
    @Published var sheetToDelete: SpriteSheet?

    init(document: ProjectDocument) {
        self.document = document
    }

    var sheetCount: Int { document.project.sheets.count }
    var hasSelectedSheet: Bool { document.selectedSheet != nil }
    var isEmpty: Bool { document.project.sheets.isEmpty }
    var sheets: [SpriteSheet] { document.project.sheets }
    var selectedSheetID: UUID? { document.selectedSheetID }

    var selectedSheetIDBinding: Binding<UUID?> {
        Binding(
            get: { [document] in document.selectedSheetID },
            set: { [document] value in document.selectedSheetID = value }
        )
    }

    func createSheet() {
        document.createSheet()
    }

    func duplicateSelectedSheet() {
        document.duplicateSelectedSheet()
    }

    func prepareDelete() {
        sheetToDelete = document.selectedSheet
    }

    func deleteSelectedSheet() {
        document.deleteSelectedSheet()
        sheetToDelete = nil
    }

    func resetPlacementSelection() {
        selectedPlacementID = nil
    }
}
