//
//  ExpenditureDetailView.swift
//  JabTracker
//
//  Detail view for Expenditure widget showing expanded chart, time filtering,
//  insights, and data sources.
//  Part of v0.7.0 Dashboard Widget UX milestone (Phase 33).
//

import Charts
import GameplayKit
import SwiftUI

// MARK: - Seeded Random Generator

/// Random number generator with seed for reproducible mock data
private struct SeededExpenditureRNG: RandomNumberGenerator {
    private var source: GKMersenneTwisterRandomSource

    init(seed: UInt64) {
        source = GKMersenneTwisterRandomSource(seed: seed)
    }

    mutating func next() -> UInt64 {
        let high = UInt64(bitPattern: Int64(source.nextInt()))
        let low = UInt64(bitPattern: Int64(source.nextInt()))
        return (high << 32) | (low & 0xFFFF_FFFF)
    }
}

// MARK: - Mock Data Structure

/// Data model for Expenditure detail view
struct ExpenditureDetailData {
    struct DailyExpenditure: Identifiable {
        let id = UUID()
        let date: Date
        let value: Int
        let status: ExpenditureStatus
    }

    enum ExpenditureStatus: String {
        case fluxRange = "Flux Range"  // Orange - initial estimate
        case updating = "Updating"  // Blue - being refined
        case holding = "Holding"  // Gray - stable estimate
    }

    struct ExpenditureChange: Identifiable {
        let id = UUID()
        let period: String  // "3-day", "7-day", etc.
        let change: Int
        let trend: String  // "Decrease", "Increase", "No Change"
    }

    struct HistoricalEntry: Identifiable {
        let id = UUID()
        let expenditure: Int
        let date: Date
        let status: ExpenditureStatus
    }

    let averageExpenditure: Int
    let difference: Int
    let dateRange: String
    let dailyData: [DailyExpenditure]
    let expenditureChanges: [ExpenditureChange]
    let currentExpenditure: Int
    let currentStrategy: String  // "Holding", "Updating"
    let strategyDescription: String
    let historicalEntries: [HistoricalEntry]

    // MARK: - Mock Data

    static let mock: ExpenditureDetailData = {
        let calendar = Calendar.current
        let today = Date()

        // Generate ~12 months of expenditure data
        var dailyData: [DailyExpenditure] = []

        // Seeded random generator for consistent mock data
        var rng = SeededExpenditureRNG(seed: 123)

        // Generate data for 365 days (1 year)
        for dayOffset in stride(from: 365, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Base expenditure around 1893 with variations
            let baseExpenditure = 1893
            let variation = Int.random(in: -100...100, using: &rng)
            let value = baseExpenditure + variation

            // Determine status based on recency
            let status: ExpenditureStatus
            if dayOffset < 14 {
                // Recent data - holding (stable)
                status = .holding
            } else if dayOffset < 60 {
                // Medium-term data - updating
                status = .updating
            } else {
                // Older data - flux range
                status = .fluxRange
            }

            dailyData.append(DailyExpenditure(date: date, value: value, status: status))
        }

        // Historical entries for Data Sources section
        let historicalEntries: [HistoricalEntry] = [
            HistoricalEntry(
                expenditure: 1893,
                date: calendar.date(byAdding: .day, value: 0, to: today) ?? today,
                status: .holding
            ),
            HistoricalEntry(
                expenditure: 1893,
                date: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
                status: .holding
            ),
            HistoricalEntry(
                expenditure: 1893,
                date: calendar.date(byAdding: .day, value: -2, to: today) ?? today,
                status: .holding
            ),
            HistoricalEntry(
                expenditure: 1893,
                date: calendar.date(byAdding: .day, value: -3, to: today) ?? today,
                status: .holding
            ),
            HistoricalEntry(
                expenditure: 1893,
                date: calendar.date(byAdding: .day, value: -4, to: today) ?? today,
                status: .holding
            ),
            HistoricalEntry(
                expenditure: 1893,
                date: calendar.date(byAdding: .day, value: -5, to: today) ?? today,
                status: .holding
            ),
            HistoricalEntry(
                expenditure: 1893,
                date: calendar.date(byAdding: .day, value: -6, to: today) ?? today,
                status: .holding
            ),
        ]

        let strategyDescription =
            "Holding safeguards your expenditure estimate against insufficient data. "
            + "Updating requires at least 3 days of nutrition data and 1 day of weight data per 7-day period."

        return ExpenditureDetailData(
            averageExpenditure: 1903,
            difference: -135,
            dateRange: "Dec 29, 2024 - Dec 28, 2025",
            dailyData: dailyData,
            expenditureChanges: [
                ExpenditureChange(period: "3-day", change: 0, trend: "No Change"),
                ExpenditureChange(period: "7-day", change: 0, trend: "No Change"),
                ExpenditureChange(period: "14-day", change: 0, trend: "No Change"),
                ExpenditureChange(period: "30-day", change: 0, trend: "No Change"),
                ExpenditureChange(period: "90-day", change: 0, trend: "No Change"),
            ],
            currentExpenditure: 1893,
            currentStrategy: "Holding",
            strategyDescription: strategyDescription,
            historicalEntries: historicalEntries
        )
    }()
}

// MARK: - Expenditure Detail View

struct ExpenditureDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPeriod: DetailTimePeriod = .oneYear
    @State private var showDetailedDates = false

    let data: ExpenditureDetailData

    init(data: ExpenditureDetailData = .mock) {
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
            .navigationTitle("Expenditure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("expenditure-detail-view")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // Average label
                Text("Average")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Current expenditure value
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(data.averageExpenditure)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("kcal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Difference
                HStack(spacing: 4) {
                    Text("Difference")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(differenceText)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(data.difference < 0 ? .green : .red)
                    Text("kcal")
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
            .accessibilityLabel("More information about expenditure")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .accessibilityIdentifier("expenditure-header-section")
    }

    private var differenceText: String {
        if data.difference >= 0 {
            return "+\(data.difference)"
        } else {
            return "\(data.difference)"
        }
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
                ForEach(filteredData) { day in
                    BarMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Expenditure", day.value)
                    )
                    .foregroundStyle(colorForStatus(day.status))
                    .cornerRadius(2)
                }
            }
            .chartYScale(domain: chartYDomain)
            .chartXAxis {
                AxisMarks(values: .stride(by: xAxisStride, count: 1)) { _ in
                    AxisValueLabel(format: xAxisFormat)
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let expenditure = value.as(Int.self) {
                            Text("\(expenditure)")
                        }
                    }
                    AxisGridLine()
                }
            }
            .frame(height: 200)
            .accessibilityIdentifier("expenditure-chart")

            // Legend
            HStack(spacing: 16) {
                legendItem(color: DesignTokens.Colors.expenditure, label: "Flux Range")
                legendItem(color: .blue, label: "Updating")
                legendItem(color: .gray, label: "Holding")
            }
            .font(.caption)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .accessibilityIdentifier("expenditure-chart-section")
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.secondary)
        }
    }

    private func colorForStatus(_ status: ExpenditureDetailData.ExpenditureStatus) -> Color {
        switch status {
        case .fluxRange: return DesignTokens.Colors.expenditure
        case .updating: return .blue
        case .holding: return .gray
        }
    }

    /// Start date for selected time period
    private var periodStartDate: Date? {
        let calendar = Calendar.current
        let today = Date()

        switch selectedPeriod {
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

    /// Filtered data based on selected time period
    private var filteredData: [ExpenditureDetailData.DailyExpenditure] {
        guard let startDate = periodStartDate else {
            return data.dailyData.sorted { $0.date < $1.date }
        }
        return data.dailyData.filter { $0.date >= startDate }.sorted { $0.date < $1.date }
    }

    /// Y-axis domain based on filtered data
    private var chartYDomain: ClosedRange<Int> {
        let values = filteredData.map { $0.value }
        guard let minValue = values.min(), let maxValue = values.max() else {
            return 1800...2000
        }
        // Add padding to domain
        let padding = max((maxValue - minValue) / 10, 50)
        return (minValue - padding)...(maxValue + padding)
    }

    /// X-axis stride based on selected period
    private var xAxisStride: Calendar.Component {
        switch selectedPeriod {
        case .oneWeek:
            return .day
        case .oneMonth:
            return .weekOfYear
        case .threeMonths, .sixMonths:
            return .month
        case .oneYear, .all:
            return .month
        }
    }

    /// X-axis date format based on selected period
    private var xAxisFormat: Date.FormatStyle {
        switch selectedPeriod {
        case .oneWeek:
            return .dateTime.weekday(.abbreviated)
        case .oneMonth:
            return .dateTime.month(.abbreviated).day()
        case .threeMonths, .sixMonths, .oneYear, .all:
            return .dateTime.month(.abbreviated)
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights & Data")
                .font(DesignTokens.Typography.headline)

            // Expenditure Changes card
            expenditureChangesCard

            // Current Expenditure card
            currentExpenditureCard

            // Current Strategy card
            currentStrategyCard
        }
        .accessibilityIdentifier("expenditure-insights-section")
    }

    private var expenditureChangesCard: some View {
        DesignCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Expenditure Changes")
                    .font(DesignTokens.Typography.headline)

                ForEach(data.expenditureChanges) { change in
                    expenditureChangeRow(change)
                }
            }
        }
        .accessibilityIdentifier("expenditure-changes-card")
    }

    private func expenditureChangeRow(_ change: ExpenditureDetailData.ExpenditureChange) -> some View {
        let changeText = change.change == 0 ? "0 kcal" : "\(change.change > 0 ? "+" : "")\(change.change) kcal"
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

    private var currentExpenditureCard: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: Value box
            VStack(spacing: 2) {
                Text("\(data.currentExpenditure)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("kcal")
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
                Text("Current Expenditure")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(currentExpenditureDescription)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .accessibilityIdentifier("current-expenditure-card")
    }

    private var currentExpenditureDescription: String {
        "The latest estimate of your daily energy expenditure based on your weight trend and nutrition data."
    }

    private var currentStrategyCard: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: Strategy value box
            VStack(spacing: 2) {
                Text(data.currentStrategy)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text("status")
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
                Text("Current Strategy")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(data.strategyDescription)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .accessibilityIdentifier("current-strategy-card")
    }

    // MARK: - Data Sources Section

    private var dataSourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Sources")
                .font(DesignTokens.Typography.headline)

            // Nutrition Data Manager source
            Button {
                // Navigate to manage data - future implementation
            } label: {
                HStack {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nutrition Data Manager")
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
            .accessibilityIdentifier("nutrition-data-source-button")

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
            historicalExpenditureLog
        }
        .accessibilityIdentifier("expenditure-data-sources")
    }

    private var historicalExpenditureLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month header
            Text(monthYearString(from: data.historicalEntries.first?.date ?? Date()))
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(data.historicalEntries) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.expenditure) kcal")
                            .font(.subheadline)
                        Text(dayDateString(from: entry.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorForStatus(entry.status))
                            .frame(width: 8, height: 8)
                        Text(entry.status.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .accessibilityIdentifier("historical-expenditure-log")
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
    ExpenditureDetailView()
}

#Preview("Light Mode") {
    ExpenditureDetailView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ExpenditureDetailView()
        .preferredColorScheme(.dark)
}
