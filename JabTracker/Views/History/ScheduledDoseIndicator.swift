//
//  ScheduledDoseIndicator.swift
//  JabTracker
//
//  Individual dose status indicator for calendar display
//

import SwiftUI

/// Visual indicator for dose status on calendar days
///
/// Provides color-coded visual feedback for different dose states:
/// - Scheduled (blue outline): Not yet taken
/// - Logged (blue filled): Successfully taken
/// - Missed (red): Past due without being taken
/// - Skipped (gray): Intentionally skipped
/// - Rescheduled (orange): Moved to different time
struct ScheduledDoseIndicator: View {
    let status: DoseEventType
    let size: IndicatorSize

    var body: some View {
        Circle()
            .strokeBorder(self.strokeColor, lineWidth: self.strokeWidth)
            .background(
                Circle()
                    .fill(self.fillColor)
            )
            .frame(width: self.size.dimension, height: self.size.dimension)
            .accessibilityLabel(self.accessibilityLabel)
    }

    // MARK: - Computed Properties

    private var strokeColor: Color {
        switch self.status {
        case .scheduled:
            return .blue
        case .taken:
            return .blue
        case .missed:
            return .red
        case .skipped:
            return .orange
        }
    }

    private var fillColor: Color {
        switch self.status {
        case .scheduled:
            return .clear  // Outline only
        case .taken:
            return .blue  // Filled
        case .missed:
            return .red  // Filled
        case .skipped:
            return .orange  // Filled
        }
    }

    private var strokeWidth: CGFloat {
        switch self.status {
        case .scheduled:
            return 1.5  // Thicker outline for visibility
        case .taken, .missed, .skipped:
            return 0  // No stroke when filled
        }
    }

    private var accessibilityLabel: String {
        switch self.status {
        case .scheduled:
            return "Scheduled dose"
        case .taken:
            return "Logged dose"
        case .missed:
            return "Missed dose"
        case .skipped:
            return "Skipped dose"
        }
    }

    // MARK: - Supporting Types

    enum IndicatorSize {
        case small  // 4pt - for multiple indicators
        case medium  // 6pt - for single indicator
        case large  // 8pt - for emphasis

        var dimension: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
}

#Preview("All Status States") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            VStack {
                ScheduledDoseIndicator(status: .scheduled, size: .medium)
                Text("Scheduled")
                    .font(.caption)
            }

            VStack {
                ScheduledDoseIndicator(status: .taken, size: .medium)
                Text("Logged")
                    .font(.caption)
            }

            VStack {
                ScheduledDoseIndicator(status: .missed, size: .medium)
                Text("Missed")
                    .font(.caption)
            }

            VStack {
                ScheduledDoseIndicator(status: .skipped, size: .medium)
                Text("Skipped")
                    .font(.caption)
            }
        }

        Divider()

        HStack(spacing: 12) {
            VStack {
                ScheduledDoseIndicator(status: .scheduled, size: .small)
                Text("Small")
                    .font(.caption)
            }

            VStack {
                ScheduledDoseIndicator(status: .scheduled, size: .medium)
                Text("Medium")
                    .font(.caption)
            }

            VStack {
                ScheduledDoseIndicator(status: .scheduled, size: .large)
                Text("Large")
                    .font(.caption)
            }
        }
    }
    .padding()
}
