import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct IntegerField: View {
    let title: String
    @Binding var value: Int

    init(_ title: String, value: Binding<Int>) {
        self.title = title
        _value = value
    }

    var body: some View {
        TextField(title, value: $value, format: .number)
    }
}

