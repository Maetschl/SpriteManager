import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel: WelcomeViewModel

    init(controller: WelcomeWindowController, recentProjects: RecentProjectsStore) {
        _viewModel = StateObject(wrappedValue: WelcomeViewModel(controller: controller, recentProjects: recentProjects))
    }

    var body: some View {
        GeometryReader { proxy in
            let widths = WelcomeLayoutMetrics.panelWidths(for: proxy.size)
            HStack(spacing: 0) {
                WelcomeLeftPanel(viewModel: viewModel, height: proxy.size.height)
                    .frame(width: widths.left)
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)
                WelcomeRecentProjectsPanel(viewModel: viewModel)
                    .frame(width: widths.right)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(.dark)
        .alert("Unable to Open Project", isPresented: Binding(
            get: { viewModel.controller.errorMessage != nil },
            set: { if !$0 { viewModel.controller.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.controller.errorMessage = nil }
        } message: {
            Text(viewModel.controller.errorMessage ?? "The project could not be opened.")
        }
    }
}
