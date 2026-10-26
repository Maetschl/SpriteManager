import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct InspectorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(AppPalette.muted)
            content()
        }
    }
}

