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
            return 0.0
        }

        // Calculate yesterday's date
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: date)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) else {
            Self.logger.error("Failed to calculate yesterday's date")
            return 0.0
        }

        // Fetch yesterday's consumption
        let consumed: Double
        do {
            let totals = try await nutritionDataSource.getDailyTotals(for: yesterday)
            consumed = totals.calories
        } catch {
            Self.logger.error("Failed to fetch yesterday's nutrition: \(error.localizedDescription)")
            return 0.0
        }

        // Get yesterday's base target (not adjusted to avoid recursion)
        let baseTarget = nutritionDataSource.getBaseCalorieTarget(for: user, on: yesterday)

        // Calculate unused calories
        let unused = baseTarget - consumed

        // Return capped rollover (0 to maxRollover)
        let rollover = min(max(unused, 0), Self.maxRollover)

        if rollover > 0 {
            Self.logger.info("Rollover: \(rollover) kcal (target: \(baseTarget), consumed: \(consumed))")
        }

        return rollover
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
