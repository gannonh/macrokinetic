//
//  OnboardingMaintenanceGoalTests.swift
//  JabTrackerTests
//
//  Integration tests verifying OnboardingViewModel correctly uses
//  NutritionCalculationService for maintenance goal pace calculations.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - NutritionCalculationService Integration Tests

@Suite("OnboardingViewModel Maintenance Goal Pace Tests")
struct MaintenanceGoalPaceIntegrationTests {

    @Test("Maintenance goal estimate uses zero weekly pace")
    @MainActor
    func testMaintenanceGoalEstimateUsesZeroPace() {
        // Given: A ViewModel configured for maintenance goal
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        viewModel.calculatedCalories = 0
        viewModel.goalViewModel.goalType = .maintenance
        viewModel.goalViewModel.currentWeightKg = 80
        viewModel.goalViewModel.weeklyRateKg = 0.5  // This should be IGNORED for maintenance
        viewModel.editHeightFeet = 5
        viewModel.editHeightInches = 10
        viewModel.editSex = "Male"
        viewModel.editBirthday = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        viewModel.trainingLevel = .cardio
        viewModel.proteinLevel = .moderate

        // When: Initializing collaborative days (triggers calorie estimation)
        viewModel.initializeCollaborativeDays()

        // Then: Calculate what TDEE should be without adjustment
        // BMR = (10 × 80) + (6.25 × 177.8) - (5 × 30) + 5 = 800 + 1111.25 - 150 + 5 = 1766.25
        // TDEE = BMR × 1.55 (cardio multiplier) ≈ 2738
        // For maintenance, daily target should equal TDEE (no adjustment)
        let calories = viewModel.collaborativeDays[1]?.calories ?? 0

        // The key test: maintenance should NOT add 550 kcal surplus
        // If the bug was present, calories would be ~3288 (TDEE + 550)
        // Correct behavior: calories should be ~2738 (TDEE only)
        #expect(calories < 3000, "Maintenance calories should not include surplus - was \(calories)")
        #expect(calories >= 2500, "Maintenance calories should be at TDEE level - was \(calories)")
    }

    @Test("Weight loss goal correctly applies negative pace")
    @MainActor
    func testWeightLossGoalAppliesNegativePace() {
        // Given: A ViewModel configured for weight loss
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        viewModel.calculatedCalories = 0
        viewModel.goalViewModel.goalType = .weightLoss
        viewModel.goalViewModel.currentWeightKg = 80
        viewModel.goalViewModel.weeklyRateKg = 0.5  // 0.5 kg/week = 550 kcal/day deficit
        viewModel.editHeightFeet = 5
        viewModel.editHeightInches = 10
        viewModel.editSex = "Male"
        viewModel.editBirthday = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        viewModel.trainingLevel = .cardio
        viewModel.proteinLevel = .moderate

        viewModel.initializeCollaborativeDays()

        let calories = viewModel.collaborativeDays[1]?.calories ?? 0

        // Weight loss: TDEE (~2738) - 550 = ~2188
        #expect(calories < 2500, "Weight loss should be below TDEE - was \(calories)")
        #expect(calories >= 1800, "Weight loss should be reasonable - was \(calories)")
    }

    @Test("Muscle gain goal correctly applies positive pace")
    @MainActor
    func testMuscleGainGoalAppliesPositivePace() {
        // Given: A ViewModel configured for muscle gain
        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)
        let viewModel = OnboardingViewModel(dataController: dataController, authManager: authManager)

        viewModel.calculatedCalories = 0
        viewModel.goalViewModel.goalType = .muscleGain
        viewModel.goalViewModel.currentWeightKg = 80
        viewModel.goalViewModel.weeklyRateKg = 0.5  // 0.5 kg/week = 550 kcal/day surplus
        viewModel.editHeightFeet = 5
        viewModel.editHeightInches = 10
        viewModel.editSex = "Male"
        viewModel.editBirthday = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        viewModel.trainingLevel = .lifting
        viewModel.proteinLevel = .high

        viewModel.initializeCollaborativeDays()

        let calories = viewModel.collaborativeDays[1]?.calories ?? 0

        // Muscle gain: TDEE (~2875 with lifting) + 550 = ~3425
        #expect(calories > 3000, "Muscle gain should include surplus - was \(calories)")
    }

    @Test("Goal type comparison shows maintenance is not weight gain")
    @MainActor
    func testMaintenanceVsMuscleGainComparison() {
        // This test demonstrates the fix for the maintenance bug
        // Before fix: maintenance was treated as muscle gain
        // After fix: maintenance uses 0 pace

        let dataController = DataController(inMemory: true)
        let authManager = AuthenticationManager(dataController: dataController)

        // Create maintenance ViewModel
        let maintenanceVM = OnboardingViewModel(dataController: dataController, authManager: authManager)
        maintenanceVM.calculatedCalories = 0
        maintenanceVM.goalViewModel.goalType = .maintenance
        maintenanceVM.goalViewModel.currentWeightKg = 80
        maintenanceVM.goalViewModel.weeklyRateKg = 0.5
        maintenanceVM.editHeightFeet = 5
        maintenanceVM.editHeightInches = 10
        maintenanceVM.editSex = "Male"
        maintenanceVM.editBirthday = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        maintenanceVM.trainingLevel = .cardio
        maintenanceVM.proteinLevel = .moderate
        maintenanceVM.initializeCollaborativeDays()

        // Create muscle gain ViewModel with same settings
        let muscleGainVM = OnboardingViewModel(dataController: dataController, authManager: authManager)
        muscleGainVM.calculatedCalories = 0
        muscleGainVM.goalViewModel.goalType = .muscleGain
        muscleGainVM.goalViewModel.currentWeightKg = 80
        muscleGainVM.goalViewModel.weeklyRateKg = 0.5
        muscleGainVM.editHeightFeet = 5
        muscleGainVM.editHeightInches = 10
        muscleGainVM.editSex = "Male"
        muscleGainVM.editBirthday = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
        muscleGainVM.trainingLevel = .cardio
        muscleGainVM.proteinLevel = .moderate
        muscleGainVM.initializeCollaborativeDays()

        let maintenanceCalories = maintenanceVM.collaborativeDays[1]?.calories ?? 0
        let muscleGainCalories = muscleGainVM.collaborativeDays[1]?.calories ?? 0

        // Key assertion: maintenance should be ~550 kcal LESS than muscle gain
        let caloriesDifference = muscleGainCalories - maintenanceCalories
        #expect(
            caloriesDifference > 400,
            "Maintenance (\(Int(maintenanceCalories))) should be significantly lower than muscle gain (\(Int(muscleGainCalories)))"
        )
    }
}
