//
//  EnergyBalanceDetailViewModel.swift
//  JabTracker
//
//  ViewModel for EnergyBalanceDetailView - provides energy balance history data
//  with dual-mode support (Expenditure vs Calorie Targets).
//

import Foundation
import OSLog
import SwiftData

/// ViewModel providing energy balance history data for EnergyBalanceDetailView
@MainActor
@Observable
final class EnergyBalanceDetailViewModel {

    // MARK: - Types

    /// Display mode for energy balance analysis
    enum DisplayMode: String, CaseIterable, Identifiable {
        case expenditure = "Expenditure"
        case calorieTargets = "Calorie Targets"

        var id: String { rawValue }
    }

    /// Data point for daily energy balance
    struct DailyData: Identifiable {
        let id = UUID()
        let date: Date
        let caloriesConsumed: Int
        let expenditure: Int  // TDEE
        let calorieTarget: Int

        /// Balance relative to expenditure (negative = deficit)
        var expenditureBalance: Int { caloriesConsumed - expenditure }

        /// Balance relative to target (negative = below target)
        var targetBalance: Int { caloriesConsumed - calorieTarget }
    }

    /// Balance change at a specific interval
    struct BalanceChange: Identifiable {
        let id = UUID()
        let period: String  // "3-day", "7-day", etc.
        let value: Int
        let trend: String  // "Deficit", "Surplus", "Balance", "At Target", "Below Target", "Above Target"
    }

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "EnergyBalanceDetailViewModel"
    )

    private let mealLogService: MealLogService
    private let context: ModelContext

    // MARK: - Published State

    /// Whether data is currently loading
    private(set) var isLoading: Bool = false

    /// Daily balance data points
    private(set) var dailyData: [DailyData] = []

    /// Balance changes at various intervals
    private(set) var balanceChanges: [BalanceChange] = []

    /// Date range string for display
    private(set) var dateRange: String = ""

    /// Header value (deficit in expenditure mode, average in targets mode)
    private(set) var headerValue: Int?

    /// Current display mode
    var displayMode: DisplayMode = .expenditure

    /// Selected time period for filtering
    var selectedPeriod: DetailTimePeriod = .oneYear

    /// Whether valid data exists
    var hasData: Bool {
        !dailyData.isEmpty
    }

    // MARK: - Initialization

    /// Initialize with meal log service and model context
    /// - Parameters:
    ///   - mealLogService: Service for fetching meal log data
    ///   - context: ModelContext for fetching user data
    init(mealLogService: MealLogService, context: ModelContext) {
        self.mealLogService = mealLogService
        self.context = context
    }

    // MARK: - Data Loading

    /// Load energy balance data for the selected time period and display mode
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

        // Get TDEE (required for expenditure mode)
        let tdee: Int?
        if let lastCalculated = activeGoal.lastCalculatedTDEE {
            tdee = Int(lastCalculated)
        } else if let initial = activeGoal.initialEstimatedTDEE {
            tdee = Int(initial)
        } else {
            tdee = nil
        }

        // Expenditure mode requires TDEE
        if displayMode == .expenditure && tdee == nil {
            clearAllData()
            Self.logger.debug("No TDEE available for expenditure mode")
            return
        }

        let calorieTarget = Int(activeGoal.dailyCalorieTarget)

        // Generate daily data for selected period
        await generateDailyData(tdee: tdee ?? calorieTarget, calorieTarget: calorieTarget)

        // Generate balance changes
        generateBalanceChanges(tdee: tdee ?? calorieTarget, calorieTarget: calorieTarget)

        // Generate header value
        calculateHeaderValue(tdee: tdee ?? calorieTarget, calorieTarget: calorieTarget)

        // Generate date range
        generateDateRange()

        Self.logger.debug("Loaded energy balance data: \(self.dailyData.count) days")
    }

    // MARK: - Private Methods

    /// Clear all data when requirements not met
    private func clearAllData() {
        dailyData = []
        balanceChanges = []
        dateRange = ""
        headerValue = nil
    }

    /// Generate daily data for selected period
    private func generateDailyData(tdee: Int, calorieTarget: Int) async {
        let calendar = Calendar.current
        let today = Date()

        // Get start date based on selected period
        guard let startDate = selectedPeriod.startDate ?? calendar.date(byAdding: .year, value: -1, to: today) else {
            dailyData = []
            return
        }

        var data: [DailyData] = []

        // Generate data from start date to today
        var currentDate = startDate
        while currentDate <= today {
            // Get calories consumed for this date
            let calories: Int
            do {
                let totals = try await mealLogService.getDailyTotals(for: currentDate)
                calories = Int(totals.calories)
            } catch {
                Self.logger.debug("No meal data for \(currentDate): \(error.localizedDescription)")
                calories = 0
            }

            data.append(
                DailyData(
                    date: currentDate,
                    caloriesConsumed: calories,
                    expenditure: tdee,
                    calorieTarget: calorieTarget
                ))

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        dailyData = data.sorted { $0.date < $1.date }
    }

    /// Generate balance changes at standard intervals
    private func generateBalanceChanges(tdee: Int, calorieTarget: Int) {
        let intervals: [(String, Int)] = [
            ("3-day", 3),
            ("7-day", 7),
            ("14-day", 14),
            ("30-day", 30),
            ("90-day", 90),
        ]

        balanceChanges = intervals.map { period, days in
            let balance = calculateBalanceForInterval(days: days, tdee: tdee, calorieTarget: calorieTarget)
            let trend = trendLabelForBalance(balance)
            return BalanceChange(period: period, value: balance, trend: trend)
        }
    }

    /// Calculate balance for a specific interval
    private func calculateBalanceForInterval(days: Int, tdee: Int, calorieTarget: Int) -> Int {
        let recentData = dailyData.suffix(days)
        guard !recentData.isEmpty else { return 0 }

        let totalBalance: Int
        if displayMode == .expenditure {
            totalBalance = recentData.reduce(0) { $0 + $1.expenditureBalance }
        } else {
            totalBalance = recentData.reduce(0) { $0 + $1.targetBalance }
        }

        return totalBalance
    }

    /// Get trend label for balance value based on display mode
    private func trendLabelForBalance(_ balance: Int) -> String {
        if displayMode == .expenditure {
            if balance < 0 {
                return "Deficit"
            } else if balance > 0 {
                return "Surplus"
            } else {
                return "Balance"
            }
        } else {
            if balance < 0 {
                return "Below Target"
            } else if balance > 0 {
                return "Above Target"
            } else {
                return "At Target"
            }
        }
    }

    /// Calculate header value (deficit for expenditure, average for targets)
    private func calculateHeaderValue(tdee: Int, calorieTarget: Int) {
        guard !dailyData.isEmpty else {
            headerValue = nil
            return
        }

        if displayMode == .expenditure {
            // Total deficit/surplus over period
            headerValue = dailyData.reduce(0) { $0 + $1.expenditureBalance }
        } else {
            // Average relative to target
            let total = dailyData.reduce(0) { $0 + $1.targetBalance }
            headerValue = total / dailyData.count
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

extension EnergyBalanceDetailViewModel {
    /// Preview data for SwiftUI previews
    static var preview: EnergyBalanceDetailViewModel {
        let context = PreviewHelpers.previewContext()
        let service = MealLogService(context: context)
        return EnergyBalanceDetailViewModel(mealLogService: service, context: context)
    }
}
