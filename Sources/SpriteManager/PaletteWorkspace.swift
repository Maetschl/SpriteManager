import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PaletteWorkspace: View {
    @ObservedObject var document: ProjectDocument
    @StateObject private var viewModel: PaletteWorkspaceViewModel

    init(document: ProjectDocument) {
        self.document = document
        _viewModel = StateObject(wrappedValue: PaletteWorkspaceViewModel(document: document))
    }

    var body: some View {
        NavigationSplitView {
            PalettePreviewSidebar(
                document: document,
                selectedSheetID: $viewModel.selectedPaletteSheetID,
                zoom: $viewModel.previewZoom,
                offset: $viewModel.previewOffset,
                highlightedColorID: viewModel.highlightedColorID,
                highlightOpacity: viewModel.highlightOpacity,
                onSelectColor: viewModel.selectColor
            )
                .navigationSplitViewColumnWidth(min: 240, ideal: 320, max: 480)
        } content: {
            PaletteGrid(
                document: document,
                selectedColorID: $viewModel.selectedPaletteColorID,
                onSelectColor: viewModel.selectColor,
                onCreatePalette: viewModel.createPalette,
                onRegeneratePalette: viewModel.regeneratePalette
            )
                .navigationSplitViewColumnWidth(min: 440, ideal: 700, max: 1400)
        } detail: {
            PaletteInspector(document: document, selectedColorID: $viewModel.selectedPaletteColorID)
                .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 720)
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear(perform: viewModel.prepareSelection)
        .onChange(of: document.selectedSheetID) { _, _ in viewModel.synchronizeSheetSelection() }
        .onChange(of: document.effectivePalette) { _, palette in
            _ = palette
            viewModel.synchronizeColorSelection()
        }
        .onChange(of: viewModel.selectedPaletteSheetID) { _, sheetID in viewModel.selectSheet(sheetID) }
    }
}

