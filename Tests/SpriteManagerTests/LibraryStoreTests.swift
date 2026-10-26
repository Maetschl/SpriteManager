import Foundation
import Testing
@testable import SpriteManager

@Suite("LibraryStore")
@MainActor
struct LibraryStoreTests {
    @Test func registersAndReadsAssetData() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LibraryStore(rootURL: root)
        let data = Data([1, 2, 3])
        let asset = SpriteAsset(name: "Test", width: 1, height: 1, contentHash: PixelData.sha256(data), originalFileName: "test.png")
        try store.register(asset, data: data)
        #expect(store.data(for: asset.id) == data)
        #expect(store.assets[asset.id]?.name == "Test")
    }
}

