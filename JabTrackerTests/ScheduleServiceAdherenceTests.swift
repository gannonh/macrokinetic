//
//  ScheduleServiceAdherenceTests.swift
//  JabTrackerTests
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
struct ScheduleServiceAdherenceTests {

    // MARK: - Test Helpers

    /// Creates a test ModelContext with all models
    /// Returns both context and container - container MUST be kept alive for test duration
    private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let container = DataController.testContainer().container
        return (container.mainContext, container)
    }

    /// Creates a test medication profile
    private func createTestProfile(context: ModelContext) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5
        )
        context.insert(profile)
        return profile
    }

    /// Creates a test schedule with configuration
    private func createTestSchedule(
        context: ModelContext,
        profile: MedicationProfile,
        doseAmount: Double = 0.5
    ) throws -> DoseSchedule {
        let config = ScheduleConfiguration(
            dayOfWeek: 1,  // Monday
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            secondTimeOfDay: nil,
            interval: 7,
            doseAmount: doseAmount,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        let encoder = JSONEncoder()
        let scheduleData = try encoder.encode(config)

        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly,
            baseSchedule: scheduleData,
            isActive: true
        )
        context.insert(schedule)
        try context.save()

        return schedule
    }

    /// Creates a test scheduled dose
    private func createTestScheduledDose(
        context: ModelContext,
        schedule: DoseSchedule,
        scheduledTime: Date,
        doseAmount: Double = 0.5
    ) -> ScheduledDose {
        let windowStart = scheduledTime.addingTimeInterval(-2 * 60 * 60)  // 2 hours before
        let windowEnd = scheduledTime.addingTimeInterval(2 * 60 * 60)  // 2 hours after

        let scheduledDose = ScheduledDose(
            scheduledTime: scheduledTime,
            doseAmount: doseAmount,
            windowStart: windowStart,
            windowEnd: windowEnd
        )
        context.insert(scheduledDose)
        scheduledDose.schedule = schedule

        return scheduledDose
    }

    // MARK: - Adherence Calculation Tests

    @Test("Calculate adherence percentage accurately")
    func testCalculateAdherencePercentageAccurately() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()

        // Create 10 scheduled doses over 10 weeks
        for index in 0..<10 {
            let scheduledTime = Calendar.current.date(byAdding: .day, value: -70 + (index * 7), to: now)!
            let dose = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )

            // Take 7 doses, miss 3 doses
            if index < 7 {
                let actualDose = Dose(
                    amount: 0.5,
                    timestamp: scheduledTime,
                    site: "Abdomen"
                )
                actualDose.medication = profile
                context.insert(actualDose)
                dose.actualDose = actualDose
            }
        }

        try context.save()

        let service = ScheduleService(context: context)
        let startDate = Calendar.current.date(byAdding: .day, value: -80, to: now)!
        let endDate = now

        let metrics = service.calculateAdherence(for: schedule, from: startDate, to: endDate)

        // Verify adherence percentage: 7 taken / (7 taken + 3 missed) = 70%
        #expect(abs(metrics.adherencePercentage - 0.7) < 0.01)
        #expect(metrics.totalScheduled == 10)
        #expect(metrics.totalTaken == 7)
        #expect(metrics.totalMissed == 3)
        #expect(metrics.totalSkipped == 0)
    }

    @Test("Calculate adherence with all doses taken")
    func testCalculateAdherenceWithAllDosesTaken() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()

        // Create 5 scheduled doses, all taken
        for index in 0..<5 {
            let scheduledTime = Calendar.current.date(byAdding: .day, value: -28 + (index * 7), to: now)!
            let dose = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )

            let actualDose = Dose(
                amount: 0.5,
                timestamp: scheduledTime,
                site: "Abdomen"
            )
            actualDose.medication = profile
            context.insert(actualDose)
            dose.actualDose = actualDose
        }

        try context.save()

        let service = ScheduleService(context: context)
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let endDate = now

        let metrics = service.calculateAdherence(for: schedule, from: startDate, to: endDate)

        // Verify 100% adherence
        #expect(metrics.adherencePercentage == 1.0)
        #expect(metrics.totalTaken == 5)
        #expect(metrics.totalMissed == 0)
    }

    @Test("Calculate adherence with all doses missed")
    func testCalculateAdherenceWithAllDosesMissed() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()

        // Create 5 scheduled doses in the past (all missed)
        for index in 0..<5 {
            let scheduledTime = Calendar.current.date(
                byAdding: .day,
                value: -28 + (index * 7),
                to: now.addingTimeInterval(-7 * 60 * 60)  // Past window end
            )!
            _ = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )
        }

        try context.save()

        let service = ScheduleService(context: context)
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let endDate = now

        let metrics = service.calculateAdherence(for: schedule, from: startDate, to: endDate)

        // Verify 0% adherence
        #expect(metrics.adherencePercentage == 0.0)
        #expect(metrics.totalTaken == 0)
        #expect(metrics.totalMissed == 5)
    }

    @Test("Calculate current streak correctly")
    func testCalculateCurrentStreakCorrectly() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()

        // Create 10 doses: missed, taken, taken, taken, missed, taken, taken, taken, taken, taken
        let statuses: [Bool] = [false, true, true, true, false, true, true, true, true, true]

        for (index, shouldTake) in statuses.enumerated() {
            let scheduledTime = Calendar.current.date(
                byAdding: .day,
                value: -63 + (index * 7),
                to: shouldTake ? now : now.addingTimeInterval(-10 * 60 * 60)  // Ensure missed doses are past window
            )!
            let dose = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )

            if shouldTake {
                let actualDose = Dose(
                    amount: 0.5,
                    timestamp: scheduledTime,
                    site: "Abdomen"
                )
                actualDose.medication = profile
                context.insert(actualDose)
                dose.actualDose = actualDose
            }
        }

        try context.save()

        let service = ScheduleService(context: context)
        let startDate = Calendar.current.date(byAdding: .day, value: -70, to: now)!
        let endDate = now

        let metrics = service.calculateAdherence(for: schedule, from: startDate, to: endDate)

        // Current streak should be 5 (last 5 doses taken)
        #expect(metrics.currentStreak == 5)
    }

    @Test("Calculate longest streak in period")
    func testCalculateLongestStreakInPeriod() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()

        // Create pattern: taken, taken, taken, taken (streak 4), missed, taken, taken (streak 2)
        let statuses: [Bool] = [true, true, true, true, false, true, true]

        for (index, shouldTake) in statuses.enumerated() {
            let scheduledTime = Calendar.current.date(
                byAdding: .day,
                value: -42 + (index * 7),
                to: shouldTake ? now : now.addingTimeInterval(-10 * 60 * 60)
            )!
            let dose = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )

            if shouldTake {
                let actualDose = Dose(
                    amount: 0.5,
                    timestamp: scheduledTime,
                    site: "Abdomen"
                )
                actualDose.medication = profile
                context.insert(actualDose)
                dose.actualDose = actualDose
            }
        }

        try context.save()

        let service = ScheduleService(context: context)
        let startDate = Calendar.current.date(byAdding: .day, value: -50, to: now)!
        let endDate = now

        let metrics = service.calculateAdherence(for: schedule, from: startDate, to: endDate)

        // Longest streak should be 4
        #expect(metrics.longestStreak == 4)
    }

    @Test("Calculate on-time percentage")
    func testCalculateOnTimePercentage() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()

        // Create 5 doses: 3 on-time, 2 late (outside window)
        for index in 0..<5 {
            let scheduledTime = Calendar.current.date(byAdding: .day, value: -28 + (index * 7), to: now)!
            let dose = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )

            // First 3 doses taken on time, last 2 taken late (3 hours after window end)
            let actualTime =
                index < 3
                ? scheduledTime : scheduledTime.addingTimeInterval(5 * 60 * 60)  // 5 hours late

            let actualDose = Dose(
                amount: 0.5,
                timestamp: actualTime,
                site: "Abdomen"
            )
            actualDose.medication = profile
            context.insert(actualDose)
            dose.actualDose = actualDose
        }

        try context.save()

        let service = ScheduleService(context: context)
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let endDate = now

        let metrics = service.calculateAdherence(for: schedule, from: startDate, to: endDate)

        // On-time percentage: 3 / 5 = 60%
        #expect(abs(metrics.onTimePercentage - 0.6) < 0.01)
    }

    @Test("Calculate adherence with mixed pattern")
    func testCalculateAdherenceWithMixedPattern() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()

        // Create 10 doses with mixed pattern: taken, missed, skipped, taken, missed, taken, skipped, taken, taken, missed
        let pattern: [String] = [
            "taken", "missed", "skipped", "taken", "missed", "taken", "skipped", "taken", "taken", "missed",
        ]

        for (index, action) in pattern.enumerated() {
            let scheduledTime = Calendar.current.date(
                byAdding: .day,
                value: -63 + (index * 7),
                to: action == "missed" ? now.addingTimeInterval(-10 * 60 * 60) : now
            )!
            let dose = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )

            switch action {
            case "taken":
                let actualDose = Dose(
                    amount: 0.5,
                    timestamp: scheduledTime,
                    site: "Abdomen"
                )
                actualDose.medication = profile
                context.insert(actualDose)
                dose.actualDose = actualDose
            case "skipped":
                dose.skippedAt = Date()
                dose.skipReason = "Feeling unwell"
            case "missed":
                // Do nothing - dose will be marked as missed
                break
            default:
                break
            }
        }

        try context.save()

        let service = ScheduleService(context: context)
        let startDate = Calendar.current.date(byAdding: .day, value: -70, to: now)!
        let endDate = now

        let metrics = service.calculateAdherence(for: schedule, from: startDate, to: endDate)

        // Adherence: 5 taken / (5 taken + 3 missed) = 62.5% (skipped doesn't count against)
        #expect(abs(metrics.adherencePercentage - 0.625) < 0.01)
        #expect(metrics.totalTaken == 5)
        #expect(metrics.totalMissed == 3)
        #expect(metrics.totalSkipped == 2)
    }

    // MARK: - Recent Adherence Pattern Tests

    @Test("Recent adherence pattern returns correct DoseEvent timeline")
    func testRecentAdherencePatternReturnsCorrectTimeline() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()

        // Create 4 weekly doses
        for index in 0..<4 {
            let scheduledTime = Calendar.current.date(byAdding: .day, value: -21 + (index * 7), to: now)!
            let dose = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )

            // First 2 taken, 3rd skipped, 4th pending (future)
            if index == 0 || index == 1 {
                let actualDose = Dose(
                    amount: 0.5,
                    timestamp: scheduledTime,
                    site: "Abdomen"
                )
                actualDose.medication = profile
                context.insert(actualDose)
                dose.actualDose = actualDose
            } else if index == 2 {
                dose.skippedAt = Date()
            }
        }

        try context.save()

        let service = ScheduleService(context: context)
        let events = service.getRecentAdherencePattern(for: schedule, days: 30)

        // Should have 4 events
        #expect(events.count == 4)

        // Verify events are sorted chronologically
        for index in 0..<(events.count - 1) {
            #expect(events[index].timestamp <= events[index + 1].timestamp)
        }

        // Verify event types
        #expect(events[0].type == .taken)
        #expect(events[1].type == .taken)
        #expect(events[2].type == .skipped)
        #expect(events[3].type == .scheduled)  // Future/pending
    }

    // MARK: - Adherence Issue Detection Tests

    @Test("Identify missed doses")
    func testIdentifyMissedDoses() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()

        // Create 5 consecutive missed doses
        for index in 0..<5 {
            let scheduledTime = Calendar.current.date(
                byAdding: .day,
                value: -28 + (index * 7),
                to: now.addingTimeInterval(-10 * 60 * 60)  // Past window
            )!
            _ = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )
        }

        try context.save()

        let service = ScheduleService(context: context)
        let issues = service.detectAdherenceIssues(for: schedule)

        // Should detect consecutive misses issue
        #expect(issues.count > 0)

        let consecutiveMissIssue = issues.first { $0.type == .consecutiveMisses }
        #expect(consecutiveMissIssue != nil)
        #expect(consecutiveMissIssue?.severity == .high)  // 5 misses = high severity
        #expect(consecutiveMissIssue?.affectedDoses.count == 5)
    }

    @Test("Identify frequent rescheduling pattern")
    func testIdentifyFrequentRescheduling() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()

        // Create 10 doses within last 30 days, reschedule 6 of them (60%)
        for index in 0..<10 {
            let scheduledTime = Calendar.current.date(byAdding: .day, value: -29 + (index * 3), to: now)!
            let dose = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )

            if index < 6 {
                // Reschedule first 6 doses
                dose.rescheduledFrom = scheduledTime
                dose.scheduledTime = scheduledTime.addingTimeInterval(24 * 60 * 60)
            }

            // Mark all as taken
            let actualDose = Dose(
                amount: 0.5,
                timestamp: dose.scheduledTime,
                site: "Abdomen"
            )
            actualDose.medication = profile
            context.insert(actualDose)
            dose.actualDose = actualDose
        }

        try context.save()

        let service = ScheduleService(context: context)
        let issues = service.detectAdherenceIssues(for: schedule)

        // Should detect frequent reschedules
        let rescheduleIssue = issues.first { $0.type == .frequentReschedules }
        #expect(rescheduleIssue != nil)
        #expect(rescheduleIssue?.severity == .medium)
    }

    // MARK: - Stream C: Calendar Adherence Statistics Tests

    @Test("Calculate calendar schedule adherence with mixed dose states")
    func testCalculateCalendarScheduleAdherenceWithMixedDoseStates() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()

        // Create 10 scheduled doses with varied states:
        // 6 taken, 2 missed, 2 skipped
        // Note: createTestScheduledDose creates window: scheduledTime ± 2 hours
        for index in 0..<10 {
            // Space doses 3 days apart, starting 30 days ago
            // This ensures windowEnd is well in the past for missed doses
            let scheduledTime = Calendar.current.date(byAdding: .day, value: -30 + (index * 3), to: now)!
            let dose = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )

            if index < 6 {
                // Mark first 6 as taken
                let actualDose = Dose(
                    amount: 0.5,
                    timestamp: scheduledTime,
                    site: "Abdomen"
                )
                actualDose.medication = profile
                context.insert(actualDose)
                dose.actualDose = actualDose
            } else if index >= 8 {
                // Mark last 2 as skipped (indices 8 and 9)
                // Use Stream B's markAsSkipped method
                dose.markAsSkipped(reason: "Feeling unwell")
            }
            // Indices 6 and 7: Mark as missed (no actualDose, no skippedAt, past window)
            // These will automatically be .missed due to windowEnd < now
        }

        try context.save()

        let service = ScheduleService(context: context)
        let startDate = Calendar.current.date(byAdding: .day, value: -31, to: now)!
        let endDate = now

        let metrics = service.calculateAdherence(
            for: schedule,
            from: startDate,
            to: endDate
        )

        // Verify adherence calculation
        // 6 taken / (6 taken + 2 missed) = 75%
        // Skipped doses don't count against adherence
        #expect(metrics.totalTaken == 6)
        #expect(metrics.totalMissed == 2)
        #expect(metrics.totalSkipped == 2)
        #expect(metrics.adherencePercentage == 0.75)
    }

    @Test("Calculate schedule adherence for specific month range")
    func testCalculateScheduleAdherenceForSpecificMonthRange() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let calendar = Calendar.current
        let now = Date()

        // Use a past month to ensure all doses are definitely past their windows
        // Go back 2 months to be safe
        let pastDate = calendar.date(byAdding: .month, value: -2, to: now)!
        let components = calendar.dateComponents([.year, .month], from: pastDate)
        let startOfMonth = calendar.date(from: components)!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!

        // Create 4 scheduled doses within that past month (weekly schedule)
        var scheduledTimes: [Date] = []
        var currentDate = startOfMonth
        while currentDate <= endOfMonth {
            if calendar.component(.weekday, from: currentDate) == 2 {  // Monday
                scheduledTimes.append(currentDate)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        // Create scheduled doses and mark the first three as taken
        let expectedTaken = min(3, scheduledTimes.count)
        for (index, scheduledTime) in scheduledTimes.enumerated() {
            let dose = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )

            if index < expectedTaken {
                // Mark first 3 as taken
                let actualDose = Dose(
                    amount: 0.5,
                    timestamp: scheduledTime,
                    site: "Abdomen"
                )
                actualDose.medication = profile
                context.insert(actualDose)
                dose.actualDose = actualDose
            }
            // Last one remains missed (past windowEnd, no actualDose, no skippedAt = .missed)
        }

        try context.save()

        let service = ScheduleService(context: context)
        let metrics = service.calculateAdherence(
            for: schedule,
            from: startOfMonth,
            to: endOfMonth
        )

        // Verify monthly adherence
        #expect(metrics.totalScheduled == scheduledTimes.count)
        #expect(metrics.totalTaken == expectedTaken)
        #expect(metrics.totalMissed == scheduledTimes.count - expectedTaken)
        #expect(
            abs(metrics.adherencePercentage - Double(expectedTaken) / Double(scheduledTimes.count)) < 0.01
        )
    }

    @Test("Calculate schedule adherence with zero scheduled doses")
    func testCalculateScheduleAdherenceWithZeroScheduledDoses() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()
        let startDate = Calendar.current.date(byAdding: .month, value: 1, to: now)!  // Future month
        let endDate = Calendar.current.date(byAdding: .month, value: 2, to: now)!

        let service = ScheduleService(context: context)
        let metrics = service.calculateAdherence(
            for: schedule,
            from: startDate,
            to: endDate
        )

        // Should handle zero scheduled doses gracefully
        #expect(metrics.totalScheduled == 0)
        #expect(metrics.totalTaken == 0)
        #expect(metrics.totalMissed == 0)
        #expect(metrics.adherencePercentage == 0.0)  // Or 1.0 if no misses means 100%
    }

    @Test("Calculate schedule adherence stats for calendar display")
    func testCalculateScheduleAdherenceStatsForCalendarDisplay() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let now = Date()

        // Create 20 scheduled doses with varied states
        for index in 0..<20 {
            let scheduledTime = Calendar.current.date(byAdding: .day, value: -60 + (index * 3), to: now)!
            let dose = createTestScheduledDose(
                context: context,
                schedule: schedule,
                scheduledTime: scheduledTime
            )

            if index < 15 {
                // 15 taken
                let actualDose = Dose(
                    amount: 0.5,
                    timestamp: scheduledTime,
                    site: "Abdomen"
                )
                actualDose.medication = profile
                context.insert(actualDose)
                dose.actualDose = actualDose
            } else if index >= 17 {
                // Last 3 skipped (indices 17, 18, 19)
                // Use Stream B's markAsSkipped method
                dose.markAsSkipped(reason: "Side effects")
            }
            // Indices 15 and 16: 2 missed
            // Leave unhandled past window (no actualDose, no skippedAt, past windowEnd = missed)
        }

        try context.save()

        let service = ScheduleService(context: context)
        let startDate = Calendar.current.date(byAdding: .day, value: -61, to: now)!
        let endDate = now

        let metrics = service.calculateAdherence(
            for: schedule,
            from: startDate,
            to: endDate
        )

        // Verify stats suitable for calendar display
        #expect(metrics.totalScheduled == 20)
        #expect(metrics.totalTaken == 15)
        #expect(metrics.totalMissed == 2)
        #expect(metrics.totalSkipped == 3)
        #expect(metrics.adherencePercentage == 15.0 / 17.0)  // 15 taken / (15 taken + 2 missed)

        // Verify on-time percentage calculation
        #expect(metrics.onTimePercentage >= 0.0)
        #expect(metrics.onTimePercentage <= 1.0)
    }
}
