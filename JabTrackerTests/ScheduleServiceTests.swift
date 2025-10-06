//
//  ScheduleServiceTests.swift
//  JabTrackerTests
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Tests for ScheduleService CRUD operations
@MainActor
struct ScheduleServiceTests {

    // MARK: - Test Helpers

    /// Creates a test ModelContext with all required models
    private func createTestContext() throws -> ModelContext {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            Dose.self,
            DoseSchedule.self,
            ScheduledDose.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    /// Creates a test medication profile for scheduling tests
    private func createTestMedicationProfile(context: ModelContext) -> MedicationProfile {
        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5,
            preferredInjectionSites: ["Abdomen", "Thigh"]
        )
        profile.user = user
        context.insert(profile)

        try? context.save()
        return profile
    }

    // MARK: - Create Schedule Tests

    @Test("Create schedule with weekly pattern")
    func testCreateScheduleWeekly() throws {
        // GIVEN: A context and medication profile
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        // WHEN: Creating a weekly schedule
        let startDate = Date()
        let config = ScheduleConfiguration(
            dayOfWeek: 1,  // Monday
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 0.5,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: startDate,
            baseSchedule: config
        )

        // THEN: Schedule is created with correct properties
        #expect(schedule.medicationProfile === profile)
        #expect(schedule.patternType == .weekly)
        #expect(schedule.isActive == true)

        // Decode and verify configuration
        let decodedConfig = try service.decodeScheduleConfiguration(schedule)
        #expect(decodedConfig.dayOfWeek == 1)
        #expect(decodedConfig.doseAmount == 0.5)
        #expect(service.activeSchedules.count == 1)
    }

    @Test("Create schedule with split-dose pattern")
    func testCreateScheduleSplitDose() throws {
        // GIVEN: A context and medication profile
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        // WHEN: Creating a split-dose schedule
        let startDate = Date()
        let config = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 1.0,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: 2,
            splitIntervalMinutes: 180,  // 3 hours between splits
            customRecurrence: nil
        )

        let schedule = try service.createSchedule(
            for: profile,
            pattern: .splitDose,
            startDate: startDate,
            baseSchedule: config
        )

        // THEN: Schedule is created with split-dose configuration
        #expect(schedule.patternType == .splitDose)

        // Decode and verify configuration
        let decodedConfig = try service.decodeScheduleConfiguration(schedule)
        #expect(decodedConfig.splitDoseCount == 2)
        #expect(decodedConfig.splitIntervalMinutes == 180)
    }

    @Test("Create schedule with custom pattern")
    func testCreateScheduleCustom() throws {
        // GIVEN: A context and medication profile
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        // WHEN: Creating a custom schedule
        let startDate = Date()
        let customRecurrence = CustomRecurrence(
            frequency: .weekly,
            intervalDays: 7,
            daysOfWeek: [1, 4],  // Monday and Thursday
            monthlyPattern: nil
        )
        let config = ScheduleConfiguration(
            dayOfWeek: nil,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 0.5,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: customRecurrence
        )

        let schedule = try service.createSchedule(
            for: profile,
            pattern: .custom,
            startDate: startDate,
            baseSchedule: config
        )

        // THEN: Schedule is created with custom configuration
        #expect(schedule.patternType == .custom)

        // Decode and verify configuration
        let decodedConfig = try service.decodeScheduleConfiguration(schedule)
        #expect(decodedConfig.customRecurrence != nil)
        #expect(decodedConfig.customRecurrence?.daysOfWeek == [1, 4])
    }

    // MARK: - Update Schedule Tests

    @Test("Update schedule pattern type")
    func testUpdateSchedulePattern() throws {
        // GIVEN: An existing weekly schedule
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 0.5,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: Date(),
            baseSchedule: config
        )

        let originalUpdatedAt = schedule.updatedAt

        // WHEN: Updating to split-dose pattern
        let newConfig = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 1.0,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: 2,
            splitIntervalMinutes: 180,
            customRecurrence: nil
        )

        try service.updateSchedule(
            schedule,
            newPattern: .splitDose,
            newBaseSchedule: newConfig
        )

        // THEN: Schedule is updated
        #expect(schedule.patternType == .splitDose)
        #expect(schedule.baseSchedule.splitDoseCount == 2)
        #expect(schedule.updatedAt > originalUpdatedAt)
    }

    @Test("Update base schedule configuration")
    func testUpdateBaseScheduleConfiguration() throws {
        // GIVEN: An existing schedule
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 0.5,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: Date(),
            baseSchedule: config
        )

        // WHEN: Updating dose amount and day of week
        let newConfig = ScheduleConfiguration(
            dayOfWeek: 3,  // Wednesday instead of Monday
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 1.0,  // Increased dose
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        try service.updateSchedule(
            schedule,
            newPattern: .weekly,
            newBaseSchedule: newConfig
        )

        // THEN: Configuration is updated
        #expect(schedule.baseSchedule.dayOfWeek == 3)
        #expect(schedule.baseSchedule.doseAmount == 1.0)
    }

    // MARK: - Delete Schedule Tests

    @Test("Delete schedule with cascade to ScheduledDose entities")
    func testDeleteScheduleCascade() throws {
        // GIVEN: A schedule with generated scheduled doses
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 0.5,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: Date(),
            baseSchedule: config
        )

        // Create some scheduled doses for this schedule
        let scheduledDose1 = ScheduledDose(
            schedule: schedule,
            scheduledTime: Date(),
            doseAmount: 0.5
        )
        let scheduledDose2 = ScheduledDose(
            schedule: schedule,
            scheduledTime: Date().addingTimeInterval(7 * 24 * 3600),
            doseAmount: 0.5
        )
        context.insert(scheduledDose1)
        context.insert(scheduledDose2)
        try context.save()

        // WHEN: Deleting the schedule
        try service.deleteSchedule(schedule)

        // THEN: Schedule is marked inactive and scheduled doses are cascade deleted
        #expect(schedule.isActive == false)
        #expect(service.activeSchedules.count == 0)

        // Verify scheduled doses are deleted (cascade rule)
        let descriptor = FetchDescriptor<ScheduledDose>()
        let remainingDoses = try context.fetch(descriptor)
        #expect(remainingDoses.count == 0)
    }

    // MARK: - Pause/Resume Schedule Tests

    @Test("Pause schedule sets pausedAt and pausedUntil")
    func testPauseSchedule() throws {
        // GIVEN: An active schedule
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 0.5,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: Date(),
            baseSchedule: config
        )

        // WHEN: Pausing the schedule until a future date
        let pauseUntil = Date().addingTimeInterval(14 * 24 * 3600)  // 2 weeks
        try service.pauseSchedule(schedule, until: pauseUntil)

        // THEN: Pause fields are set
        #expect(schedule.pausedAt != nil)
        #expect(schedule.pausedUntil != nil)
        #expect(schedule.pausedUntil == pauseUntil)
        #expect(schedule.isActive == true)  // Still active, just paused
    }

    @Test("Resume schedule clears pause fields")
    func testResumeSchedule() throws {
        // GIVEN: A paused schedule
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 0.5,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: Date(),
            baseSchedule: config
        )

        let pauseUntil = Date().addingTimeInterval(14 * 24 * 3600)
        try service.pauseSchedule(schedule, until: pauseUntil)

        // WHEN: Resuming the schedule
        try service.resumeSchedule(schedule)

        // THEN: Pause fields are cleared
        #expect(schedule.pausedAt == nil)
        #expect(schedule.pausedUntil == nil)
        #expect(schedule.isActive == true)
    }

    // MARK: - CRUD Operations Update Timestamps Tests

    @Test("CRUD operations update timestamps correctly")
    func testTimestampUpdates() throws {
        // GIVEN: A schedule
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 0.5,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        // WHEN: Creating a schedule
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: Date(),
            baseSchedule: config
        )

        let createdAt = schedule.createdAt
        let firstUpdatedAt = schedule.updatedAt

        // Small delay to ensure timestamp difference
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 second

        // WHEN: Updating the schedule
        let newConfig = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 1.0,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        try service.updateSchedule(
            schedule,
            newPattern: .weekly,
            newBaseSchedule: newConfig
        )

        // THEN: updatedAt is later than initial value
        #expect(schedule.createdAt == createdAt)  // createdAt unchanged
        #expect(schedule.updatedAt > firstUpdatedAt)  // updatedAt advanced
    }

    // MARK: - Error Handling Tests

    @Test("Create schedule with invalid configuration throws error")
    func testCreateScheduleInvalidConfiguration() throws {
        // GIVEN: A context and medication profile
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        // WHEN/THEN: Creating a schedule with negative dose amount throws error
        let invalidConfig = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: -0.5,  // Invalid negative amount
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        #expect(throws: ScheduleServiceError.invalidDoseAmount) {
            try service.createSchedule(
                for: profile,
                pattern: .weekly,
                startDate: Date(),
                baseSchedule: invalidConfig
            )
        }
    }

    @Test("Pause schedule with past date throws error")
    func testPauseSchedulePastDate() throws {
        // GIVEN: An active schedule
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 0.5,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: Date(),
            baseSchedule: config
        )

        // WHEN/THEN: Pausing with past date throws error
        let pastDate = Date().addingTimeInterval(-7 * 24 * 3600)  // 1 week ago
        #expect(throws: ScheduleServiceError.pauseUntilInPast) {
            try service.pauseSchedule(schedule, until: pastDate)
        }
    }
}
