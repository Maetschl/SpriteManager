import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SheetCanvas: View {
    @ObservedObject var document: ProjectDocument
    @Binding var selectedPlacementID: UUID?
    @StateObject private var viewModel: SheetCanvasViewModel

    init(document: ProjectDocument, selectedPlacementID: Binding<UUID?>) {
        self.document = document
        _selectedPlacementID = selectedPlacementID
        _viewModel = StateObject(wrappedValue: SheetCanvasViewModel(document: document))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Label("Composition", systemImage: "rectangle.3.group")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if let sheet = document.selectedSheet {
                    Text("\(sheet.placements.count) sprites")
                        .font(.caption)
                        .foregroundStyle(AppPalette.muted)
                }
                Button("Export", systemImage: "square.and.arrow.up") {
                    if let sheet = document.selectedSheet { viewModel.export(sheet) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(document.selectedSheet == nil)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
            Divider()

            if let sheet = document.selectedSheet, let image = try? document.renderedSheet(sheet) {
                ScrollView([.horizontal, .vertical]) {
                    ZStack(alignment: .topLeading) {
                        Image(nsImage: NSImage(cgImage: image, size: NSSize(width: sheet.canvasWidth, height: sheet.canvasHeight)))
                            .interpolation(.none)
                            .resizable()
                            .frame(width: CGFloat(sheet.canvasWidth) * viewModel.zoom, height: CGFloat(sheet.canvasHeight) * viewModel.zoom)
                            .background(Checkerboard())
                        ForEach(sheet.placements) { placement in
                            if let asset = document.asset(for: placement.spriteID) {
                                let isPreview = viewModel.dragPreview?.placementID == placement.id
                                let displayX = isPreview ? viewModel.dragPreview?.x ?? placement.x : placement.x
                                let displayY = isPreview ? viewModel.dragPreview?.y ?? placement.y : placement.y
                                if isPreview, let image = document.image(for: asset.id) {
                                    Image(nsImage: image)
                                        .interpolation(.none)
                                        .resizable()
                                        .frame(width: CGFloat(asset.width) * viewModel.zoom, height: CGFloat(asset.height) * viewModel.zoom)
                                        .opacity(0.42)
                                        .overlay {
                                            Rectangle()
                                                .stroke(viewModel.dragPreview?.isValid == true ? Color.accentColor : .red, style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                                        }
                                        .offset(x: CGFloat(displayX) * viewModel.zoom, y: CGFloat(displayY) * viewModel.zoom)
                                        .allowsHitTesting(false)
                                }
                                Rectangle()
                                    .fill(selectedPlacementID == placement.id ? Color.accentColor.opacity(0.13) : .clear)
                                    .overlay {
                                        Rectangle()
                                            .stroke(selectedPlacementID == placement.id ? Color.accentColor : Color.white.opacity(0.6), lineWidth: selectedPlacementID == placement.id ? 2 : 1)
                                    }
                                    .frame(width: CGFloat(asset.width) * viewModel.zoom, height: CGFloat(asset.height) * viewModel.zoom)
                                    .offset(x: CGFloat(displayX) * viewModel.zoom, y: CGFloat(displayY) * viewModel.zoom)
                                    .contentShape(Rectangle())
                                    .onTapGesture { selectedPlacementID = placement.id }
                                    .gesture(DragGesture(minimumDistance: 1)
                                        .onChanged { value in
                                            selectedPlacementID = placement.id
                                            viewModel.updateDrag(sheet: sheet, placement: placement, translation: value.translation)
                                        }
                                        .onEnded { value in
                                            viewModel.finishDrag(sheet: sheet, placement: placement, translation: value.translation)
                                        })
                            }
                        }
                    }
                    .frame(width: CGFloat(sheet.canvasWidth) * viewModel.zoom, height: CGFloat(sheet.canvasHeight) * viewModel.zoom)
                    .padding(36)
                }
                .background(AppPalette.canvas)
                Divider()
                HStack(spacing: 10) {
                    Button { viewModel.zoom = max(SheetCanvasConstants.minimumZoom, viewModel.zoom - 1) } label: { Image(systemName: "minus") }
                        .buttonStyle(.borderless)
                        .help("Zoom out")
                    Slider(value: $viewModel.zoom, in: SheetCanvasConstants.minimumZoom...SheetCanvasConstants.maximumZoom, step: 1)
                        .frame(width: 150)
                    Button { viewModel.zoom = min(SheetCanvasConstants.maximumZoom, viewModel.zoom + 1) } label: { Image(systemName: "plus") }
                        .buttonStyle(.borderless)
                        .help("Zoom in")
                    Text("\(Int(viewModel.zoom))×")
                        .font(.caption.monospacedDigit())
                        .frame(width: 32, alignment: .leading)
                    Spacer()
                    Text("\(sheet.canvasWidth) × \(sheet.canvasHeight) px")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(AppPalette.muted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(.bar)
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "rectangle.3.group")
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(.tint)
                    Text("Create your first spritesheet")
                        .font(.title3.weight(.semibold))
                    Text("A sheet is a canvas where you compose sprites for export.")
                        .font(.callout)
                        .foregroundStyle(AppPalette.muted)
                    Button("New Spritesheet", systemImage: "plus") { document.createSheet() }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
            }
        }
        .background(AppPalette.canvas)
        .onDeleteCommand {
            guard let sheet = document.selectedSheet, let selectedPlacementID else { return }
            document.removePlacement(sheetID: sheet.id, placementID: selectedPlacementID)
            self.selectedPlacementID = nil
        }
    }
}

