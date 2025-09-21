//
//  DoseAnalyticsTests.swift
//  JabTrackerTests
//

import Foundation
@testable import JabTracker
import SwiftData
import Testing

/// Unit tests for Dose model analytics extensions and computed properties
@Suite("Dose Analytics Tests")
struct DoseAnalyticsTests {
    // MARK: - Test Setup

    @MainActor
    func createTestModelContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: Dose.self, User.self, MedicationProfile.self, configurations: config)
    }

    @MainActor
    func createTestDose(
        amount: Double = 1.0,
        timestamp: Date = Date(),
        skipped: Bool = false,
        expectedTimestamp: Date? = nil,
        actualTimestamp: Date? = nil) -> Dose
    {
        let dose = Dose(
            amount: amount,
            timestamp: timestamp,
            skipped: skipped)
        dose.expectedTimestamp = expectedTimestamp
        dose.actualTimestamp = actualTimestamp
        return dose
    }

    @MainActor
    func createTestUser() -> User {
        User(
            email: "test@example.com",
            name: "Test User")
    }

    @MainActor
    func createTestMedicationProfile() -> MedicationProfile {
        MedicationProfile(
            genericName: "Semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0,
            medicationType: "semaglutide")
    }

    // MARK: - Analytics Metadata Fields Tests

    @Test("Dose initializes with analytics metadata fields")
    @MainActor
    func analyticsMetadataInitialization() throws {
        let dose = Dose()

        // Expected timestamp should be nil by default
        #expect(dose.expectedTimestamp == nil)

        // Actual timestamp should be nil by default
        #expect(dose.actualTimestamp == nil)

        // Analytics tags should be empty by default
        #expect(dose.analyticsTags.isEmpty)

        // Analytics context should be empty by default
        #expect(dose.analyticsContext.isEmpty)
    }

    @Test("Analytics metadata can be set and retrieved")
    @MainActor
    func analyticsMetadataSetAndGet() throws {
        let container = try createTestModelContainer()
        let context = container.mainContext

        let expectedDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let actualDate = Date()
        let tags = ["on_time", "before_meal"]
        let analyticsContext = ["medication_taken_with": "breakfast"]

        let dose = self.createTestDose()
        dose.expectedTimestamp = expectedDate
        dose.actualTimestamp = actualDate
        dose.analyticsTags = tags
        dose.analyticsContext = analyticsContext

        context.insert(dose)
        try context.save()

        #expect(dose.expectedTimestamp == expectedDate)
        #expect(dose.actualTimestamp == actualDate)
        #expect(dose.analyticsTags == tags)
        #expect(dose.analyticsContext == analyticsContext)
    }

    // MARK: - Adherence Tracking Tests

    @Test("isOnTime returns true when dose taken within adherence window")
    @MainActor
    func isOnTimeWithinWindow() throws {
        let expectedTime = Date()
        let actualTime = expectedTime.addingTimeInterval(30 * 60) // 30 minutes late

        let dose = self.createTestDose()
        dose.expectedTimestamp = expectedTime
        dose.actualTimestamp = actualTime

        #expect(dose.isOnTime == true) // Within 2-hour default window
    }

    @Test("isOnTime returns false when dose taken outside adherence window")
    @MainActor
    func isOnTimeOutsideWindow() throws {
        let expectedTime = Date()
        let actualTime = expectedTime.addingTimeInterval(3 * 60 * 60) // 3 hours late

        let dose = self.createTestDose()
        dose.expectedTimestamp = expectedTime
        dose.actualTimestamp = actualTime

        #expect(dose.isOnTime == false) // Outside 2-hour default window
    }

    @Test("isOnTime returns false when expectedTimestamp is nil")
    @MainActor
    func isOnTimeWithoutExpectedTime() throws {
        let dose = self.createTestDose()
        dose.actualTimestamp = Date()
        // expectedTimestamp is nil

        #expect(dose.isOnTime == false)
    }

    @Test("isOnTime returns false when actualTimestamp is nil")
    @MainActor
    func isOnTimeWithoutActualTime() throws {
        let dose = self.createTestDose()
        dose.expectedTimestamp = Date()
        // actualTimestamp is nil

        #expect(dose.isOnTime == false)
    }

    @Test("adherenceStatus returns correct status for different scenarios")
    @MainActor
    func adherenceStatusVariousScenarios() throws {
        // On time dose
        let onTimeDose = self.createTestDose()
        let expectedTime = Date()
        onTimeDose.expectedTimestamp = expectedTime
        onTimeDose.actualTimestamp = expectedTime.addingTimeInterval(30 * 60) // 30 min late
        #expect(onTimeDose.adherenceStatus == "on_time")

        // Late dose
        let lateDose = self.createTestDose()
        lateDose.expectedTimestamp = expectedTime
        lateDose.actualTimestamp = expectedTime.addingTimeInterval(3 * 60 * 60) // 3 hours late
        #expect(lateDose.adherenceStatus == "late")

        // Skipped dose
        let skippedDose = self.createTestDose(skipped: true)
        skippedDose.expectedTimestamp = expectedTime
        #expect(skippedDose.adherenceStatus == "skipped")

        // Early dose
        let earlyDose = self.createTestDose()
        earlyDose.expectedTimestamp = expectedTime
        earlyDose.actualTimestamp = expectedTime.addingTimeInterval(-3 * 60 * 60) // 3 hours early
        #expect(earlyDose.adherenceStatus == "early")

        // Unknown status (no expected time)
        let unknownDose = self.createTestDose()
        unknownDose.actualTimestamp = Date()
        #expect(unknownDose.adherenceStatus == "unknown")
    }

    // MARK: - Dose Timing Analysis Tests

    @Test("timingDelayInMinutes calculates correct delay")
    @MainActor
    func timingDelayCalculation() throws {
        let expectedTime = Date()
        let actualTime = expectedTime.addingTimeInterval(45 * 60) // 45 minutes late

        let dose = self.createTestDose()
        dose.expectedTimestamp = expectedTime
        dose.actualTimestamp = actualTime

        #expect(dose.timingDelayInMinutes == 45)
    }

    @Test("timingDelayInMinutes returns negative for early doses")
    @MainActor
    func timingDelayNegativeForEarly() throws {
        let expectedTime = Date()
        let actualTime = expectedTime.addingTimeInterval(-30 * 60) // 30 minutes early

        let dose = self.createTestDose()
        dose.expectedTimestamp = expectedTime
        dose.actualTimestamp = actualTime

        #expect(dose.timingDelayInMinutes == -30)
    }

    @Test("timingDelayInMinutes returns nil when timestamps missing")
    @MainActor
    func timingDelayWithMissingTimestamps() throws {
        let dose = self.createTestDose()

        // Both timestamps nil
        #expect(dose.timingDelayInMinutes == nil)

        // Only expected timestamp
        dose.expectedTimestamp = Date()
        #expect(dose.timingDelayInMinutes == nil)

        // Only actual timestamp
        dose.expectedTimestamp = nil
        dose.actualTimestamp = Date()
        #expect(dose.timingDelayInMinutes == nil)
    }

    @Test("isWithinAdherenceWindow works with custom window")
    @MainActor
    func customAdherenceWindow() throws {
        let expectedTime = Date()
        let actualTime = expectedTime.addingTimeInterval(90 * 60) // 1.5 hours late

        let dose = self.createTestDose()
        dose.expectedTimestamp = expectedTime
        dose.actualTimestamp = actualTime

        // Within 2-hour window
        #expect(dose.isWithinAdherenceWindow(hours: 2) == true)

        // Outside 1-hour window
        #expect(dose.isWithinAdherenceWindow(hours: 1) == false)
    }

    // MARK: - Day and Week Analysis Tests

    @Test("daysSinceLastDose calculates correctly from user dose history")
    @MainActor
    func daysSinceLastDoseCalculation() throws {
        let container = try createTestModelContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let medication = self.createTestMedicationProfile()
        user.medicationProfiles = [medication]

        // Create dose from 3 days ago
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let lastDose = self.createTestDose(timestamp: threeDaysAgo)
        lastDose.user = user
        lastDose.medication = medication

        // Create current dose
        let currentDose = self.createTestDose(timestamp: Date())
        currentDose.user = user
        currentDose.medication = medication

        user.doses = [lastDose, currentDose]
        medication.doses = [lastDose, currentDose]

        context.insert(user)
        context.insert(medication)
        context.insert(lastDose)
        context.insert(currentDose)

        try context.save()

        #expect(currentDose.daysSinceLastDose == 3)
    }

    @Test("daysSinceLastDose returns nil for first dose")
    @MainActor
    func daysSinceLastDoseFirstDose() throws {
        let container = try createTestModelContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let medication = self.createTestMedicationProfile()

        let dose = self.createTestDose()
        dose.user = user
        dose.medication = medication

        user.doses = [dose]
        medication.doses = [dose]

        context.insert(user)
        context.insert(medication)
        context.insert(dose)

        try context.save()

        #expect(dose.daysSinceLastDose == nil)
    }

    @Test("isFirstDoseOfWeek identifies correctly")
    @MainActor
    func firstDoseOfWeekIdentification() throws {
        let container = try createTestModelContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let medication = self.createTestMedicationProfile()

        // Create a dose on Monday (start of week)
        let calendar = Calendar.current
        let today = Date()
        let monday = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today

        let mondayDose = self.createTestDose(timestamp: monday)
        mondayDose.user = user
        mondayDose.medication = medication

        // Create a dose on Tuesday (same week)
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!
        let tuesdayDose = self.createTestDose(timestamp: tuesday)
        tuesdayDose.user = user
        tuesdayDose.medication = medication

        user.doses = [mondayDose, tuesdayDose]
        medication.doses = [mondayDose, tuesdayDose]

        context.insert(user)
        context.insert(medication)
        context.insert(mondayDose)
        context.insert(tuesdayDose)

        try context.save()

        #expect(mondayDose.isFirstDoseOfWeek == true)
        #expect(tuesdayDose.isFirstDoseOfWeek == false)
    }

    // MARK: - Streak Analysis Tests

    @Test("currentStreak calculates correctly for consecutive doses")
    @MainActor
    func currentStreakConsecutiveDoses() throws {
        let container = try createTestModelContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let medication = self.createTestMedicationProfile()
        let calendar = Calendar.current
        let today = Date()

        var doses: [Dose] = []

        // Create 5 consecutive daily doses (today back to 4 days ago)
        for i in 0 ..< 5 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let dose = self.createTestDose(timestamp: date)
            dose.user = user
            dose.medication = medication
            doses.append(dose)
            context.insert(dose)
        }

        user.doses = doses
        medication.doses = doses

        context.insert(user)
        context.insert(medication)

        try context.save()

        // Today's dose (first in array) should show streak of 5
        #expect(doses[0].currentStreak == 5)
    }

    @Test("currentStreak breaks with skipped dose")
    @MainActor
    func currentStreakWithSkippedDose() throws {
        let container = try createTestModelContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let medication = self.createTestMedicationProfile()
        let calendar = Calendar.current
        let today = Date()

        var doses: [Dose] = []

        // Create doses: today, yesterday (skipped), day before yesterday
        let todayDose = self.createTestDose(timestamp: today, skipped: false)
        let yesterdayDose = self.createTestDose(timestamp: calendar.date(byAdding: .day, value: -1, to: today)!, skipped: true)
        let dayBeforeDose = self.createTestDose(timestamp: calendar.date(byAdding: .day, value: -2, to: today)!, skipped: false)

        doses = [todayDose, yesterdayDose, dayBeforeDose]

        for dose in doses {
            dose.user = user
            dose.medication = medication
            context.insert(dose)
        }

        user.doses = doses
        medication.doses = doses

        context.insert(user)
        context.insert(medication)

        try context.save()

        // Today's dose should only count itself (streak of 1) because yesterday was skipped
        #expect(todayDose.currentStreak == 1)
    }

    @Test("longestStreak calculates historical maximum")
    @MainActor
    func longestStreakCalculation() throws {
        let container = try createTestModelContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let medication = self.createTestMedicationProfile()
        let calendar = Calendar.current
        let today = Date()

        var doses: [Dose] = []

        // Create pattern: 3 consecutive doses, 1 skipped, 5 consecutive doses
        // This creates a longest streak of 5
        for i in 0 ..< 3 {
            let date = calendar.date(byAdding: .day, value: -(i + 6), to: today)!
            let dose = self.createTestDose(timestamp: date, skipped: false)
            dose.user = user
            dose.medication = medication
            doses.append(dose)
            context.insert(dose)
        }

        // Skipped dose
        let skippedDate = calendar.date(byAdding: .day, value: -5, to: today)!
        let skippedDose = self.createTestDose(timestamp: skippedDate, skipped: true)
        skippedDose.user = user
        skippedDose.medication = medication
        doses.append(skippedDose)
        context.insert(skippedDose)

        // 5 consecutive doses (longest streak)
        for i in 0 ..< 5 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let dose = self.createTestDose(timestamp: date, skipped: false)
            dose.user = user
            dose.medication = medication
            doses.append(dose)
            context.insert(dose)
        }

        user.doses = doses
        medication.doses = doses

        context.insert(user)
        context.insert(medication)

        try context.save()

        // Any dose should report the longest streak as 5
        #expect(doses.first?.longestStreak == 5)
    }

    // MARK: - Analytics Context Tests

    @Test("analytics tags can be added and queried")
    @MainActor
    func analyticsTagsOperations() throws {
        let dose = self.createTestDose()

        // Add tags
        dose.analyticsTags = ["on_time", "before_meal", "no_side_effects"]

        #expect(dose.analyticsTags.contains("on_time"))
        #expect(dose.analyticsTags.contains("before_meal"))
        #expect(dose.analyticsTags.contains("no_side_effects"))
        #expect(dose.analyticsTags.count == 3)
    }

    @Test("analytics context stores key-value data")
    @MainActor
    func analyticsContextOperations() throws {
        let dose = self.createTestDose()

        let context = [
            "meal_timing": "before_breakfast",
            "side_effects": "none",
            "mood": "good",
            "injection_site": "thigh",
        ]

        dose.analyticsContext = context

        #expect(dose.analyticsContext["meal_timing"] == "before_breakfast")
        #expect(dose.analyticsContext["side_effects"] == "none")
        #expect(dose.analyticsContext["mood"] == "good")
        #expect(dose.analyticsContext["injection_site"] == "thigh")
        #expect(dose.analyticsContext.count == 4)
    }

    // MARK: - Edge Cases and Error Handling

    @Test("adherence calculations handle nil relationships gracefully")
    @MainActor
    func adherenceWithNilRelationships() throws {
        let dose = self.createTestDose()
        // No user or medication relationships

        #expect(dose.daysSinceLastDose == nil)
        #expect(dose.currentStreak == 1) // Should default to 1 for isolated dose
        #expect(dose.longestStreak == 1) // Should default to 1 for isolated dose
        #expect(dose.isFirstDoseOfWeek == true) // Should default to true for isolated dose
    }

    @Test("timing calculations handle edge case timestamps")
    @MainActor
    func timingCalculationsEdgeCases() throws {
        let dose = self.createTestDose()

        // Same timestamps (exactly on time)
        let exactTime = Date()
        dose.expectedTimestamp = exactTime
        dose.actualTimestamp = exactTime

        #expect(dose.timingDelayInMinutes == 0)
        #expect(dose.isOnTime == true)
        #expect(dose.adherenceStatus == "on_time")
    }

    @Test("streak calculations handle single dose correctly")
    @MainActor
    func streakCalculationsSingleDose() throws {
        let container = try createTestModelContainer()
        let context = container.mainContext

        let user = self.createTestUser()
        let medication = self.createTestMedicationProfile()

        let dose = self.createTestDose()
        dose.user = user
        dose.medication = medication

        user.doses = [dose]
        medication.doses = [dose]

        context.insert(user)
        context.insert(medication)
        context.insert(dose)

        try context.save()

        #expect(dose.currentStreak == 1)
        #expect(dose.longestStreak == 1)
        #expect(dose.isFirstDoseOfWeek == true)
    }

    // MARK: - CloudKit Compatibility Tests

    @Test("analytics fields are CloudKit compatible")
    @MainActor
    func cloudKitCompatibility() throws {
        let container = try createTestModelContainer()
        let context = container.mainContext

        let dose = self.createTestDose()
        dose.expectedTimestamp = Date()
        dose.actualTimestamp = Date()
        dose.analyticsTags = ["test", "cloudkit"]
        dose.analyticsContext = ["test_key": "test_value"]

        context.insert(dose)

        // Should not throw when saving
        #expect(throws: Never.self) {
            try context.save()
        }

        // Verify data persisted correctly
        #expect(dose.analyticsTags.count == 2)
        #expect(dose.analyticsContext.count == 1)
    }
}
