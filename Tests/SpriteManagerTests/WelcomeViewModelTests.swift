import Testing
@testable import SpriteManager

@Suite("WelcomeViewModel")
@MainActor
struct WelcomeViewModelTests {
    @Test func exposesBundleVersionFallback() {
        let controller = WelcomeWindowController.shared
        let viewModel = WelcomeViewModel(controller: controller, recentProjects: controller.recentProjects)
        #expect(!viewModel.version.isEmpty)
    }
}

