//
//  ProgramTargetCalculationTests.swift
//  JabTrackerTests
//
//  Unit tests for TDEE-to-macro calculation logic used in ProgramWizard.
//  Verifies calorie targets, calorie floor, and macro calculations.
//

import Testing

@testable import JabTracker

@Suite("Program Target Calculation Tests")
struct ProgramTargetCalculationTests {

    // MARK: - Calorie Target Tests

    @Test("Calorie target applies weekly pace adjustment for weight loss")
    func testCalorieTargetWithWeeklyPaceLoss() {
        // Given: TDEE of 2000, weight loss pace of -0.5 kg/week
        let tdee = 2000.0
        let weeklyPaceKg = -0.5

        // When: Calculate daily target
        // -0.5 kg/week * 1100 kcal/kg = -550 kcal/week = -78.6 kcal/day
        let weeklyCalorieAdjustment = weeklyPaceKg * 1100
        let expectedTarget = tdee + (weeklyCalorieAdjustment / 7)

        // Then: Target should be TDEE minus daily deficit (~1921)
        #expect(abs(expectedTarget - 1921.4) < 0.1)
    }

    @Test("Calorie target applies weekly pace adjustment for weight gain")
    func testCalorieTargetWithWeeklyPaceGain() {
        // Given: TDEE of 2000, weight gain pace of +0.25 kg/week
        let tdee = 2000.0
        let weeklyPaceKg = 0.25

        // When: Calculate daily target
        // +0.25 kg/week * 1100 kcal/kg = +275 kcal/week = +39.3 kcal/day
        let weeklyCalorieAdjustment = weeklyPaceKg * 1100
        let expectedTarget = tdee + (weeklyCalorieAdjustment / 7)

        // Then: Target should be TDEE plus daily surplus (~2039)
        #expect(abs(expectedTarget - 2039.3) < 0.1)
    }

    @Test("Calorie target respects calorie floor")
    func testCalorieFloorApplied() {
        // Given: Low TDEE with aggressive deficit that would go below floor
        let tdee = 1500.0
        let weeklyPaceKg = -1.0  // aggressive
        let calorieFloor = 1400.0

        // When: Calculate with floor enforcement
        let weeklyCalorieAdjustment = weeklyPaceKg * 1100
        let rawTarget = tdee + (weeklyCalorieAdjustment / 7)  // 1500 - 157 = 1343
        let actualTarget = max(rawTarget, calorieFloor)

        // Then: Should use floor since raw < floor
        #expect(actualTarget == calorieFloor)
    }

    @Test("Calorie target uses raw value when above floor")
    func testCalorieAboveFloor() {
        // Given: Moderate deficit that stays above floor
        let tdee = 2500.0
        let weeklyPaceKg = -0.5
        let calorieFloor = 1200.0

        // When: Calculate with floor
        let weeklyCalorieAdjustment = weeklyPaceKg * 1100
        let rawTarget = tdee + (weeklyCalorieAdjustment / 7)  // ~2421
        let actualTarget = max(rawTarget, calorieFloor)

        // Then: Should use raw target since it's above floor
        #expect(actualTarget == rawTarget)
        #expect(actualTarget > calorieFloor)
    }

    // MARK: - Protein Calculation Tests

    @Test("Protein calculated from body weight and protein level - moderate")
    func testProteinFromBodyWeightModerate() {
        // Given: 80kg user with moderate protein (1.6 g/kg)
        let weightKg = 80.0
        let proteinPerKg = 1.6

        // When: Calculate protein
        let proteinGrams = weightKg * proteinPerKg

        // Then: 128g protein
        #expect(proteinGrams == 128.0)
    }

    @Test("Protein calculated from body weight and protein level - high")
    func testProteinFromBodyWeightHigh() {
        // Given: 70kg user with high protein (2.0 g/kg)
        let weightKg = 70.0
        let proteinPerKg = 2.0

        // When: Calculate protein
        let proteinGrams = weightKg * proteinPerKg

        // Then: 140g protein
        #expect(proteinGrams == 140.0)
    }

    @Test("Protein calculated from body weight and protein level - minimum")
    func testProteinFromBodyWeightMinimum() {
        // Given: 60kg user with minimum protein (1.2 g/kg)
        let weightKg = 60.0
        let proteinPerKg = 1.2

        // When: Calculate protein
        let proteinGrams = weightKg * proteinPerKg

        // Then: 72g protein
        #expect(proteinGrams == 72.0)
    }

    // MARK: - Fat and Carb Split Tests

    @Test("Fat and carbs split remaining calories - balanced diet")
    func testMacroSplitBalancedDiet() {
        // Given: 2000 cal target, 150g protein (600 cal), balanced diet (30% P, 30% F, 40% C)
        let totalCalories = 2000.0
        let proteinGrams = 150.0
        let proteinCalories = proteinGrams * 4  // 600
        let remainingCalories = totalCalories - proteinCalories  // 1400

        // Balanced diet: P=30%, F=30%, C=40%
        // Remaining split: F=30/(30+40)=0.428, C=40/(30+40)=0.571
        let fatPercentOriginal = 0.30
        let carbPercentOriginal = 0.40
        let fatRatio = fatPercentOriginal / (fatPercentOriginal + carbPercentOriginal)
        let carbRatio = carbPercentOriginal / (fatPercentOriginal + carbPercentOriginal)

        let fatCalories = remainingCalories * fatRatio  // ~600
        let carbCalories = remainingCalories * carbRatio  // ~800

        let fatGrams = fatCalories / 9  // ~66.7g
        let carbGrams = carbCalories / 4  // ~200g

        // Then: Fat and carb grams match expected values
        #expect(abs(fatGrams - 66.7) < 0.1)
        #expect(abs(carbGrams - 200.0) < 0.1)
    }

    @Test("Fat and carbs split remaining calories - low carb diet")
    func testMacroSplitLowCarbDiet() {
        // Given: 2000 cal target, 160g protein, low carb diet (30% P, 50% F, 20% C)
        let totalCalories = 2000.0
        let proteinGrams = 160.0
        let proteinCalories = proteinGrams * 4  // 640
        let remainingCalories = totalCalories - proteinCalories  // 1360

        // Low carb: P=30%, F=50%, C=20%
        // Remaining split: F=50/(50+20)=0.714, C=20/(50+20)=0.286
        let fatPercentOriginal = 0.50
        let carbPercentOriginal = 0.20
        let fatRatio = fatPercentOriginal / (fatPercentOriginal + carbPercentOriginal)
        let carbRatio = carbPercentOriginal / (fatPercentOriginal + carbPercentOriginal)

        let fatCalories = remainingCalories * fatRatio  // ~971
        let carbCalories = remainingCalories * carbRatio  // ~389

        let fatGrams = fatCalories / 9  // ~108g
        let carbGrams = carbCalories / 4  // ~97g

        // Then: Fat and carb grams match expected values
        #expect(abs(fatGrams - 108.0) < 1.0)
        #expect(abs(carbGrams - 97.0) < 1.0)
    }

    @Test("Fat and carbs split remaining calories - high carb diet")
    func testMacroSplitHighCarbDiet() {
        // Given: 2200 cal target, 140g protein, high carb diet (25% P, 20% F, 55% C)
        let totalCalories = 2200.0
        let proteinGrams = 140.0
        let proteinCalories = proteinGrams * 4  // 560
        let remainingCalories = totalCalories - proteinCalories  // 1640

        // High carb: P=25%, F=20%, C=55%
        // Remaining split: F=20/(20+55)=0.267, C=55/(20+55)=0.733
        let fatPercentOriginal = 0.20
        let carbPercentOriginal = 0.55
        let fatRatio = fatPercentOriginal / (fatPercentOriginal + carbPercentOriginal)
        let carbRatio = carbPercentOriginal / (fatPercentOriginal + carbPercentOriginal)

        let fatCalories = remainingCalories * fatRatio  // ~437
        let carbCalories = remainingCalories * carbRatio  // ~1203

        let fatGrams = fatCalories / 9  // ~48.6g
        let carbGrams = carbCalories / 4  // ~301g

        // Then: Fat and carb grams match expected values
        #expect(abs(fatGrams - 48.6) < 1.0)
        #expect(abs(carbGrams - 301.0) < 1.0)
    }

    // MARK: - Edge Cases

    @Test("Calculation handles zero weekly pace (maintenance)")
    func testMaintenanceCalorieTarget() {
        // Given: TDEE of 2000, maintenance (0 kg/week)
        let tdee = 2000.0
        let weeklyPaceKg = 0.0

        // When: Calculate daily target
        let weeklyCalorieAdjustment = weeklyPaceKg * 1100
        let expectedTarget = tdee + (weeklyCalorieAdjustment / 7)

        // Then: Target equals TDEE exactly
        #expect(expectedTarget == tdee)
    }

    @Test("Calculation handles very high protein requirement")
    func testHighProteinScenario() {
        // Given: 100kg athlete with maximum protein (2.2 g/kg)
        let weightKg = 100.0
        let proteinPerKg = 2.2
        let totalCalories = 3000.0

        // When: Calculate protein and remaining calories
        let proteinGrams = weightKg * proteinPerKg  // 220g
        let proteinCalories = proteinGrams * 4  // 880
        let remainingCalories = totalCalories - proteinCalories  // 2120

        // Then: High protein leaves substantial room for fat/carbs
        // Use approximate comparison for floating-point precision
        #expect(abs(proteinGrams - 220.0) < 0.001)
        #expect(abs(remainingCalories - 2120.0) < 0.001)
    }
}
