//
//  MissedDosePatternView.swift
//  JabTracker
//
//  View for visualizing missed dose patterns and generating insights.
//

import SwiftUI

/// View displaying missed dose patterns with insights and recommendations
struct MissedDosePatternView: View {

    // MARK: - Properties

    /// Array of missed dose patterns to analyze and display
    let missedDoses: [MissedDosePattern]

    /// Visualization style for the pattern display
    let style: MissedDoseVisualizationStyle

    /// Accessibility identifier for testing
    let accessibilityIdentifier: String

    // MARK: - Computed Properties

    /// Day of the week with the most missed doses
    var worstDay: String? {
        let doseCounts = Dictionary(grouping: missedDoses) { $0.dayOfWeek }
            .mapValues { patterns in
                patterns.reduce(0) { $0 + $1.missedCount }
            }

        guard let maxEntry = doseCounts.max(by: { $0.value < $1.value }),
            maxEntry.value > 0
        else {
            return nil
        }

        return maxEntry.key
    }

    /// Total number of missed doses across all patterns
    var totalMissedDoses: Int {
        missedDoses.reduce(0) { $0 + $1.missedCount }
    }

    /// Whether there's a significant pattern worth highlighting
    var hasSignificantPattern: Bool {
        guard let worstDay = worstDay else { return false }

        let worstDayCount =
            missedDoses
            .filter { $0.dayOfWeek == worstDay }
            .reduce(0) { $0 + $1.missedCount }

        let totalOtherDays = totalMissedDoses - worstDayCount

        // Consider significant if worst day has more than 50% of missed doses
        return worstDayCount > totalOtherDays
    }

    /// Generated insight text based on pattern analysis
    var patternInsight: String {
        guard hasSignificantPattern, let worstDay = worstDay else {
            return "No significant pattern detected in missed doses"
        }

        return "Most missed doses occur on \(worstDay). Consider setting additional reminders for this day."
    }

    // MARK: - Initialization

    init(
        missedDoses: [MissedDosePattern],
        style: MissedDoseVisualizationStyle = .heatmap,
        accessibilityIdentifier: String = "missed-dose-pattern-view"
    ) {
        self.missedDoses = missedDoses
        self.style = style
        self.accessibilityIdentifier = accessibilityIdentifier
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Missed Dose Patterns")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(.primary)

                if totalMissedDoses > 0 {
                    HStack(spacing: 12) {
                        Label("\(totalMissedDoses)", systemImage: "exclamationmark.triangle.fill")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.warning)

                        if let worstDay = worstDay {
                            Text("Worst day: \(worstDay)")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            // Pattern Visualization
            if missedDoses.isEmpty || totalMissedDoses == 0 {
                EmptyPatternView()
            } else {
                switch style {
                case .heatmap:
                    HeatmapPatternView(patterns: groupedPatterns)
                case .barChart:
                    BarChartPatternView(patterns: groupedPatterns)
                case .calendar:
                    CalendarPatternView(patterns: missedDoses)
                }
            }

            // Insights
            if hasSignificantPattern {
                InsightCard(insight: patternInsight)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.secondaryBackground)
        )
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityLabel("Missed dose pattern analysis")
        .accessibilityValue("Total missed doses: \(totalMissedDoses)")
    }

    // MARK: - Private Properties

    private var groupedPatterns: [String: Int] {
        Dictionary(grouping: missedDoses) { $0.dayOfWeek }
            .mapValues { patterns in
                patterns.reduce(0) { $0 + $1.missedCount }
            }
    }
}

// MARK: - Supporting Views

private struct EmptyPatternView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(DesignTokens.Colors.success)

            Text("No missed doses")
                .font(DesignTokens.Typography.body)
                .foregroundColor(.primary)

            Text("Keep up the great adherence!")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
    }
}

private struct HeatmapPatternView: View {
    let patterns: [String: Int]

    private let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Pattern")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(daysOfWeek, id: \.self) { day in
                    let count = patterns[day] ?? 0
                    let maxCount = patterns.values.max() ?? 1
                    let intensity = maxCount > 0 ? Double(count) / Double(maxCount) : 0

                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(heatmapColor(intensity: intensity))
                            .frame(width: 30, height: 30)

                        Text(day.prefix(1))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func heatmapColor(intensity: Double) -> Color {
        if intensity == 0 {
            return DesignTokens.Colors.tertiaryBackground
        }

        let red = DesignTokens.Colors.danger
        return red.opacity(0.3 + (intensity * 0.7))
    }
}

private struct BarChartPatternView: View {
    let patterns: [String: Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Missed Doses by Day")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 4) {
                ForEach(patterns.sorted(by: { $0.value > $1.value }), id: \.key) { day, count in
                    HStack {
                        Text(day)
                            .font(DesignTokens.Typography.caption)
                            .frame(width: 80, alignment: .leading)

                        Rectangle()
                            .fill(DesignTokens.Colors.danger)
                            .frame(width: CGFloat(count) * 20, height: 16)
                            .opacity(0.7)

                        Text("\(count)")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)

                        Spacer()
                    }
                }
            }
        }
    }
}

private struct CalendarPatternView: View {
    let patterns: [MissedDosePattern]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Missed Doses")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(patterns.sorted(by: { $0.date > $1.date }).prefix(14)) { pattern in
                    VStack(spacing: 2) {
                        Circle()
                            .fill(pattern.missedCount > 0 ? DesignTokens.Colors.danger : DesignTokens.Colors.success)
                            .frame(width: 20, height: 20)
                            .opacity(0.7)

                        Text("\(Calendar.current.component(.day, from: pattern.date))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

private struct InsightCard: View {
    let insight: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(DesignTokens.Colors.warning)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Insight")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)

                Text(insight)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignTokens.Colors.warning.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Pattern with data
        MissedDosePatternView(
            missedDoses: [
                MissedDosePattern(date: Date(), dayOfWeek: "Monday", missedCount: 3),
                MissedDosePattern(date: Date().addingTimeInterval(-24 * 3600), dayOfWeek: "Tuesday", missedCount: 1),
                MissedDosePattern(date: Date().addingTimeInterval(-48 * 3600), dayOfWeek: "Monday", missedCount: 2),
            ]
        )

        // Empty pattern
        MissedDosePatternView(missedDoses: [])
    }
    .padding()
}
