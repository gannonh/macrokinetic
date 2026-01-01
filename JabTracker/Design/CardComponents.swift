import SwiftUI

// MARK: - Card Style Modifier

/// View modifier that applies consistent card styling across the app.
/// Uses Apple's grouped content colors - no shadows.
/// Light mode: white cards on grouped gray background
/// Dark mode: elevated dark cards on darker background
struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignTokens.Colors.cardBackground)
            )
    }
}

extension View {
    /// Applies card styling with system background color and corner radius.
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}

// MARK: - Design Card Container

struct DesignCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            self.content
        }
        .padding(20)
        .cardStyle()
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
