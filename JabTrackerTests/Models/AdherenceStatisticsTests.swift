//
//  AdherenceStatisticsTests.swift
//  JabTrackerTests
//
//  Unit tests for AdherenceStatistics model and AdherenceStatisticsCalculator
//  Defines contracts for statistics calculations, streak detection, and adherence rate accuracy
//

import Testing
import Foundation
@testable import JabTracker

@MainActor
struct AdherenceStatisticsTests {

    // MARK: - Basic Statistics Tests

    @Test("AdherenceStatistics calculates adherence rate correctly")
    func testAdherenceRateCalculation() throws {
        // Given: Known dose counts
        let stats = AdherenceStatistics(
            totalDoses: 10,
            skippedDoses: 2,
            scheduledDoses: 12,
            averageDose: 1.0,
            totalMedicationAmount: 8.0,
            doseRange: nil,
            currentStreak: 5,
            longestStreak: 7,
            isCurrentStreakActive: true,
            siteDistribution: [:],
            periodStart: Date(),
            periodEnd: Date()
        )

        // When: Calculating adherence rate
        let adherenceRate = stats.adherenceRate
        let adherencePercentage = stats.adherenceRatePercentage

        // Then: Rate is correct (8 taken doses / 12 scheduled = 66.7%)
        #expect(abs(adherenceRate - 0.6667) < 0.001, "Adherence rate should be 66.67%")
        #expect(adherencePercentage == "66.7%", "Adherence percentage string should be formatted correctly")
    }

    @Test("AdherenceStatistics handles zero scheduled doses gracefully")
    func testZeroScheduledDosesHandling() throws {
        // Given: No scheduled doses
        let stats = AdherenceStatistics(
            totalDoses: 5,
            skippedDoses: 0,
            scheduledDoses: 0,
            averageDose: 1.0,
            totalMedicationAmount: 5.0,
            doseRange: nil,
            currentStreak: 0,
            longestStreak: 0,
            isCurrentStreakActive: false,
            siteDistribution: [:],
            periodStart: Date(),
            periodEnd: Date()
        )

        // When: Getting adherence rate
        let adherenceRate = stats.adherenceRate
        let adherencePercentage = stats.adherenceRatePercentage

        // Then: Rate is 0 (no division by zero error)
        #expect(adherenceRate == 0.0, "Adherence rate should be 0 when no doses scheduled")
        #expect(adherencePercentage == "0.0%", "Adherence percentage should show 0.0%")
    }

    @Test("AdherenceStatistics computes period days correctly")
    func testPeriodDaysCalculation() throws {
        // Given: Known date range
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate

        let stats = AdherenceStatistics(
            totalDoses: 5,
            skippedDoses: 0,
            scheduledDoses: 7,
            averageDose: 1.0,
            totalMedicationAmount: 5.0,
            doseRange: nil,
            currentStreak: 0,
            longestStreak: 0,
            isCurrentStreakActive: false,
            siteDistribution: [:],
            periodStart: startDate,
            periodEnd: endDate
        )

        // When: Getting period days
        let periodDays = stats.periodDays

        // Then: Days calculation is correct
        #expect(periodDays == 7, "Period days should be 7 for a 7-day range")
    }

    @Test("AdherenceStatistics identifies most used injection site")
    func testMostUsedInjectionSite() throws {
        // Given: Site distribution with clear winner
        let siteDistribution = [
            "Thigh": 8,
            "Abdomen": 5,
            "Arm": 2
        ]

        let stats = AdherenceStatistics(
            totalDoses: 15,
            skippedDoses: 0,
            scheduledDoses: 15,
            averageDose: 1.0,
            totalMedicationAmount: 15.0,
            doseRange: nil,
            currentStreak: 0,
            longestStreak: 0,
            isCurrentStreakActive: false,
            siteDistribution: siteDistribution,
            periodStart: Date(),
            periodEnd: Date()
        )

        // When: Getting most used site
        let mostUsedSite = stats.mostUsedSite

        // Then: Correct site is identified
        #expect(mostUsedSite == "Thigh", "Most used site should be Thigh with 8 uses")
    }

    @Test("AdherenceStatistics handles empty site distribution")
    func testEmptySiteDistribution() throws {
        // Given: No injection sites recorded
        let stats = AdherenceStatistics(
            totalDoses: 5,
            skippedDoses: 0,
            scheduledDoses: 5,
            averageDose: 1.0,
            totalMedicationAmount: 5.0,
            doseRange: nil,
            currentStreak: 0,
            longestStreak: 0,
            isCurrentStreakActive: false,
            siteDistribution: [:],
            periodStart: Date(),
            periodEnd: Date()
        )

        // When: Getting most used site
        let mostUsedSite = stats.mostUsedSite

        // Then: Returns nil for empty distribution
        #expect(mostUsedSite == nil, "Most used site should be nil when no sites recorded")
    }

    // MARK: - Empty State Tests

    @Test("AdherenceStatistics empty state creates correct defaults")
    func testEmptyStateCreation() throws {
        // Given: Date range for empty period
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? startDate

        // When: Creating empty statistics
        let emptyStats = AdherenceStatistics.empty(periodStart: startDate, periodEnd: endDate)

        // Then: All values are zeroed/empty appropriately
        #expect(emptyStats.totalDoses == 0, "Empty stats should have 0 total doses")
        #expect(emptyStats.skippedDoses == 0, "Empty stats should have 0 skipped doses")
        #expect(emptyStats.scheduledDoses == 0, "Empty stats should have 0 scheduled doses")
        #expect(emptyStats.averageDose == 0.0, "Empty stats should have 0 average dose")
        #expect(emptyStats.totalMedicationAmount == 0.0, "Empty stats should have 0 total medication")
        #expect(emptyStats.doseRange == nil, "Empty stats should have nil dose range")
        #expect(emptyStats.currentStreak == 0, "Empty stats should have 0 current streak")
        #expect(emptyStats.longestStreak == 0, "Empty stats should have 0 longest streak")
        #expect(emptyStats.isCurrentStreakActive == false, "Empty stats should have inactive streak")
        #expect(emptyStats.siteDistribution.isEmpty, "Empty stats should have empty site distribution")
        #expect(emptyStats.periodStart == startDate, "Empty stats should preserve start date")
        #expect(emptyStats.periodEnd == endDate, "Empty stats should preserve end date")
    }

    // MARK: - Calculator Tests

    @Test("AdherenceStatisticsCalculator handles empty dose array")
    func testCalculatorWithEmptyDoses() throws {
        // Given: Empty dose array and date range
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? startDate

        // When: Calculating statistics
        let stats = AdherenceStatisticsCalculator.calculate(
            doses: [],
            periodStart: startDate,
            periodEnd: endDate,
            medicationFrequency: .weekly
        )

        // Then: Returns empty statistics
        #expect(stats.totalDoses == 0, "Calculator should return 0 total doses for empty array")
        #expect(stats.adherenceRate == 0.0, "Calculator should return 0 adherence rate for empty array")
        #expect(stats.siteDistribution.isEmpty, "Calculator should return empty site distribution")
    }

    @Test("AdherenceStatisticsCalculator calculates basic counts correctly")
    func testCalculatorBasicCounts() throws {
        // Given: Known doses with specific properties
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate) ?? startDate

        let doses = [
            createTestDose(timestamp: startDate, amount: 1.0, site: "Thigh", skipped: false),
            createTestDose(timestamp: Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate,
                          amount: 1.5, site: "Abdomen", skipped: false),
            createTestDose(timestamp: Calendar.current.date(byAdding: .day, value: 2, to: startDate) ?? startDate,
                          amount: 1.2, site: "Thigh", skipped: true),
            createTestDose(timestamp: Calendar.current.date(byAdding: .day, value: 10, to: startDate) ?? startDate,
                          amount: 2.0, site: "Arm", skipped: false) // Outside period
        ]

        // When: Calculating statistics
        let stats = AdherenceStatisticsCalculator.calculate(
            doses: doses,
            periodStart: startDate,
            periodEnd: endDate,
            medicationFrequency: .weekly
        )

        // Then: Counts are correct (only first 3 doses are in period)
        #expect(stats.totalDoses == 3, "Should count 3 doses in period")
        #expect(stats.skippedDoses == 1, "Should count 1 skipped dose")
        #expect(stats.scheduledDoses == 1, "Should calculate 1 scheduled dose for weekly frequency over 7 days")

        // Average should be calculated from non-skipped doses only (1.0 + 1.5) / 2 = 1.25
        #expect(abs(stats.averageDose - 1.25) < 0.001, "Average dose should be 1.25")

        // Total medication from non-skipped doses: 1.0 + 1.5 = 2.5
        #expect(abs(stats.totalMedicationAmount - 2.5) < 0.001, "Total medication should be 2.5")

        // Dose range from non-skipped doses: min=1.0, max=1.5
        #expect(stats.doseRange?.min == 1.0, "Dose range min should be 1.0")
        #expect(stats.doseRange?.max == 1.5, "Dose range max should be 1.5")
    }

    @Test("AdherenceStatisticsCalculator calculates site distribution correctly")
    func testCalculatorSiteDistribution() throws {
        // Given: Doses with known injection sites
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 5, to: startDate) ?? startDate

        let doses = [
            createTestDose(timestamp: startDate, site: "Thigh", skipped: false),
            createTestDose(timestamp: Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate,
                          site: "Thigh", skipped: false),
            createTestDose(timestamp: Calendar.current.date(byAdding: .day, value: 2, to: startDate) ?? startDate,
                          site: "Abdomen", skipped: false),
            createTestDose(timestamp: Calendar.current.date(byAdding: .day, value: 3, to: startDate) ?? startDate,
                          site: "Thigh", skipped: true), // Skipped, but still included in site distribution logic
            createTestDose(timestamp: Calendar.current.date(byAdding: .day, value: 4, to: startDate) ?? startDate,
                          site: nil, skipped: false) // No site recorded
        ]

        // When: Calculating statistics
        let stats = AdherenceStatisticsCalculator.calculate(
            doses: doses,
            periodStart: startDate,
            periodEnd: endDate,
            medicationFrequency: .daily
        )

        // Then: Site distribution is correct (based on non-skipped doses with sites)
        let expectedSites = ["Thigh": 2, "Abdomen": 1] // Only counting non-skipped doses
        #expect(stats.siteDistribution == expectedSites, "Site distribution should count non-skipped doses with sites")
        #expect(stats.mostUsedSite == "Thigh", "Most used site should be Thigh")
    }

    @Test("AdherenceStatisticsCalculator calculates weekly scheduled doses correctly")
    func testCalculatorWeeklyScheduledDoses() throws {
        // Given: Different time periods with weekly frequency
        let startDate = Date()

        // Test various periods
        let testCases = [
            (days: 7, expected: 1),   // 1 week = 1 dose
            (days: 14, expected: 2),  // 2 weeks = 2 doses
            (days: 10, expected: 2),  // 1.4 weeks = 2 doses (rounded up)
            (days: 3, expected: 1),   // 0.4 weeks = 1 dose (minimum)
            (days: 21, expected: 3),  // 3 weeks = 3 doses
        ]

        for testCase in testCases {
            let endDate = Calendar.current.date(byAdding: .day, value: testCase.days, to: startDate) ?? startDate

            // When: Calculating statistics with weekly frequency
            let stats = AdherenceStatisticsCalculator.calculate(
                doses: [],
                periodStart: startDate,
                periodEnd: endDate,
                medicationFrequency: .weekly
            )

            // Then: Scheduled doses match expected
            #expect(stats.scheduledDoses == testCase.expected,
                   "For \(testCase.days) days, should schedule \(testCase.expected) weekly doses")
        }
    }

    @Test("AdherenceStatisticsCalculator calculates daily scheduled doses correctly")
    func testCalculatorDailyScheduledDoses() throws {
        // Given: Different time periods with daily frequency
        let startDate = Date()

        let testCases = [
            (days: 1, expected: 1),
            (days: 7, expected: 7),
            (days: 30, expected: 30),
        ]

        for testCase in testCases {
            let endDate = Calendar.current.date(byAdding: .day, value: testCase.days, to: startDate) ?? startDate

            // When: Calculating statistics with daily frequency
            let stats = AdherenceStatisticsCalculator.calculate(
                doses: [],
                periodStart: startDate,
                periodEnd: endDate,
                medicationFrequency: .daily
            )

            // Then: Scheduled doses match days
            #expect(stats.scheduledDoses == testCase.expected,
                   "For \(testCase.days) days, should schedule \(testCase.expected) daily doses")
        }
    }

    @Test("AdherenceStatisticsCalculator calculates streaks correctly")
    func testCalculatorStreakCalculation() throws {
        // Given: Doses creating specific streak pattern
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!
        let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!

        // Pattern: dose 6 days ago, dose 5 days ago, gap, dose 3 days ago, dose 2 days ago, dose yesterday
        // This creates: longest streak = 3 (yesterday, 2 days ago, 3 days ago), current streak = 3, active = false (no dose today)
        let doses = [
            createTestDose(timestamp: sixDaysAgo, skipped: false),
            createTestDose(timestamp: fiveDaysAgo, skipped: false),
            // Gap on 4 days ago
            createTestDose(timestamp: threeDaysAgo, skipped: false),
            createTestDose(timestamp: twoDaysAgo, skipped: false),
            createTestDose(timestamp: yesterday, skipped: false),
            // No dose today
        ]

        let startDate = calendar.date(byAdding: .day, value: -7, to: today)!

        // When: Calculating statistics
        let stats = AdherenceStatisticsCalculator.calculate(
            doses: doses,
            periodStart: startDate,
            periodEnd: today,
            medicationFrequency: .daily
        )

        // Then: Streak calculations are correct
        #expect(stats.longestStreak == 3, "Longest streak should be 3 consecutive days")
        #expect(stats.currentStreak == 3, "Current streak should be 3 (ending yesterday)")
        #expect(stats.isCurrentStreakActive == false, "Current streak should be inactive (no dose today)")
    }

    @Test("AdherenceStatisticsCalculator handles active current streak")
    func testCalculatorActiveCurrentStreak() throws {
        // Given: Doses including today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let doses = [
            createTestDose(timestamp: yesterday, skipped: false),
            createTestDose(timestamp: today, skipped: false),
        ]

        let startDate = calendar.date(byAdding: .day, value: -7, to: today)!

        // When: Calculating statistics
        let stats = AdherenceStatisticsCalculator.calculate(
            doses: doses,
            periodStart: startDate,
            periodEnd: today,
            medicationFrequency: .daily
        )

        // Then: Current streak is active
        #expect(stats.currentStreak == 2, "Current streak should be 2 days")
        #expect(stats.isCurrentStreakActive == true, "Current streak should be active (dose today)")
    }

    // MARK: - Helper Methods

    private func createTestDose(
        timestamp: Date = Date(),
        amount: Double = 1.0,
        site: String? = nil,
        skipped: Bool = false
    ) -> Dose {
        Dose(
            amount: amount,
            timestamp: timestamp,
            site: site,
            notes: nil,
            imageData: nil,
            skipped: skipped,
            user: nil,
            medication: nil
        )
    }
}
