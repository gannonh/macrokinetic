//
//  SelectionCard.swift
//  JabTracker
//
//  Reusable selection card component for wizard and onboarding flows.
//

import SwiftUI

/// A tappable card for selecting options in wizard and onboarding flows.
///
/// Displays a title, description, optional icon, optional detail text,
/// and selection state. Used for single-selection lists.
struct SelectionCard: View {
    let title: String
    let description: String
    var icon: String?
    var detail: String?
    let isSelected: Bool
    var showWarning: Bool = false
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                if let icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? DesignTokens.Colors.accent : .secondary)
                        .frame(width: 32)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if showWarning {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundColor(DesignTokens.Colors.accent)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.accent)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                    .fill(isSelected ? DesignTokens.Colors.accent.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large)
                    .stroke(isSelected ? DesignTokens.Colors.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(description)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

#Preview {
    VStack(spacing: 12) {
        SelectionCard(
            title: "Weight Loss",
            description: "Focus on reducing body weight through calorie deficit",
            icon: "arrow.down.circle",
            isSelected: true
        ) {}

        SelectionCard(
            title: "Maintenance",
            description: "Maintain current weight and body composition",
            icon: "equal.circle",
            isSelected: false
        ) {}

        SelectionCard(
            title: "Low Calorie",
            description: "Lower minimum of 1,025 calories",
            icon: "exclamationmark.triangle",
            detail: "1025 cal/day minimum",
            isSelected: false,
            showWarning: true
        ) {}
    }
    .padding()
}
