import SwiftUI

struct ProfileField<Content: View>: View {
    let label: String
    let value: String?
    let content: Content

    init(label: String, value: String? = nil, @ViewBuilder content: () -> Content) {
        self.label = label
        self.value = value
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(self.label)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            if let value {
                Text(value)
                    .font(DesignTokens.Typography.body)
            } else {
                self.content
            }
        }
    }
}
