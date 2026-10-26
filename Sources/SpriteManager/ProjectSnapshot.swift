import Foundation
import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ProjectSnapshot: Sendable {
    let manifest: ProjectManifest
    let dataByAssetID: [UUID: Data]
}
