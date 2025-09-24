//
//  ReconstitutionCalculatorTests.swift
//  JabTrackerTests
//

import Foundation
import Testing

@testable import JabTracker

@Suite("ReconstitutionCalculator Tests")
struct ReconstitutionCalculatorTests {
    @Test("Calculate standard reconstitution")
    func standardReconstitution() throws {
        // Given: 5mg vial, 0.5mg target dose, 2ml water
        let vialStrength = 5.0
        let targetDose = 0.5
        let waterVolume = 2.0

        // When: Calculate reconstitution
        let result = try ReconstitutionCalculator.calculate(
            vialStrength: vialStrength,
            targetDose: targetDose,
            waterVolume: waterVolume)

        // Then: Verify calculations
        #expect(result.waterVolume == 2.0)
        #expect(result.concentration == 2.5)  // 5mg / 2ml = 2.5mg/ml
        #expect(result.unitsPerDose == 20.0)  // 0.5mg / 2.5mg/ml * 100 = 20 units
        #expect(result.totalUnits == 200.0)  // 2ml * 100 = 200 units
    }

    @Test("Calculate reconstitution with 10mg vial")
    func reconstitutionWith10mgVial() throws {
        // Given: 10mg vial, 2mg target dose, 3ml water
        let vialStrength = 10.0
        let targetDose = 2.0
        let waterVolume = 3.0

        // When: Calculate reconstitution
        let result = try ReconstitutionCalculator.calculate(
            vialStrength: vialStrength,
            targetDose: targetDose,
            waterVolume: waterVolume)

        // Then: Verify calculations
        #expect(result.waterVolume == 3.0)
        #expect(abs(result.concentration - 3.333) < 0.01)  // 10mg / 3ml ≈ 3.33mg/ml
        #expect(abs(result.unitsPerDose - 60.0) < 0.1)  // 2mg / 3.33mg/ml * 100 ≈ 60 units
        #expect(result.totalUnits == 300.0)  // 3ml * 100 = 300 units
    }

    @Test("Calculate water volume for desired units")
    func testCalculateWaterVolume() throws {
        // Given: 5mg vial, 0.25mg dose, want 10 units per dose
        let vialStrength = 5.0
        let targetDose = 0.25
        let desiredUnits = 10.0

        // When: Calculate water volume
        let waterVolume = try ReconstitutionCalculator.calculateWaterVolume(
            vialStrength: vialStrength,
            targetDose: targetDose,
            desiredUnits: desiredUnits)

        // Then: Verify water volume
        #expect(waterVolume == 2.0)  // (5 * 10) / (0.25 * 100) = 2ml
    }

    @Test("Invalid vial strength throws error")
    func testInvalidVialStrength() throws {
        // Given: Invalid vial strength
        let vialStrength = 0.0
        let targetDose = 0.5
        let waterVolume = 2.0

        // When/Then: Should throw error
        #expect(throws: ReconstitutionCalculator.ReconstitutionError.invalidVialStrength) {
            try ReconstitutionCalculator.calculate(
                vialStrength: vialStrength,
                targetDose: targetDose,
                waterVolume: waterVolume)
        }
    }

    @Test("Invalid target dose throws error")
    func testInvalidTargetDose() throws {
        // Given: Invalid target dose
        let vialStrength = 5.0
        let targetDose = 0.0
        let waterVolume = 2.0

        // When/Then: Should throw error
        #expect(throws: ReconstitutionCalculator.ReconstitutionError.invalidTargetDose) {
            try ReconstitutionCalculator.calculate(
                vialStrength: vialStrength,
                targetDose: targetDose,
                waterVolume: waterVolume)
        }
    }

    @Test("Target dose exceeds vial strength throws error")
    func testTargetDoseExceedsVialStrength() throws {
        // Given: Target dose > vial strength
        let vialStrength = 5.0
        let targetDose = 10.0
        let waterVolume = 2.0

        // When/Then: Should throw error
        #expect(throws: ReconstitutionCalculator.ReconstitutionError.targetDoseExceedsVialStrength) {
            try ReconstitutionCalculator.calculate(
                vialStrength: vialStrength,
                targetDose: targetDose,
                waterVolume: waterVolume)
        }
    }

    @Test("Invalid water volume throws error")
    func testInvalidWaterVolume() throws {
        // Given: Invalid water volume
        let vialStrength = 5.0
        let targetDose = 0.5
        let waterVolume = 0.0

        // When/Then: Should throw error
        #expect(throws: ReconstitutionCalculator.ReconstitutionError.invalidWaterVolume) {
            try ReconstitutionCalculator.calculate(
                vialStrength: vialStrength,
                targetDose: targetDose,
                waterVolume: waterVolume)
        }
    }

    @Test("Common scenarios generate valid results")
    func testCommonScenarios() {
        // When: Get common scenarios
        let scenarios = ReconstitutionCalculator.commonScenarios()

        // Then: Verify we have scenarios
        #expect(!scenarios.isEmpty)

        // Verify each scenario has valid results
        for (label, result) in scenarios {
            #expect(!label.isEmpty)
            #expect(result.waterVolume > 0)
            #expect(result.unitsPerDose > 0)
            #expect(result.concentration > 0)
            #expect(result.totalUnits > 0)
        }
    }

    @Test("Display text formatting")
    func testDisplayText() throws {
        // Given: A reconstitution result
        let result = try ReconstitutionCalculator.calculate(
            vialStrength: 5.0,
            targetDose: 0.5,
            waterVolume: 2.0)

        // When: Get display text
        let displayText = result.displayText

        // Then: Verify text contains key information
        #expect(displayText.contains("2"))
        #expect(displayText.contains("ml"))
        #expect(displayText.contains("20"))
        #expect(displayText.contains("units"))
    }

    @Test("Edge case: Very small doses")
    func verySmallDoses() throws {
        // Given: Very small dose
        let vialStrength = 5.0
        let targetDose = 0.01
        let waterVolume = 5.0

        // When: Calculate reconstitution
        let result = try ReconstitutionCalculator.calculate(
            vialStrength: vialStrength,
            targetDose: targetDose,
            waterVolume: waterVolume)

        // Then: Verify calculations are still accurate
        #expect(result.concentration == 1.0)  // 5mg / 5ml = 1mg/ml
        #expect(result.unitsPerDose == 1.0)  // 0.01mg / 1mg/ml * 100 = 1 unit
    }

    @Test("Edge case: Maximum dose equals vial strength")
    func maximumDoseEqualsVialStrength() throws {
        // Given: Target dose equals vial strength
        let vialStrength = 10.0
        let targetDose = 10.0
        let waterVolume = 1.0

        // When: Calculate reconstitution
        let result = try ReconstitutionCalculator.calculate(
            vialStrength: vialStrength,
            targetDose: targetDose,
            waterVolume: waterVolume)

        // Then: Verify calculations
        #expect(result.concentration == 10.0)  // 10mg / 1ml = 10mg/ml
        #expect(result.unitsPerDose == 100.0)  // 10mg / 10mg/ml * 100 = 100 units
        #expect(result.totalUnits == 100.0)  // 1ml * 100 = 100 units
    }

    @Test("Error description coverage")
    func errorDescriptions() {
        // Test all error description cases to achieve full coverage
        #expect(
            ReconstitutionCalculator.ReconstitutionError.invalidVialStrength.errorDescription
                == "Vial strength must be greater than 0")
        #expect(
            ReconstitutionCalculator.ReconstitutionError.invalidTargetDose.errorDescription
                == "Target dose must be greater than 0")
        #expect(
            ReconstitutionCalculator.ReconstitutionError.targetDoseExceedsVialStrength.errorDescription
                == "Target dose cannot exceed vial strength")
        #expect(
            ReconstitutionCalculator.ReconstitutionError.invalidWaterVolume.errorDescription
                == "Water volume must be greater than 0")
    }
}
