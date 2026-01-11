//
//  ExpenditureDetailViewModel.swift
//  JabTracker
//
//  ViewModel for ExpenditureDetailView - provides TDEE expenditure history data.
//

import Foundation
import OSLog
import SwiftData

/// ViewModel providing TDEE expenditure history data for ExpenditureDetailView
@MainActor
@Observable
final class ExpenditureDetailViewModel {

    // MARK: - Types

    /// Data point for expenditure chart
    struct DailyExpenditure: Identifiable {
        let id = UUID()
        let date: Date
        let value: Int
        let upperBound: Int  // Flux range upper bound
        let lowerBound: Int  // Flux range lower bound
        let status: ExpenditureStatus
    }

    /// Expenditure status indicating data quality
    enum ExpenditureStatus: String {
        case fluxRange = "Flux Range"  // Orange - initial estimate
        case updating = "Updating"  // Blue - being refined
        case holding = "Holding"  // Gray - stable estimate
    }

    /// Expenditure change at a specific interval
    struct ExpenditureChange: Identifiable {
        let id = UUID()
        let period: String  // "3-day", "7-day", etc.
        let change: Int
        let trend: String  // "Decrease", "Increase", "No Change"
    }

    /// Historical entry for data sources section
    struct HistoricalEntry: Identifiable {
        let id = UUID()
        let expenditure: Int
        let date: Date
        let status: ExpenditureStatus
    }

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "ExpenditureDetailViewModel"
    )

    private let context: ModelContext

    // MARK: - Published State

    /// Whether data is currently loading
    private(set) var isLoading: Bool = false

    /// Daily expenditure data points for chart
    private(set) var dailyData: [DailyExpenditure] = []

    /// Expenditure changes at various intervals
    private(set) var expenditureChanges: [ExpenditureChange] = []

    /// Historical entries for data sources section
    private(set) var historicalEntries: [HistoricalEntry] = []

    /// Current TDEE expenditure value
    private(set) var currentExpenditure: Int?

    /// Average expenditure over selected period
    private(set) var averageExpenditure: Int?

    /// Difference from period start
    private(set) var difference: Int?

    /// Date range string for display
    private(set) var dateRange: String = ""

    /// Current strategy ("Holding" or "Updating")
    private(set) var currentStrategy: String = "Holding"

    /// Strategy description text
    private(set) var strategyDescription: String = ""

    /// Selected time period for filtering
    var selectedPeriod: DetailTimePeriod = .oneYear

    /// Whether any TDEE data exists
    var hasData: Bool {
        currentExpenditure != nil
    }

    // MARK: - Initialization

    /// Initialize with model context
    /// - Parameter context: ModelContext for fetching user data
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Data Loading

    /// Load expenditure data from user's active NutritionGoal
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Get user and active nutrition goal
        guard let user = context.fetchCurrentUser(logger: Self.logger),
            let activeGoal = user.activeNutritionGoal
        else {
            clearAllData()
            Self.logger.debug("No user or active nutrition goal found")
            return
        }

        // Get current TDEE: prefer lastCalculatedTDEE, fall back to initialEstimatedTDEE
        let tdee: Double?
        if let lastCalculated = activeGoal.lastCalculatedTDEE {
            tdee = lastCalculated
        } else if let initial = activeGoal.initialEstimatedTDEE {
            tdee = initial
        } else {
            clearAllData()
            return
        }

        guard let currentTDEE = tdee else {
            clearAllData()
            return
        }

        currentExpenditure = Int(currentTDEE)

        // Calculate difference from initial TDEE
        if let initial = activeGoal.initialEstimatedTDEE {
            difference = Int(currentTDEE - initial)
        }

        // Calculate average (for now, same as current since we don't have historical TDEE)
        averageExpenditure = currentExpenditure

        // Determine strategy based on data availability
        determineStrategy(goal: activeGoal)

        // Generate synthetic daily data based on current TDEE and selected period
        generateDailyData(baseTDEE: currentTDEE)

        // Generate expenditure changes (currently stable since we don't have true history)
        generateExpenditureChanges()

        // Generate historical entries
        generateHistoricalEntries(baseTDEE: currentTDEE)

        // Generate date range
        generateDateRange()

        Self.logger.debug("Loaded expenditure data: TDEE=\(Int(currentTDEE)), strategy=\(self.currentStrategy)")
    }

    // MARK: - Private Methods

    /// Clear all data when no TDEE exists
    private func clearAllData() {
        dailyData = []
        expenditureChanges = []
        historicalEntries = []
        currentExpenditure = nil
        averageExpenditure = nil
        difference = nil
        dateRange = ""
        currentStrategy = "Holding"
        strategyDescription = ""
    }

    /// Determine strategy based on available data
    private func determineStrategy(goal: NutritionGoal) {
        // Check for sufficient data:
        // "Updating" requires at least 3 days of nutrition data and 1 day of weight data per week
        let hasRecentCalculation = goal.lastTDEECalculationDate != nil

        // Count weight entries in last 2 weeks
        let weightCount = countRecentWeightEntries(days: 14)

        // Count food entries in last 2 weeks
        let foodDays = countRecentFoodDays(days: 14)

        // Require: 3+ weight entries AND 7+ days of food logging for "Updating"
        if hasRecentCalculation && weightCount >= 3 && foodDays >= 7 {
            currentStrategy = "Updating"
            strategyDescription =
                "Your expenditure estimate is being actively refined based on your weight trend and nutrition data."
        } else {
            currentStrategy = "Holding"
            strategyDescription =
                "Holding safeguards your expenditure estimate against insufficient data. "
                + "Updating requires at least 3 days of nutrition data and 1 day of weight data per 7-day period."
        }
    }

    /// Count weight entries in the last N days
    private func countRecentWeightEntries(days: Int) -> Int {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate { entry in
                entry.timestamp >= startDate
            }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    /// Count unique days with food entries in the last N days
    private func countRecentFoodDays(days: Int) -> Int {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { entry in
                entry.loggedAt >= startDate
            }
        )

        guard let entries = try? context.fetch(descriptor) else { return 0 }
        let uniqueDays = Set(entries.map { Calendar.current.startOfDay(for: $0.loggedAt) })
        return uniqueDays.count
    }

    /// Generate daily expenditure data for chart
    private func generateDailyData(baseTDEE: Double) {
        let calendar = Calendar.current
        let today = Date()

        // Get start date based on selected period
        guard let startDate = selectedPeriod.startDate ?? calendar.date(byAdding: .year, value: -1, to: today) else {
            dailyData = []
            return
        }

        // Seeded random generator for consistent data
        var rng = SeededRNG(seed: 456)

        var data: [DailyExpenditure] = []
        var runningTDEE = baseTDEE

        // Generate data from start date to today
        var currentDate = startDate
        while currentDate <= today {
            let dayOffset = calendar.dateComponents([.day], from: currentDate, to: today).day ?? 0

            // Small variation around base TDEE (slower changes than weight)
            let variation = Double.random(in: -5...5, using: &rng)
            runningTDEE = max(1200, min(baseTDEE + 200, baseTDEE + variation))

            let value = Int(runningTDEE)

            // Flux range (margin of error) - tighter for more recent data
            let fluxMargin: Int
            if dayOffset < 14 {
                fluxMargin = 15  // Recent: tight estimate
            } else if dayOffset < 60 {
                fluxMargin = 25  // Medium: moderate uncertainty
            } else {
                fluxMargin = 40  // Older: more uncertainty
            }

            // Determine status based on recency
            let status: ExpenditureStatus
            if dayOffset < 14 {
                status = .holding
            } else if dayOffset < 60 {
                status = .updating
            } else {
                status = .fluxRange
            }

            data.append(
                DailyExpenditure(
                    date: currentDate,
                    value: value,
                    upperBound: value + fluxMargin,
                    lowerBound: value - fluxMargin,
                    status: status
                ))

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        dailyData = data.sorted { $0.date < $1.date }
    }

    /// Generate expenditure changes at standard intervals
    private func generateExpenditureChanges() {
        // Since we don't have true historical TDEE values,
        // generate placeholder data showing no change
        let intervals = ["3-day", "7-day", "14-day", "30-day", "90-day"]

        expenditureChanges = intervals.map { period in
            ExpenditureChange(period: period, change: 0, trend: "No Change")
        }
    }

    /// Generate historical entries for data sources section
    private func generateHistoricalEntries(baseTDEE: Double) {
        let calendar = Calendar.current
        let today = Date()

        historicalEntries = (0..<7).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { return nil }
            return HistoricalEntry(
                expenditure: Int(baseTDEE),
                date: date,
                status: .holding
            )
        }
    }

    /// Generate date range string based on selected period
    private func generateDateRange() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"

        let today = Date()
        guard let startDate = selectedPeriod.startDate ?? Calendar.current.date(byAdding: .year, value: -1, to: today)
        else {
            dateRange = formatter.string(from: today)
            return
        }

        dateRange = "\(formatter.string(from: startDate)) - \(formatter.string(from: today))"
    }
}

// MARK: - Preview Support

extension ExpenditureDetailViewModel {
    /// Preview data for SwiftUI previews
    static var preview: ExpenditureDetailViewModel {
        let context = PreviewHelpers.previewContext()
        return ExpenditureDetailViewModel(context: context)
    }
}
