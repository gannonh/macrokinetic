//
//  ActiveEnergyQueryTests.swift
//  JabTrackerTests
//
//  Tests for active energy query methods in MetricsService.
//  Verifies query method signatures, date range calculations, and testable stubs.
//

import Foundation
import HealthKit
import Testing

@testable import JabTracker

@Suite("Active Energy Query Tests")
@MainActor
struct ActiveEnergyQueryTests {

    // MARK: - getTodayActiveEnergy Tests

    @Test("getTodayActiveEnergy returns optional Double")
    func testGetTodayActiveEnergyReturnType() async throws {
        // Given: A MetricsService with mock data source
        let mockDataSource = MockActiveEnergyDataSource()
        mockDataSource.todayEnergy = 350.5

        // When: We call getTodayActiveEnergy
        let result = await MetricsService.getTodayActiveEnergy(dataSource: mockDataSource)

        // Then: It should return the expected value
        #expect(result == 350.5)
    }

    @Test("getTodayActiveEnergy returns nil when no data available")
    func testGetTodayActiveEnergyReturnsNil() async throws {
        // Given: A mock data source with no data
        let mockDataSource = MockActiveEnergyDataSource()
        mockDataSource.todayEnergy = nil

        // When: We call getTodayActiveEnergy
        let result = await MetricsService.getTodayActiveEnergy(dataSource: mockDataSource)

        // Then: It should return nil
        #expect(result == nil)
    }

    @Test("getTodayActiveEnergy returns value in kilocalories")
    func testGetTodayActiveEnergyReturnsKcal() async throws {
        // Given: A mock data source with known kcal value
        let mockDataSource = MockActiveEnergyDataSource()
        let expectedKcal = 523.7
        mockDataSource.todayEnergy = expectedKcal

        // When: We call getTodayActiveEnergy
        let result = await MetricsService.getTodayActiveEnergy(dataSource: mockDataSource)

        // Then: Value should be in kilocalories (kcal)
        #expect(result == expectedKcal)
    }

    // MARK: - getActiveEnergyForDate Tests

    @Test("getActiveEnergyForDate returns energy for specific date")
    func testGetActiveEnergyForDateReturnsValue() async throws {
        // Given: A mock data source with data for a specific date
        let mockDataSource = MockActiveEnergyDataSource()
        let testDate = Calendar.current.startOfDay(for: Date())
        mockDataSource.energyByDate[testDate] = 425.0

        // When: We call getActiveEnergyForDate
        let result = await MetricsService.getActiveEnergyForDate(testDate, dataSource: mockDataSource)

        // Then: It should return the expected value
        #expect(result == 425.0)
    }

    @Test("getActiveEnergyForDate returns nil for date with no data")
    func testGetActiveEnergyForDateReturnsNilWhenNoData() async throws {
        // Given: A mock data source with no data for the requested date
        let mockDataSource = MockActiveEnergyDataSource()
        let testDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!

        // When: We call getActiveEnergyForDate
        let result = await MetricsService.getActiveEnergyForDate(testDate, dataSource: mockDataSource)

        // Then: It should return nil
        #expect(result == nil)
    }

    @Test("getActiveEnergyForDate normalizes date to midnight")
    func testGetActiveEnergyForDateNormalizesDate() async throws {
        // Given: A mock data source and a mid-day date
        let mockDataSource = MockActiveEnergyDataSource()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())
        mockDataSource.energyByDate[midnight] = 300.0

        // Create a mid-day date (2:30 PM)
        let midDayDate = calendar.date(byAdding: .hour, value: 14, to: midnight)!

        // When: We call getActiveEnergyForDate with mid-day date
        let result = await MetricsService.getActiveEnergyForDate(midDayDate, dataSource: mockDataSource)

        // Then: It should still find the data (date normalized to midnight)
        #expect(result == 300.0)
    }

    // MARK: - getActiveEnergyHistory Tests

    @Test("getActiveEnergyHistory returns dictionary with date keys")
    func testGetActiveEnergyHistoryReturnsDictionary() async throws {
        // Given: A mock data source with history data
        let mockDataSource = MockActiveEnergyDataSource()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            mockDataSource.energyByDate[date] = Double(300 + dayOffset * 50)
        }

        // When: We call getActiveEnergyHistory for 7 days
        let result = await MetricsService.getActiveEnergyHistory(days: 7, dataSource: mockDataSource)

        // Then: It should return a dictionary with 7 entries
        #expect(result.count == 7)
    }

    @Test("getActiveEnergyHistory returns empty dictionary when no data")
    func testGetActiveEnergyHistoryReturnsEmptyWhenNoData() async throws {
        // Given: A mock data source with no historical data
        let mockDataSource = MockActiveEnergyDataSource()

        // When: We call getActiveEnergyHistory
        let result = await MetricsService.getActiveEnergyHistory(days: 7, dataSource: mockDataSource)

        // Then: It should return an empty dictionary
        #expect(result.isEmpty)
    }

    @Test("getActiveEnergyHistory uses normalized midnight dates as keys")
    func testGetActiveEnergyHistoryUsesNormalizedDates() async throws {
        // Given: A mock data source with history data
        let mockDataSource = MockActiveEnergyDataSource()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Add data for yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        mockDataSource.energyByDate[yesterday] = 400.0

        // When: We call getActiveEnergyHistory
        let result = await MetricsService.getActiveEnergyHistory(days: 7, dataSource: mockDataSource)

        // Then: Keys should be at midnight (start of day)
        for dateKey in result.keys {
            let components = calendar.dateComponents([.hour, .minute, .second], from: dateKey)
            #expect(components.hour == 0)
            #expect(components.minute == 0)
            #expect(components.second == 0)
        }
    }

    @Test("getActiveEnergyHistory respects days parameter")
    func testGetActiveEnergyHistoryRespectsDaysParameter() async throws {
        // Given: A mock data source with 10 days of data
        let mockDataSource = MockActiveEnergyDataSource()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            mockDataSource.energyByDate[date] = Double(300 + dayOffset * 10)
        }

        // When: We request only 3 days
        let result = await MetricsService.getActiveEnergyHistory(days: 3, dataSource: mockDataSource)

        // Then: Only 3 days should be returned
        #expect(result.count == 3)

        // And the dates should be within the requested range
        let threeDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        for dateKey in result.keys {
            #expect(dateKey >= threeDaysAgo)
            #expect(dateKey <= today)
        }
    }

    @Test("getActiveEnergyHistory values are in kilocalories")
    func testGetActiveEnergyHistoryValuesInKcal() async throws {
        // Given: A mock data source with known kcal values
        let mockDataSource = MockActiveEnergyDataSource()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expectedKcal = 567.8
        mockDataSource.energyByDate[today] = expectedKcal

        // When: We call getActiveEnergyHistory
        let result = await MetricsService.getActiveEnergyHistory(days: 1, dataSource: mockDataSource)

        // Then: Values should be in kilocalories
        #expect(result[today] == expectedKcal)
    }

    // MARK: - Edge Case Tests

    @Test("getActiveEnergyHistory handles zero days gracefully")
    func testGetActiveEnergyHistoryZeroDays() async throws {
        // Given: A mock data source
        let mockDataSource = MockActiveEnergyDataSource()

        // When: We request 0 days
        let result = await MetricsService.getActiveEnergyHistory(days: 0, dataSource: mockDataSource)

        // Then: It should return an empty dictionary
        #expect(result.isEmpty)
    }

    @Test("getActiveEnergyHistory handles negative days gracefully")
    func testGetActiveEnergyHistoryNegativeDays() async throws {
        // Given: A mock data source
        let mockDataSource = MockActiveEnergyDataSource()

        // When: We request negative days
        let result = await MetricsService.getActiveEnergyHistory(days: -5, dataSource: mockDataSource)

        // Then: It should return an empty dictionary
        #expect(result.isEmpty)
    }

    // MARK: - Production Method Signature Tests

    @Test("Production methods exist and have correct signatures")
    func testProductionMethodSignatures() async throws {
        // Verify the production method signatures compile correctly
        // These call the actual HealthKit methods (will return nil in test environment)

        // getTodayActiveEnergy() async -> Double?
        let _: Double? = await MetricsService.getTodayActiveEnergy()

        // getActiveEnergyForDate(_:) async -> Double?
        let _: Double? = await MetricsService.getActiveEnergyForDate(Date())

        // getActiveEnergyHistory(days:) async -> [Date: Double]
        let _: [Date: Double] = await MetricsService.getActiveEnergyHistory(days: 7)

        // If we reach here, the method signatures are correct
        #expect(true, "All production method signatures are correct")
    }
}
