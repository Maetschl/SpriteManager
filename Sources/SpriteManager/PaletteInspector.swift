import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PaletteInspector: View {
    @ObservedObject var document: ProjectDocument
    @Binding var selectedColorID: UUID?
    @StateObject private var viewModel: PaletteInspectorViewModel

    init(document: ProjectDocument, selectedColorID: Binding<UUID?>) {
        self.document = document
        _selectedColorID = selectedColorID
        _viewModel = StateObject(wrappedValue: PaletteInspectorViewModel(document: document))
    }

    var body: some View {
        ScrollView {
            if let color = viewModel.selectedColor(selectedColorID) {
                VStack(alignment: .leading, spacing: 18) {
                    InspectorSection(title: "Palette color") {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(color.output.swiftColor)
                                .frame(width: 64, height: 64)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                                }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(color.output.hex)
                                    .font(.title3.monospaced().weight(.semibold))
                                Text("Source: \(color.source.hex)")
                                    .font(.caption.monospaced())
                                    .foregroundStyle(AppPalette.muted)
                            }
                        }
                    }
                    InspectorSection(title: "Replacement") {
                        ColorPicker("Color", selection: Binding(
                            get: { color.output.swiftColor },
                            set: { viewModel.updateColor(color.id, color: $0) }
                        ))
                        TextField("Hex", text: Binding(
                            get: { viewModel.hexText },
                            set: { viewModel.updateColor(color.id, hex: $0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { viewModel.syncHex(for: selectedColorID) }
                        Text("Only fully opaque source pixels are replaced. Sprite PNGs remain unchanged.")
                            .font(.caption)
                            .foregroundStyle(AppPalette.muted)
                    }
                    Button("Delete Color", systemImage: "trash", role: .destructive) {
                        viewModel.colorToDelete = color
                    }
                    .buttonStyle(.bordered)
                    .disabled((document.effectivePalette?.colors.count ?? 0) <= 1)
                }
                .padding(16)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "eyedropper")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Select a color")
                        .font(.headline)
                    Text("Choose a palette card to edit its render color.")
                        .font(.caption)
                        .foregroundStyle(AppPalette.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(28)
            }
        }
        .background(.regularMaterial)
        .onChange(of: selectedColorID) { _, _ in
            viewModel.syncHex(for: selectedColorID)
        }
        .alert("Delete palette color?", isPresented: Binding(
            get: { viewModel.colorToDelete != nil },
            set: { if !$0 { viewModel.colorToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                viewModel.deleteSelectedColor()
            }
            Button("Cancel", role: .cancel) { viewModel.colorToDelete = nil }
        } message: {
            Text("Pixels using this color will be remapped to the closest remaining palette color.")
        }
    }
}

