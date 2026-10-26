import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct SpriteCanvas: View {
    @ObservedObject var document: ProjectDocument
    @Binding var showingImporter: Bool
    @StateObject private var viewModel: SpriteCanvasViewModel

    init(document: ProjectDocument, showingImporter: Binding<Bool>) {
        self.document = document
        _showingImporter = showingImporter
        _viewModel = StateObject(wrappedValue: SpriteCanvasViewModel(document: document))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Label("Pixel editor", systemImage: "pencil.and.ruler")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Toggle(isOn: $viewModel.gridEnabled) {
                    Label("Pixel grid", systemImage: "grid")
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .font(.caption)
                if let asset = viewModel.selectedAsset {
                    Text("\(asset.width) × \(asset.height) px")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(AppPalette.muted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
            Divider()

            if let asset = viewModel.selectedAsset, let image = viewModel.image(for: asset.id) {
                ScrollView([.horizontal, .vertical]) {
                    ZStack(alignment: .topLeading) {
                        Checkerboard()
                        Image(nsImage: image)
                            .interpolation(.none)
                            .resizable()
                            .frame(width: CGFloat(asset.width) * viewModel.zoom, height: CGFloat(asset.height) * viewModel.zoom)
                            .offset(
                                x: CGFloat(viewModel.dragPreview?.dx ?? 0) * viewModel.zoom,
                                y: CGFloat(viewModel.dragPreview?.dy ?? 0) * viewModel.zoom
                            )
                            .contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .onChanged { value in viewModel.updateDrag(translation: value.translation) }
                                .onEnded { value in viewModel.finishDrag(translation: value.translation) })
                        if viewModel.gridEnabled {
                                PixelGrid(width: asset.width, height: asset.height, zoom: viewModel.zoom)
                                    .allowsHitTesting(false)
                        }
                    }
                    .frame(width: CGFloat(asset.width) * viewModel.zoom, height: CGFloat(asset.height) * viewModel.zoom)
                    .clipped()
                    .padding(36)
                }
                .background(AppPalette.canvas)
                Divider()
                HStack(spacing: 10) {
                    Button {
                        viewModel.zoom = max(SpriteCanvasConstants.minimumZoom, viewModel.zoom - 1)
                    } label: {
                        Image(systemName: "minus")
                    }
                        .buttonStyle(.borderless)
                        .help("Zoom out")
                    Slider(value: $viewModel.zoom, in: SpriteCanvasConstants.minimumZoom...SpriteCanvasConstants.maximumZoom, step: 1)
                        .frame(width: 150)
                    Button {
                        viewModel.zoom = min(SpriteCanvasConstants.maximumZoom, viewModel.zoom + 1)
                    } label: {
                        Image(systemName: "plus")
                    }
                        .buttonStyle(.borderless)
                        .help("Zoom in")
                    Text("\(Int(viewModel.zoom))×")
                        .font(.caption.monospacedDigit())
                        .frame(width: 32, alignment: .leading)
                    Spacer()
                    Text("Drag to shift pixels")
                        .font(.caption)
                        .foregroundStyle(AppPalette.muted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(.bar)
            } else {
                SpriteEmptyState(document: document, showingImporter: $showingImporter)
            }
        }
        .background(AppPalette.canvas)
    }

}

