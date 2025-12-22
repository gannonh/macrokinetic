//
//  ShortcutButton.swift
//  JabTracker
//
//  A circular icon button for the shortcuts sheet top row.
//

import SwiftUI

/// A circular icon button used in the top row of the shortcuts sheet.
/// Shows an SF Symbol icon with a label below.
struct ShortcutButton: View {
    /// SF Symbol name for the icon
    let icon: String

    /// Label displayed below the button
    let label: String

    /// Whether the button is enabled (functional) or disabled (coming soon)
    let isEnabled: Bool

    /// Action to perform when tapped
    let action: () -> Void

    /// Computed accessibility identifier based on label
    var accessibilityIdentifierValue: String {
        "shortcut-button-\(label.lowercased())"
    }

    private let buttonSize: CGFloat = 60

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isEnabled ? Color(.tertiarySystemFill) : Color(.quaternarySystemFill))
                        .frame(width: buttonSize, height: buttonSize)

                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isEnabled ? .primary : .secondary)
                }

                Text(label)
                    .font(.caption)
                    .foregroundColor(isEnabled ? .primary : .secondary)
            }
        }
        .disabled(!isEnabled)
        .accessibilityIdentifier(accessibilityIdentifierValue)
        .accessibilityLabel(label)
        .accessibilityHint(isEnabled ? "Double tap to open \(label)" : "\(label) coming soon")
    }
}

// MARK: - Preview

#Preview("Enabled Buttons") {
    HStack(spacing: 20) {
        ShortcutButton(
            icon: "magnifyingglass",
            label: "Search",
            isEnabled: true,
            action: {}
        )
        ShortcutButton(
            icon: "syringe.fill",
            label: "Shots",
            isEnabled: true,
            action: {}
        )
    }
    .padding()
}

#Preview("Disabled Buttons") {
    HStack(spacing: 20) {
        ShortcutButton(
            icon: "barcode.viewfinder",
            label: "Barcode",
            isEnabled: false,
            action: {}
        )
        ShortcutButton(
            icon: "camera.fill",
            label: "Photo",
            isEnabled: false,
            action: {}
        )
    }
    .padding()
}

#Preview("All Top Row") {
    HStack(spacing: 16) {
        ShortcutButton(icon: "magnifyingglass", label: "Search", isEnabled: true, action: {})
        ShortcutButton(icon: "barcode.viewfinder", label: "Barcode", isEnabled: false, action: {})
        ShortcutButton(icon: "camera.fill", label: "Photo", isEnabled: false, action: {})
        ShortcutButton(icon: "syringe.fill", label: "Shots", isEnabled: true, action: {})
    }
    .padding()
}
