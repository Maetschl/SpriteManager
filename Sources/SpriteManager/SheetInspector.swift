import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SheetInspector: View {
    @ObservedObject var document: ProjectDocument
    @Binding var selectedPlacementID: UUID?
    let onEditSprite: (UUID) -> Void
    @StateObject private var viewModel: SheetInspectorViewModel

    init(document: ProjectDocument, selectedPlacementID: Binding<UUID?>, onEditSprite: @escaping (UUID) -> Void) {
        self.document = document
        _selectedPlacementID = selectedPlacementID
        self.onEditSprite = onEditSprite
        _viewModel = StateObject(wrappedValue: SheetInspectorViewModel(document: document))
    }

    var body: some View {
        ScrollView {
            if let sheet = viewModel.selectedSheet {
                VStack(alignment: .leading, spacing: 18) {
                    InspectorSection(title: "Sheet") {
                        TextField("Name", text: Binding(
                            get: { viewModel.selectedSheet?.name ?? sheet.name },
                            set: { viewModel.updateName(sheet.id, value: $0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                        HStack(spacing: 8) {
                            SheetInspectorIntegerField("Width", value: Binding(
                                get: { viewModel.selectedSheet?.canvasWidth ?? sheet.canvasWidth },
                                set: { viewModel.updateWidth(sheet.id, value: $0) }
                            ))
                            SheetInspectorIntegerField("Height", value: Binding(
                                get: { viewModel.selectedSheet?.canvasHeight ?? sheet.canvasHeight },
                                set: { viewModel.updateHeight(sheet.id, value: $0) }
                            ))
                        }
                        SheetInspectorIntegerField("Grid size", value: Binding(
                            get: { viewModel.selectedSheet?.gridSize ?? sheet.gridSize },
                            set: { viewModel.updateGridSize(sheet.id, value: $0) }
                        ))
                        Text("New sprites snap to this grid and use the first free cell. Existing sprites cannot overlap.")
                            .font(.caption)
                            .foregroundStyle(AppPalette.muted)
                        Text("Sprites are kept at native size and clamped inside the canvas.")
                            .font(.caption)
                            .foregroundStyle(AppPalette.muted)
                    }
                    InspectorSection(title: "Add sprites") {
                        if viewModel.availableAssets.isEmpty {
                            Text("Import sprites from the Sprites tab first.")
                                .font(.caption)
                                .foregroundStyle(AppPalette.muted)
                        } else {
                            SearchField(text: $viewModel.assetSearch, placeholder: "Find a sprite")
                            VStack(spacing: 2) {
                                ForEach(viewModel.filteredAssets) { asset in
                                    Button {
                                        viewModel.addSprite(asset.id, to: sheet.id)
                                    } label: {
                                        HStack(spacing: 8) {
                                            AssetThumbnail(document: document, asset: asset)
                                                .frame(width: 28, height: 28)
                                            Text(asset.name)
                                                .lineLimit(1)
                                            Spacer()
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundStyle(.tint)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.vertical, 3)
                                }
                            }
                        }
                    }
                    InspectorSection(title: "Placements · \(sheet.placements.count)") {
                        if sheet.placements.isEmpty {
                            Text("Add sprites above, then drag them on the canvas.")
                                .font(.caption)
                                .foregroundStyle(AppPalette.muted)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(sheet.placements) { placement in
                                    if let asset = viewModel.asset(for: placement.spriteID) {
                                        VStack(alignment: .leading, spacing: 7) {
                                            HStack {
                                                Button {
                                                    selectedPlacementID = placement.id
                                                } label: {
                                                    Label(asset.name, systemImage: "square.fill")
                                                        .font(.subheadline.weight(.medium))
                                                }
                                                .buttonStyle(.plain)
                                                Spacer()
                                                Button {
                                                    viewModel.removePlacement(placement.id, from: sheet.id)
                                                    if selectedPlacementID == placement.id { selectedPlacementID = nil }
                                                } label: {
                                                    Image(systemName: "trash")
                                                }
                                                .buttonStyle(.borderless)
                                                .help("Remove from sheet")
                                            }
                                            HStack(spacing: 8) {
                                                IntegerField("X", value: Binding(
                                                    get: {
                                                        viewModel.placement(placement).x
                                                    },
                                                    set: { value in
                                                        let current = viewModel.placement(placement)
                                                        viewModel.movePlacement(placement, in: sheet.id, x: value, y: current.y)
                                                    }
                                                )).labelsHidden()
                                                IntegerField("Y", value: Binding(
                                                    get: {
                                                        viewModel.placement(placement).y
                                                    },
                                                    set: { value in
                                                        let current = viewModel.placement(placement)
                                                        viewModel.movePlacement(placement, in: sheet.id, x: current.x, y: value)
                                                    }
                                                )).labelsHidden()
                                            }
                                            if selectedPlacementID == placement.id {
                                                HStack(spacing: 6) {
                                                    Label("Source pixels", systemImage: "move.3d")
                                                        .font(.caption)
                                                        .foregroundStyle(AppPalette.muted)
                                                    Spacer()
                                                    Button { viewModel.shiftSprite(asset.id, dx: -1, dy: 0) } label: {
                                                        Image(systemName: "arrow.left")
                                                    }
                                                    Button { viewModel.shiftSprite(asset.id, dx: 1, dy: 0) } label: {
                                                        Image(systemName: "arrow.right")
                                                    }
                                                    Button { viewModel.shiftSprite(asset.id, dx: 0, dy: -1) } label: {
                                                        Image(systemName: "arrow.up")
                                                    }
                                                    Button { viewModel.shiftSprite(asset.id, dx: 0, dy: 1) } label: {
                                                        Image(systemName: "arrow.down")
                                                    }
                                                    Button("Edit") { onEditSprite(asset.id) }
                                                        .buttonStyle(.bordered)
                                                        .controlSize(.small)
                                                }
                                                .buttonStyle(.borderless)
                                                .help("Nudge the shared source sprite by one pixel")
                                            }
                                        }
                                        .padding(9)
                                        .background(
                                            selectedPlacementID == placement.id
                                                ? Color.accentColor.opacity(0.12)
                                                : Color.primary.opacity(0.04),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    InspectorSection(title: "Border effect") {
                        Toggle("Enable one-pixel outline", isOn: Binding(
                            get: { viewModel.selectedSheet?.borderEffect.enabled ?? false },
                            set: { value in viewModel.updateBorder(sheet, enabled: value) }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        if sheet.borderEffect.enabled {
                            ColorPicker("Color", selection: Binding(
                                get: { viewModel.selectedSheet?.borderEffect.color.swiftColor ?? .white },
                                set: { color in
                                    viewModel.updateBorder(sheet, color: color)
                                }
                            ))
                        }
                        Text("Previewed here and applied only to the rendered export. Source sprites stay unchanged.")
                            .font(.caption)
                            .foregroundStyle(AppPalette.muted)
                    }
                    Button("Export PNG + JSON", systemImage: "square.and.arrow.up") {
                        viewModel.export(sheet)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                .padding(16)
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Select a sheet")
                        .font(.headline)
                    Text("Sheet settings and placements will appear here.")
                        .font(.caption)
                        .foregroundStyle(AppPalette.muted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(28)
            }
        }
        .background(.regularMaterial)
    }

}

