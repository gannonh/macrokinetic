import SwiftUI

// MARK: - Card Style Modifier

/// View modifier that applies consistent card styling across the app.
/// Uses Apple's grouped content colors - no shadows.
/// Light mode: white cards on grouped gray background
/// Dark mode: elevated dark cards on darker background
struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = DesignTokens.CornerRadius.card

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
    /// Default uses `DesignTokens.CornerRadius.card` (12pt).
    func cardStyle(cornerRadius: CGFloat = DesignTokens.CornerRadius.card) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}

// MARK: - Card List Styling

/// View modifier for List containers that want card-based styling with full corner control.
/// Removes List's default backgrounds and separators, allowing cards to define their own appearance.
struct CardListStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DesignTokens.Colors.groupedBackground)
    }
}

/// View modifier for list rows containing cards.
/// Clears row backgrounds, hides separators, and applies consistent padding.
struct CardListRow: ViewModifier {
    var horizontalPadding: CGFloat = 16
    var verticalPadding: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

extension View {
    /// Applies card-friendly styling to a List container.
    /// Use with `.plain` list style for full control over card corners.
    func cardListStyle() -> some View {
        modifier(CardListStyle())
    }

    /// Applies card-friendly styling to a list row.
    /// Clears backgrounds, hides separators, and adds consistent padding.
    func cardListRow(horizontalPadding: CGFloat = 16, verticalPadding: CGFloat = 4) -> some View {
        modifier(CardListRow(horizontalPadding: horizontalPadding, verticalPadding: verticalPadding))
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
