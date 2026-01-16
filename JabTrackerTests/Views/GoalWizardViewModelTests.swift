//
//  GoalWizardViewModelTests.swift
//  JabTrackerTests
//
//  Tests for GoalWizardViewModel - verifies goal wizard correctly uses
//  NutritionCalculationService for weekly pace calculations.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - Test Utilities

@MainActor
private func createTestContainer() throws -> ModelContainer {
    let schema = Schema([
        User.self,
        NutritionGoal.self,
        NutritionProgram.self,
        Dose.self,
        MedicationProfile.self,
        DoseTitration.self,
        DoseSchedule.self,
        ScheduledDose.self,
        Food.self,
        FoodEntry.self,
        WeightEntry.self,
        MetricsEntry.self,
        ProgressPhoto.self,
    ])
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(for: schema, configurations: [config])
}

@MainActor
private func createTestUser(in context: ModelContext) -> User {
    let user = User(
        email: "test@example.com",
        name: "Test User",
        appleUserId: "test-apple-id",
        hasCompletedOnboarding: false
    )
    context.insert(user)
    try? context.save()
    return user
}

// MARK: - GoalWizardViewModel Tests

@Suite("GoalWizardViewModel Tests")
struct GoalWizardViewModelTests {

    @Test("Initial state has no goal type selected")
    @MainActor
    func testInitialState() {
        let viewModel = GoalWizardViewModel()

        #expect(viewModel.goalType == nil)
        #expect(viewModel.currentStep == .goalType)
        #expect(viewModel.weeklyRateKg == 0.5)
    }

    @Test("configureForEdit sets correct state from existing goal")
    @MainActor
    func testConfigureForEdit() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let user = createTestUser(in: context)

        // Create an existing goal
        let existingGoal = NutritionGoal(
            goalType: .weightLoss,
            startingWeightKg: 80.0,
            targetWeightKg: 70.0,
            weeklyWeightChangePaceKg: -0.5
        )
        existingGoal.user = user
        context.insert(existingGoal)
        try context.save()

        let viewModel = GoalWizardViewModel()
        viewModel.configureForEdit(goal: existingGoal, usesMetric: true)

        #expect(viewModel.isEditMode == true)
        #expect(viewModel.goalType == .weightLoss)
        #expect(viewModel.targetWeightKg == 70.0)
        #expect(viewModel.currentWeightKg == 80.0)
        #expect(viewModel.weeklyRateKg == 0.5)  // Absolute value
    }
}

// MARK: - GoalWizardViewModel Save Tests (Weekly Pace Verification)

@Suite("GoalWizardViewModel Save Tests")
struct GoalWizardViewModelSaveTests {

    @Test("Save sets correct pace for weight loss goal")
    @MainActor
    func testSaveWeightLossPace() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let user = createTestUser(in: context)

        let viewModel = GoalWizardViewModel()
        viewModel.goalType = .weightLoss
        viewModel.currentWeightKg = 80.0
        viewModel.targetWeightKg = 70.0
        viewModel.weeklyRateKg = 0.5

        let goal = try viewModel.save(context: context, user: user)

        #expect(goal.weeklyWeightChangePaceKg == -0.5, "Weight loss should have negative pace")
    }

    @Test("Save sets zero pace for maintenance goal")
    @MainActor
    func testSaveMaintenancePace() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let user = createTestUser(in: context)

        let viewModel = GoalWizardViewModel()
        viewModel.goalType = .maintenance
        viewModel.currentWeightKg = 80.0
        viewModel.targetWeightKg = 80.0
        viewModel.weeklyRateKg = 0.5  // This should be IGNORED for maintenance

        let goal = try viewModel.save(context: context, user: user)

        // THIS IS THE KEY TEST - maintenance must be 0, not +0.5
        #expect(
            goal.weeklyWeightChangePaceKg == 0.0,
            "Maintenance should have zero pace, not \(goal.weeklyWeightChangePaceKg)")
    }

    @Test("Save sets correct pace for muscle gain goal")
    @MainActor
    func testSaveMuscleGainPace() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let user = createTestUser(in: context)

        let viewModel = GoalWizardViewModel()
        viewModel.goalType = .muscleGain
        viewModel.currentWeightKg = 70.0
        viewModel.targetWeightKg = 75.0
        viewModel.weeklyRateKg = 0.5

        let goal = try viewModel.save(context: context, user: user)

        #expect(goal.weeklyWeightChangePaceKg == 0.5, "Muscle gain should have positive pace")
    }

    @Test("Save sets correct pace for all goal types")
    @MainActor
    func testSaveAllGoalTypePaces() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let user = createTestUser(in: context)

        // Test cases: goalType -> (weeklyRateKg, expectedPace)
        let testCases: [GoalType: (rate: Double, expected: Double)] = [
            .weightLoss: (0.5, -0.5),
            .maintenance: (0.5, 0.0),
            .muscleGain: (0.5, 0.5),
        ]

        for (goalType, params) in testCases {
            let viewModel = GoalWizardViewModel()
            viewModel.goalType = goalType
            viewModel.currentWeightKg = 80.0
            viewModel.targetWeightKg = goalType == .weightLoss ? 70.0 : (goalType == .muscleGain ? 85.0 : 80.0)
            viewModel.weeklyRateKg = params.rate

            let goal = try viewModel.save(context: context, user: user)

            #expect(
                goal.weeklyWeightChangePaceKg == params.expected,
                "\(goalType) with rate \(params.rate) should have pace \(params.expected)"
            )
        }
    }

    @Test("Edit mode save updates pace correctly for maintenance")
    @MainActor
    func testEditModeSaveMaintenancePace() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let user = createTestUser(in: context)

        // Create existing weight loss goal
        let existingGoal = NutritionGoal(
            goalType: .weightLoss,
            startingWeightKg: 80.0,
            targetWeightKg: 70.0,
            weeklyWeightChangePaceKg: -0.5
        )
        existingGoal.user = user
        context.insert(existingGoal)
        try context.save()

        // Configure for edit and change to maintenance
        let viewModel = GoalWizardViewModel()
        viewModel.configureForEdit(goal: existingGoal, usesMetric: true)
        viewModel.goalType = .maintenance  // Change goal type
        viewModel.targetWeightKg = 80.0

        let updatedGoal = try viewModel.save(context: context, user: user)

        #expect(updatedGoal.weeklyWeightChangePaceKg == 0.0, "Updated maintenance goal should have zero pace")
    }

    @Test("Save without goal type throws error")
    @MainActor
    func testSaveWithoutGoalTypeThrows() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let user = createTestUser(in: context)

        let viewModel = GoalWizardViewModel()
        // Don't set goalType

        #expect(throws: GoalWizardError.self) {
            _ = try viewModel.save(context: context, user: user)
        }
    }

    @Test("Save deactivates existing active goals")
    @MainActor
    func testSaveDeactivatesExistingGoals() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let user = createTestUser(in: context)

        // Create an existing active goal
        let existingGoal = NutritionGoal(
            goalType: .weightLoss,
            startingWeightKg: 80.0,
            targetWeightKg: 70.0,
            weeklyWeightChangePaceKg: -0.5
        )
        existingGoal.user = user
        existingGoal.isActive = true
        context.insert(existingGoal)
        try context.save()

        #expect(existingGoal.isActive == true)

        // Create new goal
        let viewModel = GoalWizardViewModel()
        viewModel.goalType = .maintenance
        viewModel.currentWeightKg = 75.0
        viewModel.targetWeightKg = 75.0

        let newGoal = try viewModel.save(context: context, user: user)

        // Old goal should be deactivated
        #expect(existingGoal.isActive == false, "Existing goal should be deactivated")
        #expect(newGoal.isActive == true, "New goal should be active")
    }
}
