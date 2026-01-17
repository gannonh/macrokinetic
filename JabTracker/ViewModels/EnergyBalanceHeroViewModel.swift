//
//  EnergyBalanceHeroViewModel.swift
//  JabTracker
//
//  ViewModel for EnergyBalanceHeroWidget - provides 30-day energy balance data
//  with daily expenditure from TDEESnapshots.
//

import Foundation
import OSLog
import SwiftData

/// Data point for daily calorie chart with expenditure
struct DayCalories: Identifiable {
    /// Use date as stable identifier for animation continuity
    var id: Date { date }
    let date: Date
    let value: Double
    /// Daily expenditure from TDEESnapshot (varies per day)
    let expenditure: Double
    /// Daily calorie target (fixed from NutritionGoal)
    let target: Double
}

/// ViewModel providing 30-day energy balance data for EnergyBalanceHeroWidget
@MainActor
@Observable
final class EnergyBalanceHeroViewModel {

    // MARK: - Properties

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "EnergyBalanceHeroViewModel"
    )

    private let mealLogService: MealLogService
    private let tdeeService: TDEEService
    private let dayStatusService: DayStatusService?
    private let context: ModelContext

    /// Number of days to look back (excludes today)
    private let dayCount = 30

    // MARK: - Published State

    /// Whether data is currently loading
    private(set) var isLoading: Bool = false

    /// Daily calories for each of the last 30 days (includes per-day expenditure from TDEESnapshots)
    private(set) var dailyCalories: [DayCalories] = []

    /// Average daily expenditure (TDEE) - computed from dailyCalories
    var averageExpenditure: Double {
        guard !dailyCalories.isEmpty else { return 2000 }
        return dailyCalories.map(\.expenditure).reduce(0, +) / Double(dailyCalories.count)
    }

    /// Average daily calorie target - computed from dailyCalories
    var averageTargets: Double {
        guard !dailyCalories.isEmpty else { return 1800 }
        return dailyCalories.map(\.target).reduce(0, +) / Double(dailyCalories.count)
    }

    /// Total nutrition (sum of all daily calories)
    private(set) var totalNutrition: Int = 0

    /// Number of days with meaningful data (for average calculations)
    var actualDayCount: Int {
        dailyCalories.count
    }

    /// Number of days that failed to load (data may be incomplete)
    private(set) var daysWithLoadingErrors: Int = 0

    /// Whether fallback TDEE is being used (no calculated TDEE exists)
    private(set) var isUsingFallbackTDEE: Bool = false

    /// Error message if significant loading issues occurred
    private(set) var loadingError: String?

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

    /// Load 30 days of energy balance data with per-day TDEESnapshot values
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Get user and active nutrition goal for fallback values and target
        guard let user = context.fetchCurrentUser(logger: Self.logger),
            let activeGoal = user.activeNutritionGoal
        else {
            Self.logger.debug("No user or active nutrition goal found")
            return
        }

        // Get fallback TDEE (used when no snapshot exists for a date)
        let fallbackTDEE: Double
        if let lastCalculated = activeGoal.lastCalculatedTDEE {
            fallbackTDEE = lastCalculated
            isUsingFallbackTDEE = false
        } else if let initial = activeGoal.initialEstimatedTDEE {
            fallbackTDEE = initial
            isUsingFallbackTDEE = false
        } else {
            fallbackTDEE = 2000  // Reasonable default
            isUsingFallbackTDEE = true
            Self.logger.warning("No TDEE available, using default 2000 kcal - user should complete setup")
        }

        let calorieTarget = activeGoal.dailyCalorieTarget

        // Load daily calorie data with TDEESnapshot expenditure
        await loadDailyCalories(fallbackTDEE: fallbackTDEE, calorieTarget: calorieTarget)

        Self.logger.debug(
            """
            Loaded energy balance: total=\(self.totalNutrition), \
            exp=\(Int(self.averageExpenditure)), target=\(Int(self.averageTargets))
            """
        )
    }

    /// Load daily calorie totals for the last 30 days with per-day TDEESnapshot values
    /// - Note: Excludes today (partial data) and days without food entries or fasting status
    private func loadDailyCalories(fallbackTDEE: Double, calorieTarget: Double) async {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())

        guard let startDate = calendar.date(byAdding: .day, value: -dayCount, to: todayStart) else {
            return
        }

        let meaningfulDates = await getMeaningfulDates(from: startDate, to: todayStart)
        let tdeeByDate = loadTDEESnapshots(from: startDate, to: todayStart)

        var newDailyCalories: [DayCalories] = []
        var newTotalNutrition = 0
        var failedDays = 0

        // Load data for each day (oldest to newest), excluding today
        for daysAgo in (1...dayCount).reversed() {
            guard let dayDate = calendar.date(byAdding: .day, value: -daysAgo, to: todayStart) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: dayDate)
            guard meaningfulDates.contains(dayStart) else { continue }

            let dayExpenditure = tdeeByDate[dayStart] ?? fallbackTDEE

            do {
                let totals = try await mealLogService.getDailyTotals(for: dayDate)
                let calories = totals.calories
                newDailyCalories.append(
                    DayCalories(date: dayDate, value: calories, expenditure: dayExpenditure, target: calorieTarget)
                )
                newTotalNutrition += Int(calories)
            } catch {
                Self.logger.error("Failed to load totals for day \(-daysAgo): \(error.localizedDescription)")
                failedDays += 1
            }
        }

        updateResults(
            dailyCalories: newDailyCalories,
            totalNutrition: newTotalNutrition,
            failedDays: failedDays
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
    private func loadTDEESnapshots(from startDate: Date, to endDate: Date) -> [Date: Double] {
        let calendar = Calendar.current
        var tdeeByDate: [Date: Double] = [:]
        do {
            let snapshots = try tdeeService.getTDEESnapshots(from: startDate, to: endDate)
            for snapshot in snapshots {
                let dayStart = calendar.startOfDay(for: snapshot.timestamp)
                tdeeByDate[dayStart] = snapshot.tdeeValue
            }
            Self.logger.debug("Loaded \(snapshots.count) TDEE snapshots")
        } catch {
            Self.logger.error("Failed to load TDEE snapshots: \(error.localizedDescription)")
            loadingError = "Unable to load historical expenditure data."
        }
        return tdeeByDate
    }

    /// Update published results from calculated values
    private func updateResults(dailyCalories: [DayCalories], totalNutrition: Int, failedDays: Int) {
        self.dailyCalories = dailyCalories
        self.totalNutrition = totalNutrition
        self.daysWithLoadingErrors = failedDays

        if failedDays > 0 {
            loadingError = "\(failedDays) day(s) could not be loaded. Data may be incomplete."
        }

        Self.logger.debug("Loaded \(dailyCalories.count)/\(self.dayCount) meaningful days")
    }

}

// MARK: - Preview Support

extension EnergyBalanceHeroViewModel {
    /// Preview data for SwiftUI previews
    static var preview: EnergyBalanceHeroViewModel {
        let context = PreviewHelpers.previewContext()
        let mealLogService = MealLogService(context: context)
        let tdeeService = TDEEService(context: context)
        return EnergyBalanceHeroViewModel(
            mealLogService: mealLogService,
            tdeeService: tdeeService,
            context: context
        )
    }
}
