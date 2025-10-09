//
//  ConcentrationLabel.swift
//  JabTracker
//
//  Label component for displaying peak/trough concentration values
//

import SwiftUI

/// Label displaying concentration level with color coding
///
/// Used in ConcentrationCurvePreview to show peak and trough levels.
/// Color codes concentrations for quick visual reference.
struct ConcentrationLabel: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)

                Text(String(format: "%.2f", value))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .accessibilityIdentifier("concentration-label-\(title.lowercased())")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(String(format: "%.2f", value))")
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 32) {
        ConcentrationLabel(
            title: "Peak",
            value: 125.50,
            color: .green
        )

        ConcentrationLabel(
            title: "Trough",
            value: 45.25,
            color: .orange
        )
    }
    .padding()
}
