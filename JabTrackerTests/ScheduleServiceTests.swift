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

        // Decode and verify configuration
        let decodedConfig = try service.decodeScheduleConfiguration(schedule)
        #expect(decodedConfig.splitDoseCount == 2)
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
        let decodedConfig = try service.decodeScheduleConfiguration(schedule)
        #expect(decodedConfig.dayOfWeek == 3)
        #expect(decodedConfig.doseAmount == 1.0)
    }

    // MARK: - Delete Schedule Tests

    @Test("Delete schedule marks inactive")
    func testDeleteSchedule() throws {
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

        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: Date(),
            baseSchedule: config
        )

        // WHEN: Deleting the schedule
        try service.deleteSchedule(schedule)

        // THEN: Schedule is marked inactive
        #expect(schedule.isActive == false)
        #expect(service.activeSchedules.count == 0)
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

    // MARK: - Error Handling Tests

    @Test("Create schedule with invalid dose amount throws error")
    func testCreateScheduleInvalidDoseAmount() throws {
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

        var didThrow = false
        do {
            _ = try service.createSchedule(
                for: profile,
                pattern: .weekly,
                startDate: Date(),
                baseSchedule: invalidConfig
            )
        } catch {
            didThrow = true
        }

        #expect(didThrow == true)
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
        var didThrow = false
        do {
            try service.pauseSchedule(schedule, until: pastDate)
        } catch {
            didThrow = true
        }

        #expect(didThrow == true)
    }

    // MARK: - Split-Dose Configuration Tests

    @Test("Split-dose configuration for weekly medication returns correct interval")
    func testSplitDoseConfigurationWeeklyMedication() throws {
        // GIVEN: A weekly medication (semaglutide)
        let medication = Medication.semaglutide
        let totalWeeklyDose = 0.5

        // WHEN: Creating split-dose configuration
        let config = try ScheduleConfiguration.splitDoseConfiguration(
            for: medication,
            totalWeeklyDose: totalWeeklyDose
        )

        // THEN: Configuration has correct 3.5-day interval (5040 minutes)
        #expect(config.splitIntervalMinutes == 5040, "Split interval should be 3.5 days (5040 minutes)")
        #expect(config.splitDoseCount == 2, "Should split into 2 doses")
        #expect(config.interval == 7, "Should maintain weekly interval")
        #expect(config.doseAmount == totalWeeklyDose / 2.0, "Each dose should be half of total weekly dose")
    }

    @Test("Split-dose configuration for daily medication throws error")
    func testSplitDoseConfigurationDailyMedicationThrows() throws {
        // GIVEN: A daily medication (liraglutide)
        let medication = Medication.liraglutide
        let totalDailyDose = 1.8

        // WHEN/THEN: Attempting split-dose configuration throws error
        var didThrow = false
        var errorMessage = ""
        do {
            _ = try ScheduleConfiguration.splitDoseConfiguration(
                for: medication,
                totalWeeklyDose: totalDailyDose
            )
        } catch let error as ScheduleServiceError {
            didThrow = true
            errorMessage = error.localizedDescription
        }

        #expect(didThrow == true, "Should throw error for daily medication")
        #expect(
            errorMessage.contains("Split-dose is only supported for weekly medications"),
            "Error message should explain split-dose limitation")
    }

    @Test("Split-dose configuration validation - tirzepatide")
    func testSplitDoseConfigurationTirzepatide() throws {
        // GIVEN: Tirzepatide (weekly medication)
        let medication = Medication.tirzepatide
        let totalWeeklyDose = 5.0

        // WHEN: Creating split-dose configuration
        let config = try ScheduleConfiguration.splitDoseConfiguration(
            for: medication,
            totalWeeklyDose: totalWeeklyDose
        )

        // THEN: Configuration is correct
        #expect(config.splitIntervalMinutes == 5040, "Split interval should be 3.5 days")
        #expect(config.doseAmount == 2.5, "Each dose should be 2.5mg (half of 5.0mg)")
    }
}
