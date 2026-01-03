//
//  CalorieAdjustmentService.swift
//  JabTracker
//
//  Service for calculating adjusted calorie targets based on activity.
//

import Foundation

/// Breakdown of calorie adjustments for UI display
struct CalorieAdjustmentBreakdown {
    let burnedCalories: Double
    let rolloverCalories: Double

    var totalAdjustment: Double {
        burnedCalories + rolloverCalories
    }
}

/// Service responsible for calculating daily calorie targets with optional activity adjustments
@MainActor
final class CalorieAdjustmentService {

    private let activeEnergyDataSource: ActiveEnergyDataSource
    private var rolloverProvider: RolloverCalorieProvider?

    /// Initialize with a data source
    /// - Parameter activeEnergyDataSource: Source for active energy data. Defaults to HealthKit-backed implementation.
    init(activeEnergyDataSource: ActiveEnergyDataSource = HealthKitActiveEnergyDataSource()) {
        self.activeEnergyDataSource = activeEnergyDataSource
    }

    /// Configure rollover provider with MealLogService
    /// Must be called before rollover calculations will work
    /// - Parameter mealLogService: The meal log service for nutrition data
    func configureRolloverProvider(mealLogService: MealLogService) {
        let dataSource = MealLogNutritionDataSource(mealLogService: mealLogService)
        self.rolloverProvider = RolloverCalorieProvider(nutritionDataSource: dataSource)
    }

    /// Calculate the adjusted daily calorie target for a user
    /// Includes burned calories and rollover adjustments based on user preferences
    /// - Parameters:
    ///   - user: The user to calculate for
    ///   - date: The date to calculate for
    ///   - baseTarget: The base calorie target (e.g. from nutrition goal)
    /// - Returns: Adjusted calorie target
    func getAdjustedCalorieTarget(for user: User, on date: Date, baseTarget: Double) async -> Double {
        var adjusted = baseTarget

        // Add burned calories if enabled
        if user.addBurnedCaloriesEnabled {
            let activeEnergy = await getActiveEnergy(for: date)
            adjusted += activeEnergy ?? 0.0
        }

        // Add rollover if enabled and provider configured
        if let provider = rolloverProvider {
            let rollover = await provider.calculateAdjustment(for: user, on: date)
            adjusted += rollover
        }

        return adjusted
    }

    /// Get detailed breakdown of calorie adjustments
    /// - Parameters:
    ///   - user: The user to calculate for
    ///   - date: The date to calculate for
    /// - Returns: Breakdown of burned and rollover calories
    func getAdjustmentBreakdown(for user: User, on date: Date) async -> CalorieAdjustmentBreakdown {
        var burnedCalories = 0.0
        var rolloverCalories = 0.0

        // Get burned calories if enabled
        if user.addBurnedCaloriesEnabled {
            burnedCalories = await getActiveEnergy(for: date) ?? 0.0
        }

        // Get rollover if enabled and provider configured
        if let provider = rolloverProvider {
            rolloverCalories = await provider.calculateAdjustment(for: user, on: date)
        }

        return CalorieAdjustmentBreakdown(
            burnedCalories: burnedCalories,
            rolloverCalories: rolloverCalories
        )
    }

    // MARK: - Private Helpers

    private func getActiveEnergy(for date: Date) async -> Double? {
        if Calendar.current.isDateInToday(date) {
            return await activeEnergyDataSource.getTodayActiveEnergy()
        } else {
            return await activeEnergyDataSource.getActiveEnergyForDate(date)
        }
    }
}

/// Default implementation that routes requests to MetricsService static methods
private struct HealthKitActiveEnergyDataSource: ActiveEnergyDataSource {
    func getTodayActiveEnergy() async -> Double? {
        await MetricsService.getTodayActiveEnergy(dataSource: nil)
    }

    func getActiveEnergyForDate(_ date: Date) async -> Double? {
        await MetricsService.getActiveEnergyForDate(date, dataSource: nil)
    }

    func getActiveEnergyHistory(days: Int) async -> [Date: Double] {
        await MetricsService.getActiveEnergyHistory(days: days, dataSource: nil)
    }
}
