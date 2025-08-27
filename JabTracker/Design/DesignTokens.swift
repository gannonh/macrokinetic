import SwiftUI

enum DesignTokens {
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

        static let primaryGradient = LinearGradient(
            colors: [Color.primaryBlue, Color.primaryPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)
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
