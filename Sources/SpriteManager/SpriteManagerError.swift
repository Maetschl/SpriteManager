import Foundation

enum SpriteManagerError: LocalizedError, Equatable {
    case invalidProject
    case unsupportedSchema(Int)
    case missingAsset(UUID)
    case invalidPNG(String)
    case placementOutsideCanvas(String)
    case missingFile(String)

    var errorDescription: String? {
        switch self {
        case .invalidProject: "The selected file is not a valid SpriteManager project."
        case let .unsupportedSchema(version): "Unsupported project schema version: \(version)."
        case let .missingAsset(id): "The project is missing sprite \(id.uuidString)."
        case let .invalidPNG(name): "The file is not a readable PNG: \(name)."
        case let .placementOutsideCanvas(name): "Sprite placement is outside the canvas: \(name)."
        case let .missingFile(file): "Missing file: \(file)."
        }
    }
}

