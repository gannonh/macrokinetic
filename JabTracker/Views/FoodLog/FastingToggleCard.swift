//
//  FastingToggleCard.swift
//  JabTracker
//
//  Card component for marking a day as a fasting day.
//  Only shown when no food entries exist for the selected day.
//

import SwiftUI

/// Card component for marking a day as a fasting day
/// Allows users to indicate intentional zero-calorie days for accurate tracking
struct FastingToggleCard: View {
    /// Binding to the fasting state for the current day
    @Binding var isFasting: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: isFasting ? "moon.zzz.fill" : "moon.zzz")
                .font(.title3)
                .foregroundColor(isFasting ? .orange : .secondary)
                .frame(width: 32)

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text("Fasting Day")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(isFasting ? fastingEnabledText : fastingDisabledText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $isFasting)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .padding()
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("fasting-toggle-card")
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to toggle fasting status")
    }

    // MARK: - Text Content

    private var fastingEnabledText: String {
        "Counts as 0 kcal in calculations"
    }

    private var fastingDisabledText: String {
        "Mark as intentional fasting day"
    }

    private var accessibilityLabel: String {
        if isFasting {
            return "Fasting day enabled. Day counts as zero calories in calculations."
        } else {
            return "Fasting day disabled. Toggle on to mark as intentional fasting."
        }
    }
}

// MARK: - Preview

#Preview("Not Fasting") {
    FastingToggleCard(isFasting: .constant(false))
        .padding()
}

#Preview("Fasting") {
    FastingToggleCard(isFasting: .constant(true))
        .padding()
}
