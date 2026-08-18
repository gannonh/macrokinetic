//
//  DayStatusServiceTests.swift
//  JabTrackerTests
//
//  Tests for DayStatusService - manages day fasting status.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Tests for DayStatusService
/// Verifies fasting status CRUD operations and date-based queries
@Suite("DayStatusService Tests")
@MainActor
struct DayStatusServiceTests {

    // MARK: - setFasting Tests

    @Test("setFasting creates DayStatus entry when marking as fasting")
    func testSetFastingCreatesEntry() throws {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let testDate = Date()

        try service.setFasting(for: testDate, isFasting: true)

        let status = service.getDayStatus(for: testDate)
        #expect(status != nil)
        #expect(status?.isFasting == true)
    }

    @Test("setFasting does not create entry when marking as not fasting")
    func testSetFastingDoesNotCreateEntryForNotFasting() throws {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let testDate = Date()

        try service.setFasting(for: testDate, isFasting: false)

        let status = service.getDayStatus(for: testDate)
        #expect(status == nil, "No entry should be created for non-fasting days")
    }

    @Test("setFasting updates existing entry when toggling fasting status")
    func testSetFastingUpdatesExistingEntry() throws {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let testDate = Date()

        // Create initial fasting entry
        try service.setFasting(for: testDate, isFasting: true)
        let initialStatus = service.getDayStatus(for: testDate)
        #expect(initialStatus?.isFasting == true)

        // Toggle to not fasting
        try service.setFasting(for: testDate, isFasting: false)
        let updatedStatus = service.getDayStatus(for: testDate)
        #expect(updatedStatus?.isFasting == false)
    }

    @Test("setFasting normalizes date to start of day")
    func testSetFastingNormalizesDate() throws {
        let context = createTestContext()
        let service = DayStatusService(context: context)

        // Use a time in the middle of the day
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 14
        components.minute = 30
        let midDayDate = calendar.date(from: components)!

        try service.setFasting(for: midDayDate, isFasting: true)

        // Should be queryable with start of day
        let startOfDay = calendar.startOfDay(for: midDayDate)
        let status = service.getDayStatus(for: startOfDay)
        #expect(status != nil)
        #expect(status?.isFasting == true)
    }

    // MARK: - isFasting Tests

    @Test("isFasting returns true for fasting day")
    func testIsFastingReturnsTrue() throws {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let testDate = Date()

        try service.setFasting(for: testDate, isFasting: true)

        #expect(service.isFasting(for: testDate) == true)
    }

    @Test("isFasting returns false for non-fasting day")
    func testIsFastingReturnsFalseForNonFasting() throws {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let testDate = Date()

        // Mark as fasting then toggle off
        try service.setFasting(for: testDate, isFasting: true)
        try service.setFasting(for: testDate, isFasting: false)

        #expect(service.isFasting(for: testDate) == false)
    }

    @Test("isFasting returns false when no DayStatus exists")
    func testIsFastingReturnsFalseWhenNoEntry() {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let testDate = Date()

        #expect(service.isFasting(for: testDate) == false)
    }

    // MARK: - getFastingDates Tests

    @Test("getFastingDates returns correct fasting dates in range")
    func testGetFastingDatesReturnsCorrectDates() throws {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Mark 3 days as fasting
        let day1 = calendar.date(byAdding: .day, value: -5, to: today)!
        let day2 = calendar.date(byAdding: .day, value: -3, to: today)!
        let day3 = calendar.date(byAdding: .day, value: -1, to: today)!

        try service.setFasting(for: day1, isFasting: true)
        try service.setFasting(for: day2, isFasting: true)
        try service.setFasting(for: day3, isFasting: true)

        let startDate = calendar.date(byAdding: .day, value: -7, to: today)!
        let fastingDates = try service.getFastingDates(from: startDate, to: today)

        #expect(fastingDates.count == 3)
        #expect(fastingDates.contains(calendar.startOfDay(for: day1)))
        #expect(fastingDates.contains(calendar.startOfDay(for: day2)))
        #expect(fastingDates.contains(calendar.startOfDay(for: day3)))
    }

    @Test("getFastingDates excludes dates outside range")
    func testGetFastingDatesExcludesOutsideRange() throws {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Mark a day outside the query range
        let outsideDay = calendar.date(byAdding: .day, value: -10, to: today)!
        let insideDay = calendar.date(byAdding: .day, value: -3, to: today)!

        try service.setFasting(for: outsideDay, isFasting: true)
        try service.setFasting(for: insideDay, isFasting: true)

        // Query only last 7 days
        let startDate = calendar.date(byAdding: .day, value: -7, to: today)!
        let fastingDates = try service.getFastingDates(from: startDate, to: today)

        #expect(fastingDates.count == 1)
        #expect(fastingDates.contains(calendar.startOfDay(for: insideDay)))
        #expect(!fastingDates.contains(calendar.startOfDay(for: outsideDay)))
    }

    @Test("getFastingDates returns empty set when no fasting days")
    func testGetFastingDatesReturnsEmptySet() throws {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -7, to: today)!

        let fastingDates = try service.getFastingDates(from: startDate, to: today)

        #expect(fastingDates.isEmpty)
    }

    @Test("getFastingDates excludes days toggled back to not fasting")
    func testGetFastingDatesExcludesToggledOff() throws {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let testDay = calendar.date(byAdding: .day, value: -2, to: today)!

        // Mark as fasting then toggle off
        try service.setFasting(for: testDay, isFasting: true)
        try service.setFasting(for: testDay, isFasting: false)

        let startDate = calendar.date(byAdding: .day, value: -7, to: today)!
        let fastingDates = try service.getFastingDates(from: startDate, to: today)

        #expect(fastingDates.isEmpty, "Toggled-off day should not appear in fasting dates")
    }

    // MARK: - getDayStatus Tests

    @Test("getDayStatus returns status for existing date")
    func testGetDayStatusReturnsExisting() throws {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let testDate = Date()

        try service.setFasting(for: testDate, isFasting: true)

        let status = service.getDayStatus(for: testDate)
        #expect(status != nil)
        #expect(status?.isFasting == true)
    }

    @Test("getDayStatus returns nil for non-existing date")
    func testGetDayStatusReturnsNilForNonExisting() {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let testDate = Date()

        let status = service.getDayStatus(for: testDate)
        #expect(status == nil)
    }

    @Test("getDayStatus normalizes date for lookup")
    func testGetDayStatusNormalizesDate() throws {
        let context = createTestContext()
        let service = DayStatusService(context: context)
        let calendar = Calendar.current

        // Create entry at start of day
        let today = calendar.startOfDay(for: Date())
        try service.setFasting(for: today, isFasting: true)

        // Query with time in middle of day
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.hour = 15
        components.minute = 45
        let midDayQuery = calendar.date(from: components)!

        let status = service.getDayStatus(for: midDayQuery)
        #expect(status != nil)
        #expect(status?.isFasting == true)
    }

    // MARK: - Helpers

    private func createTestContext() -> ModelContext {
        let schema = Schema([
            User.self,
            NutritionGoal.self,
            MedicationProfile.self,
            Dose.self,
            DoseTitration.self,
            Food.self,
            FoodEntry.self,
            DayStatus.self,
        ])
        let configuration = InMemoryTestStore.configuration(schema: schema)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }
}
