import Foundation

@MainActor
final class PalettePreviewImageViewModel: ObservableObject {
    let document: ProjectDocument

    init(document: ProjectDocument) {
        self.document = document
    }

    func imageRect(in size: CGSize, sheet: SpriteSheet?) -> CGRect {
        guard let sheet, sheet.canvasWidth > 0, sheet.canvasHeight > 0 else {
            return .zero
        }
        let scale = min(size.width / CGFloat(sheet.canvasWidth), size.height / CGFloat(sheet.canvasHeight)) * 0.9
        let imageSize = CGSize(
            width: CGFloat(sheet.canvasWidth) * scale,
            height: CGFloat(sheet.canvasHeight) * scale
        )
        return CGRect(
            x: (size.width - imageSize.width) / 2,
            y: (size.height - imageSize.height) / 2,
            width: imageSize.width,
            height: imageSize.height
        )
    }

    func paletteColorID(
        at location: CGPoint,
        in size: CGSize,
        imageRect: CGRect,
        zoom: CGFloat,
        offset: CGSize,
        sheet: SpriteSheet?,
        mode: SheetRenderMode
    ) -> UUID? {
        guard let sheet, imageRect.width > 0, imageRect.height > 0 else {
            return nil
        }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let displayedRect = CGRect(
            x: center.x - imageRect.width * zoom / 2 + offset.width,
            y: center.y - imageRect.height * zoom / 2 + offset.height,
            width: imageRect.width * zoom,
            height: imageRect.height * zoom
        )
        guard displayedRect.contains(location) else {
            return nil
        }
        let relativeX = (location.x - displayedRect.minX) / displayedRect.width
        let relativeY = (location.y - displayedRect.minY) / displayedRect.height
        let pixelX = min(sheet.canvasWidth - 1, max(0, Int(relativeX * CGFloat(sheet.canvasWidth))))
        let pixelY = min(sheet.canvasHeight - 1, max(0, Int(relativeY * CGFloat(sheet.canvasHeight))))
        return document.paletteColorID(atX: pixelX, y: pixelY, in: sheet, mode: mode)
    }
}
