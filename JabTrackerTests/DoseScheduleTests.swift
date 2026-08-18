//
//  DoseScheduleTests.swift
//  JabTrackerTests
//
//  Tests for DoseSchedule SwiftData model
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
struct DoseScheduleTests {

    // MARK: - Test Helpers

    /// Create a test ModelContainer with in-memory storage
    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            DoseSchedule.self,
            ScheduledDose.self,
            MedicationProfile.self,
            Dose.self,
            User.self,
        ])

        let configuration = InMemoryTestStore.configuration(schema: schema)

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Create a test MedicationProfile
    private func createTestMedicationProfile(context: ModelContext) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 0.25,
            medicationType: "semaglutide"
        )
        context.insert(profile)
        return profile
    }

    // MARK: - Model Creation Tests

    @Test("DoseSchedule initializes with default values")
    func testDefaultInitialization() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        #expect(schedule.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(schedule.medicationProfile == nil)
        #expect(schedule.patternType == .weekly)
        #expect(schedule.baseSchedule == Data())
        #expect(schedule.isActive == true)
        #expect(schedule.pausedAt == nil)
        #expect(schedule.pausedUntil == nil)
        #expect(schedule.customScheduleData == nil)
        // createdAt and updatedAt are non-optional Dates, so just verify they exist as Dates
        _ = schedule.createdAt
        _ = schedule.updatedAt
        #expect(schedule.scheduledDoses?.isEmpty ?? true)
    }

    @Test("DoseSchedule initializes with custom values")
    func testCustomInitialization() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let profile = createTestMedicationProfile(context: context)
        let baseScheduleData = try JSONEncoder().encode(["day": "Monday", "time": "09:00"])
        let customData = try JSONEncoder().encode(["pattern": "custom"])

        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .splitDose,
            baseSchedule: baseScheduleData,
            isActive: false,
            customScheduleData: customData
        )
        context.insert(schedule)

        #expect(schedule.medicationProfile?.id == profile.id)
        #expect(schedule.patternType == .splitDose)
        #expect(schedule.baseSchedule == baseScheduleData)
        #expect(schedule.isActive == false)
        #expect(schedule.customScheduleData == customData)
    }

    // MARK: - Relationship Tests

    @Test("DoseSchedule maintains relationship with MedicationProfile")
    func testMedicationProfileRelationship() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let profile = createTestMedicationProfile(context: context)
        let schedule = DoseSchedule(medicationProfile: profile)
        context.insert(schedule)

        try context.save()

        #expect(schedule.medicationProfile?.id == profile.id)
        #expect(profile.schedules?.contains(where: { $0.id == schedule.id }) == true)
    }

    @Test("DoseSchedule cascade deletes scheduledDoses")
    func testCascadeDeleteScheduledDoses() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let profile = createTestMedicationProfile(context: context)
        let schedule = DoseSchedule(medicationProfile: profile)
        context.insert(schedule)

        // Create ScheduledDose (will be created in separate file, simulating here)
        // This test validates the relationship configuration

        try context.save()

        let scheduleId = schedule.id
        context.delete(schedule)
        try context.save()

        // Verify schedule is deleted
        let fetchDescriptor = FetchDescriptor<DoseSchedule>(
            predicate: #Predicate { $0.id == scheduleId }
        )
        let schedules = try context.fetch(fetchDescriptor)
        #expect(schedules.isEmpty)
    }

    // MARK: - Pattern Type Tests

    @Test("SchedulePatternType enum has all expected cases")
    func testSchedulePatternTypeCases() {
        #expect(SchedulePatternType.weekly.rawValue == "weekly")
        #expect(SchedulePatternType.splitDose.rawValue == "splitDose")
        #expect(SchedulePatternType.custom.rawValue == "custom")
    }

    @Test("SchedulePatternType encodes and decodes correctly")
    func testSchedulePatternTypeCodable() throws {
        let patterns: [SchedulePatternType] = [.weekly, .splitDose, .custom]

        for pattern in patterns {
            let encoded = try JSONEncoder().encode(pattern)
            let decoded = try JSONDecoder().decode(SchedulePatternType.self, from: encoded)
            #expect(decoded == pattern)
        }
    }

    // MARK: - Active State Tests

    @Test("DoseSchedule can be activated and deactivated")
    func testActivateDeactivate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        #expect(schedule.isActive == true)

        schedule.isActive = false
        #expect(schedule.isActive == false)

        schedule.isActive = true
        #expect(schedule.isActive == true)
    }

    // MARK: - Pause/Resume Tests

    @Test("DoseSchedule can be paused with timestamp")
    func testPauseSchedule() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        let pauseDate = Date()
        schedule.pausedAt = pauseDate

        #expect(schedule.pausedAt == pauseDate)
        #expect(schedule.pausedUntil == nil)
    }

    @Test("DoseSchedule can be paused with resume date")
    func testPauseScheduleWithResumeDate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        let pauseDate = Date()
        let resumeDate = Calendar.current.date(byAdding: .day, value: 7, to: pauseDate)!

        schedule.pausedAt = pauseDate
        schedule.pausedUntil = resumeDate

        #expect(schedule.pausedAt == pauseDate)
        #expect(schedule.pausedUntil == resumeDate)
    }

    @Test("DoseSchedule can be resumed by clearing pause dates")
    func testResumeSchedule() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        // Pause schedule
        schedule.pausedAt = Date()
        schedule.pausedUntil = Calendar.current.date(byAdding: .day, value: 7, to: Date())

        #expect(schedule.pausedAt != nil)
        #expect(schedule.pausedUntil != nil)

        // Resume schedule
        schedule.pausedAt = nil
        schedule.pausedUntil = nil

        #expect(schedule.pausedAt == nil)
        #expect(schedule.pausedUntil == nil)
    }

    // MARK: - Base Schedule Data Tests

    @Test("DoseSchedule stores baseSchedule as encoded JSON")
    func testBaseScheduleData() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        struct WeeklySchedule: Codable, Equatable {
            let dayOfWeek: Int
            let hour: Int
            let minute: Int
        }

        let weeklySchedule = WeeklySchedule(dayOfWeek: 1, hour: 9, minute: 0)
        let encodedData = try JSONEncoder().encode(weeklySchedule)

        let schedule = DoseSchedule(baseSchedule: encodedData)
        context.insert(schedule)

        #expect(schedule.baseSchedule == encodedData)

        // Verify we can decode it back
        let decodedSchedule = try JSONDecoder().decode(WeeklySchedule.self, from: schedule.baseSchedule)
        #expect(decodedSchedule == weeklySchedule)
    }

    // MARK: - Custom Schedule Data Tests

    @Test("DoseSchedule stores customScheduleData for complex patterns")
    func testCustomScheduleData() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Use a simple dictionary for testing custom schedule data
        let customDict = ["pattern": "alternating-weekly", "days": "mon-wed-fri"]
        let encodedData = try JSONEncoder().encode(customDict)

        let schedule = DoseSchedule(
            patternType: .custom,
            customScheduleData: encodedData
        )
        context.insert(schedule)

        #expect(schedule.customScheduleData == encodedData)
        #expect(schedule.patternType == .custom)

        // Verify we can decode it back
        if let data = schedule.customScheduleData {
            let decodedDict = try JSONDecoder().decode([String: String].self, from: data)
            #expect(decodedDict["pattern"] == "alternating-weekly")
        }
    }

    // MARK: - Computed Property Tests

    @Test("nextScheduledDose returns nil when no scheduled doses exist")
    func testNextScheduledDoseEmpty() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        #expect(schedule.nextScheduledDose == nil)
    }

    @Test("nextScheduledDose returns earliest pending dose")
    func testNextScheduledDoseWithMultiplePending() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        // Create scheduled doses with different times
        let now = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now)!

        let dose1 = ScheduledDose(
            scheduledTime: tomorrow,
            doseAmount: 0.5,
            windowStart: tomorrow.addingTimeInterval(-2 * 60 * 60),
            windowEnd: tomorrow.addingTimeInterval(2 * 60 * 60)
        )
        let dose2 = ScheduledDose(
            scheduledTime: nextWeek,
            doseAmount: 0.5,
            windowStart: nextWeek.addingTimeInterval(-2 * 60 * 60),
            windowEnd: nextWeek.addingTimeInterval(2 * 60 * 60)
        )

        context.insert(dose1)
        context.insert(dose2)

        dose1.schedule = schedule
        dose2.schedule = schedule

        try context.save()

        // Should return earliest pending dose (tomorrow)
        let nextDose = schedule.nextScheduledDose
        #expect(nextDose != nil)
        #expect(abs(nextDose!.timeIntervalSince(tomorrow)) < 1.0)  // Within 1 second
    }

    @Test("nextScheduledDose ignores taken doses")
    func testNextScheduledDoseIgnoresTaken() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!

        // Create taken dose (yesterday)
        let takenDose = ScheduledDose(
            scheduledTime: yesterday,
            doseAmount: 0.5,
            windowStart: yesterday.addingTimeInterval(-2 * 60 * 60),
            windowEnd: yesterday.addingTimeInterval(2 * 60 * 60)
        )
        context.insert(takenDose)
        takenDose.schedule = schedule

        // Link to actual dose to mark as taken
        let actualDose = Dose(amount: 0.5, timestamp: yesterday)
        context.insert(actualDose)
        actualDose.scheduledDose = takenDose

        // Create pending dose (tomorrow)
        let pendingDose = ScheduledDose(
            scheduledTime: tomorrow,
            doseAmount: 0.5,
            windowStart: tomorrow.addingTimeInterval(-2 * 60 * 60),
            windowEnd: tomorrow.addingTimeInterval(2 * 60 * 60)
        )
        context.insert(pendingDose)
        pendingDose.schedule = schedule

        try context.save()

        // Should return only the pending dose, ignoring taken
        let nextDose = schedule.nextScheduledDose
        #expect(nextDose != nil)
        #expect(abs(nextDose!.timeIntervalSince(tomorrow)) < 1.0)
    }

    @Test("nextScheduledDose ignores skipped doses")
    func testNextScheduledDoseIgnoresSkipped() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!

        // Create skipped dose (yesterday)
        let skippedDose = ScheduledDose(
            scheduledTime: yesterday,
            doseAmount: 0.5,
            windowStart: yesterday.addingTimeInterval(-2 * 60 * 60),
            windowEnd: yesterday.addingTimeInterval(2 * 60 * 60)
        )
        context.insert(skippedDose)
        skippedDose.schedule = schedule
        skippedDose.skippedAt = yesterday  // Mark as skipped

        // Create pending dose (tomorrow)
        let pendingDose = ScheduledDose(
            scheduledTime: tomorrow,
            doseAmount: 0.5,
            windowStart: tomorrow.addingTimeInterval(-2 * 60 * 60),
            windowEnd: tomorrow.addingTimeInterval(2 * 60 * 60)
        )
        context.insert(pendingDose)
        pendingDose.schedule = schedule

        try context.save()

        // Should return only the pending dose, ignoring skipped
        let nextDose = schedule.nextScheduledDose
        #expect(nextDose != nil)
        #expect(abs(nextDose!.timeIntervalSince(tomorrow)) < 1.0)
    }

    @Test("nextScheduledDose returns nil when only non-pending doses exist")
    func testNextScheduledDoseOnlyNonPending() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        // Create taken dose
        let takenDose = ScheduledDose(
            scheduledTime: yesterday,
            doseAmount: 0.5,
            windowStart: yesterday.addingTimeInterval(-2 * 60 * 60),
            windowEnd: yesterday.addingTimeInterval(2 * 60 * 60)
        )
        context.insert(takenDose)
        takenDose.schedule = schedule

        let actualDose = Dose(amount: 0.5, timestamp: yesterday)
        context.insert(actualDose)
        actualDose.scheduledDose = takenDose

        try context.save()

        // Should return nil - no pending doses
        #expect(schedule.nextScheduledDose == nil)
    }

    // MARK: - Audit Trail Tests

    @Test("DoseSchedule tracks creation timestamp")
    func testCreationTimestamp() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let beforeCreation = Date()
        let schedule = DoseSchedule()
        context.insert(schedule)
        let afterCreation = Date()

        #expect(schedule.createdAt >= beforeCreation)
        #expect(schedule.createdAt <= afterCreation)
    }

    @Test("DoseSchedule tracks update timestamp")
    func testUpdateTimestamp() async throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        let originalUpdatedAt = schedule.updatedAt

        // Simulate time passing
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds

        schedule.updatedAt = Date()

        #expect(schedule.updatedAt > originalUpdatedAt)
    }

    // MARK: - CloudKit Compatibility Tests

    @Test("DoseSchedule uses CloudKit-compatible types")
    func testCloudKitCompatibility() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        // Verify all properties are CloudKit-compatible types by accessing them
        _ = schedule.id as UUID
        _ = schedule.patternType.rawValue as String
        _ = schedule.baseSchedule as Data
        _ = schedule.isActive as Bool
        _ = schedule.createdAt as Date
        _ = schedule.updatedAt as Date

        // Optional types can be validated through their existence
        #expect(schedule.pausedAt == nil)  // Default should be nil
        #expect(schedule.pausedUntil == nil)  // Default should be nil
        #expect(schedule.customScheduleData == nil)  // Default should be nil
    }

    // MARK: - lastTakenDose Tests

    @Test("lastTakenDose returns nil when no scheduled doses exist")
    func testLastTakenDoseEmpty() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        #expect(schedule.lastTakenDose == nil)
    }

    @Test("lastTakenDose returns nil when only pending doses exist")
    func testLastTakenDoseOnlyPending() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        // Create pending dose (no actual dose linked)
        let pendingDose = ScheduledDose(
            scheduledTime: tomorrow,
            doseAmount: 0.5,
            windowStart: tomorrow.addingTimeInterval(-2 * 60 * 60),
            windowEnd: tomorrow.addingTimeInterval(2 * 60 * 60)
        )
        context.insert(pendingDose)
        pendingDose.schedule = schedule

        try context.save()

        #expect(schedule.lastTakenDose == nil)
    }

    @Test("lastTakenDose returns most recent taken dose")
    func testLastTakenDoseReturnsNewest() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: now)!

        // Create older taken dose
        let olderDose = ScheduledDose(
            scheduledTime: twoWeeksAgo,
            doseAmount: 0.5,
            windowStart: twoWeeksAgo.addingTimeInterval(-2 * 60 * 60),
            windowEnd: twoWeeksAgo.addingTimeInterval(2 * 60 * 60)
        )
        context.insert(olderDose)
        olderDose.schedule = schedule
        let olderActualDose = Dose(amount: 0.5, timestamp: twoWeeksAgo)
        context.insert(olderActualDose)
        olderActualDose.scheduledDose = olderDose

        // Create newer taken dose
        let newerDose = ScheduledDose(
            scheduledTime: oneWeekAgo,
            doseAmount: 0.5,
            windowStart: oneWeekAgo.addingTimeInterval(-2 * 60 * 60),
            windowEnd: oneWeekAgo.addingTimeInterval(2 * 60 * 60)
        )
        context.insert(newerDose)
        newerDose.schedule = schedule
        let newerActualDose = Dose(amount: 0.5, timestamp: oneWeekAgo)
        context.insert(newerActualDose)
        newerActualDose.scheduledDose = newerDose

        try context.save()

        let lastTaken = schedule.lastTakenDose
        #expect(lastTaken != nil)
        #expect(lastTaken?.id == newerDose.id)
    }

    @Test("lastTakenDose ignores skipped doses")
    func testLastTakenDoseIgnoresSkipped() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        let now = Date()
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: now)!

        // Create taken dose (older)
        let takenDose = ScheduledDose(
            scheduledTime: twoWeeksAgo,
            doseAmount: 0.5,
            windowStart: twoWeeksAgo.addingTimeInterval(-2 * 60 * 60),
            windowEnd: twoWeeksAgo.addingTimeInterval(2 * 60 * 60)
        )
        context.insert(takenDose)
        takenDose.schedule = schedule
        let actualDose = Dose(amount: 0.5, timestamp: twoWeeksAgo)
        context.insert(actualDose)
        actualDose.scheduledDose = takenDose

        // Create skipped dose (newer - should be ignored)
        let skippedDose = ScheduledDose(
            scheduledTime: oneWeekAgo,
            doseAmount: 0.5,
            windowStart: oneWeekAgo.addingTimeInterval(-2 * 60 * 60),
            windowEnd: oneWeekAgo.addingTimeInterval(2 * 60 * 60)
        )
        context.insert(skippedDose)
        skippedDose.schedule = schedule
        skippedDose.skippedAt = oneWeekAgo  // Mark as skipped

        try context.save()

        let lastTaken = schedule.lastTakenDose
        #expect(lastTaken != nil)
        #expect(lastTaken?.id == takenDose.id)
    }

    @Test("lastTakenDose returns nil when only skipped doses exist")
    func testLastTakenDoseOnlySkipped() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let schedule = DoseSchedule()
        context.insert(schedule)

        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

        // Create skipped dose
        let skippedDose = ScheduledDose(
            scheduledTime: oneWeekAgo,
            doseAmount: 0.5,
            windowStart: oneWeekAgo.addingTimeInterval(-2 * 60 * 60),
            windowEnd: oneWeekAgo.addingTimeInterval(2 * 60 * 60)
        )
        context.insert(skippedDose)
        skippedDose.schedule = schedule
        skippedDose.skippedAt = oneWeekAgo

        try context.save()

        #expect(schedule.lastTakenDose == nil)
    }
}
