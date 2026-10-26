import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct RecentProjectRow: View {
    let project: RecentProject

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: project.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                Text(project.location)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
    }
}

