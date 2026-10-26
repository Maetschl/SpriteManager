import SwiftUI

struct SpriteSidebarSectionLabel: View {
    let title: String
    let count: Int
    let icon: String

    var body: some View {
        Label {
            HStack(spacing: 6) {
                Text(title)
                Text("\(count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(AppPalette.muted)
            }
        } icon: {
            Image(systemName: icon)
        }
    }
}
