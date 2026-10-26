import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowDragAreaView {
        WindowDragAreaView()
    }

    func updateNSView(_ nsView: WindowDragAreaView, context: Context) {}
}

