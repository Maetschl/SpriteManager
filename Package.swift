// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SpriteManager",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SpriteManager", targets: ["SpriteManager"])
    ],
    targets: [
        .executableTarget(name: "SpriteManager", path: "Sources/SpriteManager"),
        .testTarget(name: "SpriteManagerTests", dependencies: ["SpriteManager"], path: "Tests/SpriteManagerTests")
    ],
    swiftLanguageModes: [.v6]
)
