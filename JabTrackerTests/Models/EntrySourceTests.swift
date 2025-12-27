//
//  EntrySourceTests.swift
//  JabTrackerTests
//
//  Tests for EntrySource enum used by WeightEntry and MetricsEntry.
//

import Testing

@testable import JabTracker

@Suite("EntrySource Tests")
struct EntrySourceTests {

    // MARK: - Raw Value Tests

    @Test("Manual source has correct raw value")
    func testManualRawValue() {
        #expect(EntrySource.manual.rawValue == "manual")
    }

    @Test("HealthKit source has correct raw value")
    func testHealthKitRawValue() {
        #expect(EntrySource.healthkit.rawValue == "healthkit")
    }

    // MARK: - Initialization Tests

    @Test("EntrySource initializes from valid raw value")
    func testInitFromRawValue() {
        let manual = EntrySource(rawValue: "manual")
        let healthkit = EntrySource(rawValue: "healthkit")

        #expect(manual == .manual)
        #expect(healthkit == .healthkit)
    }

    @Test("EntrySource returns nil for invalid raw value")
    func testInitFromInvalidRawValue() {
        let invalid = EntrySource(rawValue: "invalid")

        #expect(invalid == nil)
    }

    // MARK: - WeightEntry Integration Tests

    @Test("WeightEntry sourceEnum returns correct value")
    func testWeightEntrySourceEnum() {
        let entry = WeightEntry(weightKg: 70.0, source: "manual")

        #expect(entry.sourceEnum == .manual)
    }

    @Test("WeightEntry sourceEnum setter updates source string")
    func testWeightEntrySourceEnumSetter() {
        let entry = WeightEntry(weightKg: 70.0, source: "manual")

        entry.sourceEnum = .healthkit

        #expect(entry.source == "healthkit")
        #expect(entry.sourceEnum == .healthkit)
    }

    @Test("WeightEntry sourceEnum defaults to manual for invalid string")
    func testWeightEntrySourceEnumDefaultsToManual() {
        let entry = WeightEntry(weightKg: 70.0)
        entry.source = "invalid"

        #expect(entry.sourceEnum == .manual)
    }

    // MARK: - MetricsEntry Integration Tests

    @Test("MetricsEntry sourceEnum returns correct value")
    func testMetricsEntrySourceEnum() {
        let entry = MetricsEntry(waistCm: 80.0, source: "healthkit")

        #expect(entry.sourceEnum == .healthkit)
    }

    @Test("MetricsEntry sourceEnum setter updates source string")
    func testMetricsEntrySourceEnumSetter() {
        let entry = MetricsEntry(waistCm: 80.0, source: "manual")

        entry.sourceEnum = .healthkit

        #expect(entry.source == "healthkit")
        #expect(entry.sourceEnum == .healthkit)
    }

    @Test("MetricsEntry sourceEnum defaults to manual for invalid string")
    func testMetricsEntrySourceEnumDefaultsToManual() {
        let entry = MetricsEntry(waistCm: 80.0)
        entry.source = "unknown"

        #expect(entry.sourceEnum == .manual)
    }
}
