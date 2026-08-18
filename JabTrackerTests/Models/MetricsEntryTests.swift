//
//  MetricsEntryTests.swift
//  JabTrackerTests
//
//  Tests for MetricsEntry SwiftData model.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("MetricsEntry Tests")
@MainActor
struct MetricsEntryTests {

    // MARK: - Test Helpers

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([MetricsEntry.self])
        let configuration = InMemoryTestStore.configuration(schema: schema)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - Constants Tests

    @Test("cmToInchesConversion is correct")
    func testCmToInchesConversion() {
        #expect(abs(MetricsEntry.cmToInchesConversion - 0.393701) < 0.000001)
    }

    @Test("minCircumferenceCm is 10")
    func testMinCircumference() {
        #expect(MetricsEntry.minCircumferenceCm == 10.0)
    }

    @Test("maxCircumferenceCm is 300")
    func testMaxCircumference() {
        #expect(MetricsEntry.maxCircumferenceCm == 300.0)
    }

    // MARK: - Validation Tests

    @Test("isValidCircumference returns true for valid values")
    func testIsValidCircumferenceTrue() {
        #expect(MetricsEntry.isValidCircumference(10.0) == true)
        #expect(MetricsEntry.isValidCircumference(50.0) == true)
        #expect(MetricsEntry.isValidCircumference(100.0) == true)
        #expect(MetricsEntry.isValidCircumference(300.0) == true)
    }

    @Test("isValidCircumference returns false for values below minimum")
    func testIsValidCircumferenceBelowMin() {
        #expect(MetricsEntry.isValidCircumference(9.9) == false)
        #expect(MetricsEntry.isValidCircumference(0.0) == false)
        #expect(MetricsEntry.isValidCircumference(-10.0) == false)
    }

    @Test("isValidCircumference returns false for values above maximum")
    func testIsValidCircumferenceAboveMax() {
        #expect(MetricsEntry.isValidCircumference(300.1) == false)
        #expect(MetricsEntry.isValidCircumference(500.0) == false)
    }

    // MARK: - Initialization Tests

    @Test("Default initialization has correct values")
    func testDefaultInitialization() {
        let entry = MetricsEntry()

        #expect(entry.id != UUID())
        #expect(entry.timestamp <= Date())
        #expect(entry.waistCm == nil)
        #expect(entry.hipCm == nil)
        #expect(entry.chestCm == nil)
        #expect(entry.neckCm == nil)
        #expect(entry.source == "manual")
        #expect(entry.notes == nil)
    }

    @Test("Custom initialization sets all values")
    func testCustomInitialization() {
        let timestamp = Date()
        let entry = MetricsEntry(
            timestamp: timestamp,
            waistCm: 80.0,
            hipCm: 95.0,
            chestCm: 100.0,
            neckCm: 38.0,
            source: "healthkit",
            notes: "Morning measurement"
        )

        #expect(entry.timestamp == timestamp)
        #expect(entry.waistCm == 80.0)
        #expect(entry.hipCm == 95.0)
        #expect(entry.chestCm == 100.0)
        #expect(entry.neckCm == 38.0)
        #expect(entry.source == "healthkit")
        #expect(entry.notes == "Morning measurement")
    }

    @Test("Convenience initializer converts inches to cm")
    func testInchesConvenienceInitializer() {
        let entry = MetricsEntry(
            waistInches: 32.0,
            hipInches: 38.0,
            chestInches: 40.0,
            neckInches: 15.0
        )

        // 32 inches = 32 / 0.393701 ≈ 81.28 cm
        #expect(entry.waistCm != nil)
        #expect(abs(entry.waistCm! - 81.28) < 0.1)
        #expect(entry.hipCm != nil)
        #expect(abs(entry.hipCm! - 96.52) < 0.1)
        #expect(entry.chestCm != nil)
        #expect(abs(entry.chestCm! - 101.6) < 0.1)
        #expect(entry.neckCm != nil)
        #expect(abs(entry.neckCm! - 38.1) < 0.1)
    }

    // MARK: - Computed Properties Tests

    @Test("waistInInches converts correctly")
    func testWaistInInches() {
        let entry = MetricsEntry(waistCm: 80.0)

        #expect(entry.waistInInches != nil)
        #expect(abs(entry.waistInInches! - 31.496) < 0.01)
    }

    @Test("hipInInches converts correctly")
    func testHipInInches() {
        let entry = MetricsEntry(hipCm: 100.0)

        #expect(entry.hipInInches != nil)
        #expect(abs(entry.hipInInches! - 39.37) < 0.01)
    }

    @Test("chestInInches converts correctly")
    func testChestInInches() {
        let entry = MetricsEntry(chestCm: 100.0)

        #expect(entry.chestInInches != nil)
        #expect(abs(entry.chestInInches! - 39.37) < 0.01)
    }

    @Test("neckInInches converts correctly")
    func testNeckInInches() {
        let entry = MetricsEntry(neckCm: 40.0)

        #expect(entry.neckInInches != nil)
        #expect(abs(entry.neckInInches! - 15.748) < 0.01)
    }

    @Test("Inch conversions return nil when cm is nil")
    func testInchConversionsNil() {
        let entry = MetricsEntry()

        #expect(entry.waistInInches == nil)
        #expect(entry.hipInInches == nil)
        #expect(entry.chestInInches == nil)
        #expect(entry.neckInInches == nil)
    }

    // MARK: - hasAnyMetrics Tests

    @Test("hasAnyMetrics returns true when waist is set")
    func testHasAnyMetricsWaist() {
        let entry = MetricsEntry(waistCm: 80.0)
        #expect(entry.hasAnyMetrics == true)
    }

    @Test("hasAnyMetrics returns true when hip is set")
    func testHasAnyMetricsHip() {
        let entry = MetricsEntry(hipCm: 95.0)
        #expect(entry.hasAnyMetrics == true)
    }

    @Test("hasAnyMetrics returns true when chest is set")
    func testHasAnyMetricsChest() {
        let entry = MetricsEntry(chestCm: 100.0)
        #expect(entry.hasAnyMetrics == true)
    }

    @Test("hasAnyMetrics returns true when neck is set")
    func testHasAnyMetricsNeck() {
        let entry = MetricsEntry(neckCm: 38.0)
        #expect(entry.hasAnyMetrics == true)
    }

    @Test("hasAnyMetrics returns false when no metrics set")
    func testHasAnyMetricsFalse() {
        let entry = MetricsEntry()
        #expect(entry.hasAnyMetrics == false)
    }

    // MARK: - isValid Tests

    @Test("isValid returns true for valid entry with single metric")
    func testIsValidSingleMetric() {
        let entry = MetricsEntry(waistCm: 80.0)
        #expect(entry.isValid == true)
    }

    @Test("isValid returns true for valid entry with all metrics")
    func testIsValidAllMetrics() {
        let entry = MetricsEntry(
            waistCm: 80.0,
            hipCm: 95.0,
            chestCm: 100.0,
            neckCm: 38.0
        )
        #expect(entry.isValid == true)
    }

    @Test("isValid returns false for entry with no metrics")
    func testIsValidNoMetrics() {
        let entry = MetricsEntry()
        #expect(entry.isValid == false)
    }

    @Test("isValid returns false for entry with invalid metric")
    func testIsValidInvalidMetric() {
        let entry = MetricsEntry(waistCm: 5.0)  // Below minimum
        #expect(entry.isValid == false)
    }

    @Test("isValid returns false if any metric is invalid")
    func testIsValidAnyInvalid() {
        let entry = MetricsEntry(
            waistCm: 80.0,
            hipCm: 500.0  // Above maximum
        )
        #expect(entry.isValid == false)
    }

    // MARK: - formattedMeasurement Tests

    @Test("formattedMeasurement returns metric format")
    func testFormattedMeasurementMetric() {
        let entry = MetricsEntry()
        let result = entry.formattedMeasurement(80.5, useMetric: true)

        #expect(result == "80.5 cm")
    }

    @Test("formattedMeasurement returns imperial format")
    func testFormattedMeasurementImperial() {
        let entry = MetricsEntry()
        let result = entry.formattedMeasurement(80.0, useMetric: false)

        #expect(result != nil)
        #expect(result!.contains("in"))
        #expect(result!.contains("31.5"))
    }

    @Test("formattedMeasurement returns nil for nil value")
    func testFormattedMeasurementNil() {
        let entry = MetricsEntry()
        let result = entry.formattedMeasurement(nil, useMetric: true)

        #expect(result == nil)
    }

    // MARK: - SwiftData Persistence Tests

    @Test("MetricsEntry can be inserted into context")
    func testInsert() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let entry = MetricsEntry(waistCm: 80.0, hipCm: 95.0)
        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<MetricsEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        #expect(entries.first?.waistCm == 80.0)
        #expect(entries.first?.hipCm == 95.0)
    }

    @Test("MetricsEntry can be deleted from context")
    func testDelete() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let entry = MetricsEntry(waistCm: 80.0)
        context.insert(entry)
        try context.save()

        context.delete(entry)
        try context.save()

        let descriptor = FetchDescriptor<MetricsEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 0)
    }
}
