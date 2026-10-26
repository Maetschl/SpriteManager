import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PalettePreviewSidebar: View {
    @ObservedObject var document: ProjectDocument
    @Binding var selectedSheetID: UUID?
    @Binding var zoom: CGFloat
    @Binding var offset: CGSize
    let highlightedColorID: UUID?
    let highlightOpacity: Double
    let onSelectColor: (UUID) -> Void

    private var selectedSheet: SpriteSheet? {
        if let selectedSheetID, let sheet = document.project.sheets.first(where: { $0.id == selectedSheetID }) {
            return sheet
        }
        return document.selectedSheet ?? document.project.sheets.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sheet preview", systemImage: "rectangle.on.rectangle")
                .font(.headline)
            if document.project.sheets.isEmpty {
                ContentUnavailableView("No sheets yet", systemImage: "rectangle.3.group", description: Text("Create a spritesheet before creating a palette."))
            } else {
                Picker("Spritesheet", selection: $selectedSheetID) {
                    ForEach(document.project.sheets) { sheet in
                        Text(sheet.name).tag(Optional(sheet.id))
                    }
                }
                .labelsHidden()

                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        PalettePreviewImage(
                            document: document,
                            sheet: selectedSheet,
                            mode: .committed,
                            label: "Original",
                            zoom: $zoom,
                            offset: $offset,
                            highlightedColorID: highlightedColorID,
                            highlightOpacity: highlightOpacity,
                            onSelectColor: onSelectColor
                        )
                        Divider()
                            .padding(.vertical, 2)
                        PalettePreviewImage(
                            document: document,
                            sheet: selectedSheet,
                            mode: .preview,
                            label: "Updated",
                            zoom: $zoom,
                            offset: $offset,
                            highlightedColorID: highlightedColorID,
                            highlightOpacity: highlightOpacity,
                            onSelectColor: onSelectColor
                        )
                    }
                }
            }
        }
        .padding(.top, 4)
        .background(.clear)
    }
}

