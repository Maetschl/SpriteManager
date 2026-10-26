import Foundation
import AppKit

@MainActor
final class LibraryStore: ObservableObject {
    static let shared = LibraryStore()

    @Published private(set) var assets: [UUID: SpriteAsset] = [:]

    private let fileManager = FileManager.default
    private let rootURL: URL
    private let indexURL: URL

    init(rootURL: URL? = nil) {
        let support = rootURL ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SpriteManager", isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
        self.rootURL = support
        self.indexURL = support.appendingPathComponent("library.json")
        load()
    }

    func data(for id: UUID) -> Data? {
        let url = rootURL.appendingPathComponent("assets", isDirectory: true).appendingPathComponent("\(id.uuidString).png")
        return try? Data(contentsOf: url)
    }

    @discardableResult
    func register(_ asset: SpriteAsset, data: Data, preferIncoming: Bool = true) throws -> SpriteAsset {
        let assetsDirectory = rootURL.appendingPathComponent("assets", isDirectory: true)
        try fileManager.createDirectory(at: assetsDirectory, withIntermediateDirectories: true)
        let destination = assetsDirectory.appendingPathComponent("\(asset.id.uuidString).png")
        if preferIncoming || !fileManager.fileExists(atPath: destination.path) {
            try data.write(to: destination, options: .atomic)
        }
        assets[asset.id] = asset
        try saveIndex()
        NotificationCenter.default.post(name: .spriteAssetDidChange, object: self, userInfo: ["id": asset.id])
        return asset
    }

    func updateMetadata(_ asset: SpriteAsset) throws {
        assets[asset.id] = asset
        try saveIndex()
        NotificationCenter.default.post(name: .spriteAssetDidChange, object: self, userInfo: ["id": asset.id])
    }

    func updateData(id: UUID, data: Data) throws {
        guard var asset = assets[id] else { throw SpriteManagerError.missingAsset(id) }
        let destination = rootURL.appendingPathComponent("assets", isDirectory: true).appendingPathComponent("\(id.uuidString).png")
        try data.write(to: destination, options: .atomic)
        asset.contentHash = PixelData.sha256(data)
        assets[id] = asset
        try saveIndex()
        NotificationCenter.default.post(name: .spriteAssetDidChange, object: self, userInfo: ["id": id])
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let index = try? JSONDecoder().decode(LibraryIndex.self, from: data),
              index.schemaVersion == LibraryIndex.currentSchemaVersion else { return }
        assets = Dictionary(uniqueKeysWithValues: index.assets.map { ($0.id, $0) })
    }

    private func saveIndex() throws {
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        let index = LibraryIndex(assets: assets.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending })
        let data = try JSONEncoder.pretty.encode(index)
        try data.write(to: indexURL, options: .atomic)
    }
}
