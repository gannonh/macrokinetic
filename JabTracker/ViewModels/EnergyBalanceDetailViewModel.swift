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
    private let tdeeService: TDEEService
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

    /// Initialize with meal log service, TDEE service, and model context
    /// - Parameters:
    ///   - mealLogService: Service for fetching meal log data
    ///   - tdeeService: Service for fetching TDEE snapshots
    ///   - context: ModelContext for fetching user data
    init(mealLogService: MealLogService, tdeeService: TDEEService, context: ModelContext) {
        self.mealLogService = mealLogService
        self.tdeeService = tdeeService
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

        // Get fallback TDEE (used when no snapshot exists for a date)
        let fallbackTDEE: Int
        if let lastCalculated = activeGoal.lastCalculatedTDEE {
            fallbackTDEE = Int(lastCalculated)
        } else if let initial = activeGoal.initialEstimatedTDEE {
            fallbackTDEE = Int(initial)
        } else {
            fallbackTDEE = 2000  // Reasonable default
        }

        let calorieTarget = Int(activeGoal.dailyCalorieTarget)

        // Generate daily data (only days with actual food logged)
        await generateDailyData(fallbackTDEE: fallbackTDEE, calorieTarget: calorieTarget)

        // Generate balance changes (only from days with data)
        generateBalanceChanges()

        // Generate header value (only from days with data)
        calculateHeaderValue()

        // Generate date range (from actual data, not selected period)
        generateDateRange()

        Self.logger.debug("Loaded energy balance data: \(self.dailyData.count) days with actual food logs")
    }

    // MARK: - Private Methods

    /// Clear all data when requirements not met
    private func clearAllData() {
        dailyData = []
        balanceChanges = []
        dateRange = ""
        headerValue = nil
    }

    /// Generate daily data for selected period (only days with actual food logged)
    private func generateDailyData(fallbackTDEE: Int, calorieTarget: Int) async {
        let calendar = Calendar.current
        let today = Date()

        // Get start date based on selected period
        guard let startDate = selectedPeriod.startDate ?? calendar.date(byAdding: .year, value: -1, to: today) else {
            dailyData = []
            return
        }

        // Load TDEE snapshots for the period to get historical expenditure values
        var tdeeByDate: [Date: Int] = [:]
        do {
            let snapshots = try tdeeService.getTDEESnapshots(from: startDate, to: today)
            for snapshot in snapshots {
                let dayStart = calendar.startOfDay(for: snapshot.timestamp)
                tdeeByDate[dayStart] = Int(snapshot.tdeeValue)
            }
            Self.logger.debug("Loaded \(snapshots.count) TDEE snapshots for energy balance")
        } catch {
            Self.logger.error("Failed to load TDEE snapshots: \(error)")
        }

        var data: [DailyData] = []

        // Generate data from start date to today (only include days with food logged)
        var currentDate = startDate
        while currentDate <= today {
            let dayStart = calendar.startOfDay(for: currentDate)

            // Get calories consumed for this date
            do {
                let totals = try await mealLogService.getDailyTotals(for: currentDate)
                let calories = Int(totals.calories)

                // Only include days where food was actually logged
                if calories > 0 {
                    // Use historical TDEE if available, otherwise fallback
                    let expenditure = tdeeByDate[dayStart] ?? fallbackTDEE

                    data.append(
                        DailyData(
                            date: currentDate,
                            caloriesConsumed: calories,
                            expenditure: expenditure,
                            calorieTarget: calorieTarget
                        ))
                }
            } catch {
                // No data for this day - skip it
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        dailyData = data.sorted { $0.date < $1.date }
    }

    /// Generate balance changes at standard intervals (only using days with actual data)
    private func generateBalanceChanges() {
        // Only show intervals where we have enough data
        let totalDays = dailyData.count
        var intervals: [(String, Int)] = []

        // Add intervals based on available data
        if totalDays >= 3 { intervals.append(("3-day", 3)) }
        if totalDays >= 7 { intervals.append(("7-day", 7)) }
        if totalDays >= 14 { intervals.append(("14-day", 14)) }
        if totalDays >= 30 { intervals.append(("30-day", 30)) }
        if totalDays >= 90 { intervals.append(("90-day", 90)) }

        balanceChanges = intervals.map { period, days in
            let balance = calculateBalanceForInterval(days: days)
            let trend = trendLabelForBalance(balance)
            return BalanceChange(period: period, value: balance, trend: trend)
        }
    }

    /// Calculate AVERAGE daily balance for a specific interval (using most recent N days with data)
    private func calculateBalanceForInterval(days: Int) -> Int {
        let recentData = dailyData.suffix(days)
        guard !recentData.isEmpty else { return 0 }

        let totalBalance: Int
        if displayMode == .expenditure {
            totalBalance = recentData.reduce(0) { $0 + $1.expenditureBalance }
        } else {
            totalBalance = recentData.reduce(0) { $0 + $1.targetBalance }
        }

        // Return AVERAGE daily balance, not cumulative
        return totalBalance / recentData.count
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

    /// Calculate header value (AVERAGE daily deficit for expenditure, AVERAGE relative to targets)
    /// Only uses days with actual food data
    private func calculateHeaderValue() {
        guard !dailyData.isEmpty else {
            headerValue = nil
            return
        }

        if displayMode == .expenditure {
            // AVERAGE daily deficit/surplus over days with data
            let total = dailyData.reduce(0) { $0 + $1.expenditureBalance }
            headerValue = total / dailyData.count
        } else {
            // AVERAGE daily balance relative to target over days with data
            let total = dailyData.reduce(0) { $0 + $1.targetBalance }
            headerValue = total / dailyData.count
        }
    }

    /// Generate date range string based on actual data (not selected period)
    private func generateDateRange() {
        guard !dailyData.isEmpty else {
            dateRange = ""
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"

        let startDate = dailyData.first!.date
        let endDate = dailyData.last!.date

        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            dateRange = formatter.string(from: startDate)
        } else {
            dateRange = "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
}

// MARK: - Preview Support

extension EnergyBalanceDetailViewModel {
    /// Preview data for SwiftUI previews
    static var preview: EnergyBalanceDetailViewModel {
        let context = PreviewHelpers.previewContext()
        let mealLogService = MealLogService(context: context)
        let tdeeService = TDEEService(context: context)
        return EnergyBalanceDetailViewModel(
            mealLogService: mealLogService,
            tdeeService: tdeeService,
            context: context
        )
    }
}
