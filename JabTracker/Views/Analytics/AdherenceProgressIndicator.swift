//
//  AdherenceProgressIndicator.swift
//  JabTracker
//
//  Progress indicator showing adherence goals and current achievement levels.
//

import SwiftUI

/// Progress indicator displaying adherence goals with visual progress representation
struct AdherenceProgressIndicator: View {

    // MARK: - Properties

    /// Current adherence rate (0.0 to 1.0)
    let currentAdherence: Double

    /// Target adherence rate goal (0.0 to 1.0)
    let targetAdherence: Double

    /// Time period label for context
    let periodLabel: String

    /// Accessibility identifier for testing
    let accessibilityIdentifier: String

    // MARK: - Computed Properties

    /// Progress percentage towards goal (0.0 to 1.0+)
    var progressPercentage: Double {
        guard targetAdherence > 0 else { return 0 }
        return currentAdherence / targetAdherence
    }

    /// Whether the adherence goal has been met or exceeded
    var goalAchieved: Bool {
        progressPercentage >= 1.0
    }

    /// Color representing current adherence level
    var adherenceColor: Color {
        if goalAchieved {
            return DesignTokens.Colors.success
        } else if progressPercentage >= 0.8 {
            return DesignTokens.Colors.warning
        } else {
            return DesignTokens.Colors.danger
        }
    }

    /// Formatted current adherence percentage string
    var currentAdherenceText: String {
        "\(Int(currentAdherence * 100))%"
    }

    /// Formatted target adherence percentage string
    var targetAdherenceText: String {
        "\(Int(targetAdherence * 100))%"
    }

    /// Progress status message
    var statusMessage: String {
        if goalAchieved {
            return "Goal achieved!"
        } else {
            let remaining = targetAdherence - currentAdherence
            return "\(Int(remaining * 100))% to goal"
        }
    }

    // MARK: - Initialization

    init(
        currentAdherence: Double,
        targetAdherence: Double = 0.8,  // Default 80% target
        periodLabel: String = "This month",
        accessibilityIdentifier: String = "adherence-progress-indicator"
    ) {
        self.currentAdherence = max(0.0, min(1.0, currentAdherence))
        self.targetAdherence = max(0.0, min(1.0, targetAdherence))
        self.periodLabel = periodLabel
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Adherence Goal")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if goalAchieved {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignTokens.Colors.success)
                            .font(.title3)
                    }
                }

                Text(periodLabel)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
            }

            // Progress Visualization
            VStack(alignment: .leading, spacing: 12) {
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignTokens.Colors.tertiaryBackground)
                            .frame(height: 16)

                        // Progress Fill
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [adherenceColor, adherenceColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * min(progressPercentage, 1.0),
                                height: 16
                            )
                            .animation(.easeInOut(duration: 0.6), value: progressPercentage)

                        // Goal Line Marker
                        if progressPercentage < 1.0 {
                            Rectangle()
                                .fill(adherenceColor)
                                .frame(width: 2, height: 20)
                                .offset(x: geometry.size.width - 1)
                                .opacity(0.6)
                        }
                    }
                }
                .frame(height: 16)

                // Progress Labels
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)

                        Text(currentAdherenceText)
                            .font(DesignTokens.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(adherenceColor)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Target")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)

                        Text(targetAdherenceText)
                            .font(DesignTokens.Typography.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                }

                // Status Message
                HStack(spacing: 8) {
                    Circle()
                        .fill(adherenceColor)
                        .frame(width: 8, height: 8)

                    Text(statusMessage)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.secondaryBackground)
        )
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Goal achieved
        AdherenceProgressIndicator(
            currentAdherence: 0.92,
            targetAdherence: 0.8,
            periodLabel: "This month"
        )

        // Progress towards goal
        AdherenceProgressIndicator(
            currentAdherence: 0.65,
            targetAdherence: 0.8,
            periodLabel: "This week"
        )

        // Low adherence
        AdherenceProgressIndicator(
            currentAdherence: 0.45,
            targetAdherence: 0.8,
            periodLabel: "Last 30 days"
        )
    }
    .padding()
}
