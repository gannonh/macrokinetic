import SwiftUI

struct DesignCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    VStack(spacing: 16) {
        DesignCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Title")
                    .font(DesignTokens.Typography.headline)
                Text("This is sample content inside a design card component.")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.secondary)
            }
        }

        DesignCard {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Card with Icon")
                    .font(DesignTokens.Typography.body)
                Spacer()
            }
        }
    }
    .padding()
}
