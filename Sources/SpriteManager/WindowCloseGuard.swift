import SwiftUI
import AppKit
import UniformTypeIdentifiers

@MainActor
struct WindowCloseGuard: NSViewRepresentable {
    @ObservedObject var document: ProjectDocument

    func makeCoordinator() -> WindowCloseCoordinator {
        WindowCloseCoordinator(document: document)
    }

    func makeNSView(context: Context) -> WindowCloseGuardView {
        let view = WindowCloseGuardView()
        view.onWindowChange = { [weak coordinator = context.coordinator] window in
            coordinator?.attach(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: WindowCloseGuardView, context: Context) {
        context.coordinator.document = document
        if let window = nsView.window {
            context.coordinator.attach(to: window)
        }
    }

}

