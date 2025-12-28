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

    // MARK: - Test Helpers

    /// Standard test parameters for a male subject (BMR = 1617.5)
    private static let standardMaleParams = (weightKg: 70.0, heightCm: 170.0, age: 30, gender: "male")

    /// Calculate TDEE with standard male parameters and specified training level
    private func calculateTDEEWithStandardParams(
        engine: TDEECalculationEngine,
        trainingLevel: TrainingLevel
    ) -> Double {
        engine.calculateInitialTDEE(
            weightKg: Self.standardMaleParams.weightKg,
            heightCm: Self.standardMaleParams.heightCm,
            age: Self.standardMaleParams.age,
            gender: Self.standardMaleParams.gender,
            trainingLevel: trainingLevel
        )
    }

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
        // Using standard male params: BMR = 1617.5

        // When/Then - verify all training levels produce expected TDEE
        #expect(calculateTDEEWithStandardParams(engine: engine, trainingLevel: .none) == 1617.5 * 1.2)
        #expect(calculateTDEEWithStandardParams(engine: engine, trainingLevel: .lifting) == 1617.5 * 1.55)
        #expect(calculateTDEEWithStandardParams(engine: engine, trainingLevel: .cardio) == 1617.5 * 1.55)
        #expect(calculateTDEEWithStandardParams(engine: engine, trainingLevel: .cardioAndLifting) == 1617.5 * 1.725)
    }

    // MARK: - Input Validation Tests

    @Test("calculateBMR returns 0 for negative weight")
    @MainActor
    func testCalculateBMRNegativeWeight() {
        let engine = TDEECalculationEngine()
        let bmr = engine.calculateBMR(weightKg: -80.0, heightCm: 180.0, age: 30, gender: "male")
        #expect(bmr == 0)
    }

    @Test("calculateBMR returns 0 for zero height")
    @MainActor
    func testCalculateBMRZeroHeight() {
        let engine = TDEECalculationEngine()
        let bmr = engine.calculateBMR(weightKg: 80.0, heightCm: 0, age: 30, gender: "male")
        #expect(bmr == 0)
    }

    @Test("calculateBMR returns 0 for zero age")
    @MainActor
    func testCalculateBMRZeroAge() {
        let engine = TDEECalculationEngine()
        let bmr = engine.calculateBMR(weightKg: 80.0, heightCm: 180.0, age: 0, gender: "male")
        #expect(bmr == 0)
    }

    @Test("calculateBMR returns 0 for negative age")
    @MainActor
    func testCalculateBMRNegativeAge() {
        let engine = TDEECalculationEngine()
        let bmr = engine.calculateBMR(weightKg: 80.0, heightCm: 180.0, age: -5, gender: "male")
        #expect(bmr == 0)
    }

    @Test("calculateInitialTDEE clamps activity multiplier below minimum")
    @MainActor
    func testCalculateInitialTDEEClampsLowMultiplier() {
        // Given
        let engine = TDEECalculationEngine()
        // BMR for male 80kg, 180cm, 30yo = 1780
        // Multiplier 0.5 should be clamped to 1.0

        // When
        let tdee = engine.calculateInitialTDEE(
            weightKg: 80.0,
            heightCm: 180.0,
            age: 30,
            gender: "male",
            activityMultiplier: 0.5
        )

        // Then - should use clamped multiplier of 1.0
        #expect(tdee == 1780.0 * 1.0)
    }

    @Test("calculateInitialTDEE clamps activity multiplier above maximum")
    @MainActor
    func testCalculateInitialTDEEClampsHighMultiplier() {
        // Given
        let engine = TDEECalculationEngine()
        // BMR for male 80kg, 180cm, 30yo = 1780
        // Multiplier 5.0 should be clamped to 2.5

        // When
        let tdee = engine.calculateInitialTDEE(
            weightKg: 80.0,
            heightCm: 180.0,
            age: 30,
            gender: "male",
            activityMultiplier: 5.0
        )

        // Then - should use clamped multiplier of 2.5
        #expect(tdee == 1780.0 * 2.5)
    }

    // MARK: - EWMA Weight Smoothing Tests

    @Test("calculateEWMA smooths a simple 3-point series")
    @MainActor
    func testCalculateEWMASimpleSeries() {
        // Given: 3 weights over 3 days
        let engine = TDEECalculationEngine()
        let baseDate = Date()
        let weights: [(date: Date, weightKg: Double)] = [
            (baseDate, 80.0),
            (baseDate.addingTimeInterval(86400), 80.5),
            (baseDate.addingTimeInterval(172800), 80.0),
        ]

        // When
        let smoothed = engine.calculateEWMA(weights: weights, alpha: 0.2)

        // Then: Should have 3 smoothed values
        #expect(smoothed.count == 3)
        // First value equals first input
        #expect(smoothed[0].smoothedWeight == 80.0)
        // Second: EWMA = 0.2 * 80.5 + 0.8 * 80.0 = 16.1 + 64 = 80.1
        #expect(abs(smoothed[1].smoothedWeight - 80.1) < 0.001)
        // Third: EWMA = 0.2 * 80.0 + 0.8 * 80.1 = 16 + 64.08 = 80.08
        #expect(abs(smoothed[2].smoothedWeight - 80.08) < 0.001)
    }

    @Test("calculateEWMA reduces volatility from weight spike")
    @MainActor
    func testCalculateEWMAReducesVolatility() {
        // Given: Weight series with a spike at 82kg
        let engine = TDEECalculationEngine()
        let baseDate = Date()
        let weights: [(date: Date, weightKg: Double)] = [
            (baseDate, 80.0),
            (baseDate.addingTimeInterval(86400), 80.0),
            (baseDate.addingTimeInterval(172800), 82.0),  // Spike
            (baseDate.addingTimeInterval(259200), 80.0),
            (baseDate.addingTimeInterval(345600), 80.0),
        ]

        // When
        let smoothed = engine.calculateEWMA(weights: weights, alpha: 0.2)

        // Then: The smoothed spike should be less than 82
        let spikeIndex = 2
        #expect(smoothed[spikeIndex].smoothedWeight < 82.0)
        #expect(smoothed[spikeIndex].smoothedWeight > 80.0)
    }

    @Test("calculateWeightChangeRate returns correct kg/week for weight loss")
    @MainActor
    func testCalculateWeightChangeRateWeightLoss() {
        // Given: Lost 1kg over 14 days = 0.5 kg/week
        let engine = TDEECalculationEngine()
        let baseDate = Date()
        let smoothedWeights: [(date: Date, smoothedWeight: Double)] = [
            (baseDate, 80.0),
            (baseDate.addingTimeInterval(7 * 86400), 79.5),
            (baseDate.addingTimeInterval(14 * 86400), 79.0),
        ]

        // When
        let rate = engine.calculateWeightChangeRate(smoothedWeights: smoothedWeights)

        // Then: -1 kg over 14 days = -0.5 kg/week
        #expect(rate != nil)
        #expect(abs(rate! - (-0.5)) < 0.01)
    }

    @Test("calculateWeightChangeRate returns correct kg/week for weight gain")
    @MainActor
    func testCalculateWeightChangeRateWeightGain() {
        // Given: Gained 0.7kg over 7 days = 0.7 kg/week
        let engine = TDEECalculationEngine()
        let baseDate = Date()
        let smoothedWeights: [(date: Date, smoothedWeight: Double)] = [
            (baseDate, 70.0),
            (baseDate.addingTimeInterval(7 * 86400), 70.7),
        ]

        // When
        let rate = engine.calculateWeightChangeRate(smoothedWeights: smoothedWeights)

        // Then: +0.7 kg over 7 days = +0.7 kg/week
        #expect(rate != nil)
        #expect(abs(rate! - 0.7) < 0.01)
    }

    @Test("isWeightPlateau returns true for small changes")
    @MainActor
    func testIsWeightPlateauTrue() {
        // Given
        let engine = TDEECalculationEngine()

        // When/Then: Changes < 0.1 kg/week are a plateau
        #expect(engine.isWeightPlateau(changeRateKgPerWeek: 0.05) == true)
        #expect(engine.isWeightPlateau(changeRateKgPerWeek: -0.05) == true)
        #expect(engine.isWeightPlateau(changeRateKgPerWeek: 0.0) == true)
    }

    @Test("isWeightPlateau returns false for significant changes")
    @MainActor
    func testIsWeightPlateauFalse() {
        // Given
        let engine = TDEECalculationEngine()

        // When/Then: Changes >= 0.1 kg/week are NOT a plateau
        #expect(engine.isWeightPlateau(changeRateKgPerWeek: 0.5) == false)
        #expect(engine.isWeightPlateau(changeRateKgPerWeek: -0.3) == false)
        #expect(engine.isWeightPlateau(changeRateKgPerWeek: 0.1) == false)
    }

    @Test("calculateEWMA returns empty array for empty input")
    @MainActor
    func testCalculateEWMAEmptyInput() {
        // Given
        let engine = TDEECalculationEngine()
        let weights: [(date: Date, weightKg: Double)] = []

        // When
        let smoothed = engine.calculateEWMA(weights: weights)

        // Then
        #expect(smoothed.isEmpty)
    }

    @Test("calculateEWMA handles single entry")
    @MainActor
    func testCalculateEWMASingleEntry() {
        // Given
        let engine = TDEECalculationEngine()
        let weights: [(date: Date, weightKg: Double)] = [
            (Date(), 75.0)
        ]

        // When
        let smoothed = engine.calculateEWMA(weights: weights)

        // Then: Single entry returns that value
        #expect(smoothed.count == 1)
        #expect(smoothed[0].smoothedWeight == 75.0)
    }

    @Test("calculateWeightChangeRate returns nil for insufficient data")
    @MainActor
    func testCalculateWeightChangeRateInsufficientData() {
        // Given
        let engine = TDEECalculationEngine()

        // When/Then: Empty array
        let rate1 = engine.calculateWeightChangeRate(smoothedWeights: [])
        #expect(rate1 == nil)

        // When/Then: Single entry
        let rate2 = engine.calculateWeightChangeRate(smoothedWeights: [(Date(), 80.0)])
        #expect(rate2 == nil)

        // When/Then: Less than 7 days span
        let baseDate = Date()
        let shortSpan: [(date: Date, smoothedWeight: Double)] = [
            (baseDate, 80.0),
            (baseDate.addingTimeInterval(5 * 86400), 79.5),  // Only 5 days
        ]
        let rate3 = engine.calculateWeightChangeRate(smoothedWeights: shortSpan)
        #expect(rate3 == nil)
    }

    // MARK: - Adaptive TDEE Tests

    @Test("calculateAdaptiveTDEE for weight loss scenario")
    @MainActor
    func testCalculateAdaptiveTDEEWeightLoss() {
        // Given: Lost 2kg over 14 days while eating 1800 kcal/day
        // TDEE = 1800 + ((-2) * 7700 / 14) = 1800 + (-1100) = 1800 - (-1100) = 1800 + 1100 = 2900
        // Formula: TDEE = intake + (weightChange * 7700 / days)
        // If losing weight while eating 1800, actual TDEE must be higher
        let engine = TDEECalculationEngine()

        // When
        let tdee = engine.calculateAdaptiveTDEE(
            averageDailyIntake: 1800,
            weightChangeKg: -2.0,  // Lost 2kg
            durationDays: 14
        )

        // Then: TDEE = 1800 + (-2 * 7700 / 14) = 1800 + (-1100) = 700? No wait...
        // If you lost weight, your TDEE > intake. Formula correction:
        // Deficit = TDEE - Intake = Weight loss * 7700 / days
        // TDEE = Intake + Deficit = 1800 + (2 * 7700 / 14) = 1800 + 1100 = 2900
        // weightChange is -2 (loss), so: TDEE = 1800 + (-(-2) * 7700 / 14) = 1800 + 1100
        // Actually: TDEE = intake - (weightChange * 7700 / days) for negative change
        // Let me recalculate: The plan says + but let's check the math
        // Lost 2kg = -2kg change, 7700 cal/kg, 14 days
        // Daily deficit = 2 * 7700 / 14 = 1100 cal/day
        // So TDEE = intake + deficit = 1800 + 1100 = 2900
        // With formula: TDEE = intake + (weightChange * 7700 / days)
        // = 1800 + (-2 * 7700 / 14) = 1800 - 1100 = 700? That's wrong.
        // The formula should be: TDEE = intake - (weightChange * 7700 / days)
        // = 1800 - (-2 * 7700 / 14) = 1800 + 1100 = 2900

        #expect(tdee != nil)
        // Using formula from plan: TDEE = intake + (weightChange * 7700 / days)
        // But that gives 700 which is wrong. Let me check the plan again...
        // Plan says: "TDEE = Average Daily Intake + (Weight Change * 7700 cal/kg / Days)"
        // With weightChange = -2: TDEE = 1800 + (-2 * 7700 / 14) = 1800 - 1100 = 700
        // This is wrong for weight loss scenario. Need to verify implementation.
        // Actually maybe the plan formula has a sign error. Let me just test the logic:
        // If eating 1800 and losing 2kg in 14 days, TDEE should be ~2900
        #expect(abs(tdee! - 2900) < 1)
    }

    @Test("calculateAdaptiveTDEE for weight gain scenario")
    @MainActor
    func testCalculateAdaptiveTDEEWeightGain() {
        // Given: Gained 1kg over 14 days while eating 2500 kcal/day
        // Surplus = 1 * 7700 / 14 = 550 kcal/day
        // TDEE = intake - surplus = 2500 - 550 = 1950
        let engine = TDEECalculationEngine()

        // When
        let tdee = engine.calculateAdaptiveTDEE(
            averageDailyIntake: 2500,
            weightChangeKg: 1.0,  // Gained 1kg
            durationDays: 14
        )

        // Then: TDEE = 2500 - (1 * 7700 / 14) = 2500 - 550 = 1950
        #expect(tdee != nil)
        #expect(abs(tdee! - 1950) < 1)
    }

    @Test("calculateAdaptiveTDEE for maintenance scenario")
    @MainActor
    func testCalculateAdaptiveTDEEMaintenance() {
        // Given: No weight change while eating 2200 kcal/day
        // TDEE should equal intake
        let engine = TDEECalculationEngine()

        // When
        let tdee = engine.calculateAdaptiveTDEE(
            averageDailyIntake: 2200,
            weightChangeKg: 0.0,  // No change
            durationDays: 14
        )

        // Then: TDEE = intake (no deficit/surplus)
        #expect(tdee != nil)
        #expect(tdee! == 2200)
    }

    @Test("calculateAdaptiveTDEE returns nil for invalid inputs")
    @MainActor
    func testCalculateAdaptiveTDEEInvalidInputs() {
        let engine = TDEECalculationEngine()

        // When/Then: Zero duration
        let tdee1 = engine.calculateAdaptiveTDEE(
            averageDailyIntake: 2000,
            weightChangeKg: -1.0,
            durationDays: 0
        )
        #expect(tdee1 == nil)

        // When/Then: Zero intake
        let tdee2 = engine.calculateAdaptiveTDEE(
            averageDailyIntake: 0,
            weightChangeKg: -1.0,
            durationDays: 14
        )
        #expect(tdee2 == nil)

        // When/Then: Negative duration
        let tdee3 = engine.calculateAdaptiveTDEE(
            averageDailyIntake: 2000,
            weightChangeKg: -1.0,
            durationDays: -7
        )
        #expect(tdee3 == nil)
    }

    @Test("calculateConfidenceScore returns higher score for longer duration")
    @MainActor
    func testCalculateConfidenceScoreDuration() {
        let engine = TDEECalculationEngine()

        // When: Compare 14 days vs 28 days
        let score14Days = engine.calculateConfidenceScore(
            durationDays: 14,
            daysWithData: 14,
            weightChangeRateKgPerWeek: 0.5
        )
        let score28Days = engine.calculateConfidenceScore(
            durationDays: 28,
            daysWithData: 28,
            weightChangeRateKgPerWeek: 0.5
        )

        // Then: Longer duration = higher confidence
        #expect(score28Days > score14Days)
        #expect(score14Days > 0)
        #expect(score28Days <= 1.0)
    }

    @Test("calculateConfidenceScore returns higher score for better consistency")
    @MainActor
    func testCalculateConfidenceScoreConsistency() {
        let engine = TDEECalculationEngine()

        // When: Compare 50% vs 100% data logging consistency
        let scorePoor = engine.calculateConfidenceScore(
            durationDays: 28,
            daysWithData: 14,  // 50% of days logged
            weightChangeRateKgPerWeek: 0.5
        )
        let scoreGood = engine.calculateConfidenceScore(
            durationDays: 28,
            daysWithData: 28,  // 100% of days logged
            weightChangeRateKgPerWeek: 0.5
        )

        // Then: Better consistency = higher confidence
        #expect(scoreGood > scorePoor)
    }

    @Test("calculateConfidenceScore returns value between 0 and 1")
    @MainActor
    func testCalculateConfidenceScoreRange() {
        let engine = TDEECalculationEngine()

        // Test various inputs
        let score1 = engine.calculateConfidenceScore(
            durationDays: 7,
            daysWithData: 3,
            weightChangeRateKgPerWeek: 0.1
        )
        let score2 = engine.calculateConfidenceScore(
            durationDays: 60,
            daysWithData: 60,
            weightChangeRateKgPerWeek: 1.0
        )

        // Then: All scores should be in [0, 1] range
        #expect(score1 >= 0 && score1 <= 1)
        #expect(score2 >= 0 && score2 <= 1)
    }

    @Test("detectMetabolicAdaptation returns true when TDEE drops >15%")
    @MainActor
    func testDetectMetabolicAdaptationTrue() {
        let engine = TDEECalculationEngine()

        // Given: Expected TDEE 2500, actual 2000 = 20% drop
        let isAdapted = engine.detectMetabolicAdaptation(
            actualTDEE: 2000,
            expectedTDEE: 2500
        )

        // Then: Should detect adaptation (20% > 15%)
        #expect(isAdapted == true)
    }

    @Test("detectMetabolicAdaptation returns false for normal TDEE")
    @MainActor
    func testDetectMetabolicAdaptationFalse() {
        let engine = TDEECalculationEngine()

        // Given: Expected TDEE 2500, actual 2300 = 8% drop
        let isAdapted = engine.detectMetabolicAdaptation(
            actualTDEE: 2300,
            expectedTDEE: 2500
        )

        // Then: Should NOT detect adaptation (8% < 15%)
        #expect(isAdapted == false)
    }

    @Test("detectMetabolicAdaptation returns false at exactly 15% threshold")
    @MainActor
    func testDetectMetabolicAdaptationAtThreshold() {
        let engine = TDEECalculationEngine()

        // Given: Expected TDEE 2000, actual 1700 = exactly 15%
        let isAdapted = engine.detectMetabolicAdaptation(
            actualTDEE: 1700,
            expectedTDEE: 2000
        )

        // Then: At exactly 15%, should NOT detect (threshold is >15%, not >=)
        #expect(isAdapted == false)
    }

    @Test("detectMetabolicAdaptation handles zero expected TDEE")
    @MainActor
    func testDetectMetabolicAdaptationZeroExpected() {
        let engine = TDEECalculationEngine()

        // Given: Zero expected TDEE (invalid)
        let isAdapted = engine.detectMetabolicAdaptation(
            actualTDEE: 2000,
            expectedTDEE: 0
        )

        // Then: Should return false (can't calculate percentage)
        #expect(isAdapted == false)
    }

    // MARK: - Validation Tests

    @Test("validateBMRInputs throws for weight below 20kg")
    @MainActor
    func testValidateBMRInputsLowWeight() {
        let engine = TDEECalculationEngine()

        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateBMRInputs(weightKg: 15.0, heightCm: 170.0, age: 30)
        }
    }

    @Test("validateBMRInputs throws for weight above 500kg")
    @MainActor
    func testValidateBMRInputsHighWeight() {
        let engine = TDEECalculationEngine()

        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateBMRInputs(weightKg: 550.0, heightCm: 170.0, age: 30)
        }
    }

    @Test("validateBMRInputs throws for height below 100cm")
    @MainActor
    func testValidateBMRInputsLowHeight() {
        let engine = TDEECalculationEngine()

        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateBMRInputs(weightKg: 70.0, heightCm: 90.0, age: 30)
        }
    }

    @Test("validateBMRInputs throws for height above 250cm")
    @MainActor
    func testValidateBMRInputsHighHeight() {
        let engine = TDEECalculationEngine()

        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateBMRInputs(weightKg: 70.0, heightCm: 260.0, age: 30)
        }
    }

    @Test("validateBMRInputs throws for age below 10")
    @MainActor
    func testValidateBMRInputsLowAge() {
        let engine = TDEECalculationEngine()

        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateBMRInputs(weightKg: 70.0, heightCm: 170.0, age: 5)
        }
    }

    @Test("validateBMRInputs throws for age above 120")
    @MainActor
    func testValidateBMRInputsHighAge() {
        let engine = TDEECalculationEngine()

        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateBMRInputs(weightKg: 70.0, heightCm: 170.0, age: 130)
        }
    }

    @Test("validateBMRInputs succeeds for valid inputs")
    @MainActor
    func testValidateBMRInputsValid() throws {
        let engine = TDEECalculationEngine()

        // Should not throw for valid inputs
        try engine.validateBMRInputs(weightKg: 70.0, heightCm: 170.0, age: 30)
    }

    @Test("validateEWMAInputs throws for empty weights array")
    @MainActor
    func testValidateEWMAInputsEmptyWeights() {
        let engine = TDEECalculationEngine()

        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateEWMAInputs(weights: [], alpha: 0.2)
        }
    }

    @Test("validateEWMAInputs throws for alpha outside 0-1 range")
    @MainActor
    func testValidateEWMAInputsInvalidAlpha() {
        let engine = TDEECalculationEngine()
        let weights: [(date: Date, weightKg: Double)] = [(Date(), 70.0), (Date(), 71.0)]

        // Alpha = 0 should throw
        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateEWMAInputs(weights: weights, alpha: 0.0)
        }

        // Alpha = 1.5 should throw
        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateEWMAInputs(weights: weights, alpha: 1.5)
        }
    }

    @Test("validateEWMAInputs succeeds for valid inputs")
    @MainActor
    func testValidateEWMAInputsValid() throws {
        let engine = TDEECalculationEngine()
        let weights: [(date: Date, weightKg: Double)] = [(Date(), 70.0), (Date(), 71.0)]

        // Should not throw
        try engine.validateEWMAInputs(weights: weights, alpha: 0.2)
    }

    @Test("validateAdaptiveTDEEInputs throws for invalid duration")
    @MainActor
    func testValidateAdaptiveTDEEInputsInvalidDuration() {
        let engine = TDEECalculationEngine()

        // Zero duration
        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateAdaptiveTDEEInputs(averageDailyIntake: 2000.0, durationDays: 0)
        }

        // Negative duration
        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateAdaptiveTDEEInputs(averageDailyIntake: 2000.0, durationDays: -7)
        }
    }

    @Test("validateAdaptiveTDEEInputs throws for invalid intake")
    @MainActor
    func testValidateAdaptiveTDEEInputsInvalidIntake() {
        let engine = TDEECalculationEngine()

        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateAdaptiveTDEEInputs(averageDailyIntake: 0, durationDays: 14)
        }

        #expect(throws: TDEECalculationEngine.ValidationError.self) {
            try engine.validateAdaptiveTDEEInputs(averageDailyIntake: -500, durationDays: 14)
        }
    }

    @Test("validateAdaptiveTDEEInputs succeeds for valid inputs")
    @MainActor
    func testValidateAdaptiveTDEEInputsValid() throws {
        let engine = TDEECalculationEngine()

        // Should not throw
        try engine.validateAdaptiveTDEEInputs(averageDailyIntake: 2000.0, durationDays: 14)
    }

    @Test("ValidationError provides user-friendly error descriptions")
    @MainActor
    func testValidationErrorDescriptions() {
        // Test that each error type has a meaningful description
        let weightError = TDEECalculationEngine.ValidationError.invalidWeight(15.0)
        #expect(weightError.errorDescription?.contains("Weight") == true)
        #expect(weightError.errorDescription?.contains("20") == true)

        let heightError = TDEECalculationEngine.ValidationError.invalidHeight(90.0)
        #expect(heightError.errorDescription?.contains("Height") == true)
        #expect(heightError.errorDescription?.contains("100") == true)

        let ageError = TDEECalculationEngine.ValidationError.invalidAge(5)
        #expect(ageError.errorDescription?.contains("Age") == true)
        #expect(ageError.errorDescription?.contains("10") == true)

        let alphaError = TDEECalculationEngine.ValidationError.invalidAlpha(1.5)
        #expect(alphaError.errorDescription?.contains("Smoothing") == true)

        let durationError = TDEECalculationEngine.ValidationError.invalidDuration(0)
        #expect(durationError.errorDescription?.contains("Duration") == true)

        let intakeError = TDEECalculationEngine.ValidationError.invalidIntake(0)
        #expect(intakeError.errorDescription?.contains("intake") == true)

        let dataError = TDEECalculationEngine.ValidationError.insufficientData(required: 2, actual: 0)
        #expect(dataError.errorDescription?.contains("2") == true)
        #expect(dataError.errorDescription?.contains("0") == true)
    }

    @Test("isReasonableTDEE returns true for valid TDEE values")
    @MainActor
    func testIsReasonableTDEEValid() {
        let engine = TDEECalculationEngine()

        #expect(engine.isReasonableTDEE(1500) == true)
        #expect(engine.isReasonableTDEE(2500) == true)
        #expect(engine.isReasonableTDEE(3500) == true)
        #expect(engine.isReasonableTDEE(800) == true)  // Lower bound
        #expect(engine.isReasonableTDEE(6000) == true)  // Upper bound
    }

    @Test("isReasonableTDEE returns false for unreasonable TDEE values")
    @MainActor
    func testIsReasonableTDEEInvalid() {
        let engine = TDEECalculationEngine()

        #expect(engine.isReasonableTDEE(500) == false)  // Too low
        #expect(engine.isReasonableTDEE(799) == false)  // Just below minimum
        #expect(engine.isReasonableTDEE(6001) == false)  // Just above maximum
        #expect(engine.isReasonableTDEE(10000) == false)  // Way too high
    }
}
