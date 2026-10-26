import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class RecentProjectsStore: ObservableObject {
    static let supportedExtensions: Set<String> = ["pixproj", "spritesproject"]

    @Published private(set) var projects: [RecentProject] = []
    private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: .spriteManagerDocumentWindowsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
        refresh()
    }

    func refresh() {
        projects = Self.validRecentURLs(NSDocumentController.shared.recentDocumentURLs).map(RecentProject.init(url:))
    }

    static func validRecentURLs(_ urls: [URL], fileManager: FileManager = .default) -> [URL] {
        var seen = Set<URL>()
        return urls.filter { url in
            let ext = url.pathExtension.lowercased()
            guard supportedExtensions.contains(ext), fileManager.fileExists(atPath: url.path) else {
                return false
            }
            let normalized = url.standardizedFileURL
            guard seen.insert(normalized).inserted else {
                return false
            }
            return true
        }
    }
}

