//
//  WeightTrendDetailView.swift
//  JabTracker
//
//  Detail view for Weight Trend widget showing expanded chart, time filtering,
//  insights, and data sources.
//  Part of v0.7.0 Dashboard Widget UX milestone (Phase 33).
//

import Charts
import SwiftUI

// MARK: - Detail Time Period

/// Time periods available for detail view filtering
enum DetailTimePeriod: String, CaseIterable, Identifiable {
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "All"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var accessibilityLabel: String {
        switch self {
        case .oneWeek: return "One week"
        case .oneMonth: return "One month"
        case .threeMonths: return "Three months"
        case .sixMonths: return "Six months"
        case .oneYear: return "One year"
        case .all: return "All time"
        }
    }

    /// Start date for filtering data based on selected time period.
    /// Returns nil for `.all` (no filtering).
    var startDate: Date? {
        let calendar = Calendar.current
        let today = Date()

        switch self {
        case .oneWeek:
            return calendar.date(byAdding: .day, value: -7, to: today)
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: today)
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: today)
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: today)
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: today)
        case .all:
            return nil
        }
    }
}

// MARK: - Mock Data Structure

/// Data model for Weight Trend detail view
struct WeightTrendDetailData {
    struct WeightPoint: Identifiable {
        let id = UUID()
        let date: Date
        let weight: Double
        let isTrendLine: Bool  // true for smoothed trend, false for actual weight
    }

    struct WeightChange: Identifiable {
        let id = UUID()
        let period: String  // "3-day", "7-day", etc.
        let change: Double
        let trend: String  // "Decrease", "Increase", "No Change"
    }

    struct HistoricalEntry: Identifiable {
        let id = UUID()
        let weight: Double
        let date: Date
        let changeLabel: String?  // "No Change", "+0.2", "-0.3", etc.
    }

    let currentWeight: Double
    let weightUnit: String
    let difference: Double
    let dateRange: String
    let dataPoints: [WeightPoint]
    let weightChanges: [WeightChange]
    let smoothedWeight: Double
    let weeklyChange: Double
    let energyDeficit: Int
    let projectedWeight: Double
    let historicalEntries: [HistoricalEntry]

    // MARK: - Mock Data

    static let mock: WeightTrendDetailData = {
        let calendar = Calendar.current
        let today = Date()

        // Generate ~6 months of weight data showing gradual decline from 202 to 183 lbs
        var scalePoints: [WeightPoint] = []
        var trendPoints: [WeightPoint] = []

        // Seeded random generator for consistent mock data
        var rng = SeededRNG(seed: 42)

        // Generate data for 180 days (6 months)
        for dayOffset in stride(from: 180, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Base weight declining from ~202 to ~183 over 6 months
            let progress = Double(180 - dayOffset) / 180.0
            let baseWeight = 202.0 - (19.0 * progress)

            // Scale weight: daily measurements with small natural fluctuations (±0.5 lbs)
            // Real weigh-ins happen most days
            if dayOffset % 1 == 0 || dayOffset % 2 == 0 {
                let fluctuation = Double.random(in: -0.5...0.5, using: &rng)
                let scaleWeight = baseWeight + fluctuation
                scalePoints.append(WeightPoint(date: date, weight: scaleWeight, isTrendLine: false))
            }

            // Trend line: frequent points following the smoothed trend (every 2-3 days)
            if dayOffset % 2 == 0 {
                trendPoints.append(WeightPoint(date: date, weight: baseWeight, isTrendLine: true))
            }
        }

        // Historical entries for Data Sources section
        let historicalEntries: [HistoricalEntry] = [
            HistoricalEntry(
                weight: 183.7,
                date: calendar.date(byAdding: .day, value: 0, to: today) ?? today,
                changeLabel: nil
            ),
            HistoricalEntry(
                weight: 183.7,
                date: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
                changeLabel: "No Change"
            ),
            HistoricalEntry(
                weight: 183.8,
                date: calendar.date(byAdding: .day, value: -2, to: today) ?? today,
                changeLabel: "No Change"
            ),
            HistoricalEntry(
                weight: 183.8,
                date: calendar.date(byAdding: .day, value: -3, to: today) ?? today,
                changeLabel: "No Change"
            ),
            HistoricalEntry(
                weight: 183.9,
                date: calendar.date(byAdding: .day, value: -4, to: today) ?? today,
                changeLabel: "No Change"
            ),
        ]

        return WeightTrendDetailData(
            currentWeight: 192.2,
            weightUnit: "lbs",
            difference: -9.8,
            dateRange: "May 7 - Nov 2, 2025",
            dataPoints: scalePoints + trendPoints,
            weightChanges: [
                WeightChange(period: "3-day", change: -0.1, trend: "Decrease"),
                WeightChange(period: "7-day", change: -0.3, trend: "Decrease"),
                WeightChange(period: "14-day", change: -0.4, trend: "Decrease"),
                WeightChange(period: "30-day", change: -0.4, trend: "Decrease"),
                WeightChange(period: "90-day", change: -5.6, trend: "Decrease"),
            ],
            smoothedWeight: 183.7,
            weeklyChange: -0.14,
            energyDeficit: 67,
            projectedWeight: 183.1,
            historicalEntries: historicalEntries
        )
    }()
}

// MARK: - Weight Trend Detail View

struct WeightTrendDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: DetailTimePeriod = .oneYear
    @State private var showDetailedDates = false

    let data: WeightTrendDetailData

    init(data: WeightTrendDetailData = .mock) {
        self.data = data
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    timePeriodSelector
                    chartSection
                    insightsSection
                    dataSourcesSection
                }
                .padding()
            }
            .background(DesignTokens.Colors.groupedBackground)
            .navigationTitle("Weight Trend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("weight-trend-detail-view")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // Average label
                Text("Average")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Current weight value
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", data.currentWeight))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(data.weightUnit)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Difference
                HStack(spacing: 4) {
                    Text("Difference")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%+.1f", data.difference))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(data.difference < 0 ? .green : .red)
                    Text(data.weightUnit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Date range
                Text(data.dateRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Info button
            Button {
                // Info action - future implementation
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("More information about weight trend")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .accessibilityIdentifier("weight-header-section")
    }

    // MARK: - Time Period Selector

    private var timePeriodSelector: some View {
        DetailTimePeriodSelector(
            selectedPeriod: $selectedPeriod,
            showDetailedDates: $showDetailedDates
        )
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart
            Chart {
                // Scale weight line (actual measurements - lighter background line)
                ForEach(scaleWeightPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(DesignTokens.Colors.weight.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                }

                // Trend weight line with dots (smoothed - prominent, main line)
                ForEach(trendWeightPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(DesignTokens.Colors.weight)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.weight)
                    )
                    .foregroundStyle(DesignTokens.Colors.weight)
                    .symbolSize(30)
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let weight = value.as(Double.self) {
                            Text("\(Int(weight))")
                        }
                    }
                    AxisGridLine()
                }
            }
            .frame(height: 200)
            .accessibilityIdentifier("weight-chart")

            // Legend
            HStack(spacing: 16) {
                legendItem(color: DesignTokens.Colors.weight.opacity(0.4), label: "Scale Weight", isLine: true)
                legendItem(color: DesignTokens.Colors.weight, label: "Trend Weight", isLine: false)
            }
            .font(.caption)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .accessibilityIdentifier("weight-chart-section")
    }

    private func legendItem(color: Color, label: String, isLine: Bool) -> some View {
        HStack(spacing: 6) {
            if isLine {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 2)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            Text(label)
                .foregroundColor(.secondary)
        }
    }

    /// Scale weight points (actual measurements) - filtered and sorted
    private var scaleWeightPoints: [WeightTrendDetailData.WeightPoint] {
        let points = data.dataPoints.filter { !$0.isTrendLine }
        let filtered = selectedPeriod.startDate.map { start in points.filter { $0.date >= start } } ?? points
        return filtered.sorted { $0.date < $1.date }
    }

    /// Trend weight points (smoothed) - filtered and sorted
    private var trendWeightPoints: [WeightTrendDetailData.WeightPoint] {
        let points = data.dataPoints.filter { $0.isTrendLine }
        let filtered = selectedPeriod.startDate.map { start in points.filter { $0.date >= start } } ?? points
        return filtered.sorted { $0.date < $1.date }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights & Data")
                .font(DesignTokens.Typography.headline)

            // Weight Changes card
            weightChangesCard

            // Current Weight card
            insightCard(
                title: "Current Weight",
                value: String(format: "%.1f", data.smoothedWeight),
                unit: data.weightUnit,
                description: "Our estimate of your true weight after smoothing out day-to-day fluctuations."
            )

            // Weekly Weight Change card
            insightCard(
                title: "Weekly Weight Change",
                value: String(format: "%.2f", data.weeklyChange),
                unit: "\(data.weightUnit) per week",
                description: "Your typical weekly rate of weight loss over the past three weeks."
            )

            // Energy Deficit card
            insightCard(
                title: "Energy Deficit",
                value: "~\(data.energyDeficit)",
                unit: "kcal per day",
                description: energyDeficitDescription
            )

            // 30-Day Projection card
            insightCard(
                title: "30-Day Projection",
                value: String(format: "%.1f", data.projectedWeight),
                unit: data.weightUnit,
                description: projectionDescription
            )
        }
        .accessibilityIdentifier("weight-insights-section")
    }

    private var weightChangesCard: some View {
        DesignCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Weight Changes")
                    .font(DesignTokens.Typography.headline)

                ForEach(data.weightChanges) { change in
                    weightChangeRow(change)
                }
            }
        }
        .accessibilityIdentifier("weight-changes-card")
    }

    private func weightChangeRow(_ change: WeightTrendDetailData.WeightChange) -> some View {
        let changeText = "\(change.change > 0 ? "+" : "")\(String(format: "%.1f", change.change)) \(data.weightUnit)"
        let arrowName = change.change < 0 ? "arrow.down" : (change.change > 0 ? "arrow.up" : "minus")
        let arrowColor: Color = change.change < 0 ? .green : (change.change > 0 ? .red : .secondary)

        return HStack {
            Text(change.period)
                .foregroundColor(.secondary)
            Spacer()
            Text(changeText)
                .fontWeight(.medium)
            Image(systemName: arrowName)
                .foregroundColor(arrowColor)
            Text(change.trend)
                .foregroundColor(.secondary)
        }
        .font(.subheadline)
    }

    // MARK: - Description Text Constants

    private var energyDeficitDescription: String {
        "Our estimate of your average daily caloric deficit, based on your rate of weight loss "
            + "over the past three weeks."
    }

    private var projectionDescription: String {
        "Your projected weight in 30 days if your current rate of weight loss continues. "
    }

    private func insightCard(title: String, value: String, unit: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: Value box
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 100)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignTokens.Colors.cardBackground)
            )

            // Right: Title and description
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }

    // MARK: - Data Sources Section

    private var dataSourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Sources")
                .font(DesignTokens.Typography.headline)

            // Scale Weight source
            Button {
                // Navigate to manage data - future implementation
            } label: {
                HStack {
                    Image(systemName: "scalemass")
                        .foregroundColor(.purple)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scale Weight")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text("Manage Data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card)
                        .fill(DesignTokens.Colors.cardBackground)
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("scale-weight-source-button")

            // Historical log
            historicalWeightLog
        }
        .accessibilityIdentifier("weight-data-sources")
    }

    private var historicalWeightLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month header
            Text(monthYearString(from: data.historicalEntries.first?.date ?? Date()))
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(data.historicalEntries) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.1f %@", entry.weight, data.weightUnit))
                            .font(.subheadline)
                        Text(dayDateString(from: entry.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let changeLabel = entry.changeLabel {
                        Text(changeLabel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .accessibilityIdentifier("historical-weight-log")
    }

    // MARK: - Date Formatting Helpers

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func dayDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    WeightTrendDetailView()
}

#Preview("Light Mode") {
    WeightTrendDetailView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    WeightTrendDetailView()
        .preferredColorScheme(.dark)
}
