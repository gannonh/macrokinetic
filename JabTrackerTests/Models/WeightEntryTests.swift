//
//  WeightEntryTests.swift
//  JabTrackerTests
//
//  Tests for the WeightEntry SwiftData model.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
struct WeightEntryTests {

    // MARK: - Test Helpers

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([WeightEntry.self, User.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - Default Initialization Tests

    @Test("WeightEntry initializes with CloudKit-compatible defaults")
    func testDefaultInitialization() throws {
        let entry = WeightEntry()

        #expect(entry.id != UUID())  // Has a valid UUID
        #expect(entry.weightKg == 70.0)
        #expect(entry.source == "manual")
        #expect(entry.bodyFatPercentage == nil)
        #expect(entry.notes == nil)
        #expect(entry.timestamp <= Date())
    }

    @Test("WeightEntry initializes with custom values")
    func testCustomInitialization() throws {
        let testDate = Date()
        let testId = UUID()

        let entry = WeightEntry(
            id: testId,
            timestamp: testDate,
            weightKg: 85.5,
            bodyFatPercentage: 22.5,
            source: "healthkit",
            notes: "Morning weigh-in"
        )

        #expect(entry.id == testId)
        #expect(entry.timestamp == testDate)
        #expect(entry.weightKg == 85.5)
        #expect(entry.bodyFatPercentage == 22.5)
        #expect(entry.source == "healthkit")
        #expect(entry.notes == "Morning weigh-in")
    }

    // MARK: - Convenience Initializer Tests

    @Test("WeightEntry convenience initializer converts lbs to kg")
    func testConvenienceInitFromLbs() throws {
        let entry = WeightEntry(weightLbs: 154.32)

        // 154.32 / 2.20462 ≈ 70.0
        #expect(abs(entry.weightKg - 70.0) < 0.1)
        #expect(entry.source == "manual")
    }

    @Test("WeightEntry convenience initializer with all parameters")
    func testConvenienceInitWithAllParams() throws {
        let testDate = Date()

        let entry = WeightEntry(
            weightLbs: 165.0,
            bodyFatPercentage: 18.0,
            timestamp: testDate,
            source: "healthkit",
            notes: "Post-workout"
        )

        // 165 / 2.20462 ≈ 74.84
        #expect(abs(entry.weightKg - 74.84) < 0.1)
        #expect(entry.bodyFatPercentage == 18.0)
        #expect(entry.timestamp == testDate)
        #expect(entry.source == "healthkit")
        #expect(entry.notes == "Post-workout")
    }

    // MARK: - Weight Conversion Tests

    @Test("Weight conversion to lbs is accurate")
    func testWeightConversionToLbs() throws {
        let entry = WeightEntry()
        entry.weightKg = 70.0

        // 70 * 2.20462 = 154.3234
        #expect(abs(entry.weightInLbs - 154.32) < 0.1)
    }

    @Test("Weight conversion round-trip is accurate")
    func testWeightConversionRoundTrip() throws {
        let originalLbs = 180.0
        let entry = WeightEntry(weightLbs: originalLbs)

        // Convert back: should be close to original
        #expect(abs(entry.weightInLbs - originalLbs) < 0.01)
    }

    @Test("Conversion constant matches expected value")
    func testConversionConstant() throws {
        #expect(WeightEntry.kgToLbsConversion == 2.20462)
    }

    // MARK: - Formatted Weight Tests

    @Test("formattedWeight returns metric format when useMetric is true")
    func testFormattedWeightMetric() throws {
        let entry = WeightEntry()
        entry.weightKg = 72.5

        let formatted = entry.formattedWeight(useMetric: true)

        #expect(formatted == "72.5 kg")
    }

    @Test("formattedWeight returns imperial format when useMetric is false")
    func testFormattedWeightImperial() throws {
        let entry = WeightEntry()
        entry.weightKg = 70.0

        let formatted = entry.formattedWeight(useMetric: false)

        // 70 * 2.20462 = 154.3234
        #expect(formatted == "154.3 lbs")
    }

    // MARK: - Validation Tests

    @Test("isValid returns true for weight at minimum boundary")
    func testIsValidAtMinBoundary() throws {
        let entry = WeightEntry()
        entry.weightKg = WeightEntry.minWeightKg  // 20.0

        #expect(entry.isValid == true)
    }

    @Test("isValid returns true for weight at maximum boundary")
    func testIsValidAtMaxBoundary() throws {
        let entry = WeightEntry()
        entry.weightKg = WeightEntry.maxWeightKg  // 500.0

        #expect(entry.isValid == true)
    }

    @Test("isValid returns true for weight within range")
    func testIsValidWithinRange() throws {
        let entry = WeightEntry()
        entry.weightKg = 75.0

        #expect(entry.isValid == true)
    }

    @Test("isValid returns false for weight below minimum")
    func testIsValidBelowMinimum() throws {
        let entry = WeightEntry()
        entry.weightKg = 19.9

        #expect(entry.isValid == false)
    }

    @Test("isValid returns false for weight at zero")
    func testIsValidAtZero() throws {
        let entry = WeightEntry()
        entry.weightKg = 0

        #expect(entry.isValid == false)
    }

    @Test("isValid returns false for negative weight")
    func testIsValidNegativeWeight() throws {
        let entry = WeightEntry()
        entry.weightKg = -10.0

        #expect(entry.isValid == false)
    }

    @Test("isValid returns false for weight above maximum")
    func testIsValidAboveMaximum() throws {
        let entry = WeightEntry()
        entry.weightKg = 500.1

        #expect(entry.isValid == false)
    }

    // MARK: - Body Fat Validation Tests

    @Test("Entry with valid body fat percentage is valid")
    func testBodyFatValid() throws {
        let entry = WeightEntry()
        entry.weightKg = 70.0
        entry.bodyFatPercentage = 25.0

        #expect(entry.isValid == true)
    }

    @Test("Entry with zero body fat is valid")
    func testBodyFatZero() throws {
        let entry = WeightEntry()
        entry.weightKg = 70.0
        entry.bodyFatPercentage = 0.0

        #expect(entry.isValid == true)
    }

    @Test("Entry with 100% body fat is valid (edge case)")
    func testBodyFatMax() throws {
        let entry = WeightEntry()
        entry.weightKg = 70.0
        entry.bodyFatPercentage = 100.0

        #expect(entry.isValid == true)
    }

    @Test("Entry with nil body fat is valid")
    func testBodyFatNil() throws {
        let entry = WeightEntry()
        entry.weightKg = 70.0
        entry.bodyFatPercentage = nil

        #expect(entry.isValid == true)
    }

    // MARK: - Constants Tests

    @Test("Minimum weight constant is 20 kg")
    func testMinWeightConstant() throws {
        #expect(WeightEntry.minWeightKg == 20.0)
    }

    @Test("Maximum weight constant is 500 kg")
    func testMaxWeightConstant() throws {
        #expect(WeightEntry.maxWeightKg == 500.0)
    }

    // MARK: - SwiftData Persistence Tests

    @Test("WeightEntry can be inserted into SwiftData context")
    func testInsert() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let entry = WeightEntry(
            timestamp: Date(),
            weightKg: 75.5,
            bodyFatPercentage: 20.0,
            source: "manual",
            notes: "Test entry"
        )
        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<WeightEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        #expect(entries.first?.weightKg == 75.5)
        #expect(entries.first?.bodyFatPercentage == 20.0)
        #expect(entries.first?.source == "manual")
        #expect(entries.first?.notes == "Test entry")
    }

    @Test("WeightEntry can be fetched from SwiftData context")
    func testFetch() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Insert multiple entries
        let entry1 = WeightEntry(weightKg: 70.0)
        let entry2 = WeightEntry(weightKg: 72.0)
        let entry3 = WeightEntry(weightKg: 71.5)

        context.insert(entry1)
        context.insert(entry2)
        context.insert(entry3)
        try context.save()

        let descriptor = FetchDescriptor<WeightEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 3)
    }

    @Test("WeightEntry can be updated in SwiftData context")
    func testUpdate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let entry = WeightEntry(weightKg: 70.0)
        context.insert(entry)
        try context.save()

        // Update the entry
        entry.weightKg = 71.5
        entry.bodyFatPercentage = 22.0
        entry.notes = "Updated"
        try context.save()

        // Fetch and verify
        let descriptor = FetchDescriptor<WeightEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        #expect(entries.first?.weightKg == 71.5)
        #expect(entries.first?.bodyFatPercentage == 22.0)
        #expect(entries.first?.notes == "Updated")
    }

    @Test("WeightEntry can be deleted from SwiftData context")
    func testDelete() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let entry = WeightEntry(weightKg: 70.0)
        context.insert(entry)
        try context.save()

        // Verify inserted
        var descriptor = FetchDescriptor<WeightEntry>()
        var entries = try context.fetch(descriptor)
        #expect(entries.count == 1)

        // Delete
        context.delete(entry)
        try context.save()

        // Verify deleted
        descriptor = FetchDescriptor<WeightEntry>()
        entries = try context.fetch(descriptor)
        #expect(entries.count == 0)
    }

    @Test("WeightEntry with all values persists correctly")
    func testFullPersistence() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let testDate = Date()
        let testId = UUID()

        let entry = WeightEntry(
            id: testId,
            timestamp: testDate,
            weightKg: 82.3,
            bodyFatPercentage: 18.5,
            source: "healthkit",
            notes: "Post-run"
        )

        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<WeightEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        guard let fetched = entries.first else {
            Issue.record("No WeightEntry found after insert")
            return
        }

        #expect(fetched.id == testId)
        #expect(fetched.timestamp == testDate)
        #expect(fetched.weightKg == 82.3)
        #expect(fetched.bodyFatPercentage == 18.5)
        #expect(fetched.source == "healthkit")
        #expect(fetched.notes == "Post-run")
    }
}
