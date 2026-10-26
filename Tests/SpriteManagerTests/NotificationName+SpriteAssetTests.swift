import Foundation
import Testing
@testable import SpriteManager

@Suite("NotificationName+SpriteAsset")
struct NotificationNameSpriteAssetExtensionTests {
    @Test func exposesSpriteChangeNotification() {
        #expect(Notification.Name.spriteAssetDidChange.rawValue == "SpriteManager.spriteAssetDidChange")
    }
}
