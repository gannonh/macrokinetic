//
//  MonthlyStatsView+ComputedProperties.swift
//  JabTracker
//
//  Extension containing computed properties for MonthlyStatsView
//

import SwiftUI

// MARK: - Computed Properties

extension MonthlyStatsView {
    var monthlyPeriodText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let start = formatter.string(from: self.statistics.periodStart)
        let end = formatter.string(from: self.statistics.periodEnd)

        return "\(start) - \(end)"
    }

    var streakDisplayText: String {
        let days = self.statistics.currentStreak
        return "\(days) day\(days == 1 ? "" : "s")"
    }

    var adherenceColor: Color {
        let rate = self.statistics.adherenceRate
        if rate >= 0.9 { return .green }
        if rate >= 0.7 { return .orange }
        return .red
    }

    var summaryGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
        ]
    }

    var detailedGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
        ]
    }

    // MARK: - Schedule Adherence Computed Properties

    var scheduleBreakdownText: String {
        let taken = self.statistics.takenScheduledDoses
        let scheduled = self.statistics.totalScheduledDoses
        let missed = self.statistics.missedScheduledDoses
        let skipped = self.statistics.skippedScheduledDoses

        return "\(taken) taken / \(scheduled) scheduled (\(missed) missed, \(skipped) skipped)"
    }

    var scheduleBreakdownAccessibilityLabel: String {
        let taken = self.statistics.takenScheduledDoses
        let scheduled = self.statistics.totalScheduledDoses
        let missed = self.statistics.missedScheduledDoses
        let skipped = self.statistics.skippedScheduledDoses

        return
            "\(taken) doses taken out of \(scheduled) scheduled. \(missed) doses missed, \(skipped) doses skipped."
    }

    var scheduleAdherenceColor: Color {
        let rate = self.statistics.scheduleAdherenceRate
        if rate >= 0.9 { return .green }
        if rate >= 0.7 { return .orange }
        return .red
    }
}
