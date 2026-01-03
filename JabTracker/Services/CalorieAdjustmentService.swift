//
//  CalorieAdjustmentService.swift
//  JabTracker
//
//  Service for calculating adjusted calorie targets based on activity.
//

import Foundation

/// Service responsible for calculating daily calorie targets with optional activity adjustments
@MainActor
final class CalorieAdjustmentService {

    private let activeEnergyDataSource: ActiveEnergyDataSource

    /// Initialize with a data source
    /// - Parameter activeEnergyDataSource: Source for active energy data. Defaults to HealthKit-backed implementation.
    init(activeEnergyDataSource: ActiveEnergyDataSource = HealthKitActiveEnergyDataSource()) {
        self.activeEnergyDataSource = activeEnergyDataSource
    }

    /// Calculate the adjusted daily calorie target for a user
    /// - Parameters:
    ///   - user: The user to calculate for
    ///   - date: The date to calculate for
    ///   - baseTarget: The base calorie target (e.g. from nutrition goal)
    /// - Returns: Adjusted calorie target
    func getAdjustedCalorieTarget(for user: User, on date: Date, baseTarget: Double) async -> Double {
        // Return base target if feature is disabled
        guard user.addBurnedCaloriesEnabled else {
            return baseTarget
        }

        // Fetch active energy
        let activeEnergy: Double?
        if Calendar.current.isDateInToday(date) {
            activeEnergy = await activeEnergyDataSource.getTodayActiveEnergy()
        } else {
            activeEnergy = await activeEnergyDataSource.getActiveEnergyForDate(date)
        }

        // Add burned calories if available, otherwise return base target
        return baseTarget + (activeEnergy ?? 0.0)
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
