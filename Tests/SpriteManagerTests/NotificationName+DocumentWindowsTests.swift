import Foundation
import Testing
@testable import SpriteManager

@Suite("NotificationName+DocumentWindows")
struct NotificationNameDocumentWindowsExtensionTests {
    @Test func exposesDocumentWindowChangeNotification() {
        #expect(Notification.Name.spriteManagerDocumentWindowsDidChange.rawValue == "SpriteManagerDocumentWindowsDidChange")
    }
}
