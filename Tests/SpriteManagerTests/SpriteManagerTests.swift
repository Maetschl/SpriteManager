import AppKit
import Foundation
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import SpriteManager

@Suite("SpriteManager")
@MainActor
struct SpriteManagerTests {
    @Test func testWelcomeLayoutPreservesRequestedRatios() {
        let size = WelcomeLayoutMetrics.windowSize(for: CGSize(width: 2000, height: 1400))
        #expect(abs(size.height - WelcomeLayoutMetrics.referenceBase) <= 0.001)
        #expect(abs(size.width - size.height * 8.0 / 5.0) <= 0.001)

        let panels = WelcomeLayoutMetrics.panelWidths(for: size)
        #expect(abs(panels.left - size.height) <= 0.001)
        #expect(abs(panels.right - size.height * 3.0 / 5.0) <= 0.001)
    }

    @Test func testWelcomeLayoutScalesDownToAvailableScreen() {
        let size = WelcomeLayoutMetrics.windowSize(for: CGSize(width: 1000, height: 600))
        #expect(size.width <= 1000.001)
        #expect(size.height <= 600.001)
        #expect(abs(size.width / size.height - 8.0 / 5.0) <= 0.001)
    }

    @Test func testRecentProjectsFilterSupportedExistingURLs() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let first = root.appendingPathComponent("First.pixproj")
        let legacy = root.appendingPathComponent("Legacy.spritesproject")
        let ignored = root.appendingPathComponent("Ignored.txt")
        try FileManager.default.createDirectory(at: first, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        try Data().write(to: ignored)

        let urls = RecentProjectsStore.validRecentURLs([first, ignored, legacy, first, root.appendingPathComponent("Missing.pixproj")])
        #expect(urls == [first, legacy])
    }

    @Test func testRecentProjectAbbreviatesHomePath() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        #expect(RecentProject.abbreviatedPath(home.appendingPathComponent("Documents").path, homeDirectory: home) == "~/Documents")
    }

    @Test func testProjectDocumentUsesPixprojAndReadsLegacyProjects() {
        #expect(ProjectDocument.writableContentTypes.map(\.identifier) == ["com.spritesmanager.pixproj"])
        #expect(Set(ProjectDocument.readableContentTypes.map(\.identifier)) == Set(["com.spritesmanager.pixproj", "com.spritesmanager.project"]))
    }

    @Test func testShiftKeepsDimensionsAndClipsPixels() throws {
        let buffer = try PixelBuffer(width: 3, height: 2, pixels: [
            255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255,
            255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 0, 255
        ])

        let shifted = buffer.shifted(dx: 1, dy: 0)
        #expect(shifted.width == 3)
        #expect(shifted.height == 2)
        #expect(shifted[0, 0].a == 0)
        #expect(shifted[1, 0].r == 255)
        #expect(shifted[2, 0].g == 255)
    }

    @Test func testOutlineOnlyFillsTransparentNeighbors() throws {
        let buffer = try PixelBuffer(width: 3, height: 3, pixels: [
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 255, 0, 0, 255, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        ])
        let outlined = buffer.withInternalOutline(color: RGBAColor(r: 1, g: 1, b: 1, a: 1))
        #expect(outlined[1, 1].a == 255)
        #expect(outlined[0, 1].a == 255)
        #expect(outlined[1, 0].a == 255)
        #expect(outlined[0, 0].a == 255)
    }

    @Test func testProjectRoundTripThroughPackage() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let project = SpriteProject(name: "Test")
        let document = ProjectDocument(project: project, library: LibraryStore(rootURL: root.appendingPathComponent("library")))
        let data = try PixelBuffer(width: 1, height: 1, pixels: [255, 0, 0, 255]).pngData()
        document.importPNG(data: data, originalName: "red.png")
        let snapshot = try document.snapshot(contentType: .spritesProject)
        let wrapper = try document.fileWrapper(snapshot: snapshot)
        let manifestData = try #require(wrapper.fileWrappers?["project.json"]?.regularFileContents)
        let manifest = try JSONDecoder().decode(ProjectManifest.self, from: manifestData)
        #expect(manifest.project.name == "Test")
        #expect(manifest.assets.count == 1)
        #expect(wrapper.fileWrappers?["assets"]?.fileWrappers?.first?.value.regularFileContents != nil)
    }

    @Test func testNewProjectDoesNotPackageUnusedGlobalLibraryAssets() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let library = LibraryStore(rootURL: root.appendingPathComponent("library"))
        let data = try PixelBuffer(width: 2, height: 2, pixels: [
            255, 0, 0, 255, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 255, 0, 255
        ]).pngData()
        let asset = SpriteAsset(name: "global", width: 2, height: 2, contentHash: PixelData.sha256(data), originalFileName: "global.png")
        try library.register(asset, data: data)

        let document = ProjectDocument(library: library)
        #expect(document.assets.isEmpty)
        #expect(document.availableAssets.count == 1)
        #expect(document.projectAssetCount == 0)

        document.createSheet()
        document.addSprite(asset.id, to: try #require(document.selectedSheetID))
        let snapshot = try document.snapshot(contentType: .spritesProject)
        #expect(snapshot.manifest.assets.map(\.id) == [asset.id])
        #expect(snapshot.dataByAssetID[asset.id] == data)
    }

    @Test func testDuplicateSheetKeepsSourceIDsButCreatesIndependentPlacements() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let library = LibraryStore(rootURL: root.appendingPathComponent("library"))
        let data = try PixelBuffer(width: 1, height: 1, pixels: [255, 255, 255, 255]).pngData()
        let document = ProjectDocument(library: library)
        document.importPNG(data: data, originalName: "pixel.png")
        document.createSheet()
        let sheetID = try #require(document.selectedSheetID)
        document.addSprite(try #require(document.selectedSpriteID), to: sheetID)
        let sourcePlacement = try #require(document.selectedSheet?.placements.first)

        document.duplicateSelectedSheet()
        let copy = try #require(document.selectedSheet)
        #expect(document.project.sheets.count == 2)
        #expect(copy.placements.first?.spriteID == sourcePlacement.spriteID)
        #expect(copy.placements.first?.id != sourcePlacement.id)

        document.movePlacement(sheetID: copy.id, placementID: try #require(copy.placements.first?.id), x: 20, y: 20)
        #expect(document.project.sheets.first?.placements.first?.x == 0)
        #expect(document.selectedSheet?.placements.first?.x == 16)
    }

    @Test func testAddingSpritesUsesGridAndAvoidsOverlap() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let document = ProjectDocument(library: LibraryStore(rootURL: root.appendingPathComponent("library")))
        let data = try PixelBuffer(width: 8, height: 8, pixels: [UInt8](repeating: 255, count: 8 * 8 * 4)).pngData()
        document.importPNG(data: data, originalName: "pixel.png")
        let spriteID = try #require(document.selectedSpriteID)
        document.createSheet()
        let sheetID = try #require(document.selectedSheetID)
        document.addSprite(spriteID, to: sheetID)
        document.addSprite(spriteID, to: sheetID)

        let placements = try #require(document.selectedSheet?.placements)
        #expect(placements.map(\.x) == [0, 16])
        #expect(placements.map(\.y) == [0, 0])
        #expect(!(document.canMovePlacement(sheetID: sheetID, placementID: placements[1].id, x: 0, y: 0)))
    }

    @Test func testExportWritesPNGAndManifest() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let document = ProjectDocument(library: LibraryStore(rootURL: root.appendingPathComponent("library")))
        let data = try PixelBuffer(width: 1, height: 1, pixels: [255, 0, 0, 255]).pngData()
        document.importPNG(data: data, originalName: "red.png")
        document.createSheet()
        let sheet = try #require(document.selectedSheet)
        document.addSprite(try #require(document.selectedSpriteID), to: sheet.id)
        let updatedSheet = try #require(document.project.sheets.first)
        try document.export(sheet: updatedSheet, to: root)

        let pngURL = root.appendingPathComponent("Spritesheet-1.png")
        let manifestURL = root.appendingPathComponent("Spritesheet-1.json")
        #expect(FileManager.default.fileExists(atPath: pngURL.path))
        #expect(FileManager.default.fileExists(atPath: manifestURL.path))
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as? [String: Any]
        #expect(json?["width"] as? Int == updatedSheet.canvasWidth)
        #expect((json?["sprites"] as? [[String: Any]])?.count == 1)
    }

    @Test func testSharedLibraryEditsReachAnotherProject() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let library = LibraryStore(rootURL: root.appendingPathComponent("library"))
        let originalData = try PixelBuffer(width: 2, height: 1, pixels: [
            255, 0, 0, 255, 0, 255, 0, 255
        ]).pngData()
        let projectA = ProjectDocument(library: library)
        let projectB = ProjectDocument(library: library)
        projectA.importPNG(data: originalData, originalName: "shared.png")
        let sharedID = try #require(projectA.selectedSpriteID)

        projectB.includeAssetInProject(sharedID)
        projectA.shiftAsset(sharedID, dx: 1, dy: 0)
        let updatedData = try #require(projectB.pixelData[sharedID])
        let updatedBuffer = try PixelBuffer(pngData: updatedData)
        #expect(updatedBuffer[0, 0].a == 0)
        #expect(updatedBuffer[1, 0].r == 255)
        #expect(projectB.assets[sharedID]?.contentHash == PixelData.sha256(updatedData))
    }

    @Test func testImportUndoAndRedoRestoreProjectMembership() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let document = ProjectDocument(library: LibraryStore(rootURL: root.appendingPathComponent("library")))
        let data = try PixelBuffer(width: 1, height: 1, pixels: [255, 255, 255, 255]).pngData()
        document.importPNG(data: data, originalName: "pixel.png")
        #expect(document.projectAssetCount == 1)
        document.undo()
        #expect(document.projectAssetCount == 0)
        document.redo()
        #expect(document.projectAssetCount == 1)
    }

    @Test func testProjectNameEditingSavesLiveAndUndoesAsOneOperation() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let document = ProjectDocument(library: LibraryStore(rootURL: root.appendingPathComponent("library")))
        document.updateProjectNameLive("P")
        document.updateProjectNameLive("Pixel Pack")
        #expect(document.project.name == "Pixel Pack")
        document.finishProjectNameEdit()
        document.undo()
        #expect(document.project.name == "Untitled Project")
        document.redo()
        #expect(document.project.name == "Pixel Pack")
    }

    @Test func testProjectOpenDetectsUUIDContentConflictsBeforeReplacingLibrary() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let sourceLibrary = LibraryStore(rootURL: root.appendingPathComponent("source-library"))
        let sourceDocument = ProjectDocument(library: sourceLibrary)
        let incomingData = try PixelBuffer(width: 1, height: 1, pixels: [255, 0, 0, 255]).pngData()
        sourceDocument.importPNG(data: incomingData, originalName: "shared.png")
        let sharedID = try #require(sourceDocument.selectedSpriteID)
        let snapshot = try sourceDocument.snapshot(contentType: .spritesProject)
        let wrapper = try sourceDocument.fileWrapper(snapshot: snapshot)

        let localLibrary = LibraryStore(rootURL: root.appendingPathComponent("local-library"))
        let localData = try PixelBuffer(width: 1, height: 1, pixels: [0, 0, 255, 255]).pngData()
        let incomingAsset = try #require(sourceDocument.assets[sharedID])
        let localAsset = SpriteAsset(
            id: sharedID,
            name: incomingAsset.name,
            width: 1,
            height: 1,
            contentHash: PixelData.sha256(localData),
            originalFileName: incomingAsset.originalFileName
        )
        try localLibrary.register(localAsset, data: localData)

        let opened = try ProjectDocument(packageWrapper: wrapper, library: localLibrary)
        #expect(opened.conflictAssetIDs == [sharedID])
        #expect(localLibrary.data(for: sharedID) == localData)
        #expect(opened.pixelData[sharedID] == incomingData)

        opened.resolveNextConflict(useProjectVersion: true)
        #expect(opened.conflictAssetIDs.isEmpty)
        #expect(localLibrary.data(for: sharedID) == incomingData)
    }

    @Test func testTwoProjectsKeepIndependentSpriteMembership() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let library = LibraryStore(rootURL: root.appendingPathComponent("library"))
        let first = ProjectDocument(library: library)
        let second = ProjectDocument(library: library)
        let red = try PixelBuffer(width: 1, height: 1, pixels: [255, 0, 0, 255]).pngData()
        let blue = try PixelBuffer(width: 1, height: 1, pixels: [0, 0, 255, 255]).pngData()
        first.importPNG(data: red, originalName: "red.png")
        second.importPNG(data: blue, originalName: "blue.png")

        let firstSnapshot = try first.snapshot(contentType: .spritesProject)
        let secondSnapshot = try second.snapshot(contentType: .spritesProject)
        #expect(firstSnapshot.manifest.assets.count == 1)
        #expect(secondSnapshot.manifest.assets.count == 1)
        #expect(firstSnapshot.manifest.assets.first?.id != secondSnapshot.manifest.assets.first?.id)
    }

    @Test func testPaletteCollectsUniqueOpaqueSourceColors() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let document = ProjectDocument(library: LibraryStore(rootURL: root.appendingPathComponent("library")))
        let data = try PixelBuffer(width: 2, height: 2, pixels: [
            255, 0, 0, 255, 0, 255, 0, 255,
            255, 0, 0, 0, 0, 0, 255, 128
        ]).pngData()
        document.importPNG(data: data, originalName: "colors.png")
        let spriteID = try #require(document.selectedSpriteID)
        document.createSheet()
        let sheetID = try #require(document.selectedSheetID)
        document.addSprite(spriteID, to: sheetID)

        document.createPalette()

        let colors = try #require(document.effectivePalette?.colors.map(\.source))
        #expect(Set(colors) == [PaletteRGBColor(r: 255, g: 0, b: 0), PaletteRGBColor(r: 0, g: 255, b: 0)])
        #expect(try #require(document.pixelData[spriteID]) == data)
    }

    @Test func testPaletteReplacementIsNonDestructiveAndRendersAcrossSheets() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let document = ProjectDocument(library: LibraryStore(rootURL: root.appendingPathComponent("library")))
        let data = try PixelBuffer(width: 1, height: 1, pixels: [255, 0, 0, 255]).pngData()
        document.importPNG(data: data, originalName: "red.png")
        let spriteID = try #require(document.selectedSpriteID)
        document.createSheet()
        let firstSheetID = try #require(document.selectedSheetID)
        document.addSprite(spriteID, to: firstSheetID)
        document.createSheet()
        let secondSheetID = try #require(document.selectedSheetID)
        document.addSprite(spriteID, to: secondSheetID)
        document.createPalette()

        let red = try #require(document.effectivePalette?.colors.first(where: { $0.source == PaletteRGBColor(r: 255, g: 0, b: 0) }))
        document.updatePaletteColor(red.id, output: PaletteRGBColor(r: 0, g: 255, b: 0))

        let preview = try PixelBuffer(image: try document.renderedSheet(try #require(document.project.sheets.first), mode: .preview))
        let committed = try PixelBuffer(image: try document.renderedSheet(try #require(document.project.sheets.first), mode: .committed))
        #expect(preview[0, 0].g == 255)
        #expect(committed[0, 0].r == 255)
        #expect(try #require(document.pixelData[spriteID]) == data)
        let lastPreview = try PixelBuffer(image: try document.renderedSheet(try #require(document.project.sheets.last), mode: .preview))
        let expectedWidth = try #require(document.project.sheets.last?.canvasWidth)
        #expect(lastPreview.width == expectedWidth)
    }

    @Test func testDeletingPaletteColorCreatesAliasThatFollowsTargetEdits() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let document = ProjectDocument(library: LibraryStore(rootURL: root.appendingPathComponent("library")))
        let data = try PixelBuffer(width: 2, height: 1, pixels: [
            255, 0, 0, 255, 0, 0, 255, 255
        ]).pngData()
        document.importPNG(data: data, originalName: "pair.png")
        let spriteID = try #require(document.selectedSpriteID)
        document.createSheet()
        let sheetID = try #require(document.selectedSheetID)
        document.addSprite(spriteID, to: sheetID)
        document.createPalette()

        let palette = try #require(document.effectivePalette)
        let red = try #require(palette.colors.first(where: { $0.source == PaletteRGBColor(r: 255, g: 0, b: 0) }))
        let blue = try #require(palette.colors.first(where: { $0.source == PaletteRGBColor(r: 0, g: 0, b: 255) }))
        document.deletePaletteColor(red.id)

        var rendered = try PixelBuffer(image: try document.renderedSheet(try #require(document.selectedSheet), mode: .preview))
        #expect(rendered[0, 0].b == 255)
        document.updatePaletteColor(blue.id, output: PaletteRGBColor(r: 0, g: 255, b: 0))
        rendered = try PixelBuffer(image: try document.renderedSheet(try #require(document.selectedSheet), mode: .preview))
        #expect(rendered[0, 0].g == 255)
        #expect(rendered[1, 0].g == 255)
    }

    @Test func testPaletteRoundTripAndExportManifest() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let library = LibraryStore(rootURL: root.appendingPathComponent("library"))
        let document = ProjectDocument(library: library)
        let data = try PixelBuffer(width: 1, height: 1, pixels: [255, 0, 0, 255]).pngData()
        document.importPNG(data: data, originalName: "red.png")
        let spriteID = try #require(document.selectedSpriteID)
        document.createSheet()
        let sheetID = try #require(document.selectedSheetID)
        document.addSprite(spriteID, to: sheetID)
        document.createPalette()
        let red = try #require(document.effectivePalette?.colors.first)
        document.updatePaletteColor(red.id, output: PaletteRGBColor(r: 0, g: 255, b: 0))

        let snapshot = try document.snapshot(contentType: .spritesProject)
        #expect(snapshot.manifest.project.palette?.colors.first?.output == PaletteRGBColor(r: 0, g: 255, b: 0))
        let wrapper = try document.fileWrapper(snapshot: snapshot)
        let reopened = try ProjectDocument(packageWrapper: wrapper, library: LibraryStore(rootURL: root.appendingPathComponent("reopened-library")))
        #expect(reopened.project.palette?.colors.first?.output == PaletteRGBColor(r: 0, g: 255, b: 0))

        try document.export(sheet: try #require(document.project.sheets.first), to: root)
        let manifestURL = root.appendingPathComponent("Spritesheet-1.json")
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: manifestURL)) as? [String: Any]
        #expect(json?["palette"] as? [String: Any] != nil)
    }

    @Test func testLegacyProjectWithoutPaletteMigratesOnOpen() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let projectID = UUID()
        let legacyJSON: [String: Any] = [
            "schemaVersion": 1,
            "project": [
                "schemaVersion": 1,
                "id": projectID.uuidString,
                "name": "Legacy Project",
                "sheets": []
            ],
            "assets": []
        ]
        let manifest = try JSONSerialization.data(withJSONObject: legacyJSON)
        let wrapper = FileWrapper(directoryWithFileWrappers: [
            "project.json": FileWrapper(regularFileWithContents: manifest),
            "assets": FileWrapper(directoryWithFileWrappers: [:])
        ])

        let opened = try ProjectDocument(packageWrapper: wrapper, library: LibraryStore(rootURL: root.appendingPathComponent("library")))
        #expect(opened.project.schemaVersion == SpriteProject.currentSchemaVersion)
        #expect(opened.project.palette == nil)
        #expect(opened.isDirty)
    }

    @Test func testPalettePreviewPixelSelectionAndHighlightUseRenderedColor() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let document = ProjectDocument(library: LibraryStore(rootURL: root.appendingPathComponent("library")))
        let data = try PixelBuffer(width: 2, height: 1, pixels: [
            255, 0, 0, 255, 0, 0, 255, 255
        ]).pngData()
        document.importPNG(data: data, originalName: "pair.png")
        let spriteID = try #require(document.selectedSpriteID)
        document.createSheet()
        let sheetID = try #require(document.selectedSheetID)
        document.addSprite(spriteID, to: sheetID)
        let sheet = try #require(document.selectedSheet)
        document.createPalette()
        let red = try #require(document.effectivePalette?.colors.first(where: { $0.source == PaletteRGBColor(r: 255, g: 0, b: 0) }))

        #expect(document.paletteColorID(atX: 0, y: 0, in: sheet, mode: .preview) == red.id)
        document.updatePaletteColor(red.id, output: PaletteRGBColor(r: 0, g: 255, b: 0))
        #expect(document.paletteColorID(atX: 0, y: 0, in: sheet, mode: .preview) == red.id)
        #expect(document.paletteColorID(atX: 0, y: 0, in: sheet, mode: .committed) == red.id)

        let highlight = try PixelBuffer(image: try document.highlightedSheet(sheet, mode: .preview, colorID: red.id))
        let originalHighlight = try PixelBuffer(image: try document.highlightedSheet(sheet, mode: .committed, colorID: red.id))
        #expect(highlight[0, 0].r == 255)
        #expect(highlight[0, 0].g == 64)
        #expect(highlight[1, 0].a == 0)
        #expect(originalHighlight[0, 0].a == 220)
    }
}


