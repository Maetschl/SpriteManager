import UniformTypeIdentifiers

extension UTType {
    /// The current on-disk project format. The property name is retained so
    /// existing call sites continue to compile while new projects use `.pixproj`.
    static let spritesProject = UTType(exportedAs: "com.spritesmanager.pixproj", conformingTo: .package)

    /// The V1 extension remains readable so existing projects can be opened.
    static let legacySpritesProject = UTType(importedAs: "com.spritesmanager.project", conformingTo: .package)
}

