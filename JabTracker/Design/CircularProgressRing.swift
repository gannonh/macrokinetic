//
//  CircularProgressRing.swift
//  JabTracker
//
//  A reusable circular progress ring component for macro visualization.
//

import SwiftUI

/// A circular progress indicator showing a percentage with a label below.
/// Used for displaying macro impact on daily targets.
struct CircularProgressRing: View {
    /// Progress value from 0.0 to 1.0 (can exceed 1.0 for overflow display)
    let progress: Double

    /// Label displayed below the ring (e.g., "Calories", "Protein")
    let label: String

    /// Text displayed in the center of the ring (e.g., "45%")
    let valueText: String

    /// Color for the progress fill
    let color: Color

    /// Width of the ring stroke (default: 8)
    var lineWidth: CGFloat = 8

    /// Diameter of the ring (default: 60)
    var size: CGFloat = 60

    /// Whether to show the label below the ring (default: true)
    var showLabel: Bool = true

    /// Computed accessibility identifier based on label
    var accessibilityIdentifierValue: String {
        "progress-ring-\(label.lowercased())"
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Background track
                Circle()
                    .stroke(
                        color.opacity(0.2),
                        lineWidth: lineWidth
                    )

                // Progress fill
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)

                // Overflow indicator (subtle outer ring when > 100%)
                if progress > 1.0 {
                    Circle()
                        .stroke(
                            color.opacity(0.4),
                            lineWidth: 2
                        )
                        .scaleEffect(1.15)
                }

                // Center text
                Text(valueText)
                    .font(.system(size: size * 0.25, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .frame(width: size, height: size)

            // Label below (optional)
            if showLabel {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityIdentifier(accessibilityIdentifierValue)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(valueText)")
        .accessibilityValue(String(format: "%.0f percent", progress * 100))
    }
}

// MARK: - Preview

#Preview("Standard Macros") {
    HStack(spacing: 20) {
        CircularProgressRing(
            progress: 0.47,
            label: "Calories",
            valueText: "47%",
            color: .orange
        )
        CircularProgressRing(
            progress: 0.26,
            label: "Protein",
            valueText: "26%",
            color: .blue
        )
        CircularProgressRing(
            progress: 0.76,
            label: "Fat",
            valueText: "76%",
            color: .purple
        )
        CircularProgressRing(
            progress: 0.42,
            label: "Carbs",
            valueText: "42%",
            color: .green
        )
    }
    .padding()
}

#Preview("Overflow") {
    CircularProgressRing(
        progress: 1.5,
        label: "Calories",
        valueText: "150%",
        color: .orange
    )
    .padding()
}

#Preview("Custom Size") {
    CircularProgressRing(
        progress: 0.65,
        label: "Protein",
        valueText: "65%",
        color: .blue,
        lineWidth: 12,
        size: 100
    )
    .padding()
}
