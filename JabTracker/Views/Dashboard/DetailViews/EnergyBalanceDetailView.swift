//
//  EnergyBalanceDetailView.swift
//  JabTracker
//
//  Detail view for Energy Balance widget showing dual-mode display
//  (Expenditure vs Calorie Targets), charts, insights, and historical log.
//  Part of v0.7.0 Dashboard Widget UX milestone (Phase 33).
//

import Charts
import SwiftUI

// MARK: - Mock Data Structure

/// Data model for Energy Balance detail view with dual-mode display
struct EnergyBalanceDetailData {
    struct DailyBalance: Identifiable {
        let id = UUID()
        let date: Date
        let value: Int  // Negative = deficit, Positive = surplus
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

    // Expenditure mode data
    let expenditureDeficit: Int
    let expenditureDateRange: String
    let expenditureDaily: [DailyBalance]
    let expenditureChanges: [BalanceChange]

    // Calorie Targets mode data
    let targetAverage: Int
    let targetDateRange: String
    let targetDaily: [DailyBalance]
    let targetChanges: [BalanceChange]

    // MARK: - Mock Data

    static let mock: EnergyBalanceDetailData = {
        let calendar = Calendar.current
        let today = Date()

        // Seeded random generator for consistent mock data
        var rng = SeededRNG(seed: 456)

        // Generate expenditure mode data (1 year of data)
        // Mix of deficit days (negative) and occasional surplus days (positive)
        var expenditureDaily: [DailyBalance] = []
        for dayOffset in stride(from: 365, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            // 70% deficit days, 30% surplus days for realistic variation
            let isDeficit = Int.random(in: 1...10, using: &rng) <= 7
            let value: Int
            if isDeficit {
                value = -Int.random(in: 200...600, using: &rng)  // Deficit: ate less than expended
            } else {
                value = Int.random(in: 100...400, using: &rng)  // Surplus: ate more than expended
            }
            expenditureDaily.append(DailyBalance(date: date, value: value))
        }

        // Generate calorie targets mode data (3 months of data)
        // Similar pattern but relative to targets
        var targetDaily: [DailyBalance] = []
        for dayOffset in stride(from: 90, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            // 75% below target, 25% above target
            let isBelowTarget = Int.random(in: 1...100, using: &rng) <= 75
            let value: Int
            if isBelowTarget {
                value = -Int.random(in: 300...700, using: &rng)  // Below target
            } else {
                value = Int.random(in: 50...300, using: &rng)  // Above target
            }
            targetDaily.append(DailyBalance(date: date, value: value))
        }

        return EnergyBalanceDetailData(
            expenditureDeficit: -395,
            expenditureDateRange: "Dec 29, 2024 - Dec 28, 2025",
            expenditureDaily: expenditureDaily,
            expenditureChanges: [
                BalanceChange(period: "3-day", value: 0, trend: "Balance"),
                BalanceChange(period: "7-day", value: -1793, trend: "Deficit"),
                BalanceChange(period: "14-day", value: -1078, trend: "Deficit"),
                BalanceChange(period: "30-day", value: -1078, trend: "Deficit"),
                BalanceChange(period: "90-day", value: -1076, trend: "Deficit"),
            ],
            targetAverage: -614,
            targetDateRange: "Sep 30 - Dec 28, 2025",
            targetDaily: targetDaily,
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
    @State private var displayMode: EnergyBalanceDetailData.DisplayMode = .expenditure
    @State private var selectedPeriod: DetailTimePeriod = .oneYear
    @State private var showDetailedDates = false

    let data: EnergyBalanceDetailData

    init(data: EnergyBalanceDetailData = .mock) {
        self.data = data
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
        }
        .accessibilityIdentifier("energy-balance-detail-view")
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

    private var currentValue: Int {
        displayMode == .expenditure ? data.expenditureDeficit : data.targetAverage
    }

    private var currentDateRange: String {
        displayMode == .expenditure ? data.expenditureDateRange : data.targetDateRange
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
            Chart {
                ForEach(filteredDailyData) { day in
                    BarMark(
                        x: .value("Date", day.date, unit: .day),
                        y: .value("Balance", day.value)
                    )
                    .foregroundStyle(day.value >= 0 ? DesignTokens.Colors.danger : DesignTokens.Colors.calories)
                    .cornerRadius(2)
                }

                // Zero reference line
                RuleMark(y: .value("Zero", 0))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .chartYScale(domain: .automatic(includesZero: true))
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
                        if let balance = value.as(Int.self) {
                            Text("\(balance)")
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                }
            }
            .frame(height: 200)
            .accessibilityIdentifier("energy-balance-chart")

            // Legend - shows what bar colors mean
            HStack(spacing: 16) {
                legendItem(color: DesignTokens.Colors.calories, label: "Deficit")
                legendItem(color: DesignTokens.Colors.danger, label: "Surplus")
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

    /// Current daily data based on display mode
    private var currentDailyData: [EnergyBalanceDetailData.DailyBalance] {
        displayMode == .expenditure ? data.expenditureDaily : data.targetDaily
    }

    /// Filtered daily data based on selected time period
    private var filteredDailyData: [EnergyBalanceDetailData.DailyBalance] {
        guard let startDate = selectedPeriod.startDate else {
            return currentDailyData.sorted { $0.date < $1.date }
        }
        return currentDailyData.filter { $0.date >= startDate }.sorted { $0.date < $1.date }
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
        let changes = displayMode == .expenditure ? data.expenditureChanges : data.targetChanges
        let title = displayMode == .expenditure ? "Relative to Expenditure" : "Relative to Targets"

        return DesignCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(DesignTokens.Typography.headline)

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

    private var historicalLogSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Month header
            Text(monthYearString(from: filteredDailyData.last?.date ?? Date()))
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(filteredDailyData.suffix(7).reversed()) { day in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(day.value) kcal")
                            .font(.subheadline)
                        Text(formatDate(day.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: day.value < 0 ? "arrow.down" : "arrow.up")
                        .font(.system(size: 12))
                        .foregroundColor(day.value < 0 ? .green : .red)
                    Text(day.value < 0 ? "Deficit" : "Surplus")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .accessibilityIdentifier("historical-balance-log")
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
    EnergyBalanceDetailView()
}

#Preview("Light Mode") {
    EnergyBalanceDetailView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    EnergyBalanceDetailView()
        .preferredColorScheme(.dark)
}
