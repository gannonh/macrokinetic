//
//  SchedulePatternCard.swift
//  JabTracker
//
//  Individual schedule pattern selection card component
//

import SwiftUI

/// Card view for a single schedule pattern option
///
/// Displays pattern information with selection state and handles tap interaction.
/// Provides visual feedback for selected state with blue border and checkmark.
struct SchedulePatternCard: View {
    let pattern: SchedulePatternType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pattern.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(pattern.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pattern-card-\(pattern.rawValue)")
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pattern.displayName)
        .accessibilityHint(pattern.description)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - SchedulePatternType Extensions

extension SchedulePatternType {
    /// Human-readable display name
    var displayName: String {
        switch self {
        case .weekly:
            return "Standard Weekly"
        case .splitDose:
            return "Split Dose (Twice Weekly)"
        case .custom:
            return "Custom Pattern"
        }
    }

    /// Pattern description for user understanding
    var description: String {
        switch self {
        case .weekly:
            return "One dose per week, same day and time"
        case .splitDose:
            return "Divide weekly dose into two smaller doses"
        case .custom:
            return "Create your own custom schedule (Coming Soon)"
        }
    }
}

// MARK: - Preview

#Preview("Unselected") {
    VStack(spacing: 16) {
        SchedulePatternCard(
            pattern: .weekly,
            isSelected: false,
            onSelect: {}
        )

        SchedulePatternCard(
            pattern: .splitDose,
            isSelected: false,
            onSelect: {}
        )

        SchedulePatternCard(
            pattern: .custom,
            isSelected: false,
            onSelect: {}
        )
    }
    .padding()
}

#Preview("Selected") {
    VStack(spacing: 16) {
        SchedulePatternCard(
            pattern: .weekly,
            isSelected: true,
            onSelect: {}
        )

        SchedulePatternCard(
            pattern: .splitDose,
            isSelected: false,
            onSelect: {}
        )
    }
    .padding()
}
