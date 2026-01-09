import SwiftUI
import UIKit

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
        // MARK: - Brand Colors (Teal-based)

        /// Primary brand color - use for buttons, progress indicators, interactive elements
        static let primary = Color(hex: "00A693") ?? Color(.systemMint)

        /// App accent color - darker mint for good contrast with white text
        static let accent = Color(hex: "00A693") ?? Color(.systemMint)

        // Semantic status colors
        static let success = Color.green
        static let warning = Color.orange
        static let danger = Color.red
        static let info = Color.blue

        // Energy balance colors
        static let expenditure = Color.orange
        static let targets = Color.yellow

        // MARK: - Background Colors (Apple HIG)

        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let tertiaryBackground = Color(.tertiarySystemBackground)

        // Grouped background colors - for cards on grouped backgrounds
        // Use groupedBackground for page, cardBackground for cards on that page
        static let groupedBackground = Color(.systemGroupedBackground)
        static let cardBackground = Color(.secondarySystemGroupedBackground)

        /// Card background when selected - tinted with accent for selection state
        static let cardBackgroundSelected = accent.opacity(0.15)

        /// Inactive/disabled state color - for progress indicators, deselected items
        static let inactive = Color(.systemGray4)

        // MARK: - Brand Gradient

        /// Brand gradient for decorative elements (icons, illustrations)
        static let primaryGradient = LinearGradient(
            colors: [Color(.systemTeal), Color(hex: "0A8F8F") ?? Color(.systemTeal)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing)

        // Macro colors - Apple semantic system colors
        // Avoiding red/green which indicate over/under elsewhere
        static let calories = Color(.systemTeal)
        static let protein = Color(.systemIndigo)
        static let fat = Color(.systemYellow)
        static let carbs = Color(.systemOrange)
    }

    // MARK: - Spacing

    enum Spacing {
        /// Top padding for custom page headers (space below status bar)
        static let pageHeaderTopPadding: CGFloat = 8
        /// Horizontal padding for custom page headers
        static let pageHeaderHorizontalPadding: CGFloat = 19
    }

    // MARK: - Header Button Style

    enum HeaderButton {
        /// Icon size for header action buttons
        static let iconSize: CGFloat = 14
        /// Icon weight for header action buttons
        static let iconWeight: Font.Weight = .semibold
        /// Icon color for header action buttons
        static let iconColor = Color(.secondaryLabel)
        /// Button size (circular background)
        static let buttonSize: CGFloat = 28
        /// Button background color (visible in both light and dark modes)
        static let backgroundColor = Color(.tertiarySystemBackground)
        /// Shadow radius (diffuse)
        static let shadowRadius: CGFloat = 4
        /// Shadow y offset
        static let shadowOffsetY: CGFloat = 2
        /// Shadow opacity
        static let shadowOpacity: CGFloat = 0.12
    }

    enum Typography {
        static let largeTitle = Font.system(.largeTitle, design: .default)
        static let headline = Font.system(.headline, design: .default).bold()
        static let body = Font.system(.body, design: .default)
        static let caption = Font.system(.caption, design: .default)

        /// Page title font size for main navigation views (smaller than default largeTitle)
        static let pageTitleSize: CGFloat = 24

        /// Configure navigation bar appearance with smaller page titles
        /// Call this in init() of main views that use large title display mode
        static func configurePageTitleAppearance() {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            // Hide inline title when scrolled
            appearance.titleTextAttributes = [.foregroundColor: UIColor.clear]
            // Smaller large title
            appearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: pageTitleSize, weight: .bold),
            ]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    enum ButtonStyles {
        static let primary = PrimaryButtonStyle()
        static let secondary = SecondaryButtonStyle()
    }
}
