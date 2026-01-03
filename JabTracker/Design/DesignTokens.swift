import SwiftUI

enum DesignTokens {
    // MARK: - Corner Radii

    enum CornerRadius {
        /// Tiny elements: pills, small badges, progress bars (4pt)
        static let small: CGFloat = 4
        /// Small elements: buttons, inputs, chips, tags (8pt)
        static let medium: CGFloat = 8
        /// Standard cards: list items, content cards (10pt - matches iOS insetGrouped list)
        static let card: CGFloat = 10
        /// Large cards: main containers, sheets, modals (16pt)
        static let large: CGFloat = 16
    }

    // MARK: - Colors

    enum Colors {
        static let primary = Color.primaryBlue
        static let primaryLight = Color(hex: "8b9ff4") ?? .blue
        static let primaryDark = Color(hex: "4c5fbf") ?? .blue
        static let secondary = Color.primaryPurple
        static let success = Color.green
        static let warning = Color.orange
        static let danger = Color.red
        static let info = Color.blue

        // Background colors following Apple HIG
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)

        // Grouped background colors - for cards on grouped backgrounds
        // Use groupedBackground for page, cardBackground for cards on that page
        static let groupedBackground = Color(.systemGroupedBackground)
        static let cardBackground = Color(.secondarySystemGroupedBackground)

        static let primaryGradient = LinearGradient(
            colors: [Color.primaryBlue, Color.primaryPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)

        // Macro colors - Apple semantic system colors
        // Avoiding red/green which indicate over/under elsewhere
        static let calories = Color(.systemTeal)
        static let protein = Color(.systemIndigo)
        static let fat = Color(.systemYellow)
        static let carbs = Color(.systemOrange)
    }

    enum Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded)
        static let headline = Font.system(.headline, design: .default).bold()
        static let body = Font.system(.body, design: .default)
        static let caption = Font.system(.caption, design: .default)
    }

    enum ButtonStyles {
        static let primary = PrimaryButtonStyle()
        static let secondary = SecondaryButtonStyle()
    }
}
