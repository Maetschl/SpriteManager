import Foundation
import SwiftUI

@MainActor
final class PaletteWorkspaceViewModel: ObservableObject {
    let document: ProjectDocument

    @Published var selectedPaletteColorID: UUID?
    @Published var selectedPaletteSheetID: UUID?
    @Published var previewZoom: CGFloat = 1
    @Published var previewOffset: CGSize = .zero
    @Published var highlightedColorID: UUID?
    @Published var highlightOpacity: Double = 0

    private var highlightTask: Task<Void, Never>?

    init(document: ProjectDocument) {
        self.document = document
    }

    var sheets: [SpriteSheet] { document.project.sheets }
    var effectivePalette: ColorPalette? { document.effectivePalette }
    var selectedSheetID: UUID? { document.selectedSheetID }

    var selectedSheet: SpriteSheet? {
        if let selectedPaletteSheetID,
           let sheet = sheets.first(where: { $0.id == selectedPaletteSheetID }) {
            return sheet
        }
        return document.selectedSheet ?? sheets.first
    }

    deinit {
        highlightTask?.cancel()
    }

    func prepareSelection() {
        selectedPaletteSheetID = selectedPaletteSheetID ?? document.selectedSheetID ?? document.project.sheets.first?.id
        if selectedPaletteColorID == nil {
            selectedPaletteColorID = document.effectivePalette?.colors.first?.id
        }
    }

    func synchronizeColorSelection() {
        guard let selectedPaletteColorID,
              document.effectivePalette?.colors.contains(where: { $0.id == selectedPaletteColorID }) == true else {
            self.selectedPaletteColorID = document.effectivePalette?.colors.first?.id
            return
        }
    }

    func synchronizeSheetSelection() {
        if selectedPaletteSheetID == nil {
            selectedPaletteSheetID = document.selectedSheetID
        }
    }

    func selectSheet(_ sheetID: UUID?) {
        selectedPaletteSheetID = sheetID
        if let sheetID {
            document.selectedSheetID = sheetID
        }
        previewZoom = 1
        previewOffset = .zero
    }

    func selectColor(_ colorID: UUID) {
        selectedPaletteColorID = colorID
        highlightedColorID = colorID
        highlightOpacity = 1
        highlightTask?.cancel()
        highlightTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(700))
            guard let self, !Task.isCancelled, self.highlightedColorID == colorID else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                self.highlightOpacity = 0
            }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, self.highlightedColorID == colorID else { return }
            self.highlightedColorID = nil
        }
    }

    func createPalette() {
        document.createPalette()
    }

    func regeneratePalette() {
        document.regeneratePalette()
    }
}
