import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct AppPalette {
    static let window = Color(nsColor: .windowBackgroundColor)
    static let canvas = Color(nsColor: .underPageBackgroundColor)
    static let panel = Color(nsColor: .controlBackgroundColor)
    static let muted = Color.secondary.opacity(0.72)
}

