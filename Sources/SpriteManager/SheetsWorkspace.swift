import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SheetsWorkspace: View {
    @ObservedObject var document: ProjectDocument
    let onEditSprite: (UUID) -> Void
    @State private var selectedPlacementID: UUID?
    @State private var sheetToDelete: SpriteSheet?

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Label("Sheets", systemImage: "rectangle.3.group")
                        .font(.headline)
                    Spacer()
                    Text("\(document.project.sheets.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppPalette.muted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }
                List(selection: $document.selectedSheetID) {
                    ForEach(document.project.sheets) { sheet in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(sheet.name)
                                .font(.subheadline.weight(.medium))
                            Text("\(sheet.canvasWidth) × \(sheet.canvasHeight) px · \(sheet.placements.count) sprites")
                                .font(.caption)
                                .foregroundStyle(AppPalette.muted)
                        }
                        .padding(.vertical, 3)
                        .tag(sheet.id)
                    }
                }
                .listStyle(.sidebar)
                .overlay {
                    if document.project.sheets.isEmpty {
                        ContentUnavailableView("No sheets yet", systemImage: "rectangle.3.group", description: Text("Create a sheet to start composing a pack."))
                            .allowsHitTesting(false)
                    }
                }
                HStack(spacing: 8) {
                    Button("New", systemImage: "plus") { document.createSheet() }
                        .buttonStyle(.borderedProminent)
                    Button("Duplicate", systemImage: "plus.square.on.square") { document.duplicateSelectedSheet() }
                        .disabled(document.selectedSheet == nil)
                        .help("Duplicate selected sheet")
                    Spacer()
                    Button("Delete", systemImage: "trash") { sheetToDelete = document.selectedSheet }
                        .buttonStyle(.borderless)
                        .disabled(document.selectedSheet == nil)
                        .help("Delete selected sheet")
                }
                .padding(.horizontal, 2)
            }
            .padding(.top, 4)
            .background(.clear)
            .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 420)
        } content: {
            SheetCanvas(document: document, selectedPlacementID: $selectedPlacementID)
                .navigationSplitViewColumnWidth(min: 420, ideal: 640, max: 1200)
        } detail: {
            SheetInspector(document: document, selectedPlacementID: $selectedPlacementID, onEditSprite: onEditSprite)
                .navigationSplitViewColumnWidth(min: 300, ideal: 400, max: 720)
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: document.selectedSheetID) { _, _ in selectedPlacementID = nil }
        .alert("Delete spritesheet?", isPresented: Binding(
            get: { sheetToDelete != nil },
            set: { if !$0 { sheetToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                document.deleteSelectedSheet()
                sheetToDelete = nil
            }
            Button("Cancel", role: .cancel) { sheetToDelete = nil }
        } message: {
            Text("\(sheetToDelete?.name ?? "This sheet") and its placements will be removed from the project.")
        }
    }
}

