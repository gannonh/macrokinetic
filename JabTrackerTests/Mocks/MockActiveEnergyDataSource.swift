//
//  MockActiveEnergyDataSource.swift
//  JabTrackerTests
//
//  Mock implementation of ActiveEnergyDataSource for testing active energy queries.
//  Allows tests to inject controlled data without requiring actual HealthKit access.
//

import Foundation

@testable import JabTracker

/// Mock implementation of ActiveEnergyDataSource for unit testing
/// Provides controllable data for testing active energy query methods
@MainActor
final class MockActiveEnergyDataSource: ActiveEnergyDataSource {

    // MARK: - Mock Data Storage

    /// Today's energy value to return (nil simulates no data available)
    var todayEnergy: Double?

    /// Dictionary of energy values by date (normalized to midnight)
    var energyByDate: [Date: Double] = [:]

    /// Track method calls for verification
    var getTodayActiveEnergyCalled = false
    var getActiveEnergyForDateCalls: [Date] = []
    var getActiveEnergyHistoryCalls: [Int] = []

    // MARK: - ActiveEnergyDataSource Protocol

    func getTodayActiveEnergy() async -> Double? {
        getTodayActiveEnergyCalled = true
        return todayEnergy
    }

    func getActiveEnergyForDate(_ date: Date) async -> Double? {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        getActiveEnergyForDateCalls.append(normalizedDate)
        return energyByDate[normalizedDate]
    }

    func getActiveEnergyHistory(days: Int) async -> [Date: Double] {
        getActiveEnergyHistoryCalls.append(days)

        guard days > 0 else { return [:] }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var result: [Date: Double] = [:]
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            if let energy = energyByDate[date] {
                result[date] = energy
            }
        }

        return result
    }

    // MARK: - Test Helpers

    /// Reset all mock state
    func reset() {
        todayEnergy = nil
        energyByDate.removeAll()
        getTodayActiveEnergyCalled = false
        getActiveEnergyForDateCalls.removeAll()
        getActiveEnergyHistoryCalls.removeAll()
    }

    /// Convenience method to set up history data
    /// - Parameters:
    ///   - days: Number of days to populate
    ///   - baseValue: Starting calorie value
    ///   - variance: Random variance range (+/-)
    func populateHistory(days: Int, baseValue: Double = 400.0, variance: Double = 100.0) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let randomVariance = Double.random(in: -variance...variance)
            energyByDate[date] = baseValue + randomVariance
        }

        // Also set today's energy
        todayEnergy = energyByDate[today]
    }
}
