//
//  TDEECalculationEngineTests.swift
//  JabTrackerTests
//
//  Tests for TDEECalculationEngine - Mifflin-St Jeor BMR and TDEE calculations
//

import Foundation
import Testing

@testable import JabTracker

// MARK: - TDEECalculationEngineTests

@Suite("TDEECalculationEngine Tests")
struct TDEECalculationEngineTests {

    // MARK: - BMR Calculation Tests (Mifflin-St Jeor Formula)

    @Test("calculateBMR for male returns correct value (80kg, 180cm, 30yo)")
    @MainActor
    func testCalculateBMRMale() {
        // Given
        // Mifflin-St Jeor for male: BMR = (10 x weight) + (6.25 x height) - (5 x age) + 5
        // = (10 x 80) + (6.25 x 180) - (5 x 30) + 5
        // = 800 + 1125 - 150 + 5 = 1780
        let engine = TDEECalculationEngine()

        // When
        let bmr = engine.calculateBMR(
            weightKg: 80.0,
            heightCm: 180.0,
            age: 30,
            gender: "male"
        )

        // Then
        #expect(bmr == 1780.0)
    }

    @Test("calculateBMR for female returns correct value (60kg, 165cm, 25yo)")
    @MainActor
    func testCalculateBMRFemale() {
        // Given
        // Mifflin-St Jeor for female: BMR = (10 x weight) + (6.25 x height) - (5 x age) - 161
        // = (10 x 60) + (6.25 x 165) - (5 x 25) - 161
        // = 600 + 1031.25 - 125 - 161 = 1345.25
        let engine = TDEECalculationEngine()

        // When
        let bmr = engine.calculateBMR(
            weightKg: 60.0,
            heightCm: 165.0,
            age: 25,
            gender: "female"
        )

        // Then
        #expect(bmr == 1345.25)
    }

    @Test("calculateBMR accepts lowercase and abbreviated gender values")
    @MainActor
    func testCalculateBMRGenderVariants() {
        // Given
        let engine = TDEECalculationEngine()

        // When/Then - "m" should work like "male"
        let bmrM = engine.calculateBMR(
            weightKg: 80.0,
            heightCm: 180.0,
            age: 30,
            gender: "m"
        )
        #expect(bmrM == 1780.0)

        // When/Then - "f" should work like "female"
        let bmrF = engine.calculateBMR(
            weightKg: 60.0,
            heightCm: 165.0,
            age: 25,
            gender: "f"
        )
        #expect(bmrF == 1345.25)

        // When/Then - "Male" (capitalized) should work
        let bmrMale = engine.calculateBMR(
            weightKg: 80.0,
            heightCm: 180.0,
            age: 30,
            gender: "Male"
        )
        #expect(bmrMale == 1780.0)
    }

    @Test("calculateBMR with unknown gender returns average of male/female formulas")
    @MainActor
    func testCalculateBMRUnknownGender() {
        // Given
        // For unknown gender, use average: baseBMR - 78 (midpoint between +5 and -161)
        // baseBMR = (10 x 70) + (6.25 x 170) - (5 x 30) = 700 + 1062.5 - 150 = 1612.5
        // Result = 1612.5 - 78 = 1534.5
        let engine = TDEECalculationEngine()

        // When
        let bmr = engine.calculateBMR(
            weightKg: 70.0,
            heightCm: 170.0,
            age: 30,
            gender: ""
        )

        // Then
        #expect(bmr == 1534.5)
    }

    // MARK: - Initial TDEE Calculation Tests

    @Test("calculateInitialTDEE applies activity multiplier correctly")
    @MainActor
    func testCalculateInitialTDEEWithMultiplier() {
        // Given
        // BMR for male 80kg, 180cm, 30yo = 1780
        // TDEE = BMR x 1.55 (moderately active) = 1780 x 1.55 = 2759
        let engine = TDEECalculationEngine()

        // When
        let tdee = engine.calculateInitialTDEE(
            weightKg: 80.0,
            heightCm: 180.0,
            age: 30,
            gender: "male",
            activityMultiplier: 1.55
        )

        // Then
        #expect(tdee == 2759.0)
    }

    @Test("calculateInitialTDEE with sedentary multiplier (1.2)")
    @MainActor
    func testCalculateInitialTDEESedentary() {
        // Given
        // BMR for male 80kg, 180cm, 30yo = 1780
        // TDEE = 1780 x 1.2 = 2136
        let engine = TDEECalculationEngine()

        // When
        let tdee = engine.calculateInitialTDEE(
            weightKg: 80.0,
            heightCm: 180.0,
            age: 30,
            gender: "male",
            activityMultiplier: 1.2
        )

        // Then
        #expect(tdee == 2136.0)
    }

    @Test("calculateInitialTDEE with TrainingLevel.cardioAndLifting (very active)")
    @MainActor
    func testCalculateInitialTDEEWithTrainingLevel() {
        // Given
        // BMR for male 80kg, 180cm, 30yo = 1780
        // TrainingLevel.cardioAndLifting has multiplier 1.725
        // TDEE = 1780 x 1.725 = 3070.5
        let engine = TDEECalculationEngine()

        // When
        let tdee = engine.calculateInitialTDEE(
            weightKg: 80.0,
            heightCm: 180.0,
            age: 30,
            gender: "male",
            trainingLevel: .cardioAndLifting
        )

        // Then
        #expect(tdee == 3070.5)
    }

    @Test("calculateInitialTDEE with TrainingLevel.none (sedentary)")
    @MainActor
    func testCalculateInitialTDEEWithTrainingLevelNone() {
        // Given
        // BMR for female 60kg, 165cm, 25yo = 1345.25
        // TrainingLevel.none has multiplier 1.2
        // TDEE = 1345.25 x 1.2 = 1614.3
        let engine = TDEECalculationEngine()

        // When
        let tdee = engine.calculateInitialTDEE(
            weightKg: 60.0,
            heightCm: 165.0,
            age: 25,
            gender: "female",
            trainingLevel: .none
        )

        // Then
        #expect(tdee == 1614.3)
    }

    @Test("calculateInitialTDEE with TrainingLevel.lifting")
    @MainActor
    func testCalculateInitialTDEEWithTrainingLevelLifting() {
        // Given
        // BMR for male 75kg, 175cm, 28yo = (10x75) + (6.25x175) - (5x28) + 5
        // = 750 + 1093.75 - 140 + 5 = 1708.75
        // TrainingLevel.lifting has multiplier 1.55
        // TDEE = 1708.75 x 1.55 = 2648.5625
        let engine = TDEECalculationEngine()

        // When
        let tdee = engine.calculateInitialTDEE(
            weightKg: 75.0,
            heightCm: 175.0,
            age: 28,
            gender: "male",
            trainingLevel: .lifting
        )

        // Then
        #expect(tdee == 2648.5625)
    }

    // MARK: - Edge Case Tests

    @Test("calculateBMR with minimum valid inputs")
    @MainActor
    func testCalculateBMRMinimumInputs() {
        // Given - minimum reasonable values
        let engine = TDEECalculationEngine()

        // When
        let bmr = engine.calculateBMR(
            weightKg: 40.0,  // Very light adult
            heightCm: 140.0,  // Short adult
            age: 18,
            gender: "female"
        )

        // Then - BMR = (10x40) + (6.25x140) - (5x18) - 161
        // = 400 + 875 - 90 - 161 = 1024
        #expect(bmr == 1024.0)
    }

    @Test("calculateBMR with maximum valid inputs")
    @MainActor
    func testCalculateBMRMaximumInputs() {
        // Given - maximum reasonable values
        let engine = TDEECalculationEngine()

        // When
        let bmr = engine.calculateBMR(
            weightKg: 150.0,  // Heavy individual
            heightCm: 210.0,  // Tall individual
            age: 70,
            gender: "male"
        )

        // Then - BMR = (10x150) + (6.25x210) - (5x70) + 5
        // = 1500 + 1312.5 - 350 + 5 = 2467.5
        #expect(bmr == 2467.5)
    }

    @Test("calculateInitialTDEE with all training levels")
    @MainActor
    func testCalculateInitialTDEEAllTrainingLevels() {
        // Given
        let engine = TDEECalculationEngine()
        let baseParams = (weightKg: 70.0, heightCm: 170.0, age: 30, gender: "male")
        // BMR = (10x70) + (6.25x170) - (5x30) + 5 = 700 + 1062.5 - 150 + 5 = 1617.5

        // When/Then - verify all training levels produce expected TDEE
        let tdeeNone = engine.calculateInitialTDEE(
            weightKg: baseParams.weightKg,
            heightCm: baseParams.heightCm,
            age: baseParams.age,
            gender: baseParams.gender,
            trainingLevel: .none
        )
        #expect(tdeeNone == 1617.5 * 1.2)  // 1941.0

        let tdeeLifting = engine.calculateInitialTDEE(
            weightKg: baseParams.weightKg,
            heightCm: baseParams.heightCm,
            age: baseParams.age,
            gender: baseParams.gender,
            trainingLevel: .lifting
        )
        #expect(tdeeLifting == 1617.5 * 1.55)  // 2507.125

        let tdeeCardio = engine.calculateInitialTDEE(
            weightKg: baseParams.weightKg,
            heightCm: baseParams.heightCm,
            age: baseParams.age,
            gender: baseParams.gender,
            trainingLevel: .cardio
        )
        #expect(tdeeCardio == 1617.5 * 1.55)  // 2507.125

        let tdeeCardioAndLifting = engine.calculateInitialTDEE(
            weightKg: baseParams.weightKg,
            heightCm: baseParams.heightCm,
            age: baseParams.age,
            gender: baseParams.gender,
            trainingLevel: .cardioAndLifting
        )
        #expect(tdeeCardioAndLifting == 1617.5 * 1.725)  // 2790.1875
    }
}
