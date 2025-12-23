//
//  MonthlyStatsView.swift
//  JabTracker
//
//  SwiftUI view for displaying monthly dose statistics including adherence rate,
//  streak information, injection site distribution, and dose summaries
//

import SwiftUI

/// Displays comprehensive monthly statistics for dose tracking
struct MonthlyStatsView: View {
    // MARK: - Properties

    /// Monthly statistics to display
    let statistics: AdherenceStatistics

    /// Whether to show detailed breakdown
    let showDetailedView: Bool

    // MARK: - Initialization

    init(statistics: AdherenceStatistics, showDetailedView: Bool = false) {
        self.statistics = statistics
        self.showDetailedView = showDetailedView
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            self.monthlyStatsHeader

            if self.showDetailedView {
                // Detailed statistics view
                self.detailedStatsView
            } else {
                // Summary statistics view
                self.summaryStatsView
            }
        }
        .padding()
        .cardStyle(cornerRadius: 12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Monthly Statistics")
    }

    // MARK: - Header

    @ViewBuilder
    private var monthlyStatsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Monthly Summary")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(self.monthlyPeriodText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Adherence rate badge
            self.adherenceRateBadge
        }
    }

    // MARK: - Summary View

    @ViewBuilder
    private var summaryStatsView: some View {
        LazyVGrid(columns: self.summaryGridColumns, spacing: 12) {
            StatisticCard(
                title: "Total Doses",
                value: "\(self.statistics.totalDoses)",
                icon: "syringe.fill",
                color: .blue)

            StatisticCard(
                title: "Current Streak",
                value: self.streakDisplayText,
                icon: "flame.fill",
                color: self.statistics.isCurrentStreakActive ? .orange : .gray)

            if self.statistics.averageDose > 0 {
                StatisticCard(
                    title: "Avg Dose",
                    value: String(format: "%.1f mg", self.statistics.averageDose),
                    icon: "drop.fill",
                    color: .green)
            }

            if let mostUsedSite = statistics.mostUsedSite {
                StatisticCard(
                    title: "Primary Site",
                    value: mostUsedSite,
                    icon: "location.fill",
                    color: .purple)
            }
        }
    }

    // MARK: - Detailed View

    @ViewBuilder
    private var detailedStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Adherence section
            self.adherenceSection

            // MARK: - Stream C: Schedule Adherence Display
            // Schedule adherence section (Issue #178)
            if self.statistics.totalScheduledDoses > 0 {
                self.scheduleAdherenceSection
            }

            // Dose information section
            self.doseInformationSection

            // Streak information section
            self.streakSection

            // Injection sites section
            if !self.statistics.siteDistribution.isEmpty {
                self.injectionSitesSection
            }
        }
    }

    // MARK: - Note
    // Detailed sections, computed properties, and helper views are in extensions:
    // - MonthlyStatsView+DetailedSections.swift
    // - MonthlyStatsView+ComputedProperties.swift
    // - MonthlyStatsView+Helpers.swift
}

// MARK: - Supporting Views

struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: self.icon)
                    .foregroundColor(self.color)
                    .font(.system(size: 14, weight: .medium))

                Spacer()
            }

            Text(self.value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(self.title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(self.title): \(self.value)")
    }
}

struct DetailStatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(self.label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(self.value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(self.label): \(self.value)")
    }
}

// MARK: - Preview

#Preview("Summary View") {
    let sampleStats = AdherenceStatistics(
        totalDoses: 12,
        skippedDoses: 1,
        scheduledDoses: 13,
        averageDose: 1.2,
        totalMedicationAmount: 14.4,
        doseRange: (min: 1.0, max: 1.5),
        currentStreak: 7,
        longestStreak: 10,
        isCurrentStreakActive: true,
        siteDistribution: ["Thigh": 6, "Abdomen": 4, "Arm": 2],
        periodStart: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
        periodEnd: Date())

    return MonthlyStatsView(statistics: sampleStats)
        .padding()
}

#Preview("Detailed View") {
    let sampleStats = AdherenceStatistics(
        totalDoses: 12,
        skippedDoses: 1,
        scheduledDoses: 13,
        averageDose: 1.2,
        totalMedicationAmount: 14.4,
        doseRange: (min: 1.0, max: 1.5),
        currentStreak: 7,
        longestStreak: 10,
        isCurrentStreakActive: true,
        siteDistribution: ["Thigh": 6, "Abdomen": 4, "Arm": 2],
        periodStart: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date(),
        periodEnd: Date(),
        // Stream C: Schedule adherence preview data
        totalScheduledDoses: 13,
        takenScheduledDoses: 11,
        missedScheduledDoses: 1,
        skippedScheduledDoses: 1)

    return MonthlyStatsView(statistics: sampleStats, showDetailedView: true)
        .padding()
}
