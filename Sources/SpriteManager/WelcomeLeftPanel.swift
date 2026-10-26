import AppKit
import SwiftUI

struct WelcomeLeftPanel: View {
    @ObservedObject var viewModel: WelcomeViewModel
    let height: CGFloat

    var body: some View {
        let contentScale = min(1, height / WelcomeLayoutMetrics.contentHeight)
        ZStack(alignment: .topLeading) {
            WindowDragArea()
                .background(Color(nsColor: .windowBackgroundColor))
            Button(action: viewModel.close) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color.white.opacity(0.14), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(WelcomeLayoutMetrics.closeButtonInset)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                VStack(spacing: WelcomeLayoutMetrics.brandSpacing) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.34))
                            .frame(width: 210 * contentScale, height: 210 * contentScale)
                            .blur(radius: 46 * contentScale)
                            .blendMode(.screen)
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.blue.opacity(0.28), Color.blue.opacity(0.08), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 150 * contentScale
                                )
                            )
                            .frame(width: 300 * contentScale, height: 300 * contentScale)
                            .blur(radius: 6 * contentScale)
                            .blendMode(.screen)
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 220 * contentScale, height: 220 * contentScale)
                            .shadow(color: .blue.opacity(0.65), radius: 28 * contentScale, x: 0, y: 18 * contentScale)
                    }
                    .frame(height: 300 * contentScale)
                    VStack(spacing: 3) {
                        Text("SpriteManager")
                            .font(.system(size: max(26, 42 * contentScale), weight: .bold, design: .rounded))
                        Text("Version \(viewModel.version)")
                            .font(.system(size: max(12, 16 * contentScale), weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                VStack(spacing: WelcomeLayoutMetrics.actionSpacing) {
                    WelcomeActionButton(
                        title: "Create New Project…", systemImage: "plus.square", scale: contentScale,
                        action: viewModel.createProject
                    )
                    WelcomeActionButton(
                        title: "Open Existing Project…", systemImage: "folder", scale: contentScale,
                        action: viewModel.openExistingProject
                    )
                }
                .padding(.horizontal, WelcomeLayoutMetrics.actionHorizontalPadding * contentScale)
                .padding(.bottom, WelcomeLayoutMetrics.actionBottomPadding * contentScale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(true)
        }
    }
}
