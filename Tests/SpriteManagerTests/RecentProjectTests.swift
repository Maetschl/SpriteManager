import Foundation
import Testing
@testable import SpriteManager

@Suite("RecentProject")
struct RecentProjectTests {
    @Test func abbreviatesHomeDirectory() {
        let home = URL(fileURLWithPath: "/Users/test")
        #expect(RecentProject.abbreviatedPath("/Users/test/Documents", homeDirectory: home) == "~/Documents")
    }
}

