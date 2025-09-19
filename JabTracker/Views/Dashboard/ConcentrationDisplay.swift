//
//  ConcentrationDisplay.swift
//  JabTracker
//
//  Helper component for displaying concentration values with consistent formatting
//  Provides visual indicators and accessibility support for concentration levels
//

import SwiftUI

/// Reusable component for displaying concentration values with consistent formatting
struct ConcentrationDisplay: View {
    let concentration: Double
    let isCurrentLevel: Bool

    // Concentration level thresholds for visual indicators
    private let lowThreshold: Double = 0.1
    private let highThreshold: Double = 3.0

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            // Concentration value
            Text(formattedConcentration)
                .font(isCurrentLevel ? DesignTokens.Typography.headline : DesignTokens.Typography.body)
                .fontWeight(isCurrentLevel ? .bold : .medium)
                .foregroundColor(concentrationColor)

            // Units
            Text("units")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("concentration-unit")

            // Visual level indicator (only for current level)
            if isCurrentLevel {
                levelIndicator
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityValue(accessibilityValue)
    }

    // MARK: - Computed Properties

    private var formattedConcentration: String {
        String(format: "%.2f", concentration)
    }

    private var concentrationColor: Color {
        if concentration <= lowThreshold {
            return DesignTokens.Colors.warning
        } else if concentration >= highThreshold {
            return DesignTokens.Colors.danger
        } else {
            return .primary
        }
    }

    private var levelIndicator: some View {
        Group {
            if concentration <= lowThreshold {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(DesignTokens.Colors.warning)
                    .font(.caption)
                    .accessibilityHidden(true)
            } else if concentration >= highThreshold {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(DesignTokens.Colors.danger)
                    .font(.caption)
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignTokens.Colors.success)
                    .font(.caption)
                    .accessibilityHidden(true)
            }
        }
    }

    private var accessibilityDescription: String {
        let levelType = isCurrentLevel ? "Current" : "Projected"
        return "\(levelType) concentration level"
    }

    private var accessibilityValue: String {
        let formattedValue = "\(formattedConcentration) units"
        let levelDescription: String

        if concentration <= lowThreshold {
            levelDescription = "Low level"
        } else if concentration >= highThreshold {
            levelDescription = "High level"
        } else {
            levelDescription = "Normal level"
        }

        return "\(formattedValue), \(levelDescription)"
    }
}

// MARK: - Concentration Level Extensions

extension ConcentrationDisplay {
    /// Creates a display for zero concentration with appropriate styling
    static func empty(isCurrentLevel: Bool = true) -> ConcentrationDisplay {
        ConcentrationDisplay(concentration: 0.0, isCurrentLevel: isCurrentLevel)
    }

    /// Creates a display for a specific concentration level
    static func level(_ concentration: Double, isCurrentLevel: Bool = false) -> ConcentrationDisplay {
        ConcentrationDisplay(concentration: concentration, isCurrentLevel: isCurrentLevel)
    }
}

// MARK: - Preview

#Preview("Concentration Display Examples") {
    VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Level Examples")
                .font(DesignTokens.Typography.headline)

            VStack(alignment: .leading, spacing: 8) {
                ConcentrationDisplay(concentration: 0.05, isCurrentLevel: true) // Low
                ConcentrationDisplay(concentration: 1.25, isCurrentLevel: true) // Normal
                ConcentrationDisplay(concentration: 4.75, isCurrentLevel: true) // High
                ConcentrationDisplay(concentration: 0.0, isCurrentLevel: true)  // Zero
            }
        }

        Divider()

        VStack(alignment: .leading, spacing: 16) {
            Text("Projected Level Examples")
                .font(DesignTokens.Typography.headline)

            VStack(alignment: .leading, spacing: 8) {
                ConcentrationDisplay(concentration: 0.85, isCurrentLevel: false)
                ConcentrationDisplay(concentration: 2.1, isCurrentLevel: false)
                ConcentrationDisplay(concentration: 0.3, isCurrentLevel: false)
            }
        }

        Divider()

        VStack(alignment: .leading, spacing: 16) {
            Text("Helper Constructors")
                .font(DesignTokens.Typography.headline)

            VStack(alignment: .leading, spacing: 8) {
                ConcentrationDisplay.empty(isCurrentLevel: true)
                ConcentrationDisplay.level(1.75, isCurrentLevel: true)
                ConcentrationDisplay.level(0.45, isCurrentLevel: false)
            }
        }
    }
    .padding()
}
