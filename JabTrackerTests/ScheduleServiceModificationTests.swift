//
//  ScheduleServiceModificationTests.swift
//  JabTrackerTests
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
struct ScheduleServiceModificationTests {

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
        scheduledTime: Date = Date(),
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

    // MARK: - Reschedule Tests

    @Test("Reschedule dose within valid range succeeds")
    func testRescheduleDoseWithinValidRange() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let originalTime = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            scheduledTime: originalTime
        )
        try context.save()

        let service = ScheduleService(context: context)

        // Reschedule to 3 days later (within 7-day limit)
        let newTime = Calendar.current.date(byAdding: .day, value: 3, to: originalTime)!

        try service.rescheduleDose(scheduledDose, to: newTime)

        // Verify scheduled time updated
        #expect(scheduledDose.scheduledTime == newTime)

        // Verify original time preserved
        #expect(scheduledDose.rescheduledFrom == originalTime)

        // Verify adherence window updated
        let expectedWindowStart = newTime.addingTimeInterval(-2 * 60 * 60)
        let expectedWindowEnd = newTime.addingTimeInterval(2 * 60 * 60)

        #expect(abs(scheduledDose.windowStart.timeIntervalSince(expectedWindowStart)) < 1.0)
        #expect(abs(scheduledDose.windowEnd.timeIntervalSince(expectedWindowEnd)) < 1.0)

        // Verify updatedAt timestamp updated
        #expect(scheduledDose.updatedAt > originalTime)
    }

    @Test("Reschedule dose beyond 7 days throws error")
    func testRescheduleDoseBeyondValidRange() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let originalTime = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            scheduledTime: originalTime
        )
        try context.save()

        let service = ScheduleService(context: context)

        // Try to reschedule 8 days later (exceeds 7-day limit)
        let newTime = Calendar.current.date(byAdding: .day, value: 8, to: originalTime)!

        #expect(throws: ScheduleServiceError.invalidTimeRange) {
            try service.rescheduleDose(scheduledDose, to: newTime)
        }

        // Verify dose unchanged
        #expect(scheduledDose.scheduledTime == originalTime)
        #expect(scheduledDose.rescheduledFrom == nil)
    }

    @Test("Reschedule dose that is already taken throws error")
    func testRescheduleAlreadyTakenDose() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let scheduledDose = createTestScheduledDose(context: context, schedule: schedule)

        // Create actual dose and link
        let actualDose = Dose(
            amount: 0.5,
            timestamp: Date(),
            site: "Abdomen"
        )
        actualDose.medication = profile
        context.insert(actualDose)
        scheduledDose.actualDose = actualDose
        try context.save()

        let service = ScheduleService(context: context)
        let newTime = Date().addingTimeInterval(24 * 60 * 60)

        #expect(throws: ScheduleServiceError.doseNotModifiable) {
            try service.rescheduleDose(scheduledDose, to: newTime)
        }
    }

    @Test("Reschedule dose that is already skipped throws error")
    func testRescheduleAlreadySkippedDose() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let scheduledDose = createTestScheduledDose(context: context, schedule: schedule)
        scheduledDose.skippedAt = Date()
        scheduledDose.skipReason = "Feeling unwell"
        try context.save()

        let service = ScheduleService(context: context)
        let newTime = Date().addingTimeInterval(24 * 60 * 60)

        #expect(throws: ScheduleServiceError.doseNotModifiable) {
            try service.rescheduleDose(scheduledDose, to: newTime)
        }
    }

    @Test("Multiple reschedules preserve original time")
    func testMultipleReschedulesPreserveOriginalTime() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let originalTime = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            scheduledTime: originalTime
        )
        try context.save()

        let service = ScheduleService(context: context)

        // First reschedule
        let firstNewTime = Calendar.current.date(byAdding: .day, value: 1, to: originalTime)!
        try service.rescheduleDose(scheduledDose, to: firstNewTime)

        #expect(scheduledDose.scheduledTime == firstNewTime)
        #expect(scheduledDose.rescheduledFrom == originalTime)

        // Second reschedule
        let secondNewTime = Calendar.current.date(byAdding: .day, value: 2, to: originalTime)!
        try service.rescheduleDose(scheduledDose, to: secondNewTime)

        // Verify original time still preserved
        #expect(scheduledDose.scheduledTime == secondNewTime)
        #expect(scheduledDose.rescheduledFrom == originalTime)
    }

    // MARK: - Skip Dose Tests

    @Test("Skip dose sets skipped timestamp and reason")
    func testSkipDoseSetsTimestampAndReason() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let scheduledDose = createTestScheduledDose(context: context, schedule: schedule)
        try context.save()

        let service = ScheduleService(context: context)
        let skipReason = "Feeling unwell"
        let beforeSkip = Date()

        try service.skipDose(scheduledDose, reason: skipReason)

        // Verify skippedAt set
        #expect(scheduledDose.skippedAt != nil)
        #expect(scheduledDose.skippedAt! >= beforeSkip)

        // Verify reason set
        #expect(scheduledDose.skipReason == skipReason)

        // Verify updatedAt updated
        #expect(scheduledDose.updatedAt >= beforeSkip)
    }

    @Test("Skip dose without reason succeeds")
    func testSkipDoseWithoutReason() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let scheduledDose = createTestScheduledDose(context: context, schedule: schedule)
        try context.save()

        let service = ScheduleService(context: context)

        try service.skipDose(scheduledDose, reason: nil)

        // Verify skippedAt set
        #expect(scheduledDose.skippedAt != nil)

        // Verify reason is nil
        #expect(scheduledDose.skipReason == nil)
    }

    @Test("Skip dose that is already taken throws error")
    func testSkipAlreadyTakenDose() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let scheduledDose = createTestScheduledDose(context: context, schedule: schedule)

        // Create actual dose and link
        let actualDose = Dose(
            amount: 0.5,
            timestamp: Date(),
            site: "Abdomen"
        )
        actualDose.medication = profile
        context.insert(actualDose)
        scheduledDose.actualDose = actualDose
        try context.save()

        let service = ScheduleService(context: context)

        #expect(throws: ScheduleServiceError.doseNotModifiable) {
            try service.skipDose(scheduledDose, reason: "Test")
        }
    }

    // MARK: - Mark Dose Taken Tests

    @Test("Mark dose taken links actual dose")
    func testMarkDoseTakenLinksActualDose() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let scheduledDose = createTestScheduledDose(context: context, schedule: schedule)

        let actualDose = Dose(
            amount: 0.5,
            timestamp: Date(),
            site: "Abdomen"
        )
        actualDose.medication = profile
        context.insert(actualDose)
        try context.save()

        let service = ScheduleService(context: context)

        try service.markDoseTaken(scheduledDose, actualDose: actualDose)

        // Verify link created
        #expect(scheduledDose.actualDose == actualDose)
        #expect(actualDose.scheduledDose == scheduledDose)

        // Verify updatedAt updated
        #expect(scheduledDose.updatedAt > Date().addingTimeInterval(-5))
    }

    @Test("Mark dose taken on already taken dose throws error")
    func testMarkDoseTakenOnAlreadyTakenDose() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let scheduledDose = createTestScheduledDose(context: context, schedule: schedule)

        // First actual dose
        let firstDose = Dose(
            amount: 0.5,
            timestamp: Date(),
            site: "Abdomen"
        )
        firstDose.medication = profile
        context.insert(firstDose)
        scheduledDose.actualDose = firstDose
        try context.save()

        let service = ScheduleService(context: context)

        // Try to link second dose
        let secondDose = Dose(
            amount: 0.5,
            timestamp: Date(),
            site: "Thigh"
        )
        secondDose.medication = profile
        context.insert(secondDose)

        #expect(throws: ScheduleServiceError.doseNotModifiable) {
            try service.markDoseTaken(scheduledDose, actualDose: secondDose)
        }

        // Verify original link preserved
        #expect(scheduledDose.actualDose == firstDose)
    }

    @Test("Mark dose taken on skipped dose throws error")
    func testMarkDoseTakenOnSkippedDose() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let scheduledDose = createTestScheduledDose(context: context, schedule: schedule)
        scheduledDose.skippedAt = Date()
        try context.save()

        let service = ScheduleService(context: context)

        let actualDose = Dose(
            amount: 0.5,
            timestamp: Date(),
            site: "Abdomen"
        )
        actualDose.medication = profile
        context.insert(actualDose)

        #expect(throws: ScheduleServiceError.doseNotModifiable) {
            try service.markDoseTaken(scheduledDose, actualDose: actualDose)
        }
    }

    // MARK: - Combined Modification Tests

    @Test("Skip dose after reschedule succeeds")
    func testSkipDoseAfterReschedule() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let originalTime = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            scheduledTime: originalTime
        )
        try context.save()

        let service = ScheduleService(context: context)

        // First reschedule
        let newTime = Calendar.current.date(byAdding: .day, value: 2, to: originalTime)!
        try service.rescheduleDose(scheduledDose, to: newTime)

        // Then skip
        try service.skipDose(scheduledDose, reason: "Changed plans")

        // Verify both operations succeeded
        #expect(scheduledDose.rescheduledFrom == originalTime)
        #expect(scheduledDose.scheduledTime == newTime)
        #expect(scheduledDose.skippedAt != nil)
        #expect(scheduledDose.skipReason == "Changed plans")
    }

    @Test("Mark taken after reschedule succeeds")
    func testMarkTakenAfterReschedule() throws {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive for duration of test
        let profile = createTestProfile(context: context)
        let schedule = try createTestSchedule(context: context, profile: profile)

        let originalTime = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            scheduledTime: originalTime
        )
        try context.save()

        let service = ScheduleService(context: context)

        // First reschedule
        let newTime = Calendar.current.date(byAdding: .day, value: 1, to: originalTime)!
        try service.rescheduleDose(scheduledDose, to: newTime)

        // Then mark taken
        let actualDose = Dose(
            amount: 0.5,
            timestamp: newTime,
            site: "Abdomen"
        )
        actualDose.medication = profile
        context.insert(actualDose)
        try service.markDoseTaken(scheduledDose, actualDose: actualDose)

        // Verify both operations succeeded
        #expect(scheduledDose.rescheduledFrom == originalTime)
        #expect(scheduledDose.scheduledTime == newTime)
        #expect(scheduledDose.actualDose == actualDose)
    }
}
