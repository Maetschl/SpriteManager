import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct RecentProject: Identifiable, Equatable {
    let url: URL
    let name: String
    let location: String
    let icon: NSImage

    var id: URL { url }

    init(url: URL) {
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.location = Self.abbreviatedPath(url.deletingLastPathComponent().path)
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
    }

    static func abbreviatedPath(_ path: String, homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> String {
        let homePath = homeDirectory.standardizedFileURL.path
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        if standardizedPath == homePath {
            return "~"
        }
        if standardizedPath.hasPrefix(homePath + "/") {
            return "~" + standardizedPath.dropFirst(homePath.count)
        }
        return standardizedPath
    }
}

