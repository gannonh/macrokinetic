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
            monthlyStatsHeader

            if showDetailedView {
                // Detailed statistics view
                detailedStatsView
            } else {
                // Summary statistics view
                summaryStatsView
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
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

                Text(monthlyPeriodText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Adherence rate badge
            adherenceRateBadge
        }
    }

    // MARK: - Summary View

    @ViewBuilder
    private var summaryStatsView: some View {
        LazyVGrid(columns: summaryGridColumns, spacing: 12) {
            StatisticCard(
                title: "Total Doses",
                value: "\(statistics.totalDoses)",
                icon: "syringe.fill",
                color: .blue
            )

            StatisticCard(
                title: "Current Streak",
                value: streakDisplayText,
                icon: "flame.fill",
                color: statistics.isCurrentStreakActive ? .orange : .gray
            )

            if statistics.averageDose > 0 {
                StatisticCard(
                    title: "Avg Dose",
                    value: String(format: "%.1f mg", statistics.averageDose),
                    icon: "drop.fill",
                    color: .green
                )
            }

            if let mostUsedSite = statistics.mostUsedSite {
                StatisticCard(
                    title: "Primary Site",
                    value: mostUsedSite,
                    icon: "location.fill",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Detailed View

    @ViewBuilder
    private var detailedStatsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Adherence section
            adherenceSection

            // Dose information section
            doseInformationSection

            // Streak information section
            streakSection

            // Injection sites section
            if !statistics.siteDistribution.isEmpty {
                injectionSitesSection
            }
        }
    }

    // MARK: - Detailed Sections

    @ViewBuilder
    private var adherenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Adherence", icon: "checkmark.circle.fill", color: .green)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rate: \(statistics.adherenceRatePercentage)")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(statistics.totalDoses - statistics.skippedDoses) of \(statistics.scheduledDoses) scheduled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Adherence progress circle
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 4)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: statistics.adherenceRate)
                        .stroke(adherenceColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: statistics.adherenceRate)
                }
            }
        }
    }

    @ViewBuilder
    private var doseInformationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Dose Information", icon: "drop.fill", color: .blue)

            LazyVGrid(columns: detailedGridColumns, spacing: 8) {
                DetailStatRow(label: "Total Doses", value: "\(statistics.totalDoses)")
                DetailStatRow(label: "Skipped", value: "\(statistics.skippedDoses)")

                if statistics.averageDose > 0 {
                    DetailStatRow(
                        label: "Average",
                        value: String(format: "%.1f mg", statistics.averageDose)
                    )
                }

                if statistics.totalMedicationAmount > 0 {
                    DetailStatRow(
                        label: "Total Amount",
                        value: String(format: "%.1f mg", statistics.totalMedicationAmount)
                    )
                }

                if let range = statistics.doseRange {
                    DetailStatRow(
                        label: "Range",
                        value: String(format: "%.1f - %.1f mg", range.min, range.max)
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Streaks", icon: "flame.fill", color: .orange)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Text("\(statistics.currentStreak)")
                            .font(.title2)
                            .fontWeight(.semibold)

                        if statistics.isCurrentStreakActive {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Longest")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(statistics.longestStreak)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var injectionSitesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Injection Sites", icon: "location.fill", color: .purple)

            LazyVGrid(columns: detailedGridColumns, spacing: 8) {
                ForEach(Array(statistics.siteDistribution.sorted(by: { $0.value > $1.value })), id: \.key) { site, count in
                    DetailStatRow(label: site, value: "\(count)")
                }
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14, weight: .medium))

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    private var adherenceRateBadge: some View {
        Text(statistics.adherenceRatePercentage)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(adherenceColor.opacity(0.2))
            )
            .foregroundColor(adherenceColor)
    }

    // MARK: - Computed Properties

    private var monthlyPeriodText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let start = formatter.string(from: statistics.periodStart)
        let end = formatter.string(from: statistics.periodEnd)

        return "\(start) - \(end)"
    }

    private var streakDisplayText: String {
        let days = statistics.currentStreak
        return "\(days) day\(days == 1 ? "" : "s")"
    }

    private var adherenceColor: Color {
        let rate = statistics.adherenceRate
        if rate >= 0.9 { return .green }
        if rate >= 0.7 { return .orange }
        return .red
    }

    private var summaryGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }

    private var detailedGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }
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
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .medium))

                Spacer()
            }

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct DetailStatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
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
        periodEnd: Date()
    )

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
        periodEnd: Date()
    )

    return MonthlyStatsView(statistics: sampleStats, showDetailedView: true)
        .padding()
}
