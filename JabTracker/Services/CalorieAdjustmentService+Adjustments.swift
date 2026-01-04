//
//  CalorieAdjustmentService+Adjustments.swift
//  JabTracker
//
//  Adjustment pipeline for calorie target modifications (rollover, predictive).
//

import Foundation
import OSLog

// MARK: - Protocols

/// Protocol for calorie adjustment providers (rollover, predictive activity)
protocol CalorieAdjustmentProvider {
    /// Calculate the calorie adjustment to add to the base target
    /// - Parameters:
    ///   - user: The user to calculate for
    ///   - date: The date to calculate for
    /// - Returns: Adjustment in kcal to add (always non-negative)
    @MainActor func calculateAdjustment(for user: User, on date: Date) async -> Double
}

/// Protocol for nutrition data retrieval, enabling testability via dependency injection
protocol NutritionDataSource {
    /// Get daily nutrition totals for a specific date
    @MainActor func getDailyTotals(for date: Date) async throws -> DailyNutritionTotals

    /// Get base calorie target (not adjusted) for a user on a date
    @MainActor func getBaseCalorieTarget(for user: User, on date: Date) -> Double
}

// MARK: - Rollover Calorie Provider

/// Provides rollover calorie adjustment based on yesterday's unused calories
/// Cap: Maximum 200 kcal rollover
@MainActor
final class RolloverCalorieProvider: CalorieAdjustmentProvider {
    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "RolloverCalorieProvider"
    )

    /// Maximum calories that can roll over from yesterday
    private static let maxRollover: Double = 200.0

    private let nutritionDataSource: NutritionDataSource

    init(nutritionDataSource: NutritionDataSource) {
        self.nutritionDataSource = nutritionDataSource
    }

    func calculateAdjustment(for user: User, on date: Date) async -> Double {
        // Check feature flag
        guard user.rolloverCaloriesEnabled else {
            Self.logger.debug("Rollover disabled for user")
            return 0.0
        }

        // Calculate yesterday's date
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) else {
            Self.logger.error("Failed to calculate yesterday's date")
            return 0.0
        }

        Self.logger.debug("Calculating rollover for date: \(date), yesterday: \(yesterday)")

        // Fetch yesterday's consumption
        let consumed: Double
        do {
            let totals = try await nutritionDataSource.getDailyTotals(for: yesterday)
            consumed = totals.calories
            Self.logger.debug("Yesterday's consumed calories: \(consumed)")
        } catch {
            Self.logger.error("Failed to fetch yesterday's nutrition: \(error.localizedDescription)")
            return 0.0
        }

        // Get yesterday's base target (not adjusted to avoid recursion)
        let baseTarget = nutritionDataSource.getBaseCalorieTarget(for: user, on: yesterday)
        Self.logger.debug("Yesterday's base target: \(baseTarget)")

        // Calculate unused calories
        let unused = baseTarget - consumed
        Self.logger.debug("Unused calories: \(unused)")

        // Return capped rollover (0 to maxRollover)
        let rollover = min(max(unused, 0), Self.maxRollover)
        Self.logger.info(
            "Rollover result: \(rollover) kcal (target: \(baseTarget), consumed: \(consumed), unused: \(unused))")

        return rollover
    }
}

// MARK: - Predictive Activity Provider

/// Provides predictive calorie adjustment based on 7-day activity average
/// Applies goal-type multipliers: weightLoss=0.8, maintenance=1.0, muscleGain=1.2
@MainActor
final class PredictiveActivityProvider: CalorieAdjustmentProvider {
    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "PredictiveActivityProvider"
    )

    private let activeEnergyDataSource: ActiveEnergyDataSource

    init(activeEnergyDataSource: ActiveEnergyDataSource) {
        self.activeEnergyDataSource = activeEnergyDataSource
    }

    func calculateAdjustment(for user: User, on date: Date) async -> Double {
        // Check feature flag
        guard user.predictiveActivityEnabled else {
            Self.logger.debug("Predictive activity disabled for user")
            return 0.0
        }

        // Skip predictive when burned calories is enabled to avoid double-counting
        // (Burned adds today's actual; predictive uses 7-day avg which may include today)
        guard !user.addBurnedCaloriesEnabled else {
            Self.logger.debug("Skipping predictive - burned calories enabled (avoids double-counting)")
            return 0.0
        }

        // Get 7-day history ending the day before the specified date
        // This prevents overlap when calculating for today with today's data
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)
        guard let endDate = calendar.date(byAdding: .day, value: -1, to: startOfDate) else {
            Self.logger.error("Failed to calculate end date for history")
            return 0.0
        }

        let history = await getHistoryWindow(ending: endDate, days: 7)
        guard !history.isEmpty else {
            Self.logger.debug("No activity history available")
            return 0.0
        }

        // Calculate average
        let total = history.values.reduce(0, +)
        let average = total / Double(history.count)
        Self.logger.debug("7-day activity average: \(average) kcal from \(history.count) days")

        // Apply goal-type multiplier
        let multiplier = getGoalMultiplier(for: user)
        let adjustment = average * multiplier

        Self.logger.info(
            "Predictive adjustment: \(adjustment) kcal (avg: \(average), multiplier: \(multiplier))")

        return adjustment
    }

    private func getGoalMultiplier(for user: User) -> Double {
        guard let goal = user.activeNutritionGoal else {
            Self.logger.debug("No active goal, using maintenance multiplier (1.0)")
            return 1.0
        }

        switch goal.goalType {
        case .weightLoss:
            return 0.8
        case .maintenance:
            return 1.0
        case .muscleGain:
            return 1.2
        }
    }

    /// Get activity history for a window of days ending on a specific date
    /// - Parameters:
    ///   - endDate: The last date to include in the window
    ///   - days: Number of days to include
    /// - Returns: Dictionary of date -> energy values for the window
    private func getHistoryWindow(ending endDate: Date, days: Int) async -> [Date: Double] {
        let calendar = Calendar.current
        let endDay = calendar.startOfDay(for: endDate)

        // Get full history from data source
        let fullHistory = await activeEnergyDataSource.getActiveEnergyHistory(days: days + 7)

        // Filter to only dates within our window
        var windowHistory: [Date: Double] = [:]
        for offset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: -offset, to: endDay) else { continue }
            let targetDay = calendar.startOfDay(for: targetDate)
            if let energy = fullHistory[targetDay] {
                windowHistory[targetDay] = energy
            }
        }

        return windowHistory
    }
}

// MARK: - Default Implementation

/// Default implementation bridging to MealLogService
@MainActor
final class MealLogNutritionDataSource: NutritionDataSource {
    private let mealLogService: MealLogService

    init(mealLogService: MealLogService) {
        self.mealLogService = mealLogService
    }

    func getDailyTotals(for date: Date) async throws -> DailyNutritionTotals {
        try await mealLogService.getDailyTotals(for: date)
    }

    func getBaseCalorieTarget(for user: User, on date: Date) -> Double {
        // Use macroTargetsForDate which checks active goal first, then falls back to user defaults
        // This returns BASE target without adjustments (burned calories, rollover)
        user.macroTargetsForDate(date).calories
    }
}
