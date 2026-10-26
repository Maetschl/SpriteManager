import Foundation

enum PixelData {
    static func sha256(_ data: Data) -> String {
        // A stable, dependency-free content identity for the local library.
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in data {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return String(format: "%016llx", hash)
    }
}
