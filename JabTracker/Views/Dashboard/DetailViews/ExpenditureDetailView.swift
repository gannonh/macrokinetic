//
//  ExpenditureDetailView.swift
//  JabTracker
//
//  Detail view for Expenditure widget showing expanded chart, time filtering,
//  insights, and data sources.
//  Part of v0.7.0 Dashboard Widget UX milestone (Phase 33).
//

import Charts
import SwiftData
import SwiftUI

// MARK: - Mock Data Structure

/// Data model for Expenditure detail view (used for previews)
struct ExpenditureDetailData {
    struct DailyExpenditure: Identifiable {
        let id = UUID()
        let date: Date
        let value: Int
        let upperBound: Int  // Flux range upper bound
        let lowerBound: Int  // Flux range lower bound
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
        var rng = SeededRNG(seed: 123)

        // Generate data for 365 days (1 year)
        // Create a slow-changing trend with small daily variations
        var runningAverage = 1893.0

        for dayOffset in stride(from: 365, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Slow drift in the underlying trend (±3 kcal per day max)
            let trendDrift = Double.random(in: -3...3, using: &rng)
            runningAverage += trendDrift
            runningAverage = max(1800, min(2100, runningAverage))  // Keep in realistic range

            // Small daily variation around the trend
            let dailyVariation = Int.random(in: -10...10, using: &rng)
            let value = Int(runningAverage) + dailyVariation

            // Flux range (margin of error) - tighter for more recent data
            let fluxMargin: Int
            if dayOffset < 14 {
                fluxMargin = 15  // Recent: tight estimate
            } else if dayOffset < 60 {
                fluxMargin = 25  // Medium: moderate uncertainty
            } else {
                fluxMargin = 40  // Older: more uncertainty
            }

            let upperBound = value + fluxMargin
            let lowerBound = value - fluxMargin

            // Determine status based on recency
            let status: ExpenditureStatus
            if dayOffset < 14 {
                status = .holding
            } else if dayOffset < 60 {
                status = .updating
            } else {
                status = .fluxRange
            }

            dailyData.append(
                DailyExpenditure(
                    date: date,
                    value: value,
                    upperBound: upperBound,
                    lowerBound: lowerBound,
                    status: status
                ))
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
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ExpenditureDetailViewModel?
    @State private var selectedPeriod: DetailTimePeriod = .oneYear
    @State private var showDetailedDates = false

    /// Flag to use mock data for previews
    private let useMockData: Bool

    init(useMockData: Bool = false) {
        self.useMockData = useMockData
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
            .task {
                if !useMockData {
                    await loadData()
                }
            }
            .onChange(of: selectedPeriod) { _, _ in
                Task {
                    if !useMockData {
                        await loadData()
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .accessibilityIdentifier("expenditure-detail-view")
    }

    // MARK: - Data Loading

    private func loadData() async {
        if viewModel == nil {
            viewModel = ExpenditureDetailViewModel(context: modelContext)
        }
        viewModel?.selectedPeriod = selectedPeriod
        await viewModel?.loadData()
    }

    // MARK: - Data Access Helpers

    private var averageExpenditure: Int {
        if useMockData {
            return ExpenditureDetailData.mock.averageExpenditure
        }
        return viewModel?.averageExpenditure ?? 0
    }

    private var currentExpenditure: Int {
        if useMockData {
            return ExpenditureDetailData.mock.currentExpenditure
        }
        return viewModel?.currentExpenditure ?? 0
    }

    private var difference: Int {
        if useMockData {
            return ExpenditureDetailData.mock.difference
        }
        return viewModel?.difference ?? 0
    }

    private var dateRange: String {
        if useMockData {
            return ExpenditureDetailData.mock.dateRange
        }
        return viewModel?.dateRange ?? ""
    }

    private var currentStrategy: String {
        if useMockData {
            return ExpenditureDetailData.mock.currentStrategy
        }
        return viewModel?.currentStrategy ?? "Holding"
    }

    private var strategyDescription: String {
        if useMockData {
            return ExpenditureDetailData.mock.strategyDescription
        }
        return viewModel?.strategyDescription ?? ""
    }

    private var expenditureChanges: [ExpenditureDetailViewModel.ExpenditureChange] {
        if useMockData {
            return ExpenditureDetailData.mock.expenditureChanges.map {
                ExpenditureDetailViewModel.ExpenditureChange(
                    period: $0.period,
                    change: $0.change,
                    trend: $0.trend
                )
            }
        }
        return viewModel?.expenditureChanges ?? []
    }

    private var historicalEntries: [ExpenditureDetailViewModel.HistoricalEntry] {
        if useMockData {
            return ExpenditureDetailData.mock.historicalEntries.map {
                ExpenditureDetailViewModel.HistoricalEntry(
                    expenditure: $0.expenditure,
                    date: $0.date,
                    status: convertStatus($0.status)
                )
            }
        }
        return viewModel?.historicalEntries ?? []
    }

    private func convertStatus(_ status: ExpenditureDetailData.ExpenditureStatus)
        -> ExpenditureDetailViewModel.ExpenditureStatus
    {
        switch status {
        case .fluxRange: return .fluxRange
        case .updating: return .updating
        case .holding: return .holding
        }
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
                    Text("\(averageExpenditure)")
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
                        .foregroundColor(difference < 0 ? .green : .red)
                    Text("kcal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Date range
                Text(dateRange)
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
        if difference >= 0 {
            return "+\(difference)"
        } else {
            return "\(difference)"
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

    /// Whether to show dots on data points (only for shorter periods)
    private var showDataPoints: Bool {
        switch selectedPeriod {
        case .oneWeek, .oneMonth:
            return true
        case .threeMonths, .sixMonths, .oneYear, .all:
            return false
        }
    }

    /// Whether there's enough data to show a meaningful chart
    private var hasEnoughChartData: Bool {
        filteredData.count >= 3
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                if hasEnoughChartData {
                    Chart {
                        // Flux range band (shaded area between upper and lower bounds)
                        ForEach(filteredData) { day in
                            AreaMark(
                                x: .value("Date", day.date),
                                yStart: .value("Lower", day.lowerBound),
                                yEnd: .value("Upper", day.upperBound)
                            )
                            .foregroundStyle(DesignTokens.Colors.expenditure.opacity(0.25))
                            .interpolationMethod(.catmullRom)
                        }

                        // Main expenditure line
                        ForEach(filteredData) { day in
                            LineMark(
                                x: .value("Date", day.date),
                                y: .value("Expenditure", day.value)
                            )
                            .foregroundStyle(DesignTokens.Colors.expenditure)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)
                        }

                        // Data point dots (only for 1W/1M)
                        if showDataPoints {
                            ForEach(filteredData) { day in
                                PointMark(
                                    x: .value("Date", day.date),
                                    y: .value("Expenditure", day.value)
                                )
                                .foregroundStyle(DesignTokens.Colors.expenditure)
                                .symbolSize(25)
                            }
                        }
                    }
                    .chartYScale(domain: chartYDomain)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: xAxisStride, count: 1)) { _ in
                            AxisValueLabel(format: xAxisFormat)
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                                .foregroundStyle(Color.secondary.opacity(0.3))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisValueLabel {
                                if let expenditure = value.as(Int.self) {
                                    Text("\(expenditure)")
                                }
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                                .foregroundStyle(Color.secondary.opacity(0.3))
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("Not enough data yet")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        Text("Your expenditure trend will appear after a few days of tracking.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 200)
            .accessibilityIdentifier("expenditure-chart")

            // Legend
            HStack(spacing: 16) {
                legendItem(
                    icon: "triangle.fill",
                    color: colorForStatus(.fluxRange),
                    label: "Flux Range"
                )
                legendItem(
                    icon: "circle.fill",
                    color: colorForStatus(.updating),
                    label: "Updating"
                )
                legendItem(
                    icon: "square.fill",
                    color: colorForStatus(.holding),
                    label: "Holding"
                )
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

    private func legendItem(icon: String, color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(color)
            Text(label)
                .foregroundColor(.secondary)
        }
    }

    private func colorForStatus(_ status: ExpenditureDetailViewModel.ExpenditureStatus) -> Color {
        switch status {
        case .fluxRange: return DesignTokens.Colors.expenditure
        case .updating: return .blue
        case .holding: return .gray
        }
    }

    /// Filtered data based on selected time period
    private var filteredData: [ExpenditureDetailViewModel.DailyExpenditure] {
        if useMockData {
            let mockData = ExpenditureDetailData.mock.dailyData
            guard let startDate = selectedPeriod.startDate else {
                return mockData.map { convertDailyData($0) }.sorted { $0.date < $1.date }
            }
            return mockData.filter { $0.date >= startDate }.map { convertDailyData($0) }.sorted { $0.date < $1.date }
        }
        guard let startDate = selectedPeriod.startDate else {
            return (viewModel?.dailyData ?? []).sorted { $0.date < $1.date }
        }
        return (viewModel?.dailyData ?? []).filter { $0.date >= startDate }.sorted { $0.date < $1.date }
    }

    private func convertDailyData(_ data: ExpenditureDetailData.DailyExpenditure)
        -> ExpenditureDetailViewModel.DailyExpenditure
    {
        ExpenditureDetailViewModel.DailyExpenditure(
            date: data.date,
            value: data.value,
            upperBound: data.upperBound,
            lowerBound: data.lowerBound,
            status: convertStatus(data.status)
        )
    }

    /// Y-axis domain based on filtered data - tight fit to fill chart area
    private var chartYDomain: ClosedRange<Int> {
        // Use upper/lower bounds for the full range
        let lowerValues = filteredData.map { $0.lowerBound }
        let upperValues = filteredData.map { $0.upperBound }
        guard let minValue = lowerValues.min(), let maxValue = upperValues.max() else {
            return 1800...2000
        }
        // Minimal padding (5%) to give slight breathing room
        let range = maxValue - minValue
        let padding = max(range / 20, 5)
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

                if expenditureChanges.isEmpty {
                    Text("Not enough data yet. Changes will appear after a few days of tracking.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(expenditureChanges) { change in
                        expenditureChangeRow(change)
                    }
                }
            }
        }
        .accessibilityIdentifier("expenditure-changes-card")
    }

    private func expenditureChangeRow(_ change: ExpenditureDetailViewModel.ExpenditureChange) -> some View {
        // Format change text with sign
        let changeText: String
        if change.change == 0 {
            changeText = "0 kcal"
        } else if change.change > 0 {
            changeText = "+\(change.change) kcal"
        } else {
            changeText = "\(change.change) kcal"
        }

        // Determine arrow icon and color based on direction
        let arrowName: String
        let arrowColor: Color
        if change.change < 0 {
            arrowName = "arrow.down"
            arrowColor = .green
        } else if change.change > 0 {
            arrowName = "arrow.up"
            arrowColor = .red
        } else {
            arrowName = "minus"
            arrowColor = .secondary
        }

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
                Text("\(currentExpenditure)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
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
                Text(currentStrategy)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
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

                Text(strategyDescription)
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
            Text(monthYearString(from: historicalEntries.first?.date ?? Date()))
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(historicalEntries) { entry in
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
    ExpenditureDetailView(useMockData: true)
}

#Preview("Light Mode") {
    ExpenditureDetailView(useMockData: true)
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ExpenditureDetailView(useMockData: true)
        .preferredColorScheme(.dark)
}
