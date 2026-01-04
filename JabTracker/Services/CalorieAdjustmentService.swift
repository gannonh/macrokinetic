//
//  CalorieAdjustmentService.swift
//  JabTracker
//
//  Service for calculating adjusted calorie targets based on activity.
//

import Foundation
import OSLog

/// Breakdown of calorie adjustments for UI display
struct CalorieAdjustmentBreakdown {
    let burnedCalories: Double
    let rolloverCalories: Double
    let predictiveCalories: Double

    var totalAdjustment: Double {
        burnedCalories + rolloverCalories + predictiveCalories
    }

    /// Convenience initializer for backward compatibility (default predictiveCalories to 0)
    init(burnedCalories: Double, rolloverCalories: Double, predictiveCalories: Double = 0.0) {
        self.burnedCalories = burnedCalories
        self.rolloverCalories = rolloverCalories
        self.predictiveCalories = predictiveCalories
    }
}

/// Service responsible for calculating daily calorie targets with optional activity adjustments
@MainActor
final class CalorieAdjustmentService {

    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "CalorieAdjustmentService"
    )

    private let activeEnergyDataSource: ActiveEnergyDataSource
    private var rolloverProvider: RolloverCalorieProvider?
    private var predictiveProvider: PredictiveActivityProvider?

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

    /// Configure predictive activity provider with ActiveEnergyDataSource
    /// Must be called before predictive calculations will work
    /// - Parameter activeEnergyDataSource: Source for activity history data
    func configurePredictiveProvider(activeEnergyDataSource: ActiveEnergyDataSource) {
        self.predictiveProvider = PredictiveActivityProvider(
            activeEnergyDataSource: activeEnergyDataSource
        )
    }

    /// Calculate the adjusted daily calorie target for a user
    /// Includes burned calories, rollover, and predictive adjustments based on user preferences
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
            if activeEnergy == nil {
                Self.logger.warning("Active energy unavailable for \(date) - check HealthKit authorization")
            }
            adjusted += activeEnergy ?? 0.0
        }

        // Add rollover if enabled and provider configured
        if let provider = rolloverProvider {
            let rollover = await provider.calculateAdjustment(for: user, on: date)
            adjusted += rollover
        }

        // Add predictive if enabled and provider configured
        if let provider = predictiveProvider {
            let predictive = await provider.calculateAdjustment(for: user, on: date)
            adjusted += predictive
        }

        return adjusted
    }

    /// Get detailed breakdown of calorie adjustments
    /// - Parameters:
    ///   - user: The user to calculate for
    ///   - date: The date to calculate for
    /// - Returns: Breakdown of burned, rollover, and predictive calories
    func getAdjustmentBreakdown(for user: User, on date: Date) async -> CalorieAdjustmentBreakdown {
        var burnedCalories = 0.0
        var rolloverCalories = 0.0
        var predictiveCalories = 0.0

        // Get burned calories if enabled
        if user.addBurnedCaloriesEnabled {
            let activeEnergy = await getActiveEnergy(for: date)
            if activeEnergy == nil {
                Self.logger.warning("Active energy unavailable for breakdown on \(date)")
            }
            burnedCalories = activeEnergy ?? 0.0
        }

        // Get rollover if enabled and provider configured
        if let provider = rolloverProvider {
            rolloverCalories = await provider.calculateAdjustment(for: user, on: date)
        }

        // Get predictive if enabled and provider configured
        if let provider = predictiveProvider {
            predictiveCalories = await provider.calculateAdjustment(for: user, on: date)
        }

        return CalorieAdjustmentBreakdown(
            burnedCalories: burnedCalories,
            rolloverCalories: rolloverCalories,
            predictiveCalories: predictiveCalories
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
struct HealthKitActiveEnergyDataSource: ActiveEnergyDataSource {
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
