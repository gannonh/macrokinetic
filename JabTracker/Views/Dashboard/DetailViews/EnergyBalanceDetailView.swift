//
//  EnergyBalanceDetailView.swift
//  JabTracker
//
//  Detail view for Energy Balance widget showing dual-mode display
//  (Expenditure vs Calorie Targets), charts, insights, and historical log.
//  Part of v0.7.0 Dashboard Widget UX milestone (Phase 33).
//

import Charts
import SwiftData
import SwiftUI

// MARK: - Mock Data Structure

/// Data model for Energy Balance detail view with dual-mode display (used for previews)
struct EnergyBalanceDetailData {
    /// Daily data point with calories consumed and reference values
    struct DailyData: Identifiable {
        let id = UUID()
        let date: Date
        let caloriesConsumed: Int  // Vertical bars - what user ate
        let expenditure: Int  // Horizontal line in Expenditure mode
        let calorieTarget: Int  // Horizontal line in Calorie Targets mode

        /// Balance relative to expenditure (negative = deficit)
        var expenditureBalance: Int { caloriesConsumed - expenditure }

        /// Balance relative to target (negative = below target)
        var targetBalance: Int { caloriesConsumed - calorieTarget }
    }

    struct BalanceChange: Identifiable {
        let id = UUID()
        let period: String
        let value: Int
        let trend: String  // "Deficit", "Surplus", "Balance", "At Target", "Below Target", "Above Target"
    }

    enum DisplayMode: String, CaseIterable, Identifiable {
        case expenditure = "Expenditure"
        case calorieTargets = "Calorie Targets"

        var id: String { rawValue }
    }

    // Shared daily data (contains both expenditure and target reference values)
    let dailyData: [DailyData]

    // Expenditure mode summary
    let expenditureDeficit: Int
    let expenditureDateRange: String
    let expenditureChanges: [BalanceChange]

    // Calorie Targets mode summary
    let targetAverage: Int
    let targetDateRange: String
    let targetChanges: [BalanceChange]

    // MARK: - Mock Data

    static let mock: EnergyBalanceDetailData = {
        let calendar = Calendar.current
        let today = Date()

        // Seeded random generator for consistent mock data
        var rng = SeededRNG(seed: 456)

        // Generate 1 year of daily data
        var dailyData: [DailyData] = []
        for dayOffset in stride(from: 365, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Expenditure hovers around 2000-2200 with slight daily variation
            let expenditure = Int.random(in: 1900...2200, using: &rng)

            // Calorie target changes by week (simulating weekly check-ins)
            // Base target around 1600-1800, varies by week
            let weekOfYear = calendar.component(.weekOfYear, from: date)
            let baseTarget = 1650 + (weekOfYear % 4) * 50  // Varies 1650-1800
            let calorieTarget = baseTarget + Int.random(in: -25...25, using: &rng)

            // Calories consumed - mostly under expenditure (70%), sometimes over (30%)
            let isDeficit = Int.random(in: 1...10, using: &rng) <= 7
            let caloriesConsumed: Int
            if isDeficit {
                // Under expenditure by 200-600 kcal
                caloriesConsumed = expenditure - Int.random(in: 200...600, using: &rng)
            } else {
                // Over expenditure by 100-400 kcal
                caloriesConsumed = expenditure + Int.random(in: 100...400, using: &rng)
            }

            dailyData.append(
                DailyData(
                    date: date,
                    caloriesConsumed: caloriesConsumed,
                    expenditure: expenditure,
                    calorieTarget: calorieTarget
                ))
        }

        return EnergyBalanceDetailData(
            dailyData: dailyData,
            expenditureDeficit: -395,
            expenditureDateRange: "Dec 29, 2024 - Dec 28, 2025",
            expenditureChanges: [
                BalanceChange(period: "3-day", value: 0, trend: "Balance"),
                BalanceChange(period: "7-day", value: -1793, trend: "Deficit"),
                BalanceChange(period: "14-day", value: -1078, trend: "Deficit"),
                BalanceChange(period: "30-day", value: -1078, trend: "Deficit"),
                BalanceChange(period: "90-day", value: -1076, trend: "Deficit"),
            ],
            targetAverage: -614,
            targetDateRange: "Sep 30 - Dec 28, 2025",
            targetChanges: [
                BalanceChange(period: "3-day", value: 0, trend: "At Target"),
                BalanceChange(period: "7-day", value: -1331, trend: "Below Target"),
                BalanceChange(period: "14-day", value: -618, trend: "Below Target"),
                BalanceChange(period: "30-day", value: -618, trend: "Below Target"),
                BalanceChange(period: "90-day", value: -614, trend: "Below Target"),
            ]
        )
    }()
}

// MARK: - Energy Balance Detail View

struct EnergyBalanceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var displayMode: EnergyBalanceDetailData.DisplayMode = .expenditure
    @State private var selectedPeriod: DetailTimePeriod = .oneYear
    @State private var showDetailedDates = false
    @State private var viewModel: EnergyBalanceDetailViewModel?

    /// Whether to use mock data for previews
    private let useMockData: Bool

    /// Mock data for preview mode
    private let mockData: EnergyBalanceDetailData

    init(useMockData: Bool = false, data: EnergyBalanceDetailData = .mock) {
        self.useMockData = useMockData
        self.mockData = data
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    modeToggle
                    headerSection
                    timePeriodSelector
                    chartSection
                    insightsSection
                    historicalLogSection
                }
                .padding()
            }
            .background(DesignTokens.Colors.groupedBackground)
            .navigationTitle("Energy Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                if !useMockData {
                    initializeViewModel()
                    await loadData()
                }
            }
            .onChange(of: selectedPeriod) { _, _ in
                Task {
                    await loadData()
                }
            }
            .onChange(of: displayMode) { _, _ in
                Task {
                    await loadData()
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .accessibilityIdentifier("energy-balance-detail-view")
    }

    // MARK: - ViewModel Management

    private func initializeViewModel() {
        guard viewModel == nil else { return }
        let mealLogService = MealLogService(context: modelContext)
        let tdeeService = TDEEService(context: modelContext)
        viewModel = EnergyBalanceDetailViewModel(
            mealLogService: mealLogService,
            tdeeService: tdeeService,
            context: modelContext
        )
    }

    private func loadData() async {
        guard let viewModel = viewModel else { return }
        viewModel.selectedPeriod = selectedPeriod
        viewModel.displayMode = displayModeToViewModelMode(displayMode)
        await viewModel.loadData()
    }

    private func displayModeToViewModelMode(
        _ mode: EnergyBalanceDetailData.DisplayMode
    ) -> EnergyBalanceDetailViewModel.DisplayMode {
        switch mode {
        case .expenditure:
            return .expenditure
        case .calorieTargets:
            return .calorieTargets
        }
    }

    // MARK: - Data Accessors

    private var dailyData: [EnergyBalanceDetailData.DailyData] {
        if useMockData {
            return filteredMockDailyData
        }
        guard let viewModel = viewModel else { return [] }
        return viewModel.dailyData.map { vmData in
            EnergyBalanceDetailData.DailyData(
                date: vmData.date,
                caloriesConsumed: vmData.caloriesConsumed,
                expenditure: vmData.expenditure,
                calorieTarget: vmData.calorieTarget
            )
        }
    }

    private var balanceChanges: [EnergyBalanceDetailData.BalanceChange] {
        if useMockData {
            return displayMode == .expenditure ? mockData.expenditureChanges : mockData.targetChanges
        }
        guard let viewModel = viewModel else { return [] }
        return viewModel.balanceChanges.map { vmChange in
            EnergyBalanceDetailData.BalanceChange(
                period: vmChange.period,
                value: vmChange.value,
                trend: vmChange.trend
            )
        }
    }

    private var currentValue: Int {
        if useMockData {
            return displayMode == .expenditure ? mockData.expenditureDeficit : mockData.targetAverage
        }
        return viewModel?.headerValue ?? 0
    }

    private var currentDateRange: String {
        if useMockData {
            return displayMode == .expenditure ? mockData.expenditureDateRange : mockData.targetDateRange
        }
        return viewModel?.dateRange ?? ""
    }

    /// Filtered mock daily data based on selected time period
    private var filteredMockDailyData: [EnergyBalanceDetailData.DailyData] {
        guard let startDate = selectedPeriod.startDate else {
            return mockData.dailyData.sorted { $0.date < $1.date }
        }
        return mockData.dailyData.filter { $0.date >= startDate }.sorted { $0.date < $1.date }
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        Picker("Display Mode", selection: $displayMode) {
            ForEach(EnergyBalanceDetailData.DisplayMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityIdentifier("energy-balance-mode-toggle")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // Label changes based on mode
                Text(displayMode == .expenditure ? "Deficit" : "Average")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Current value
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(currentValue)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("kcal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Date range
                Text(currentDateRange)
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
            .accessibilityLabel("More information about energy balance")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .accessibilityIdentifier("energy-balance-header-section")
    }

    // MARK: - Time Period Selector

    private var timePeriodSelector: some View {
        DetailTimePeriodSelector(
            selectedPeriod: $selectedPeriod,
            showDetailedDates: $showDetailedDates
        )
    }

    // MARK: - Chart Section

    /// Daily data filtered to only include days with actual data (calories > 0)
    private var chartData: [EnergyBalanceDetailData.DailyData] {
        dailyData.filter { $0.caloriesConsumed > 0 }
    }

    /// Whether there's enough data to show a meaningful chart
    private var hasEnoughChartData: Bool {
        chartData.count >= 3
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                if hasEnoughChartData {
                    Chart {
                        // Vertical bars for calories consumed (only days with data)
                        ForEach(chartData) { day in
                            BarMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value("Calories", day.caloriesConsumed)
                            )
                            .foregroundStyle(DesignTokens.Colors.calories)
                            .cornerRadius(2)
                        }

                        // Line showing expenditure or target per day (varies based on TDEESnapshots)
                        ForEach(chartData) { day in
                            LineMark(
                                x: .value("Date", day.date, unit: .day),
                                y: .value(
                                    "Reference",
                                    displayMode == .expenditure ? day.expenditure : day.calorieTarget
                                ),
                                series: .value("Series", "Reference")
                            )
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                            .foregroundStyle(DesignTokens.Colors.expenditure)
                        }
                    }
                    .chartYScale(domain: 0...2500)
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
                                if let kcal = value.as(Int.self) {
                                    Text("\(kcal)")
                                }
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                                .foregroundStyle(Color.secondary.opacity(0.3))
                        }
                    }
                } else {
                    // Empty state
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("Not enough data yet")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                        Text("Your energy balance will appear after logging a few days of meals.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: 200)
            .accessibilityIdentifier("energy-balance-chart")

            // Legend
            HStack(spacing: 16) {
                legendItem(color: DesignTokens.Colors.calories, label: "Calories")
                legendItem(
                    color: DesignTokens.Colors.expenditure,
                    label: displayMode == .expenditure ? "Expenditure" : "Targets"
                )
            }
            .font(.caption)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card)
                .fill(DesignTokens.Colors.cardBackground)
        )
        .accessibilityIdentifier("energy-balance-chart-section")
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

            // Balance changes card (mode-dependent)
            balanceChangesCard
        }
        .accessibilityIdentifier("energy-balance-insights-section")
    }

    private var balanceChangesCard: some View {
        let changes = balanceChanges
        let title = displayMode == .expenditure ? "Relative to Expenditure" : "Relative to Targets"

        return DesignCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(DesignTokens.Typography.headline)

                if changes.isEmpty {
                    Text("Not enough data yet. Balance changes will appear after a few days of tracking.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(changes) { change in
                        HStack {
                            Text(change.period)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(change.value) kcal")
                                .fontWeight(.medium)
                            trendIndicator(for: change.trend)
                            Text(change.trend)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .accessibilityIdentifier("balance-changes-card")
    }

    @ViewBuilder
    private func trendIndicator(for trend: String) -> some View {
        let (icon, color): (String, Color) = {
            switch trend.lowercased() {
            case "deficit", "below target":
                return ("arrow.down", .green)
            case "surplus", "above target":
                return ("arrow.up", .red)
            default:
                return ("minus", .secondary)
            }
        }()

        Image(systemName: icon)
            .foregroundColor(color)
    }

    // MARK: - Historical Log Section

    /// Number of historical entries to show based on selected period
    private var historicalEntryCount: Int {
        switch selectedPeriod {
        case .oneWeek:
            return 7
        case .oneMonth:
            return 14
        case .threeMonths, .sixMonths, .oneYear, .all:
            return 30
        }
    }

    /// Group daily data by month for display
    private var dailyDataByMonth: [(month: String, days: [EnergyBalanceDetailData.DailyData])] {
        let recentData = Array(dailyData.suffix(historicalEntryCount).reversed())
        var grouped: [String: [EnergyBalanceDetailData.DailyData]] = [:]
        var monthOrder: [String] = []

        for day in recentData {
            let monthKey = monthYearString(from: day.date)
            if grouped[monthKey] == nil {
                grouped[monthKey] = []
                monthOrder.append(monthKey)
            }
            grouped[monthKey]?.append(day)
        }

        return monthOrder.map { month in
            (month: month, days: grouped[month] ?? [])
        }
    }

    private var historicalLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(dailyDataByMonth, id: \.month) { monthData in
                DesignCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(monthData.month)
                            .font(DesignTokens.Typography.headline)

                        ForEach(monthData.days) { day in
                            let balance =
                                displayMode == .expenditure
                                ? day.expenditureBalance
                                : day.targetBalance
                            let trendLabel =
                                displayMode == .expenditure
                                ? (balance < 0 ? "Deficit" : "Surplus")
                                : (balance < 0 ? "Below Target" : "Above Target")

                            HStack {
                                Text(formatDayDate(day.date))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(balance) kcal")
                                    .fontWeight(.medium)
                                trendIndicator(for: trendLabel)
                                Text(trendLabel)
                                    .foregroundColor(.secondary)
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("historical-balance-log")
    }

    /// Format date as "Mon, Jan 6"
    private func formatDayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }

    // MARK: - Date Formatting Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    EnergyBalanceDetailView(useMockData: true)
}

#Preview("Light Mode") {
    EnergyBalanceDetailView(useMockData: true)
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    EnergyBalanceDetailView(useMockData: true)
        .preferredColorScheme(.dark)
}
