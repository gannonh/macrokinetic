//
//  ShortcutRowButton.swift
//  JabTracker
//
//  A list row button for the shortcuts sheet secondary options.
//

import SwiftUI

/// A list row button used in the shortcuts sheet for secondary actions.
/// Shows an icon, label, and chevron in a horizontal layout.
struct ShortcutRowButton: View {
    /// SF Symbol name for the icon
    let icon: String

    /// Label displayed next to the icon
    let label: String

    /// Whether the button is enabled (functional) or disabled (coming soon)
    let isEnabled: Bool

    /// Action to perform when tapped
    let action: () -> Void

    /// Computed accessibility identifier based on label
    var accessibilityIdentifierValue: String {
        "shortcut-row-\(label.lowercased())"
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isEnabled ? .primary : .secondary)
                    .frame(width: 28)

                Text(label)
                    .font(.body)
                    .foregroundColor(isEnabled ? .primary : .secondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
        .accessibilityIdentifier(accessibilityIdentifierValue)
        .accessibilityLabel(label)
        .accessibilityHint(isEnabled ? "Double tap to open \(label)" : "\(label) coming soon")
    }
}

// MARK: - Preview

#Preview("All Row Buttons") {
    VStack(spacing: 0) {
        ShortcutRowButton(
            icon: "scalemass.fill",
            label: "Weight",
            isEnabled: false,
            action: {}
        )
        Divider()
            .padding(.leading, 56)
        ShortcutRowButton(
            icon: "plus.circle.fill",
            label: "Quick Add",
            isEnabled: false,
            action: {}
        )
        Divider()
            .padding(.leading, 56)
        ShortcutRowButton(
            icon: "chart.bar.fill",
            label: "Metrics",
            isEnabled: false,
            action: {}
        )
        Divider()
            .padding(.leading, 56)
        ShortcutRowButton(
            icon: "star.fill",
            label: "Your Foods",
            isEnabled: false,
            action: {}
        )
        Divider()
            .padding(.leading, 56)
        ShortcutRowButton(
            icon: "book.fill",
            label: "Recipes",
            isEnabled: false,
            action: {}
        )
        Divider()
            .padding(.leading, 56)
        ShortcutRowButton(
            icon: "calendar.badge.plus",
            label: "Edit Days",
            isEnabled: false,
            action: {}
        )
    }
    .background(Color(.secondarySystemBackground))
    .cornerRadius(12)
    .padding()
}

#Preview("Enabled Row Button") {
    ShortcutRowButton(
        icon: "scalemass.fill",
        label: "Weight",
        isEnabled: true,
        action: {}
    )
    .background(Color(.secondarySystemBackground))
    .cornerRadius(12)
    .padding()
}
