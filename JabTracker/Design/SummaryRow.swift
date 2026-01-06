//
//  SummaryRow.swift
//  JabTracker
//
//  Reusable summary row component for wizard and onboarding confirmation steps.
//

import SwiftUI

/// A horizontal row displaying a label and value pair.
///
/// Used in confirmation/summary steps of wizards and onboarding flows
/// to display selected options.
struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                .fill(Color.gray.opacity(0.05))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    VStack(spacing: 8) {
        SummaryRow(label: "Goal Type", value: "Weight Loss")
        SummaryRow(label: "Target Weight", value: "165 lbs")
        SummaryRow(label: "Weekly Rate", value: "1.0 lb/week")
    }
    .padding()
}
