//
//  HealthKitAuthorizationTests.swift
//  JabTrackerTests
//
//  Tests for HealthKit authorization type configuration.
//  Verifies that required HealthKit types are included in authorization requests.
//

import HealthKit
import Testing

@testable import JabTracker

@Suite("HealthKit Authorization Tests")
@MainActor
struct HealthKitAuthorizationTests {

    // MARK: - Authorization Type Configuration Tests

    @Test("Authorization read types includes activeEnergyBurned")
    func testAuthorizationIncludesActiveEnergyBurned() {
        // Given: The expected active energy type
        let expectedType = HKQuantityType(.activeEnergyBurned)

        // When: We check the authorization read types
        let readTypes = MetricsService.testableReadTypes

        // Then: activeEnergyBurned should be included
        #expect(readTypes.contains(expectedType), "Authorization read types must include activeEnergyBurned")
    }

    @Test("Authorization read types includes all required body metrics types")
    func testAuthorizationIncludesBodyMetricsTypes() {
        let readTypes = MetricsService.testableReadTypes

        // Verify all expected quantity types are present
        #expect(readTypes.contains(HKQuantityType(.bodyMass)), "Must include bodyMass")
        #expect(readTypes.contains(HKQuantityType(.height)), "Must include height")
        #expect(readTypes.contains(HKQuantityType(.bodyFatPercentage)), "Must include bodyFatPercentage")
        #expect(readTypes.contains(HKQuantityType(.waistCircumference)), "Must include waistCircumference")
        #expect(readTypes.contains(HKQuantityType(.activeEnergyBurned)), "Must include activeEnergyBurned")
    }

    @Test("Authorization read types includes characteristic types for TDEE")
    func testAuthorizationIncludesCharacteristicTypes() {
        let readTypes = MetricsService.testableReadTypes

        // Verify characteristic types are present
        #expect(readTypes.contains(HKCharacteristicType(.biologicalSex)), "Must include biologicalSex")
        #expect(readTypes.contains(HKCharacteristicType(.dateOfBirth)), "Must include dateOfBirth")
    }

    @Test("activeEnergyType constant has correct identifier")
    func testActiveEnergyTypeIdentifier() {
        // Verify the active energy type constant is correctly configured
        let activeEnergyType = MetricsService.testableActiveEnergyType

        #expect(activeEnergyType.identifier == HKQuantityTypeIdentifier.activeEnergyBurned.rawValue)
    }

    @Test("Authorization read types count is correct")
    func testAuthorizationReadTypesCount() {
        let readTypes = MetricsService.testableReadTypes

        // Expected: 5 quantity types + 2 characteristic types = 7 total
        // Quantity: bodyMass, height, bodyFatPercentage, waistCircumference, activeEnergyBurned
        // Characteristic: biologicalSex, dateOfBirth
        #expect(readTypes.count == 7, "Expected 7 read types total")
    }
}
