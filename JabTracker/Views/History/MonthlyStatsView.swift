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

  // MARK: - Detailed Sections

  @ViewBuilder
  private var adherenceSection: some View {
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
  private var doseInformationSection: some View {
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
  private var streakSection: some View {
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
  private var injectionSitesSection: some View {
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
    Text(self.statistics.adherenceRatePercentage)
      .font(.caption)
      .fontWeight(.semibold)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(self.adherenceColor.opacity(0.2))
      )
      .foregroundColor(self.adherenceColor)
  }

  // MARK: - Computed Properties

  private var monthlyPeriodText: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d"

    let start = formatter.string(from: self.statistics.periodStart)
    let end = formatter.string(from: self.statistics.periodEnd)

    return "\(start) - \(end)"
  }

  private var streakDisplayText: String {
    let days = self.statistics.currentStreak
    return "\(days) day\(days == 1 ? "" : "s")"
  }

  private var adherenceColor: Color {
    let rate = self.statistics.adherenceRate
    if rate >= 0.9 { return .green }
    if rate >= 0.7 { return .orange }
    return .red
  }

  private var summaryGridColumns: [GridItem] {
    [
      GridItem(.flexible(), spacing: 8),
      GridItem(.flexible(), spacing: 8),
    ]
  }

  private var detailedGridColumns: [GridItem] {
    [
      GridItem(.flexible(), spacing: 8),
      GridItem(.flexible(), spacing: 8),
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
    periodEnd: Date())

  return MonthlyStatsView(statistics: sampleStats, showDetailedView: true)
    .padding()
}
