import Foundation
import SwiftUI
import UniformTypeIdentifiers
import AppKit

enum QualityIssueSeverity: String, Codable, Hashable, Sendable {
    case error
    case warning

    var title: String { rawValue.capitalized }
    var sortOrder: Int { self == .error ? 0 : 1 }
}

struct QualityIssue: Identifiable, Hashable, Sendable {
    let id = UUID()
    let severity: QualityIssueSeverity
    let message: String
    let sheetID: UUID?
    let placementID: UUID?
    let spriteID: UUID?

    init(
        severity: QualityIssueSeverity,
        message: String,
        sheetID: UUID? = nil,
        placementID: UUID? = nil,
        spriteID: UUID? = nil
    ) {
        self.severity = severity
        self.message = message
        self.sheetID = sheetID
        self.placementID = placementID
        self.spriteID = spriteID
    }
}

struct QualityReport: Hashable, Sendable {
    let issues: [QualityIssue]

    var errors: [QualityIssue] { issues.filter { $0.severity == .error } }
    var warnings: [QualityIssue] { issues.filter { $0.severity == .warning } }
    var isClean: Bool { issues.isEmpty }
}

@MainActor
final class ProjectDocument: @preconcurrency ReferenceFileDocument, ObservableObject {
    typealias Snapshot = ProjectSnapshot

    static var readableContentTypes: [UTType] { [.spritesProject, .legacySpritesProject] }
    static var writableContentTypes: [UTType] { [.spritesProject] }

    @Published var project: SpriteProject
    @Published var assets: [UUID: SpriteAsset]
    @Published var pixelData: [UUID: Data]
    @Published var selectedSpriteID: UUID?
    @Published var selectedSheetID: UUID?
    @Published var isDirty = false
    @Published var errorMessage: String?
    @Published private(set) var conflictAssetIDs: [UUID] = []
    @Published private(set) var dirtyAssetIDs: Set<UUID> = []
    @Published private(set) var pendingPalette: ColorPalette?

    private let library: LibraryStore
    private let imageCache = NSCache<NSUUID, NSImage>()
    private var observer: NSObjectProtocol?
    private var projectNameEditActive = false
    private var undoStack: [ProjectEditState] = []
    private var redoStack: [ProjectEditState] = []

    init(project: SpriteProject = SpriteProject(), library: LibraryStore = .shared) {
        self.project = project
        self.library = library
        self.assets = [:]
        self.pixelData = [:]
        self.selectedSheetID = project.sheets.first?.id
        self.pendingPalette = nil
        self.observer = nil
        observeLibrary()
    }

    required convenience init(configuration: ReadConfiguration) throws {
        try self.init(packageWrapper: configuration.file, library: .shared)
    }

    init(packageWrapper wrapper: FileWrapper, library: LibraryStore) throws {
        self.library = library
        guard wrapper.isDirectory,
              let manifestWrapper = wrapper.fileWrappers?["project.json"],
              let manifestData = manifestWrapper.regularFileContents else {
            throw SpriteManagerError.invalidProject
        }
        let manifest = try JSONDecoder().decode(ProjectManifest.self, from: manifestData)
        guard manifest.schemaVersion <= ProjectManifest.currentSchemaVersion,
              manifest.project.schemaVersion <= SpriteProject.currentSchemaVersion else {
            throw SpriteManagerError.unsupportedSchema(manifest.schemaVersion)
        }
        var loadedProject = manifest.project
        loadedProject.schemaVersion = SpriteProject.currentSchemaVersion
        self.project = loadedProject
        self.assets = Dictionary(uniqueKeysWithValues: manifest.assets.map { ($0.id, $0) })
        self.pixelData = [:]
        self.selectedSheetID = manifest.project.sheets.first?.id
        self.pendingPalette = nil
        self.observer = nil
        let assetWrappers = wrapper.fileWrappers?["assets"]?.fileWrappers ?? [:]
        for asset in manifest.assets {
            let fileName = "\(asset.id.uuidString).png"
            guard let data = assetWrappers[fileName]?.regularFileContents else {
                throw SpriteManagerError.missingFile("assets/\(fileName)")
            }
            let buffer = try PixelBuffer(pngData: data)
            guard buffer.width == asset.width, buffer.height == asset.height else {
                throw SpriteManagerError.invalidPNG(fileName)
            }
            self.pixelData[asset.id] = data
            if let localAsset = library.assets[asset.id], localAsset.contentHash != asset.contentHash {
                self.conflictAssetIDs.append(asset.id)
            } else {
                _ = try? library.register(asset, data: data, preferIncoming: false)
            }
        }
        self.selectedSpriteID = manifest.assets.first?.id
        self.isDirty = manifest.schemaVersion < ProjectManifest.currentSchemaVersion
            || manifest.project.schemaVersion < SpriteProject.currentSchemaVersion
        observeLibrary()
    }

    func snapshot(contentType: UTType) throws -> ProjectSnapshot {
        try validate()
        var projectForSave = project
        projectForSave.schemaVersion = SpriteProject.currentSchemaVersion
        if let pendingPalette { projectForSave.palette = pendingPalette }
        let manifest = ProjectManifest(project: projectForSave, assets: assets.values.sorted { $0.name < $1.name })
        var data = pixelData
        for asset in assets.values where data[asset.id] == nil {
            if let libraryData = library.data(for: asset.id) { data[asset.id] = libraryData }
        }
        return ProjectSnapshot(manifest: manifest, dataByAssetID: data)
    }

    func fileWrapper(snapshot: ProjectSnapshot, configuration: WriteConfiguration) throws -> FileWrapper {
        let wrapper = try fileWrapper(snapshot: snapshot)
        project = snapshot.manifest.project
        pendingPalette = nil
        isDirty = false
        dirtyAssetIDs.removeAll()
        return wrapper
    }

    func fileWrapper(snapshot: ProjectSnapshot) throws -> FileWrapper {
        let manifestData = try JSONEncoder.pretty.encode(snapshot.manifest)
        let manifestWrapper = FileWrapper(regularFileWithContents: manifestData)
        manifestWrapper.preferredFilename = "project.json"

        var assetWrappers: [String: FileWrapper] = [:]
        for asset in snapshot.manifest.assets {
            guard let data = snapshot.dataByAssetID[asset.id] else { throw SpriteManagerError.missingAsset(asset.id) }
            let wrapper = FileWrapper(regularFileWithContents: data)
            wrapper.preferredFilename = "\(asset.id.uuidString).png"
            assetWrappers[wrapper.preferredFilename ?? "\(asset.id.uuidString).png"] = wrapper
        }
        let assetsWrapper = FileWrapper(directoryWithFileWrappers: assetWrappers)
        assetsWrapper.preferredFilename = "assets"
        return FileWrapper(directoryWithFileWrappers: [
            "project.json": manifestWrapper,
            "assets": assetsWrapper
        ])
    }

    func importPNG(data: Data, originalName: String) {
        do {
            recordUndo()
            let buffer = try PixelBuffer(pngData: data)
            let id = UUID()
            let baseName = originalName.replacingOccurrences(of: ".png", with: "", options: .caseInsensitive)
            let asset = SpriteAsset(
                id: id,
                name: baseName.isEmpty ? "Sprite" : baseName,
                width: buffer.width,
                height: buffer.height,
                contentHash: PixelData.sha256(data),
                originalFileName: originalName
            )
            assets[id] = asset
            pixelData[id] = data
            try library.register(asset, data: data)
            selectedSpriteID = id
            markDirty(assetID: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProjectName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != project.name else { return }
        recordUndo()
        project.name = trimmed
        markDirty()
    }

    func updateProjectNameLive(_ name: String) {
        guard project.name != name else { return }
        if !projectNameEditActive {
            recordUndo()
            projectNameEditActive = true
        }
        project.name = name
        markDirty()
    }

    func finishProjectNameEdit() {
        let trimmed = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed != project.name {
            project.name = trimmed
            markDirty()
        }
        projectNameEditActive = false
    }

    func includeAssetInProject(_ id: UUID) {
        guard let asset = asset(for: id), assets[id] == nil else { return }
        recordUndo()
        includeAssetInProjectIfNeeded(asset)
        markDirty()
    }

    func updateAssetName(_ id: UUID, name: String) {
        guard var asset = asset(for: id) else { return }
        recordUndo()
        includeAssetInProjectIfNeeded(asset)
        asset.name = name
        assets[id] = asset
        try? library.updateMetadata(asset)
        markDirty(assetID: id)
    }

    func updateAssetTags(_ id: UUID, tags: [String]) {
        guard var asset = asset(for: id) else { return }
        let normalized = Array(Set(tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty })).sorted()
        guard asset.tags != normalized else { return }
        recordUndo()
        asset.tags = normalized
        includeAssetInProjectIfNeeded(asset)
        assets[id] = asset
        try? library.updateMetadata(asset)
        markDirty(assetID: id)
    }

    func createCollection(name: String? = nil) {
        recordUndo()
        let defaultName = "Collection \(project.collections.count + 1)"
        project.collections.append(SpriteCollection(name: name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? name! : defaultName))
        markDirty()
    }

    func renameCollection(_ id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = project.collections.firstIndex(where: { $0.id == id }),
              project.collections[index].name != trimmed else { return }
        recordUndo()
        project.collections[index].name = trimmed
        markDirty()
    }

    func deleteCollection(_ id: UUID) {
        guard project.collections.contains(where: { $0.id == id }) else { return }
        recordUndo()
        project.collections.removeAll { $0.id == id }
        markDirty()
    }

    func setAsset(_ assetID: UUID, inCollection collectionID: UUID, included: Bool) {
        guard let index = project.collections.firstIndex(where: { $0.id == collectionID }) else { return }
        let contains = project.collections[index].assetIDs.contains(assetID)
        guard contains != included else { return }
        recordUndo()
        if included {
            project.collections[index].assetIDs.append(assetID)
        } else {
            project.collections[index].assetIDs.removeAll { $0 == assetID }
        }
        markDirty()
    }

    func shiftAsset(_ id: UUID, dx: Int, dy: Int) {
        guard let data = pixelData[id] ?? library.data(for: id) else { return }
        do {
            recordUndo()
            if let asset = asset(for: id) { includeAssetInProjectIfNeeded(asset) }
            let buffer = try PixelBuffer(pngData: data).shifted(dx: dx, dy: dy)
            let shiftedData = try buffer.pngData()
            pixelData[id] = shiftedData
            imageCache.removeObject(forKey: id as NSUUID)
            try library.updateData(id: id, data: shiftedData)
            if let libraryAsset = library.assets[id] { assets[id] = libraryAsset }
            markDirty(assetID: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createSheet() {
        recordUndo()
        let sheet = SpriteSheet(name: "Spritesheet \(project.sheets.count + 1)")
        project.sheets.append(sheet)
        selectedSheetID = sheet.id
        markDirty()
    }

    func duplicateSelectedSheet() {
        guard let sheet = selectedSheet else { return }
        recordUndo()
        var copy = sheet
        copy = SpriteSheet(
            name: "\(sheet.name) Copy",
            canvasWidth: sheet.canvasWidth,
            canvasHeight: sheet.canvasHeight,
            gridSize: sheet.gridSize,
            placements: sheet.placements.map { SpritePlacement(spriteID: $0.spriteID, x: $0.x, y: $0.y, zIndex: $0.zIndex) },
            borderEffect: sheet.borderEffect
        )
        project.sheets.append(copy)
        selectedSheetID = copy.id
        markDirty()
    }

    func deleteSelectedSheet() {
        guard let id = selectedSheetID else { return }
        recordUndo()
        project.sheets.removeAll { $0.id == id }
        selectedSheetID = project.sheets.first?.id
        markDirty()
    }

    func addSprite(_ spriteID: UUID, to sheetID: UUID) {
        guard let index = project.sheets.firstIndex(where: { $0.id == sheetID }), let asset = asset(for: spriteID) else { return }
        let sheet = project.sheets[index]
        guard asset.width <= sheet.canvasWidth, asset.height <= sheet.canvasHeight else {
            errorMessage = "\(asset.name) is larger than the selected canvas."
            return
        }
        guard let position = firstAvailablePosition(for: asset, in: sheet) else {
            errorMessage = "There is no free grid position for \(asset.name) on this canvas."
            return
        }
        recordUndo()
        includeAssetInProjectIfNeeded(asset)
        let placement = SpritePlacement(spriteID: spriteID, x: position.x, y: position.y, zIndex: sheet.placements.count)
        project.sheets[index].placements.append(placement)
        markDirty()
    }

    func updateSheet(
        _ sheetID: UUID,
        name: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        gridSize: Int? = nil,
        border: BorderEffect? = nil
    ) {
        guard let index = project.sheets.firstIndex(where: { $0.id == sheetID }) else { return }
        recordUndo()
        if let name { project.sheets[index].name = name }
        if let width { project.sheets[index].canvasWidth = max(1, width) }
        if let height { project.sheets[index].canvasHeight = max(1, height) }
        if let gridSize { project.sheets[index].gridSize = max(1, gridSize) }
        if let border { project.sheets[index].borderEffect = border }
        clampPlacements(in: index)
        markDirty()
    }

    func updatePreviewConfiguration(_ configuration: PackPreviewConfiguration) {
        guard project.previewConfiguration != configuration else { return }
        recordUndo()
        project.previewConfiguration = configuration
        markDirty()
    }

    @discardableResult
    func movePlacement(sheetID: UUID, placementID: UUID, x: Int, y: Int) -> Bool {
        guard let sheetIndex = project.sheets.firstIndex(where: { $0.id == sheetID }),
              let placementIndex = project.sheets[sheetIndex].placements.firstIndex(where: { $0.id == placementID }),
              let asset = asset(for: project.sheets[sheetIndex].placements[placementIndex].spriteID) else { return false }
        let sheet = project.sheets[sheetIndex]
        guard let position = snappedPlacementPosition(sheetID: sheetID, placementID: placementID, x: x, y: y),
              canPlace(asset: asset, at: position, in: sheet, excluding: placementID) else { return false }
        let current = sheet.placements[placementIndex]
        guard current.x != position.x || current.y != position.y else { return true }
        recordUndo()
        project.sheets[sheetIndex].placements[placementIndex].x = position.x
        project.sheets[sheetIndex].placements[placementIndex].y = position.y
        markDirty()
        return true
    }

    func snappedPlacementPosition(sheetID: UUID, placementID: UUID, x: Int, y: Int) -> PlacementPosition? {
        guard let sheet = project.sheets.first(where: { $0.id == sheetID }),
              let placement = sheet.placements.first(where: { $0.id == placementID }),
              let asset = asset(for: placement.spriteID) else { return nil }
        return PlacementPosition(
            x: snap(x, to: sheet.gridSize, maximum: max(0, sheet.canvasWidth - asset.width)),
            y: snap(y, to: sheet.gridSize, maximum: max(0, sheet.canvasHeight - asset.height))
        )
    }

    func canMovePlacement(sheetID: UUID, placementID: UUID, x: Int, y: Int) -> Bool {
        guard let sheet = project.sheets.first(where: { $0.id == sheetID }),
              let placement = sheet.placements.first(where: { $0.id == placementID }),
              let asset = asset(for: placement.spriteID),
              let position = snappedPlacementPosition(sheetID: sheetID, placementID: placementID, x: x, y: y) else { return false }
        return canPlace(asset: asset, at: position, in: sheet, excluding: placementID)
    }

    func removePlacement(sheetID: UUID, placementID: UUID) {
        guard let sheetIndex = project.sheets.firstIndex(where: { $0.id == sheetID }) else { return }
        guard project.sheets[sheetIndex].placements.contains(where: { $0.id == placementID }) else { return }
        recordUndo()
        project.sheets[sheetIndex].placements.removeAll { $0.id == placementID }
        for index in project.sheets[sheetIndex].placements.indices {
            project.sheets[sheetIndex].placements[index].zIndex = index
        }
        markDirty()
    }

    func resolveNextConflict(useProjectVersion: Bool) {
        guard let id = conflictAssetIDs.first,
              let asset = assets[id],
              let data = pixelData[id] else { return }
        if useProjectVersion {
            _ = try? library.register(asset, data: data, preferIncoming: true)
        }
        conflictAssetIDs.removeFirst()
        objectWillChange.send()
    }

    func createPalette() {
        let palette = generatedPalette()
        recordUndo()
        pendingPalette = palette
        markDirty()
    }

    func regeneratePalette() {
        let palette = generatedPalette()
        recordUndo()
        pendingPalette = palette
        markDirty()
    }

    func updatePaletteColor(_ colorID: UUID, output: PaletteRGBColor) {
        guard var palette = paletteForEditing(),
              let index = palette.colors.firstIndex(where: { $0.id == colorID }) else { return }
        recordUndo()
        palette.colors[index].output = output
        pendingPalette = palette.orderedBySimilarity()
        markDirty()
    }

    func deletePaletteColor(_ colorID: UUID) {
        guard var palette = paletteForEditing(), palette.colors.count > 1,
              let index = palette.colors.firstIndex(where: { $0.id == colorID }) else { return }
        let deleted = palette.colors[index]
        let candidates = palette.colors.filter { $0.id != colorID }
        guard let target = candidates.min(by: {
            let leftDistance = PaletteColorMath.distance(deleted.output, $0.output)
            let rightDistance = PaletteColorMath.distance(deleted.output, $1.output)
            if leftDistance != rightDistance { return leftDistance < rightDistance }
            return $0.output.hex < $1.output.hex
        }) else { return }

        recordUndo()
        palette.colors.remove(at: index)
        palette.aliases = palette.aliases.map { alias in
            var updated = alias
            if updated.targetColorID == colorID { updated.targetColorID = target.id }
            return updated
        }
        palette.aliases.removeAll { $0.source == deleted.source }
        palette.aliases.append(PaletteAlias(source: deleted.source, targetColorID: target.id))
        pendingPalette = palette.orderedBySimilarity()
        markDirty()
    }

    func renderedSheet(_ sheet: SpriteSheet, mode: SheetRenderMode = .preview) throws -> CGImage {
        var canvas = PixelBuffer.blank(width: sheet.canvasWidth, height: sheet.canvasHeight)
        for placement in sheet.placements.sorted(by: { $0.zIndex < $1.zIndex }) {
            guard let asset = asset(for: placement.spriteID),
                  let data = pixelData[asset.id] ?? library.data(for: asset.id) else { continue }
            var buffer = try PixelBuffer(pngData: data)
            if let palette = palette(for: mode) {
                buffer = buffer.applying(palette)
            }
            if sheet.borderEffect.enabled {
                buffer = buffer.withInternalOutline(color: sheet.borderEffect.color, thickness: sheet.borderEffect.thickness)
            }
            canvas.composite(buffer, atX: placement.x, y: placement.y)
        }
        return try canvas.cgImage()
    }

    func export(sheet: SpriteSheet, to directory: URL) throws {
        let image = try renderedSheet(sheet, mode: .preview)
        let pngURL = directory.appendingPathComponent("\(safeName(sheet.name)).png")
        let manifestURL = directory.appendingPathComponent("\(safeName(sheet.name)).json")
        try PixelBuffer(image: image).pngData().write(to: pngURL, options: .atomic)
        let placements = sheet.placements.sorted { $0.zIndex < $1.zIndex }.compactMap { placement -> [String: Any]? in
            guard let asset = asset(for: placement.spriteID) else { return nil }
            return [
                "uuid": asset.id.uuidString,
                "name": asset.name,
                "x": placement.x,
                "y": placement.y,
                "width": asset.width,
                "height": asset.height,
                "zIndex": placement.zIndex
            ]
        }
        var json: [String: Any] = [
            "schemaVersion": 1,
            "sheetID": sheet.id.uuidString,
            "name": sheet.name,
            "width": sheet.canvasWidth,
            "height": sheet.canvasHeight,
            "border": [
                "enabled": sheet.borderEffect.enabled,
                "thickness": sheet.borderEffect.thickness,
                "algorithmVersion": sheet.borderEffect.algorithmVersion,
                "color": [
                    "r": sheet.borderEffect.color.r,
                    "g": sheet.borderEffect.color.g,
                    "b": sheet.borderEffect.color.b,
                    "a": sheet.borderEffect.color.a
                ]
            ],
            "sprites": placements
        ]
        if let palette = palette(for: .preview) {
            json["palette"] = [
                "algorithmVersion": palette.algorithmVersion,
                "colors": palette.colors.map { color in
                    [
                        "id": color.id.uuidString,
                        "source": color.source.hex,
                        "output": color.output.hex
                    ]
                },
                "aliases": palette.aliases.map { alias in
                    [
                        "source": alias.source.hex,
                        "targetColorID": alias.targetColorID.uuidString
                    ]
                }
            ]
        }
        let manifestData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        try manifestData.write(to: manifestURL, options: .atomic)
    }

    var selectedAsset: SpriteAsset? { selectedSpriteID.flatMap { asset(for: $0) } }
    var selectedSheet: SpriteSheet? { selectedSheetID.flatMap { id in project.sheets.first { $0.id == id } } }
    var effectivePalette: ColorPalette? { pendingPalette ?? project.palette }
    var hasPalette: Bool { effectivePalette != nil }
    var hasPendingPaletteChanges: Bool { pendingPalette != nil }
    var availableAssets: [UUID: SpriteAsset] {
        var result = library.assets
        for asset in assets.values { result[asset.id] = asset }
        return result
    }
    var projectAssetCount: Int { assets.count }
    var assignedAssetIDs: Set<UUID> {
        Set(project.sheets.flatMap { $0.placements.map(\.spriteID) })
    }
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func palette(for mode: SheetRenderMode) -> ColorPalette? {
        switch mode {
        case .source:
            return nil
        case .committed:
            return project.palette
        case .preview:
            return pendingPalette ?? project.palette
        }
    }

    func paletteColorID(atX x: Int, y: Int, in sheet: SpriteSheet, mode: SheetRenderMode) -> UUID? {
        guard effectivePalette != nil,
              x >= 0, x < sheet.canvasWidth,
              y >= 0, y < sheet.canvasHeight,
              let image = try? renderedSheet(sheet, mode: mode),
              let buffer = try? PixelBuffer(image: image) else { return nil }
        let pixel = buffer[x, y]
        guard pixel.a > 0 else { return nil }
        let renderedColor = PaletteRGBColor(r: pixel.r, g: pixel.g, b: pixel.b)
        for palette in [effectivePalette, palette(for: mode)].compactMap({ $0 }) {
            if let exactSource = palette.colors.first(where: { $0.source == renderedColor }) {
                return exactSource.id
            }
            if let exactOutput = palette.colors.first(where: { $0.output == renderedColor }) {
                return exactOutput.id
            }
            if let alias = palette.aliases.first(where: { $0.source == renderedColor }) {
                return alias.targetColorID
            }
        }
        return nil
    }

    func highlightedSheet(_ sheet: SpriteSheet, mode: SheetRenderMode, colorID: UUID) throws -> CGImage {
        guard let selectedColor = effectivePalette?.colors.first(where: { $0.id == colorID }) else {
            return try PixelBuffer.blank(width: sheet.canvasWidth, height: sheet.canvasHeight).cgImage()
        }
        let rendered = try PixelBuffer(image: renderedSheet(sheet, mode: mode))
        var highlight = PixelBuffer.blank(width: sheet.canvasWidth, height: sheet.canvasHeight)
        var matchingColors: Set<PaletteRGBColor> = [selectedColor.source, selectedColor.output]
        if let modePalette = palette(for: mode), let modeColor = modePalette.colors.first(where: { $0.id == colorID }) {
            matchingColors.insert(modeColor.source)
            matchingColors.insert(modeColor.output)
        }
        for alias in effectivePalette?.aliases ?? [] where alias.targetColorID == colorID {
            matchingColors.insert(alias.source)
        }
        for alias in palette(for: mode)?.aliases ?? [] where alias.targetColorID == colorID {
            matchingColors.insert(alias.source)
        }
        for y in 0..<rendered.height {
            for x in 0..<rendered.width {
                let pixel = rendered[x, y]
                guard pixel.a > 0 else { continue }
                let color = PaletteRGBColor(r: pixel.r, g: pixel.g, b: pixel.b)
                guard matchingColors.contains(color) else { continue }
                let index = (y * highlight.width + x) * PixelBuffer.bytesPerPixel
                highlight.pixels[index + PixelBuffer.redChannelOffset] = 255
                highlight.pixels[index + PixelBuffer.greenChannelOffset] = 64
                highlight.pixels[index + PixelBuffer.blueChannelOffset] = 170
                highlight.pixels[index + PixelBuffer.alphaChannelOffset] = 220
            }
        }
        return try highlight.cgImage()
    }

    func assetContainsColor(_ assetID: UUID, color: PaletteRGBColor) -> Bool {
        guard let data = pixelData[assetID] ?? library.data(for: assetID),
              let buffer = try? PixelBuffer(pngData: data) else { return false }
        for y in 0..<buffer.height {
            for x in 0..<buffer.width {
                let pixel = buffer[x, y]
                if pixel.a == PixelBuffer.opaqueAlpha,
                   PaletteRGBColor(r: pixel.r, g: pixel.g, b: pixel.b) == color {
                    return true
                }
            }
        }
        return false
    }

    func qualityReport() -> QualityReport {
        var issues: [QualityIssue] = []
        for sheet in project.sheets {
            if sheet.placements.isEmpty {
                issues.append(QualityIssue(
                    severity: .warning,
                    message: "This spritesheet has no sprites.",
                    sheetID: sheet.id
                ))
                continue
            }

            var occupiedArea = 0
            var referenceDimensions: (width: Int, height: Int)?
            for placement in sheet.placements {
                guard let asset = asset(for: placement.spriteID) else {
                    issues.append(QualityIssue(
                        severity: .error,
                        message: "The placement references a missing sprite.",
                        sheetID: sheet.id,
                        placementID: placement.id,
                        spriteID: placement.spriteID
                    ))
                    continue
                }

                occupiedArea += asset.width * asset.height
                if referenceDimensions == nil { referenceDimensions = (asset.width, asset.height) }
                if let referenceDimensions,
                   asset.width != referenceDimensions.width || asset.height != referenceDimensions.height {
                    issues.append(QualityIssue(
                        severity: .warning,
                        message: "This sprite has different dimensions from the first sprite in the sheet.",
                        sheetID: sheet.id,
                        placementID: placement.id,
                        spriteID: asset.id
                    ))
                }

                if placement.x < 0 || placement.y < 0 ||
                    placement.x + asset.width > sheet.canvasWidth ||
                    placement.y + asset.height > sheet.canvasHeight {
                    issues.append(QualityIssue(
                        severity: .error,
                        message: "This sprite extends outside the sheet canvas.",
                        sheetID: sheet.id,
                        placementID: placement.id,
                        spriteID: asset.id
                    ))
                }

                if placement.x % max(1, sheet.gridSize) != 0 || placement.y % max(1, sheet.gridSize) != 0 {
                    issues.append(QualityIssue(
                        severity: .warning,
                        message: "This placement does not match the sheet grid.",
                        sheetID: sheet.id,
                        placementID: placement.id,
                        spriteID: asset.id
                    ))
                }
            }

            for leftIndex in sheet.placements.indices {
                guard let leftAsset = asset(for: sheet.placements[leftIndex].spriteID) else { continue }
                let left = sheet.placements[leftIndex]
                let leftRect = CGRect(x: left.x, y: left.y, width: leftAsset.width, height: leftAsset.height)
                for rightIndex in sheet.placements.indices where rightIndex > leftIndex {
                    guard let rightAsset = asset(for: sheet.placements[rightIndex].spriteID) else { continue }
                    let right = sheet.placements[rightIndex]
                    let rightRect = CGRect(x: right.x, y: right.y, width: rightAsset.width, height: rightAsset.height)
                    if leftRect.intersects(rightRect) {
                        issues.append(QualityIssue(
                            severity: .error,
                            message: "Two sprites overlap in this sheet.",
                            sheetID: sheet.id,
                            placementID: right.id,
                            spriteID: right.spriteID
                        ))
                    }
                }
            }

            let canvasArea = max(1, sheet.canvasWidth * sheet.canvasHeight)
            if Double(occupiedArea) / Double(canvasArea) < 0.25 {
                issues.append(QualityIssue(
                    severity: .warning,
                    message: "This sheet has a large amount of unused canvas space.",
                    sheetID: sheet.id
                ))
            }
        }

        return QualityReport(issues: issues.sorted { left, right in
            if left.severity != right.severity { return left.severity.sortOrder < right.severity.sortOrder }
            if left.sheetID != right.sheetID { return (left.sheetID?.uuidString ?? "") < (right.sheetID?.uuidString ?? "") }
            return left.message < right.message
        })
    }

    func renderedPackPreview(configuration: PackPreviewConfiguration? = nil) throws -> CGImage {
        let configuration = configuration ?? project.previewConfiguration ?? PackPreviewConfiguration(title: project.name)
        let sheets = project.sheets.compactMap { sheet -> (SpriteSheet, CGImage)? in
            guard let image = try? renderedSheet(sheet, mode: .preview) else { return nil }
            return (sheet, image)
        }
        let margin: CGFloat = 36
        let titleHeight: CGFloat = configuration.title.isEmpty ? 20 : 54
        let paletteHeight: CGFloat = configuration.showsPalette && effectivePalette != nil ? 42 : 0
        let scale = CGFloat(max(1, configuration.scale))
        let maximumSheetWidth = sheets.map { CGFloat($0.0.canvasWidth) * scale }.max() ?? 1
        let width = max(1, Int(ceil(maximumSheetWidth + margin * 2)))
        let sheetsHeight = sheets.reduce(CGFloat(0)) { result, entry in
            result + CGFloat(entry.0.canvasHeight) * scale + (configuration.showsSheetNames ? 24 : 0)
        }
        let spacing = CGFloat(max(0, configuration.spacing))
        let height = max(1, Int(ceil(margin * 2 + titleHeight + paletteHeight + sheetsHeight + spacing * CGFloat(max(0, sheets.count - 1)))))
        let preview = NSImage(size: NSSize(width: width, height: height))
        preview.lockFocus()
        let background = NSColor(
            calibratedRed: CGFloat(configuration.background.r),
            green: CGFloat(configuration.background.g),
            blue: CGFloat(configuration.background.b),
            alpha: CGFloat(configuration.background.a)
        )
        background.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        NSGraphicsContext.current?.cgContext.interpolationQuality = .none

        var cursorY = CGFloat(height) - margin
        if !configuration.title.isEmpty {
            NSString(string: configuration.title).draw(
                at: NSPoint(x: margin, y: cursorY - 32),
                withAttributes: [
                    .font: NSFont.systemFont(ofSize: 26, weight: .bold),
                    .foregroundColor: NSColor.white
                ]
            )
            cursorY -= titleHeight
        }

        if configuration.showsPalette, let palette = effectivePalette {
            var swatchX = margin
            for color in palette.colors {
                NSColor(
                    calibratedRed: CGFloat(color.output.r) / 255,
                    green: CGFloat(color.output.g) / 255,
                    blue: CGFloat(color.output.b) / 255,
                    alpha: 1
                ).setFill()
                NSRect(x: swatchX, y: cursorY - 22, width: 22, height: 22).fill()
                swatchX += 28
                if swatchX > CGFloat(width) - margin - 22 { break }
            }
            cursorY -= paletteHeight
        }

        for (sheet, cgImage) in sheets {
            let sheetWidth = CGFloat(sheet.canvasWidth) * scale
            let sheetHeight = CGFloat(sheet.canvasHeight) * scale
            cursorY -= sheetHeight
            let rect = NSRect(x: margin, y: cursorY, width: sheetWidth, height: sheetHeight)
            NSImage(cgImage: cgImage, size: NSSize(width: sheetWidth, height: sheetHeight))
                .draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
            if configuration.showsSheetNames {
                NSString(string: sheet.name).draw(
                    at: NSPoint(x: margin, y: cursorY - 20),
                    withAttributes: [
                        .font: NSFont.systemFont(ofSize: 13, weight: .medium),
                        .foregroundColor: NSColor.white.withAlphaComponent(0.8)
                    ]
                )
                cursorY -= 24
            }
            cursorY -= spacing
        }
        preview.unlockFocus()
        guard let cgImage = preview.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw SpriteManagerError.invalidPNG("cannot create pack preview")
        }
        return cgImage
    }

    func exportPackPreview(to url: URL, configuration: PackPreviewConfiguration? = nil) throws {
        let image = try renderedPackPreview(configuration: configuration)
        try PixelBuffer(image: image).pngData().write(to: url, options: .atomic)
    }

    func image(for id: UUID) -> NSImage? {
        let cacheKey = id as NSUUID
        if let cached = imageCache.object(forKey: cacheKey) { return cached }
        guard let data = pixelData[id] ?? library.data(for: id),
              let buffer = try? PixelBuffer(pngData: data),
              let cgImage = try? buffer.cgImage() else { return nil }
        let image = NSImage(cgImage: cgImage, size: NSSize(width: buffer.width, height: buffer.height))
        imageCache.setObject(image, forKey: cacheKey)
        return image
    }

    private func markDirty(assetID: UUID? = nil) {
        if let assetID { dirtyAssetIDs.insert(assetID) }
        isDirty = true
        objectWillChange.send()
    }

    func undo() {
        guard let state = undoStack.popLast() else { return }
        redoStack.append(
            ProjectEditState(
                project: project,
                assets: assets,
                pixelData: pixelData,
                dirtyAssetIDs: dirtyAssetIDs,
                pendingPalette: pendingPalette
            )
        )
        restore(state)
    }

    func redo() {
        guard let state = redoStack.popLast() else { return }
        undoStack.append(
            ProjectEditState(
                project: project,
                assets: assets,
                pixelData: pixelData,
                dirtyAssetIDs: dirtyAssetIDs,
                pendingPalette: pendingPalette
            )
        )
        restore(state)
    }

    private func recordUndo() {
        undoStack.append(
            ProjectEditState(
                project: project,
                assets: assets,
                pixelData: pixelData,
                dirtyAssetIDs: dirtyAssetIDs,
                pendingPalette: pendingPalette
            )
        )
        if undoStack.count > 50 { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    private func restore(_ state: ProjectEditState) {
        project = state.project
        assets = state.assets
        pixelData = state.pixelData
        dirtyAssetIDs = state.dirtyAssetIDs
        pendingPalette = state.pendingPalette
        selectedSheetID = project.sheets.first?.id
        selectedSpriteID = assets.keys.sorted { $0.uuidString < $1.uuidString }.first
        for asset in assets.values {
            if let data = pixelData[asset.id] { _ = try? library.register(asset, data: data) }
        }
        markDirty()
    }

    private func clampPlacements(in sheetIndex: Int) {
        let sheet = project.sheets[sheetIndex]
        for placementIndex in project.sheets[sheetIndex].placements.indices {
            guard let asset = asset(for: project.sheets[sheetIndex].placements[placementIndex].spriteID) else { continue }
            project.sheets[sheetIndex].placements[placementIndex].x = min(
                max(0, project.sheets[sheetIndex].placements[placementIndex].x),
                max(0, sheet.canvasWidth - asset.width)
            )
            project.sheets[sheetIndex].placements[placementIndex].y = min(
                max(0, project.sheets[sheetIndex].placements[placementIndex].y),
                max(0, sheet.canvasHeight - asset.height)
            )
        }
    }

    private func validate() throws {
        for sheet in project.sheets {
            guard sheet.canvasWidth > 0, sheet.canvasHeight > 0 else { throw SpriteManagerError.invalidProject }
            for placement in sheet.placements {
                guard let asset = assets[placement.spriteID] else { throw SpriteManagerError.missingAsset(placement.spriteID) }
                guard placement.x >= 0, placement.y >= 0,
                      placement.x + asset.width <= sheet.canvasWidth,
                      placement.y + asset.height <= sheet.canvasHeight else {
                    throw SpriteManagerError.placementOutsideCanvas(asset.name)
                }
            }
        }
    }

    private func observeLibrary() {
        observer = NotificationCenter.default.addObserver(
            forName: .spriteAssetDidChange,
            object: library,
            queue: .main
        ) { [weak self] notification in
            guard let id = notification.userInfo?["id"] as? UUID else { return }
            MainActor.assumeIsolated {
                guard let self else { return }
                if let data = self.library.data(for: id), self.assets[id] != nil {
                    self.pixelData[id] = data
                    self.imageCache.removeObject(forKey: id as NSUUID)
                    self.dirtyAssetIDs.insert(id)
                }
                if let libraryAsset = self.library.assets[id], self.assets[id] != nil {
                    self.assets[id] = libraryAsset
                    self.isDirty = true
                }
                self.objectWillChange.send()
            }
        }
    }

    func asset(for id: UUID) -> SpriteAsset? {
        assets[id] ?? library.assets[id]
    }

    private func includeAssetInProjectIfNeeded(_ asset: SpriteAsset) {
        guard assets[asset.id] == nil else { return }
        assets[asset.id] = asset
        if let data = library.data(for: asset.id) { pixelData[asset.id] = data }
    }

    private func paletteForEditing() -> ColorPalette? {
        pendingPalette ?? project.palette
    }

    private func generatedPalette() -> ColorPalette {
        var uniqueColors = Set<PaletteRGBColor>()
        let usedSpriteIDs = Set(project.sheets.flatMap { $0.placements.map(\.spriteID) })
        for spriteID in usedSpriteIDs {
            guard let data = pixelData[spriteID] ?? library.data(for: spriteID),
                  let buffer = try? PixelBuffer(pngData: data) else { continue }
            for y in 0..<buffer.height {
                for x in 0..<buffer.width {
                    let pixel = buffer[x, y]
                    guard pixel.a == PixelBuffer.opaqueAlpha else { continue }
                    uniqueColors.insert(PaletteRGBColor(r: pixel.r, g: pixel.g, b: pixel.b))
                }
            }
        }
        return ColorPalette(colors: uniqueColors
            .sorted { $0.hex < $1.hex }
            .map { PaletteColor(source: $0) })
            .orderedBySimilarity()
    }

    private func firstAvailablePosition(for sprite: SpriteAsset, in sheet: SpriteSheet) -> PlacementPosition? {
        let xPositions = gridPositions(maximum: max(0, sheet.canvasWidth - sprite.width), step: sheet.gridSize)
        let yPositions = gridPositions(maximum: max(0, sheet.canvasHeight - sprite.height), step: sheet.gridSize)
        for y in yPositions {
            for x in xPositions {
                let position = PlacementPosition(x: x, y: y)
                if canPlace(asset: sprite, at: position, in: sheet, excluding: nil) { return position }
            }
        }
        return nil
    }

    private func canPlace(
        asset sprite: SpriteAsset,
        at position: PlacementPosition,
        in sheet: SpriteSheet,
        excluding placementID: UUID?
    ) -> Bool {
        guard position.x >= 0, position.y >= 0,
              position.x + sprite.width <= sheet.canvasWidth,
              position.y + sprite.height <= sheet.canvasHeight else { return false }
        let candidate = CGRect(x: position.x, y: position.y, width: sprite.width, height: sprite.height)
        for placement in sheet.placements where placement.id != placementID {
            guard let other = asset(for: placement.spriteID) else { continue }
            let otherRect = CGRect(x: placement.x, y: placement.y, width: other.width, height: other.height)
            if candidate.intersects(otherRect) { return false }
        }
        return true
    }

    private func gridPositions(maximum: Int, step: Int) -> [Int] {
        let stride = max(1, step)
        var values = Array(Swift.stride(from: 0, through: maximum, by: stride))
        if values.last != maximum { values.append(maximum) }
        return values
    }

    private func snap(_ value: Int, to step: Int, maximum: Int) -> Int {
        let stride = max(1, step)
        let snapped = Int((Double(value) / Double(stride)).rounded()) * stride
        return min(max(0, snapped), maximum)
    }

    private func safeName(_ name: String) -> String {
        let value = name
            .replacingOccurrences(of: "[^A-Za-z0-9_-]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return value.isEmpty ? "spritesheet" : value
    }
}
