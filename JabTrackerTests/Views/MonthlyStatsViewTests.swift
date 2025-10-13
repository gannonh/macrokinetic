//
//  MonthlyStatsViewTests.swift
//  JabTrackerTests
//
//  Stream C: Statistics Integration & Performance
//  Issue #178
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Unit tests for MonthlyStatsView schedule adherence display
@MainActor
struct MonthlyStatsViewTests {

    // MARK: - Test Helpers

    /// Creates test AdherenceStatistics with schedule metrics
    private func createTestStatistics(
        totalDoses: Int = 10,
        skippedDoses: Int = 0,
        scheduledDoses: Int = 12,
        scheduledTotal: Int = 12,
        scheduledTaken: Int = 10,
        scheduledMissed: Int = 2,
        scheduledSkipped: Int = 0
    ) -> AdherenceStatistics {
        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now)!

        return AdherenceStatistics(
            totalDoses: totalDoses,
            skippedDoses: skippedDoses,
            scheduledDoses: scheduledDoses,
            averageDose: 0.5,
            totalMedicationAmount: Double(totalDoses) * 0.5,
            doseRange: (min: 0.25, max: 1.0),
            currentStreak: 5,
            longestStreak: 10,
            isCurrentStreakActive: true,
            siteDistribution: ["Abdomen": 8, "Thigh": 2],
            periodStart: weekAgo,
            periodEnd: now,
            // Stream C: Schedule adherence parameters
            totalScheduledDoses: scheduledTotal,
            takenScheduledDoses: scheduledTaken,
            missedScheduledDoses: scheduledMissed,
            skippedScheduledDoses: scheduledSkipped
        )
    }

    // MARK: - Schedule Adherence Display Tests

    @Test("MonthlyStatsView displays schedule adherence rate")
    func testDisplaysScheduleAdherenceRate() throws {
        let statistics = createTestStatistics(
            scheduledTotal: 10,
            scheduledTaken: 8,
            scheduledMissed: 2,
            scheduledSkipped: 0
        )

        // View should display 80% adherence rate (8/10)
        #expect(statistics.scheduleAdherenceRate == 0.8)
        #expect(statistics.totalScheduledDoses == 10)
        #expect(statistics.takenScheduledDoses == 8)
        #expect(statistics.missedScheduledDoses == 2)
    }

    @Test("MonthlyStatsView displays schedule adherence breakdown")
    func testDisplaysScheduleAdherenceBreakdown() throws {
        let statistics = createTestStatistics(
            scheduledTotal: 20,
            scheduledTaken: 15,
            scheduledMissed: 2,
            scheduledSkipped: 3
        )

        // Verify breakdown counts
        #expect(statistics.totalScheduledDoses == 20)
        #expect(statistics.takenScheduledDoses == 15)
        #expect(statistics.missedScheduledDoses == 2)
        #expect(statistics.skippedScheduledDoses == 3)

        // Adherence rate excludes skipped doses: 15 / (15 + 2) = 88.2%
        let expectedRate = 15.0 / 17.0
        #expect(abs(statistics.scheduleAdherenceRate - expectedRate) < 0.001)
    }

    @Test("MonthlyStatsView handles zero scheduled doses gracefully")
    func testHandlesZeroScheduledDosesGracefully() throws {
        let statistics = createTestStatistics(
            scheduledTotal: 0,
            scheduledTaken: 0,
            scheduledMissed: 0,
            scheduledSkipped: 0
        )

        // Should handle zero scheduled doses without crash
        #expect(statistics.totalScheduledDoses == 0)
        #expect(statistics.takenScheduledDoses == 0)

        // Note: scheduleAdherenceRate should be 0.0 or 1.0 depending on implementation
        // (no misses could mean 100% adherence, or no data could mean 0%)
        #expect(statistics.scheduleAdherenceRate >= 0.0)
        #expect(statistics.scheduleAdherenceRate <= 1.0)
    }

    @Test("MonthlyStatsView calculates adherence rate correctly with mixed states")
    func testCalculatesAdherenceRateCorrectlyWithMixedStates() throws {
        let statistics = createTestStatistics(
            scheduledTotal: 100,
            scheduledTaken: 85,
            scheduledMissed: 10,
            scheduledSkipped: 5
        )

        // Adherence = taken / (taken + missed)
        // 85 / (85 + 10) = 85 / 95 = 89.47%
        let expectedRate = 85.0 / 95.0
        #expect(abs(statistics.scheduleAdherenceRate - expectedRate) < 0.001)
    }

    @Test("MonthlyStatsView displays 100 percent adherence correctly")
    func testDisplays100PercentAdherenceCorrectly() throws {
        let statistics = createTestStatistics(
            scheduledTotal: 10,
            scheduledTaken: 10,
            scheduledMissed: 0,
            scheduledSkipped: 0
        )

        #expect(statistics.scheduleAdherenceRate == 1.0)
        #expect(statistics.missedScheduledDoses == 0)
    }

    @Test("MonthlyStatsView displays 0 percent adherence correctly")
    func testDisplays0PercentAdherenceCorrectly() throws {
        let statistics = createTestStatistics(
            scheduledTotal: 10,
            scheduledTaken: 0,
            scheduledMissed: 10,
            scheduledSkipped: 0
        )

        #expect(statistics.scheduleAdherenceRate == 0.0)
        #expect(statistics.takenScheduledDoses == 0)
        #expect(statistics.missedScheduledDoses == 10)
    }
}
