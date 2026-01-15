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
    private let dayStatusService: DayStatusService?
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

    /// Error message if data loading failed
    private(set) var loadingError: String?

    /// Whether fallback TDEE is being used (no calculated TDEE exists)
    private(set) var isUsingFallbackTDEE: Bool = false

    /// Whether historical TDEE snapshots failed to load
    private(set) var tdeeSnapshotLoadFailed: Bool = false

    /// Whether valid data exists
    var hasData: Bool {
        !dailyData.isEmpty
    }

    // MARK: - Initialization

    /// Initialize with meal log service, TDEE service, and model context
    /// - Parameters:
    ///   - mealLogService: Service for fetching meal log data
    ///   - tdeeService: Service for fetching TDEE snapshots
    ///   - dayStatusService: Service for fasting status (optional for backward compat)
    ///   - context: ModelContext for fetching user data
    init(
        mealLogService: MealLogService,
        tdeeService: TDEEService,
        dayStatusService: DayStatusService? = nil,
        context: ModelContext
    ) {
        self.mealLogService = mealLogService
        self.tdeeService = tdeeService
        self.dayStatusService = dayStatusService
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
            isUsingFallbackTDEE = false
        } else if let initial = activeGoal.initialEstimatedTDEE {
            fallbackTDEE = Int(initial)
            isUsingFallbackTDEE = false
        } else {
            fallbackTDEE = 2000  // Reasonable default
            isUsingFallbackTDEE = true
            Self.logger.warning("No TDEE available, using default 2000 kcal - user should complete setup")
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
        loadingError = nil
        isUsingFallbackTDEE = false
        tdeeSnapshotLoadFailed = false
    }

    /// Generate daily data for selected period
    /// - Note: Excludes today (partial data) and days without food entries or fasting status
    private func generateDailyData(fallbackTDEE: Int, calorieTarget: Int) async {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        let startDate = await calculateStartDate(todayStart: todayStart, calendar: calendar)
        let meaningfulDates = await getMeaningfulDates(from: startDate, to: todayStart)
        let tdeeByDate = loadTDEESnapshots(from: startDate, to: todayStart, calendar: calendar)

        var data: [DailyData] = []
        var currentDate = startDate
        while currentDate < todayStart {
            let dayStart = calendar.startOfDay(for: currentDate)

            if meaningfulDates.contains(dayStart) {
                if let dayData = await loadDayData(
                    date: dayStart, fallbackTDEE: fallbackTDEE, calorieTarget: calorieTarget, tdeeByDate: tdeeByDate
                ) {
                    data.append(dayData)
                }
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        dailyData = data.sorted { $0.date < $1.date }
        Self.logger.debug("Generated \(data.count) days from \(meaningfulDates.count) meaningful dates")
    }

    /// Calculate start date based on selected period
    private func calculateStartDate(todayStart: Date, calendar: Calendar) async -> Date {
        if let periodStart = selectedPeriod.startDate {
            return calendar.startOfDay(for: periodStart)
        }
        let earliestDate = await getEarliestFoodEntryDate()
        return earliestDate
            ?? calendar.startOfDay(
                for: calendar.date(byAdding: .year, value: -1, to: todayStart) ?? todayStart
            )
    }

    /// Get dates with meaningful data from the service
    private func getMeaningfulDates(from startDate: Date, to endDate: Date) async -> Set<Date> {
        do {
            return try await mealLogService.getDatesWithMeaningfulData(
                from: startDate, to: endDate, dayStatusService: dayStatusService
            )
        } catch {
            Self.logger.error("Failed to get meaningful dates: \(error.localizedDescription)")
            return []
        }
    }

    /// Load TDEE snapshots and create date-to-value mapping
    private func loadTDEESnapshots(from startDate: Date, to endDate: Date, calendar: Calendar) -> [Date: Int] {
        var tdeeByDate: [Date: Int] = [:]
        do {
            let snapshots = try tdeeService.getTDEESnapshots(from: startDate, to: endDate)
            for snapshot in snapshots {
                let dayStart = calendar.startOfDay(for: snapshot.timestamp)
                tdeeByDate[dayStart] = Int(snapshot.tdeeValue)
            }
            Self.logger.debug("Loaded \(snapshots.count) TDEE snapshots for energy balance")
        } catch {
            Self.logger.error("Failed to load TDEE snapshots: \(error.localizedDescription)")
            tdeeSnapshotLoadFailed = true
            loadingError = "Unable to load historical expenditure data. Using current TDEE estimate."
        }
        return tdeeByDate
    }

    /// Load data for a single day
    private func loadDayData(
        date: Date, fallbackTDEE: Int, calorieTarget: Int, tdeeByDate: [Date: Int]
    ) async -> DailyData? {
        do {
            let totals = try await mealLogService.getDailyTotals(for: date)
            let calories = Int(totals.calories)
            let expenditure = tdeeByDate[date] ?? fallbackTDEE
            return DailyData(
                date: date, caloriesConsumed: calories, expenditure: expenditure, calorieTarget: calorieTarget)
        } catch {
            Self.logger.error("Failed to load day data for \(date): \(error.localizedDescription)")
            return nil
        }
    }

    /// Get the earliest date with a food entry
    private func getEarliestFoodEntryDate() async -> Date? {
        let descriptor = FetchDescriptor<FoodEntry>(
            sortBy: [SortDescriptor(\.loggedAt, order: .forward)]
        )
        var limitedDescriptor = descriptor
        limitedDescriptor.fetchLimit = 1

        do {
            let entries = try context.fetch(limitedDescriptor)
            if let earliest = entries.first {
                return Calendar.current.startOfDay(for: earliest.loggedAt)
            }
        } catch {
            Self.logger.error("Failed to fetch earliest food entry: \(error.localizedDescription)")
            // Note: returning nil here will cause fallback to 1-year default
            // The UI should handle this gracefully
        }
        return nil
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
