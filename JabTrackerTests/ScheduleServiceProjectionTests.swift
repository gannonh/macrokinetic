//
//  ScheduleServiceProjectionTests.swift
//  JabTrackerTests
//
//  Created by Claude Code on 2025-10-06.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Tests for ScheduleService schedule projection and dose generation algorithms
@MainActor
struct ScheduleServiceProjectionTests {

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

        return profile
    }

    /// Creates a weekly schedule configuration
    private func createWeeklyScheduleConfig(
        dayOfWeek: Int = 1,  // Monday
        hour: Int = 9,
        minute: Int = 0,
        doseAmount: Double = 0.5,
        interval: Int = 7
    ) -> ScheduleConfiguration {
        ScheduleConfiguration(
            dayOfWeek: dayOfWeek,
            timeOfDay: TimeComponents(hour: hour, minute: minute),
            interval: interval,
            doseAmount: doseAmount,
            windowMinutesBefore: 120,  // 2 hours
            windowMinutesAfter: 120,  // 2 hours
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )
    }

    // MARK: - Weekly Pattern Generation Tests

    /// Test: Generate weekly doses for 30 days (approximately 4-5 doses)
    @Test("Generate weekly doses for 30 days")
    func testGenerateWeeklyDosesFor30Days() throws {
        // GIVEN: A schedule with weekly pattern starting today
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = createWeeklyScheduleConfig()
        let startDate = Date()
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: startDate,
            baseSchedule: config
        )

        // WHEN: Generating doses for next 30 days
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate)!
        let doses = service.generateScheduledDoses(for: schedule, from: startDate, to: endDate)

        // THEN: Should generate approximately 4-5 doses (30 days / 7 days)
        #expect(doses.count >= 4 && doses.count <= 5, "Expected 4-5 weekly doses in 30 days, got \(doses.count)")

        // THEN: All doses should have correct amount
        for dose in doses {
            #expect(dose.doseAmount == config.doseAmount)
        }

        // THEN: All doses should have scheduling windows (±2 hours)
        for dose in doses {
            let windowBefore = dose.scheduledTime.timeIntervalSince(dose.windowStart)
            let windowAfter = dose.windowEnd.timeIntervalSince(dose.scheduledTime)

            #expect(abs(windowBefore - 7200) < 60, "Window before should be ~2 hours")  // 7200s = 2h
            #expect(abs(windowAfter - 7200) < 60, "Window after should be ~2 hours")
        }

        // THEN: Doses should be approximately 7 days apart
        for index in 1..<doses.count {
            let interval = doses[index].scheduledTime.timeIntervalSince(doses[index - 1].scheduledTime)
            let expectedInterval: TimeInterval = 7 * 24 * 60 * 60  // 7 days in seconds
            #expect(abs(interval - expectedInterval) < 3600, "Doses should be ~7 days apart")  // ±1 hour tolerance
        }
    }

    /// Test: Generate weekly doses for 365 days (performance test - must be <100ms)
    @Test("Generate weekly doses for 365 days - performance test")
    func testGenerateWeeklyDosesFor365DaysPerformance() throws {
        // GIVEN: A schedule with weekly pattern
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = createWeeklyScheduleConfig()
        let startDate = Date()
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: startDate,
            baseSchedule: config
        )

        // WHEN: Generating doses for 365 days
        let endDate = Calendar.current.date(byAdding: .day, value: 365, to: startDate)!

        let startTime = Date()
        let doses = service.generateScheduledDoses(for: schedule, from: startDate, to: endDate)
        let executionTime = Date().timeIntervalSince(startTime) * 1000  // Convert to ms

        // THEN: Should complete in <100ms (critical performance requirement)
        print("📊 Performance: Generated \(doses.count) doses in \(String(format: "%.2f", executionTime))ms")
        #expect(
            executionTime < 100,
            "365-day projection must complete in <100ms, took \(String(format: "%.2f", executionTime))ms")

        // THEN: Should generate approximately 52 doses (365 days / 7 days)
        #expect(doses.count >= 52 && doses.count <= 53, "Expected ~52 weekly doses in 365 days, got \(doses.count)")
    }

    /// Test: Generate weekly doses with correct day-of-week alignment
    @Test("Weekly doses align with configured day of week")
    func testWeeklyDosesAlignWithDayOfWeek() throws {
        // GIVEN: A schedule configured for Mondays (dayOfWeek: 2)
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = createWeeklyScheduleConfig(dayOfWeek: 2)  // Monday
        let startDate = Date()
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: startDate,
            baseSchedule: config
        )

        // WHEN: Generating doses for 30 days
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate)!
        let doses = service.generateScheduledDoses(for: schedule, from: startDate, to: endDate)

        // THEN: All doses should fall on Mondays
        let calendar = Calendar.current
        for dose in doses {
            let weekday = calendar.component(.weekday, from: dose.scheduledTime)
            #expect(weekday == 2, "Dose should be on Monday (weekday 2), got \(weekday)")
        }
    }

    /// Test: Generate weekly doses with correct time-of-day
    @Test("Weekly doses have correct time of day")
    func testWeeklyDosesHaveCorrectTimeOfDay() throws {
        // GIVEN: A schedule configured for 9:30 AM
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = createWeeklyScheduleConfig(hour: 9, minute: 30)
        let startDate = Date()
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: startDate,
            baseSchedule: config
        )

        // WHEN: Generating doses for 30 days
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate)!
        let doses = service.generateScheduledDoses(for: schedule, from: startDate, to: endDate)

        // THEN: All doses should be at 9:30 AM
        let calendar = Calendar.current
        for dose in doses {
            let hour = calendar.component(.hour, from: dose.scheduledTime)
            let minute = calendar.component(.minute, from: dose.scheduledTime)

            #expect(hour == 9, "Hour should be 9, got \(hour)")
            #expect(minute == 30, "Minute should be 30, got \(minute)")
        }
    }

    // MARK: - Edge Case Tests

    /// Test: Generate doses when schedule starts in the past
    @Test("Generate doses when schedule starts in past")
    func testGenerateDosesWithPastStartDate() throws {
        // GIVEN: A schedule that started 14 days ago
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = createWeeklyScheduleConfig()
        let pastStartDate = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: pastStartDate,
            baseSchedule: config
        )

        // WHEN: Generating doses from past start date to 30 days in future
        let futureEndDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let doses = service.generateScheduledDoses(for: schedule, from: pastStartDate, to: futureEndDate)

        // THEN: Should generate doses for entire period (past + future)
        // 44 days / 7 days = ~6 doses
        #expect(doses.count >= 6 && doses.count <= 7, "Expected ~6 doses for 44-day period, got \(doses.count)")

        // THEN: Some doses should be in the past
        let now = Date()
        let pastDoses = doses.filter { $0.scheduledTime < now }
        #expect(pastDoses.count >= 2, "Expected at least 2 past doses")
    }

    /// Test: Generate doses when schedule has no future doses
    @Test("Generate doses returns empty array when no future doses")
    func testGenerateDosesWithNoFutureDoses() throws {
        // GIVEN: A schedule with past date range
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = createWeeklyScheduleConfig()
        let startDate = Date()
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: startDate,
            baseSchedule: config
        )

        // WHEN: Requesting doses for past date range only
        let pastStart = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let pastEnd = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let doses = service.generateScheduledDoses(for: schedule, from: pastStart, to: pastEnd)

        // THEN: Should return empty array (no doses before schedule start)
        #expect(doses.isEmpty, "Expected no doses for date range before schedule start")
    }

    // MARK: - Pause Period Handling Tests

    /// Test: Skip dose generation during pause periods
    @Test("Skip dose generation during pause period")
    func testSkipDoseGenerationDuringPause() throws {
        // GIVEN: A paused schedule
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = createWeeklyScheduleConfig()
        let startDate = Date()
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: startDate,
            baseSchedule: config
        )

        // Pause schedule for next 14 days
        let pauseUntil = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        try service.pauseSchedule(schedule, until: pauseUntil)

        // WHEN: Generating doses for next 30 days
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate)!
        let doses = service.generateScheduledDoses(for: schedule, from: startDate, to: endDate)

        // THEN: Should skip doses during pause period (14 days)
        // Without pause: ~4 doses in 30 days
        // With 14-day pause: ~2 doses (only from day 15-30)
        #expect(doses.count <= 3, "Expected fewer doses due to pause period, got \(doses.count)")

        // THEN: No doses should fall within pause period
        for dose in doses {
            let isInPausePeriod = dose.scheduledTime >= Date() && dose.scheduledTime < pauseUntil
            #expect(!isInPausePeriod, "Dose should not be scheduled during pause period")
        }
    }

    // MARK: - Split-Dose Pattern Tests

    /// Test: Generate split-dose pattern correctly
    @Test("Generate split-dose pattern with multiple doses per day")
    func testGenerateSplitDosePattern() throws {
        // GIVEN: A schedule with split-dose pattern (2 doses, 6 hours apart)
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = ScheduleConfiguration(
            dayOfWeek: nil,
            timeOfDay: TimeComponents(hour: 8, minute: 0),  // First dose at 8 AM
            interval: 1,  // Daily
            doseAmount: 2.5,  // Tirzepatide
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: 2,
            splitIntervalMinutes: 360,  // 6 hours between doses
            customRecurrence: nil
        )

        let startDate = Date()
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .splitDose,
            startDate: startDate,
            baseSchedule: config
        )

        // WHEN: Generating doses for 7 days
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        let doses = service.generateScheduledDoses(for: schedule, from: startDate, to: endDate)

        // THEN: Should generate 2 doses per day = 14 total doses
        #expect(doses.count == 14, "Expected 14 doses (2 per day for 7 days), got \(doses.count)")

        // THEN: Doses should be in pairs 6 hours apart
        for index in stride(from: 0, to: doses.count - 1, by: 2) {
            let interval = doses[index + 1].scheduledTime.timeIntervalSince(doses[index].scheduledTime)
            let expectedInterval: TimeInterval = 6 * 60 * 60  // 6 hours in seconds
            #expect(abs(interval - expectedInterval) < 60, "Split doses should be 6 hours apart")
        }
    }

    // MARK: - Custom Pattern Tests

    /// Test: Generate custom pattern from configuration
    @Test("Generate custom pattern from JSON configuration")
    func testGenerateCustomPattern() throws {
        // GIVEN: A schedule with custom recurrence (every 3 days)
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let customRecurrence = CustomRecurrence(
            frequency: .daily,
            intervalDays: 3,
            daysOfWeek: nil,
            monthlyPattern: nil
        )

        let config = ScheduleConfiguration(
            dayOfWeek: nil,
            timeOfDay: TimeComponents(hour: 10, minute: 0),
            interval: 3,  // Every 3 days
            doseAmount: 1.0,
            windowMinutesBefore: 120,
            windowMinutesAfter: 120,
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: customRecurrence
        )

        let startDate = Date()
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .custom,
            startDate: startDate,
            baseSchedule: config
        )

        // WHEN: Generating doses for 30 days
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: startDate)!
        let doses = service.generateScheduledDoses(for: schedule, from: startDate, to: endDate)

        // THEN: Should generate ~10 doses (30 days / 3 days)
        #expect(doses.count >= 10 && doses.count <= 11, "Expected ~10 doses with 3-day interval, got \(doses.count)")

        // THEN: Doses should be approximately 3 days apart
        for index in 1..<doses.count {
            let interval = doses[index].scheduledTime.timeIntervalSince(doses[index - 1].scheduledTime)
            let expectedInterval: TimeInterval = 3 * 24 * 60 * 60  // 3 days in seconds
            #expect(abs(interval - expectedInterval) < 3600, "Doses should be ~3 days apart")
        }
    }

    // MARK: - Dose Escalation Tests

    /// Test: Handle dose escalation over time
    @Test("Handle dose escalation over time")
    func testHandleDoseEscalation() throws {
        // GIVEN: A schedule with initial dose that should escalate
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = createWeeklyScheduleConfig(doseAmount: 0.25)  // Starting dose
        let startDate = Date()
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: startDate,
            baseSchedule: config
        )

        // Simulate dose escalation: increase to 0.5mg after 4 weeks
        // (This would normally be handled by DoseTitration, but we test the schedule generation)
        // Note: escalationDate would be used for titration tracking, but we update schedule directly

        // Update schedule configuration with new dose amount
        let updatedConfig = ScheduleConfiguration(
            dayOfWeek: config.dayOfWeek,
            timeOfDay: config.timeOfDay,
            interval: config.interval,
            doseAmount: 0.5,  // Escalated dose
            windowMinutesBefore: config.windowMinutesBefore,
            windowMinutesAfter: config.windowMinutesAfter,
            splitDoseCount: config.splitDoseCount,
            splitIntervalMinutes: config.splitIntervalMinutes,
            customRecurrence: config.customRecurrence
        )
        try service.updateSchedule(schedule, newPattern: .weekly, newBaseSchedule: updatedConfig)

        // WHEN: Generating doses after escalation
        let endDate = Calendar.current.date(byAdding: .day, value: 60, to: startDate)!
        let doses = service.generateScheduledDoses(for: schedule, from: startDate, to: endDate)

        // THEN: All generated doses should use the new dose amount (0.5mg)
        // (Since we updated the baseSchedule, all projected doses use new amount)
        for dose in doses {
            #expect(dose.doseAmount == 0.5, "Dose amount should be escalated to 0.5mg")
        }
    }

    // MARK: - Next Scheduled Dose Tests

    /// Test: Get next scheduled dose for active schedule
    @Test("Get next scheduled dose returns upcoming dose")
    func testGetNextScheduledDoseReturnsUpcoming() throws {
        // GIVEN: A schedule with future doses
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = createWeeklyScheduleConfig()
        let startDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!  // Start in 1 hour
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: startDate,
            baseSchedule: config
        )

        // WHEN: Getting next scheduled dose
        let nextDose = service.getNextScheduledDose(for: schedule)

        // THEN: Should return a dose
        #expect(nextDose != nil, "Expected to find next scheduled dose")

        // THEN: Next dose should be in the future
        if let dose = nextDose {
            #expect(dose.scheduledTime > Date(), "Next scheduled dose should be in future")
        }
    }

    /// Test: Get next scheduled dose returns nil when no future doses
    @Test("Get next scheduled dose returns nil when no future doses")
    func testGetNextScheduledDoseReturnsNilWhenNone() throws {
        // GIVEN: A schedule that has ended
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = createWeeklyScheduleConfig()
        let pastStart = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: pastStart,
            baseSchedule: config
        )

        // Mark schedule as inactive (ended)
        schedule.isActive = false

        // WHEN: Getting next scheduled dose
        let nextDose = service.getNextScheduledDose(for: schedule)

        // THEN: Should return nil (no future doses for inactive schedule)
        #expect(nextDose == nil, "Expected nil for inactive schedule")
    }

    // MARK: - Refresh Upcoming Doses Tests

    /// Test: Refresh upcoming doses updates observable property
    @Test("Refresh upcoming doses updates property")
    func testRefreshUpcomingDosesUpdatesProperty() throws {
        // GIVEN: A service with active schedules
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = createWeeklyScheduleConfig()
        let startDate = Date()
        _ = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: startDate,
            baseSchedule: config
        )

        // WHEN: Refreshing upcoming doses (30 days ahead by default)
        service.refreshUpcomingDoses(daysAhead: 30)

        // THEN: upcomingDoses property should be populated
        #expect(service.upcomingDoses.count > 0, "Expected upcoming doses to be populated")

        // THEN: All upcoming doses should be in the future (or very recent past)
        let cutoff = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        for dose in service.upcomingDoses {
            #expect(dose.scheduledTime >= cutoff, "Upcoming doses should be in future or recent past")
        }
    }

    /// Test: Refresh upcoming doses with custom days ahead
    @Test("Refresh upcoming doses with custom days ahead")
    func testRefreshUpcomingDosesWithCustomDaysAhead() throws {
        // GIVEN: A service with active schedule
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = createWeeklyScheduleConfig()
        let startDate = Date()
        _ = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: startDate,
            baseSchedule: config
        )

        // WHEN: Refreshing upcoming doses for 60 days ahead
        service.refreshUpcomingDoses(daysAhead: 60)

        // THEN: Should have approximately 8-9 doses (60 days / 7 days)
        #expect(
            service.upcomingDoses.count >= 8 && service.upcomingDoses.count <= 9,
            "Expected ~8-9 doses for 60-day window, got \(service.upcomingDoses.count)")
    }

    // MARK: - Scheduling Window Validation Tests

    /// Test: Apply scheduling windows correctly
    @Test("Apply scheduling windows with correct duration")
    func testApplySchedulingWindows() throws {
        // GIVEN: A schedule with custom window settings (60 minutes before/after)
        let context = try createTestContext()
        let profile = createTestMedicationProfile(context: context)
        let service = ScheduleService(context: context)

        let config = ScheduleConfiguration(
            dayOfWeek: 1,
            timeOfDay: TimeComponents(hour: 9, minute: 0),
            interval: 7,
            doseAmount: 0.5,
            windowMinutesBefore: 60,  // 1 hour before
            windowMinutesAfter: 60,  // 1 hour after
            splitDoseCount: nil,
            splitIntervalMinutes: nil,
            customRecurrence: nil
        )

        let startDate = Date()
        let schedule = try service.createSchedule(
            for: profile,
            pattern: .weekly,
            startDate: startDate,
            baseSchedule: config
        )

        // WHEN: Generating doses
        let endDate = Calendar.current.date(byAdding: .day, value: 14, to: startDate)!
        let doses = service.generateScheduledDoses(for: schedule, from: startDate, to: endDate)

        // THEN: All doses should have 1-hour windows
        for dose in doses {
            let windowBefore = dose.scheduledTime.timeIntervalSince(dose.windowStart)
            let windowAfter = dose.windowEnd.timeIntervalSince(dose.scheduledTime)

            #expect(abs(windowBefore - 3600) < 60, "Window before should be ~1 hour (3600s)")
            #expect(abs(windowAfter - 3600) < 60, "Window after should be ~1 hour (3600s)")
        }
    }
}
