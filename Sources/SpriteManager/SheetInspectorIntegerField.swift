import SwiftUI

struct SheetInspectorIntegerField: View {
    let title: String
    @Binding var value: Int

    init(_ title: String, value: Binding<Int>) {
        self.title = title
        _value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppPalette.muted)
            IntegerField(title, value: $value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
