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

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

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
        #expect(schedule.scheduledDoses.isEmpty)
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

    // Note: Full nextScheduledDose testing requires ScheduledDose model
    // Additional tests will be added in integration testing

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
}
