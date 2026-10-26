import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct PlacementDragPreview: Equatable {
    var placementID: UUID
    var x: Int
    var y: Int
    var isValid: Bool
}

