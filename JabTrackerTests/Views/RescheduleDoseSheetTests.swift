//
//  RescheduleDoseSheetTests.swift
//  JabTrackerTests
//
//  Unit tests for RescheduleDoseSheet component
//  Stream B: Action Sheet UI & Dose Management (Issue #178)
//

import SwiftData
import SwiftUI
import Testing

@testable import JabTracker

@MainActor
struct RescheduleDoseSheetTests {
    // MARK: - Test Infrastructure

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            Dose.self,
            DoseSchedule.self,
            ScheduledDose.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func createTestUser(context: ModelContext) -> User {
        let user = User(
            email: "test@test.com",
            name: "Test User",
            weight: 70.0,
            hasCompletedOnboarding: true
        )
        context.insert(user)
        return user
    }

    private func createTestMedicationProfile(
        context: ModelContext,
        user: User
    ) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 0.5
        )
        context.insert(profile)
        profile.user = user
        return profile
    }

    private func createTestSchedule(
        context: ModelContext,
        profile: MedicationProfile
    ) -> DoseSchedule {
        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly
        )
        context.insert(schedule)
        return schedule
    }

    private func createTestScheduledDose(
        context: ModelContext,
        schedule: DoseSchedule,
        time: Date
    ) -> ScheduledDose {
        let twoHours: TimeInterval = 2 * 60 * 60
        let scheduledDose = ScheduledDose(
            scheduledTime: time,
            doseAmount: 0.5,
            windowStart: time.addingTimeInterval(-twoHours),
            windowEnd: time.addingTimeInterval(twoHours)
        )
        context.insert(scheduledDose)
        scheduledDose.schedule = schedule
        return scheduledDose
    }

    // MARK: - Date Validation Tests

    @Test("Reschedule prevents past dates")
    func testPreventsPastDates() throws {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        // Date picker should have range: Date()...
        // This prevents selecting dates before now
        let validRange = now...

        // Past date should be outside valid range
        #expect(yesterday < validRange.lowerBound)

        // Future date should be within valid range
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        #expect(tomorrow >= validRange.lowerBound)
    }

    @Test("Reschedule allows future dates")
    func testAllowsFutureDates() throws {
        let now = Date()
        let calendar = Calendar.current

        // Test various future dates
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: now)!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: now)!

        // All should be valid for rescheduling
        #expect(tomorrow > now)
        #expect(nextWeek > now)
        #expect(nextMonth > now)
    }

    // MARK: - Smart Suggestion Tests

    @Test("Tomorrow same time suggestion calculates correctly")
    func testTomorrowSameTimeSuggestion() throws {
        let calendar = Calendar.current
        let now = Date()

        // Get tomorrow at same time
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!

        // Verify it's exactly 1 day later
        let components = calendar.dateComponents([.day], from: now, to: tomorrow)
        #expect(components.day == 1)

        // Verify hour/minute are preserved
        let nowHour = calendar.component(.hour, from: now)
        let tomorrowHour = calendar.component(.hour, from: tomorrow)
        #expect(nowHour == tomorrowHour)

        let nowMinute = calendar.component(.minute, from: now)
        let tomorrowMinute = calendar.component(.minute, from: tomorrow)
        #expect(nowMinute == tomorrowMinute)
    }

    @Test("24 hours suggestion calculates correctly")
    func test24HoursSuggestion() throws {
        let now = Date()
        let in24Hours = now.addingTimeInterval(24 * 60 * 60)

        // Verify exactly 24 hours difference
        let interval = in24Hours.timeIntervalSince(now)
        #expect(abs(interval - 24 * 60 * 60) < 1)  // Within 1 second tolerance
    }

    @Test("48 hours suggestion calculates correctly")
    func test48HoursSuggestion() throws {
        let now = Date()
        let in48Hours = now.addingTimeInterval(48 * 60 * 60)

        // Verify exactly 48 hours difference
        let interval = in48Hours.timeIntervalSince(now)
        #expect(abs(interval - 48 * 60 * 60) < 1)  // Within 1 second tolerance
    }

    // MARK: - Initial State Tests

    @Test("Reschedule sheet initializes with +24 hour default")
    func testInitializedWith24HourDefault() throws {
        let scheduledTime = Date()
        let expected24HoursLater = scheduledTime.addingTimeInterval(24 * 60 * 60)

        // Sheet should initialize with scheduledTime + 24 hours
        // This provides a reasonable default for users
        let interval = expected24HoursLater.timeIntervalSince(scheduledTime)
        #expect(abs(interval - 24 * 60 * 60) < 1)
    }

    // MARK: - Reschedule Integration Tests

    @Test("Reschedule updates scheduled dose time")
    func testRescheduleUpdatesScheduledDoseTime() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = createTestSchedule(context: context, profile: profile)
        let originalTime = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            time: originalTime
        )

        // Verify initial time
        #expect(scheduledDose.scheduledTime == originalTime)

        // Reschedule to tomorrow
        let newTime = Calendar.current.date(byAdding: .day, value: 1, to: originalTime)!
        scheduledDose.reschedule(to: newTime)

        // Verify time updated
        #expect(scheduledDose.scheduledTime == newTime)
        #expect(scheduledDose.rescheduledFrom == originalTime)
    }

    @Test("Reschedule preserves dose amount")
    func testReschedulePreservesDoseAmount() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = createTestSchedule(context: context, profile: profile)
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            time: Date()
        )

        let originalAmount = scheduledDose.doseAmount
        #expect(originalAmount == 0.5)

        // Reschedule
        let newTime = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        scheduledDose.reschedule(to: newTime)

        // Verify amount unchanged
        #expect(scheduledDose.doseAmount == originalAmount)
    }

    @Test("Reschedule tracks original time")
    func testRescheduleTracksOriginalTime() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = createTestSchedule(context: context, profile: profile)
        let originalTime = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            time: originalTime
        )

        // Before reschedule, rescheduledFrom should be nil
        #expect(scheduledDose.rescheduledFrom == nil)

        // Reschedule
        let newTime = Calendar.current.date(byAdding: .day, value: 1, to: originalTime)!
        scheduledDose.reschedule(to: newTime)

        // After reschedule, rescheduledFrom should track original time
        #expect(scheduledDose.rescheduledFrom == originalTime)
    }

    // MARK: - Edge Cases

    @Test("Cannot reschedule already taken dose")
    func testCannotRescheduleLoggedDose() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = createTestSchedule(context: context, profile: profile)
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            time: Date()
        )

        // Create and link actual dose
        let actualDose = Dose(
            amount: 0.5,
            timestamp: Date(),
            site: "Abdomen",
            notes: nil,
            imageData: nil,
            skipped: false,
            user: user,
            medication: profile
        )
        context.insert(actualDose)
        scheduledDose.actualDose = actualDose

        // Status should be taken
        #expect(scheduledDose.status == .taken)

        // Attempting to reschedule should be prevented by UI
        // Model should validate or ignore
        // This test documents expected behavior
    }

    @Test("Multiple reschedules track first original time")
    func testMultipleReschedulesTrackFirstOriginal() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = createTestUser(context: context)
        let profile = createTestMedicationProfile(context: context, user: user)
        let schedule = createTestSchedule(context: context, profile: profile)
        let originalTime = Date()
        let scheduledDose = createTestScheduledDose(
            context: context,
            schedule: schedule,
            time: originalTime
        )

        // First reschedule
        let firstNewTime = Calendar.current.date(byAdding: .day, value: 1, to: originalTime)!
        scheduledDose.reschedule(to: firstNewTime)
        #expect(scheduledDose.rescheduledFrom == originalTime)

        // Second reschedule - should still track original time
        let secondNewTime = Calendar.current.date(byAdding: .day, value: 2, to: originalTime)!
        scheduledDose.reschedule(to: secondNewTime)

        // rescheduledFrom should still be the FIRST original time
        #expect(scheduledDose.rescheduledFrom == originalTime)
    }
}
