import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PalettePreviewImage: View {
    @ObservedObject var document: ProjectDocument
    let sheet: SpriteSheet?
    let mode: SheetRenderMode
    let label: String
    @Binding var zoom: CGFloat
    @Binding var offset: CGSize
    let highlightedColorID: UUID?
    let highlightOpacity: Double
    let onSelectColor: (UUID) -> Void
    @State private var magnificationStartZoom: CGFloat?
    @State private var dragStartOffset: CGSize?
    @StateObject private var viewModel: PalettePreviewImageViewModel

    init(
        document: ProjectDocument,
        sheet: SpriteSheet?,
        mode: SheetRenderMode,
        label: String,
        zoom: Binding<CGFloat>,
        offset: Binding<CGSize>,
        highlightedColorID: UUID?,
        highlightOpacity: Double,
        onSelectColor: @escaping (UUID) -> Void
    ) {
        self.document = document
        self.sheet = sheet
        self.mode = mode
        self.label = label
        self._zoom = zoom
        self._offset = offset
        self.highlightedColorID = highlightedColorID
        self.highlightOpacity = highlightOpacity
        self.onSelectColor = onSelectColor
        _viewModel = StateObject(wrappedValue: PalettePreviewImageViewModel(document: document))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                Spacer()
                if let sheet {
                    Text("\(sheet.canvasWidth) × \(sheet.canvasHeight) px")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(AppPalette.muted)
                }
            }
            GeometryReader { geometry in
                let imageRect = viewModel.imageRect(in: geometry.size, sheet: sheet)
                ZStack {
                    Checkerboard()
                    if let sheet,
                       let image = try? document.renderedSheet(sheet, mode: mode) {
                        Image(nsImage: NSImage(cgImage: image, size: NSSize(width: sheet.canvasWidth, height: sheet.canvasHeight)))
                            .interpolation(.none)
                            .resizable()
                            .frame(width: imageRect.width, height: imageRect.height)
                            .scaleEffect(zoom)
                            .offset(offset)
                        if let highlightedColorID,
                           let highlight = try? document.highlightedSheet(sheet, mode: mode, colorID: highlightedColorID) {
                            Image(nsImage: NSImage(cgImage: highlight, size: NSSize(width: sheet.canvasWidth, height: sheet.canvasHeight)))
                                .interpolation(.none)
                                .resizable()
                                .frame(width: imageRect.width, height: imageRect.height)
                                .scaleEffect(zoom)
                                .offset(offset)
                                .opacity(highlightOpacity)
                                .allowsHitTesting(false)
                        }
                    } else {
                        Image(systemName: "rectangle.dashed")
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            if magnificationStartZoom == nil { magnificationStartZoom = zoom }
                            zoom = max(0.5, min(12, (magnificationStartZoom ?? zoom) * value))
                        }
                        .onEnded { _ in
                            magnificationStartZoom = nil
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if dragStartOffset == nil { dragStartOffset = offset }
                            let start = dragStartOffset ?? offset
                            offset = CGSize(
                                width: start.width + value.translation.width,
                                height: start.height + value.translation.height
                            )
                        }
                        .onEnded { _ in dragStartOffset = nil }
                )
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            if let colorID = viewModel.paletteColorID(
                                at: value.location,
                                in: geometry.size,
                                imageRect: imageRect,
                                zoom: zoom,
                                offset: offset,
                                sheet: sheet,
                                mode: mode
                            ) {
                                onSelectColor(colorID)
                            }
                        }
                )
            }
            .frame(maxWidth: .infinity)
            .frame(height: PalettePreviewImageConstants.previewHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.12))
            }
        }
    }

}

