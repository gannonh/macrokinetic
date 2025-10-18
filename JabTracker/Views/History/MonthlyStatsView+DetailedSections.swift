//
//  MonthlyStatsView+DetailedSections.swift
//  JabTracker
//
//  Extension containing detailed section views for MonthlyStatsView
//

import SwiftUI

// MARK: - Detailed Sections

extension MonthlyStatsView {
    @ViewBuilder
    var adherenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            self.sectionHeader("Adherence", icon: "checkmark.circle.fill", color: .green)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rate: \(self.statistics.adherenceRatePercentage)")
                        .font(.title2)
                        .fontWeight(.semibold)

                    let completedDoses = self.statistics.totalDoses - self.statistics.skippedDoses
                    Text("\(completedDoses) of \(self.statistics.scheduledDoses) scheduled")
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
                        .trim(from: 0, to: self.statistics.adherenceRate)
                        .stroke(self.adherenceColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: self.statistics.adherenceRate)
                }
            }
        }
    }

    @ViewBuilder
    var doseInformationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            self.sectionHeader("Dose Information", icon: "drop.fill", color: .blue)

            LazyVGrid(columns: self.detailedGridColumns, spacing: 8) {
                DetailStatRow(label: "Total Doses", value: "\(self.statistics.totalDoses)")
                DetailStatRow(label: "Skipped", value: "\(self.statistics.skippedDoses)")

                if self.statistics.averageDose > 0 {
                    DetailStatRow(
                        label: "Average",
                        value: String(format: "%.1f mg", self.statistics.averageDose))
                }

                if self.statistics.totalMedicationAmount > 0 {
                    DetailStatRow(
                        label: "Total Amount",
                        value: String(format: "%.1f mg", self.statistics.totalMedicationAmount))
                }

                if let range = statistics.doseRange {
                    DetailStatRow(
                        label: "Range",
                        value: String(format: "%.1f - %.1f mg", range.min, range.max))
                }
            }
        }
    }

    @ViewBuilder
    var streakSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            self.sectionHeader("Streaks", icon: "flame.fill", color: .orange)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Text("\(self.statistics.currentStreak)")
                            .font(.title2)
                            .fontWeight(.semibold)

                        if self.statistics.isCurrentStreakActive {
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

                    Text("\(self.statistics.longestStreak)")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    var injectionSitesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            self.sectionHeader("Injection Sites", icon: "location.fill", color: .purple)

            LazyVGrid(columns: self.detailedGridColumns, spacing: 8) {
                let sortedSites = self.statistics.siteDistribution.sorted(by: { $0.value > $1.value })
                ForEach(Array(sortedSites), id: \.key) { site, count in
                    DetailStatRow(label: site, value: "\(count)")
                }
            }
        }
    }

    @ViewBuilder
    var scheduleAdherenceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            self.sectionHeader("Schedule Adherence", icon: "calendar.badge.checkmark", color: .blue)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rate: \(self.statistics.scheduleAdherenceRatePercentage)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibilityLabel(
                            "Schedule adherence rate: \(self.statistics.scheduleAdherenceRatePercentage)"
                        )

                    Text(self.scheduleBreakdownText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(self.scheduleBreakdownAccessibilityLabel)
                }

                Spacer()

                // Schedule adherence progress circle
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 4)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: self.statistics.scheduleAdherenceRate)
                        .stroke(
                            self.scheduleAdherenceColor,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: self.statistics.scheduleAdherenceRate)
                }
                .accessibilityHidden(true)  // Rate already announced in text
            }

            // Breakdown grid
            LazyVGrid(columns: self.detailedGridColumns, spacing: 8) {
                DetailStatRow(
                    label: "Scheduled",
                    value: "\(self.statistics.totalScheduledDoses)")
                DetailStatRow(
                    label: "Taken",
                    value: "\(self.statistics.takenScheduledDoses)")
                DetailStatRow(
                    label: "Missed",
                    value: "\(self.statistics.missedScheduledDoses)")
                DetailStatRow(
                    label: "Skipped",
                    value: "\(self.statistics.skippedScheduledDoses)")
            }
        }
    }
}
