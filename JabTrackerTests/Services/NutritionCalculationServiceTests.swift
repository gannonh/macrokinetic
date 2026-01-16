//
//  NutritionCalculationServiceTests.swift
//  JabTrackerTests
//
//  Unit tests for NutritionCalculationService - the centralized nutrition calculation service.
//

import Foundation
import Testing

@testable import JabTracker

@Suite("NutritionCalculationService Tests")
struct NutritionCalculationServiceTests {

    // MARK: - Weekly Pace Tests (THE BUG FIX)

    @Test("Weight loss goal returns negative pace")
    func testWeightLossPace() {
        let pace = NutritionCalculationService.weeklyPace(for: .weightLoss, weeklyRateKg: 0.5)
        #expect(pace == -0.5)
    }

    @Test("Maintenance goal returns zero pace regardless of input rate")
    func testMaintenancePace() {
        // This is the KEY test - maintenance should ALWAYS return 0, regardless of input
        let pace = NutritionCalculationService.weeklyPace(for: .maintenance, weeklyRateKg: 0.5)
        #expect(pace == 0.0)

        // Even with a large rate, maintenance should still be 0
        let paceWithLargeRate = NutritionCalculationService.weeklyPace(for: .maintenance, weeklyRateKg: 1.0)
        #expect(paceWithLargeRate == 0.0)
    }

    @Test("Muscle gain goal returns positive pace")
    func testMuscleGainPace() {
        let pace = NutritionCalculationService.weeklyPace(for: .muscleGain, weeklyRateKg: 0.5)
        #expect(pace == 0.5)
    }

    @Test("Weekly pace handles negative input by using absolute value")
    func testWeeklyPaceNormalizesInput() {
        // Even if caller passes negative, the sign is determined by goal type
        let lossWithNegative = NutritionCalculationService.weeklyPace(for: .weightLoss, weeklyRateKg: -0.5)
        #expect(lossWithNegative == -0.5)

        let gainWithNegative = NutritionCalculationService.weeklyPace(for: .muscleGain, weeklyRateKg: -0.5)
        #expect(gainWithNegative == 0.5)
    }

    // MARK: - Daily Calorie Adjustment Tests

    @Test("Daily calorie adjustment uses 1100 kcal per kg/week")
    func testDailyCalorieAdjustmentFactor() {
        // 1 kg/week = 7700 kcal/week = 1100 kcal/day
        let adjustment = NutritionCalculationService.dailyCalorieAdjustment(from: 1.0)
        #expect(adjustment == 1100.0)

        let halfKg = NutritionCalculationService.dailyCalorieAdjustment(from: 0.5)
        #expect(halfKg == 550.0)
    }

    @Test("Daily calorie adjustment preserves sign")
    func testDailyCalorieAdjustmentSign() {
        let deficit = NutritionCalculationService.dailyCalorieAdjustment(from: -0.5)
        #expect(deficit == -550.0)

        let surplus = NutritionCalculationService.dailyCalorieAdjustment(from: 0.5)
        #expect(surplus == 550.0)
    }

    // MARK: - Daily Calorie Target Tests

    @Test("Maintenance target equals TDEE")
    func testMaintenanceCalorieTarget() {
        let tdee = 2703.0
        let target = NutritionCalculationService.dailyCalorieTarget(
            tdee: tdee,
            goalType: .maintenance,
            weeklyRateKg: 0.5  // Should be ignored for maintenance
        )
        #expect(target == tdee)
    }

    @Test("Weight loss target is TDEE minus adjustment")
    func testWeightLossCalorieTarget() {
        let tdee = 2700.0
        let target = NutritionCalculationService.dailyCalorieTarget(
            tdee: tdee,
            goalType: .weightLoss,
            weeklyRateKg: 0.5
        )
        // 2700 - (0.5 * 1100) = 2700 - 550 = 2150
        #expect(target == 2150.0)
    }

    @Test("Muscle gain target is TDEE plus adjustment")
    func testMuscleGainCalorieTarget() {
        let tdee = 2700.0
        let target = NutritionCalculationService.dailyCalorieTarget(
            tdee: tdee,
            goalType: .muscleGain,
            weeklyRateKg: 0.5
        )
        // 2700 + (0.5 * 1100) = 2700 + 550 = 3250
        #expect(target == 3250.0)
    }

    @Test("Calorie target from weekly pace (already signed)")
    func testCalorieTargetFromPace() {
        let tdee = 2700.0

        // Negative pace (weight loss)
        let deficitTarget = NutritionCalculationService.dailyCalorieTarget(
            tdee: tdee,
            weeklyPaceKg: -0.5
        )
        #expect(deficitTarget == 2150.0)

        // Zero pace (maintenance)
        let maintenanceTarget = NutritionCalculationService.dailyCalorieTarget(
            tdee: tdee,
            weeklyPaceKg: 0.0
        )
        #expect(maintenanceTarget == tdee)

        // Positive pace (muscle gain)
        let surplusTarget = NutritionCalculationService.dailyCalorieTarget(
            tdee: tdee,
            weeklyPaceKg: 0.5
        )
        #expect(surplusTarget == 3250.0)
    }

    @Test("Calorie floor is enforced")
    func testCalorieFloorEnforced() {
        let target = NutritionCalculationService.dailyCalorieTarget(
            tdee: 1500.0,
            goalType: .weightLoss,
            weeklyRateKg: 1.0,  // Would be 1500 - 1100 = 400
            calorieFloor: 1200.0
        )
        #expect(target == 1200.0)
    }

    @Test("Target above floor is not clamped")
    func testTargetAboveFloorNotClamped() {
        let target = NutritionCalculationService.dailyCalorieTarget(
            tdee: 2700.0,
            goalType: .weightLoss,
            weeklyRateKg: 0.5,  // 2700 - 550 = 2150
            calorieFloor: 1200.0
        )
        #expect(target == 2150.0)
    }

    // MARK: - Macro Calculation Tests

    @Test("Protein calculation from weight and level")
    func testProteinCalculation() {
        let protein = NutritionCalculationService.proteinGrams(
            weightKg: 80.0,
            proteinLevel: .moderate  // 1.6 g/kg
        )
        #expect(protein == 128.0)
    }

    @Test("Protein calculation for different levels")
    func testProteinLevels() {
        let weight = 80.0

        let lowProtein = NutritionCalculationService.proteinGrams(
            weightKg: weight,
            proteinLevel: .low  // 1.2 g/kg
        )
        #expect(lowProtein == 96.0)

        let highProtein = NutritionCalculationService.proteinGrams(
            weightKg: weight,
            proteinLevel: .high  // 2.0 g/kg
        )
        #expect(highProtein == 160.0)
    }

    @Test("Macro distribution with carb/fat ratio")
    func testMacroDistribution() {
        let macros = NutritionCalculationService.macroDistribution(
            totalCalories: 2000.0,
            proteinGrams: 150.0,
            carbFatRatio: 0.5
        )

        // Protein: 150g * 4 = 600 cal
        // Remaining: 2000 - 600 = 1400 cal
        // Carbs: 1400 * 0.5 / 4 = 175g
        // Fat: 1400 * 0.5 / 9 = 77.78g
        #expect(macros.protein == 150.0)
        #expect(abs(macros.carbs - 175.0) < 0.1)
        #expect(abs(macros.fat - 77.78) < 0.1)
    }

    @Test("Macro distribution handles high carb ratio")
    func testHighCarbRatio() {
        let macros = NutritionCalculationService.macroDistribution(
            totalCalories: 2000.0,
            proteinGrams: 100.0,
            carbFatRatio: 0.7  // 70% carbs, 30% fat of remaining
        )

        // Protein: 100g * 4 = 400 cal
        // Remaining: 2000 - 400 = 1600 cal
        // Carbs: 1600 * 0.7 / 4 = 280g
        // Fat: 1600 * 0.3 / 9 = 53.33g
        #expect(abs(macros.carbs - 280.0) < 0.1)
        #expect(abs(macros.fat - 53.33) < 0.1)
    }

    // MARK: - Adaptive TDEE Tests

    @Test("Adaptive TDEE calculation")
    func testAdaptiveTDEE() {
        // If someone ate 2500 cal/day and lost 0.5kg over 7 days
        // TDEE = 2500 - ((-0.5) * 7700 / 7) = 2500 - (-550) = 2500 + 550 = 3050
        let tdee = NutritionCalculationService.adaptiveTDEE(
            averageDailyIntake: 2500.0,
            weightChangeKg: -0.5,
            days: 7
        )
        #expect(tdee == 3050.0)
    }

    @Test("Adaptive TDEE with weight gain")
    func testAdaptiveTDEEWithGain() {
        // If someone ate 3000 cal/day and gained 0.5kg over 7 days
        // TDEE = 3000 - ((0.5) * 7700 / 7) = 3000 - 550 = 2450
        let tdee = NutritionCalculationService.adaptiveTDEE(
            averageDailyIntake: 3000.0,
            weightChangeKg: 0.5,
            days: 7
        )
        #expect(tdee == 2450.0)
    }

    @Test("Adaptive TDEE rejects unreasonable values")
    func testAdaptiveTDEERejectsUnreasonable() {
        // Calculation would yield extremely low TDEE
        let lowTDEE = NutritionCalculationService.adaptiveTDEE(
            averageDailyIntake: 500.0,
            weightChangeKg: 0.0,
            days: 7
        )
        #expect(lowTDEE == nil)

        // Calculation would yield extremely high TDEE
        let highTDEE = NutritionCalculationService.adaptiveTDEE(
            averageDailyIntake: 7000.0,
            weightChangeKg: 0.0,
            days: 7
        )
        #expect(highTDEE == nil)
    }

    @Test("Adaptive TDEE rejects zero days")
    func testAdaptiveTDEERejectsZeroDays() {
        let tdee = NutritionCalculationService.adaptiveTDEE(
            averageDailyIntake: 2500.0,
            weightChangeKg: 0.0,
            days: 0
        )
        #expect(tdee == nil)
    }

    // MARK: - Display Helper Tests

    @Test("Daily calorie adjustment display is absolute value")
    func testDailyCalorieAdjustmentDisplay() {
        let deficitDisplay = NutritionCalculationService.dailyCalorieAdjustmentDisplay(weeklyPaceKg: -0.5)
        #expect(deficitDisplay == 550)

        let surplusDisplay = NutritionCalculationService.dailyCalorieAdjustmentDisplay(weeklyPaceKg: 0.5)
        #expect(surplusDisplay == 550)
    }

    @Test("Weekly pace display string for deficit")
    func testWeeklyPaceDisplayDeficit() {
        let display = NutritionCalculationService.weeklyPaceDisplayString(
            weeklyPaceKg: -0.5,
            usesMetric: true
        )
        #expect(display == "0.5 kg/week deficit")
    }

    @Test("Weekly pace display string for surplus")
    func testWeeklyPaceDisplaySurplus() {
        let display = NutritionCalculationService.weeklyPaceDisplayString(
            weeklyPaceKg: 0.5,
            usesMetric: true
        )
        #expect(display == "0.5 kg/week surplus")
    }

    @Test("Weekly pace display string for maintenance")
    func testWeeklyPaceDisplayMaintenance() {
        let display = NutritionCalculationService.weeklyPaceDisplayString(
            weeklyPaceKg: 0.0,
            usesMetric: true
        )
        #expect(display == "Maintenance")
    }

    @Test("Weekly pace display string in imperial")
    func testWeeklyPaceDisplayImperial() {
        let display = NutritionCalculationService.weeklyPaceDisplayString(
            weeklyPaceKg: -0.5,
            usesMetric: false
        )
        // 0.5 kg = 1.1 lbs
        #expect(display.contains("lbs/week deficit"))
    }

    // MARK: - Constants Tests

    @Test("Nutrition constants are correct")
    func testNutritionConstants() {
        #expect(NutritionConstants.caloriesPerKgBodyFat == 7700)
        #expect(NutritionConstants.dailyCaloriesPerKgWeeklyChange == 1100)
        #expect(abs(NutritionConstants.kgToLbs - 2.20462) < 0.0001)
    }
}
