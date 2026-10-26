import Foundation
import Testing
@testable import SpriteManager

@Suite("RecentProjectsStore")
@MainActor
struct RecentProjectsStoreTests {
    @Test func filtersAndDeduplicatesSupportedExistingURLs() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let pixproj = root.appendingPathComponent("One.pixproj")
        let legacy = root.appendingPathComponent("Two.spritesproject")
        let ignored = root.appendingPathComponent("Ignored.txt")
        try FileManager.default.createDirectory(at: pixproj, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        try Data().write(to: ignored)
        #expect(RecentProjectsStore.validRecentURLs([pixproj, ignored, legacy, pixproj]) == [pixproj, legacy])
    }
}

