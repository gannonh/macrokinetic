//
//  NutritionGoalTests.swift
//  JabTrackerTests
//
//  Tests for NutritionGoal SwiftData model
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - Test Utilities

/// Creates an in-memory SwiftData context for testing
/// Returns both context and container - container must be kept alive for context to remain valid
@MainActor
private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
    let schema = Schema([
        User.self,
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
        NutritionGoal.self,
        NutritionProgram.self,
    ])
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    let container = try! ModelContainer(for: schema, configurations: [config])
    return (container.mainContext, container)
}

// MARK: - NutritionGoalTests

@Suite("NutritionGoal Tests")
struct NutritionGoalTests {

    // MARK: - Initialization Tests

    @Test("Default initialization creates valid goal with expected defaults")
    @MainActor
    func testDefaultInitialization() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container  // Keep alive

        // When
        let goal = NutritionGoal()
        context.insert(goal)
        try context.save()

        // Then
        // ID is auto-generated - verify goal was saved and can be queried
        let saved = try context.fetch(FetchDescriptor<NutritionGoal>()).first
        #expect(saved?.id == goal.id)
        #expect(goal.goalTypeRaw == "weight_loss")
        #expect(goal.isActive == true)
        #expect(goal.startingWeightKg == 70.0)
        #expect(goal.targetWeightKg == 70.0)
        #expect(goal.weeklyWeightChangePaceKg == -0.5)
        #expect(goal.dailyCalorieTarget == 2000.0)
        #expect(goal.dailyProteinTargetGrams == 150.0)
        #expect(goal.dailyCarbTargetGrams == 200.0)
        #expect(goal.dailyFatTargetGrams == 65.0)
        #expect(goal.createdAt <= Date())
        #expect(goal.updatedAt <= Date())
    }

    @Test("Initialization with custom values")
    @MainActor
    func testCustomInitialization() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let targetDate = Date().addingTimeInterval(86400 * 90)  // 90 days

        // When
        let goal = NutritionGoal(
            goalType: .muscleGain,
            startingWeightKg: 75.0,
            targetWeightKg: 80.0,
            targetDate: targetDate,
            weeklyWeightChangePaceKg: 0.25,
            dailyCalorieTarget: 2800.0,
            dailyProteinTargetGrams: 180.0,
            dailyCarbTargetGrams: 350.0,
            dailyFatTargetGrams: 80.0
        )
        context.insert(goal)
        try context.save()

        // Then
        #expect(goal.goalType == .muscleGain)
        #expect(goal.startingWeightKg == 75.0)
        #expect(goal.targetWeightKg == 80.0)
        #expect(goal.weeklyWeightChangePaceKg == 0.25)
        #expect(goal.dailyCalorieTarget == 2800.0)
        #expect(goal.dailyProteinTargetGrams == 180.0)
        #expect(goal.dailyCarbTargetGrams == 350.0)
        #expect(goal.dailyFatTargetGrams == 80.0)
    }

    // MARK: - Goal Type Accessor Tests

    @Test("Goal type accessor converts to/from GoalType enum")
    @MainActor
    func testGoalTypeAccessor() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When - default is weight_loss
        let goal = NutritionGoal()
        context.insert(goal)

        // Then
        #expect(goal.goalType == .weightLoss)

        // When - change via setter
        goal.goalType = .maintenance
        #expect(goal.goalTypeRaw == "maintenance")
        #expect(goal.goalType == .maintenance)

        // When - change to muscle gain
        goal.goalType = .muscleGain
        #expect(goal.goalTypeRaw == "muscle_gain")
        #expect(goal.goalType == .muscleGain)
    }

    @Test("Goal type with invalid raw value defaults to weightLoss")
    @MainActor
    func testGoalTypeInvalidRawValue() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let goal = NutritionGoal()
        goal.goalTypeRaw = "invalid_type"
        context.insert(goal)

        // Then - should default to weightLoss when raw is invalid
        #expect(goal.goalType == .weightLoss)
    }

    // MARK: - Weight Change Calculation Tests

    @Test("totalWeightChangeKg calculates target - starting for loss")
    @MainActor
    func testTotalWeightChangeKgLoss() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 100.0
        goal.targetWeightKg = 85.0
        context.insert(goal)

        // Then - negative for weight loss
        #expect(goal.totalWeightChangeKg == -15.0)
    }

    @Test("totalWeightChangeKg calculates target - starting for gain")
    @MainActor
    func testTotalWeightChangeKgGain() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 70.0
        goal.targetWeightKg = 80.0
        context.insert(goal)

        // Then - positive for weight gain
        #expect(goal.totalWeightChangeKg == 10.0)
    }

    @Test("totalWeightChangeKg is zero for maintenance")
    @MainActor
    func testTotalWeightChangeKgMaintenance() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 75.0
        goal.targetWeightKg = 75.0
        context.insert(goal)

        // Then
        #expect(goal.totalWeightChangeKg == 0.0)
    }

    // MARK: - Estimated Weeks Tests

    @Test("estimatedWeeksToGoal calculates correctly for loss")
    @MainActor
    func testEstimatedWeeksToGoalLoss() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 100.0
        goal.targetWeightKg = 90.0  // 10kg to lose
        goal.weeklyWeightChangePaceKg = -0.5  // 0.5kg per week
        context.insert(goal)

        // Then - 10kg / 0.5kg per week = 20 weeks
        #expect(goal.estimatedWeeksToGoal == 20.0)
    }

    @Test("estimatedWeeksToGoal calculates correctly for gain")
    @MainActor
    func testEstimatedWeeksToGoalGain() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 70.0
        goal.targetWeightKg = 75.0  // 5kg to gain
        goal.weeklyWeightChangePaceKg = 0.25  // 0.25kg per week
        context.insert(goal)

        // Then - 5kg / 0.25kg per week = 20 weeks
        #expect(goal.estimatedWeeksToGoal == 20.0)
    }

    @Test("estimatedWeeksToGoal is zero for maintenance")
    @MainActor
    func testEstimatedWeeksToGoalMaintenance() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 75.0
        goal.targetWeightKg = 75.0
        goal.weeklyWeightChangePaceKg = 0.0
        context.insert(goal)

        // Then
        #expect(goal.estimatedWeeksToGoal == 0.0)
    }

    // MARK: - Progress Percentage Tests

    @Test("progressPercentage returns 0-1 range for weight loss")
    @MainActor
    func testProgressPercentageLoss() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 100.0
        goal.targetWeightKg = 80.0  // 20kg goal
        context.insert(goal)

        // When - at starting weight
        var progress = goal.progressPercentage(currentWeightKg: 100.0)
        #expect(progress == 0.0)

        // When - halfway there (lost 10kg)
        progress = goal.progressPercentage(currentWeightKg: 90.0)
        #expect(progress == 0.5)

        // When - at target
        progress = goal.progressPercentage(currentWeightKg: 80.0)
        #expect(progress == 1.0)

        // When - past target (lost extra)
        progress = goal.progressPercentage(currentWeightKg: 75.0)
        #expect(progress > 1.0)
    }

    @Test("progressPercentage returns 0-1 range for weight gain")
    @MainActor
    func testProgressPercentageGain() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 70.0
        goal.targetWeightKg = 80.0  // 10kg goal
        context.insert(goal)

        // When - at starting weight
        var progress = goal.progressPercentage(currentWeightKg: 70.0)
        #expect(progress == 0.0)

        // When - halfway there (gained 5kg)
        progress = goal.progressPercentage(currentWeightKg: 75.0)
        #expect(progress == 0.5)

        // When - at target
        progress = goal.progressPercentage(currentWeightKg: 80.0)
        #expect(progress == 1.0)
    }

    @Test("progressPercentage returns 0 for maintenance goal")
    @MainActor
    func testProgressPercentageMaintenance() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 75.0
        goal.targetWeightKg = 75.0
        context.insert(goal)

        // When - at target (maintenance)
        let progress = goal.progressPercentage(currentWeightKg: 75.0)

        // Then - 0 because no change needed
        #expect(progress == 0.0)
    }

    // MARK: - isOnTrack Tests

    @Test("isOnTrack returns true when targetDate is in future")
    @MainActor
    func testIsOnTrackFuture() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.targetDate = Date().addingTimeInterval(86400 * 30)  // 30 days from now
        context.insert(goal)

        // Then
        #expect(goal.isOnTrack == true)
    }

    @Test("isOnTrack returns false when targetDate is in past")
    @MainActor
    func testIsOnTrackPast() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.targetDate = Date().addingTimeInterval(-86400)  // Yesterday
        context.insert(goal)

        // Then
        #expect(goal.isOnTrack == false)
    }

    // MARK: - Weight Change Display Tests

    @Test("weightChangeDisplay shows loss correctly")
    @MainActor
    func testWeightChangeDisplayLoss() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 100.0
        goal.targetWeightKg = 85.0
        context.insert(goal)

        // Then - should show negative (loss)
        #expect(goal.weightChangeDisplay == "-15.0 kg")
    }

    @Test("weightChangeDisplay shows gain correctly")
    @MainActor
    func testWeightChangeDisplayGain() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 70.0
        goal.targetWeightKg = 80.0
        context.insert(goal)

        // Then - should show positive (gain)
        #expect(goal.weightChangeDisplay == "+10.0 kg")
    }

    @Test("weightChangeDisplay shows maintenance correctly")
    @MainActor
    func testWeightChangeDisplayMaintenance() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 75.0
        goal.targetWeightKg = 75.0
        context.insert(goal)

        // Then
        #expect(goal.weightChangeDisplay == "0.0 kg")
    }

    // MARK: - User Relationship Tests

    @Test("Goal can be associated with User")
    @MainActor
    func testUserRelationship() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let user = User(email: "test@example.com", name: "Test User")
        context.insert(user)

        let goal = NutritionGoal()
        context.insert(goal)

        // When
        goal.user = user

        try context.save()

        // Then
        #expect(goal.user != nil)
        #expect(goal.user?.email == "test@example.com")
    }

    // MARK: - TDEE Fields Tests

    @Test("TDEE fields are optional and nil by default")
    @MainActor
    func testTDEEFieldsOptional() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        // When
        let goal = NutritionGoal()
        context.insert(goal)

        // Then
        #expect(goal.lastCalculatedTDEE == nil)
        #expect(goal.lastTDEECalculationDate == nil)
        #expect(goal.initialEstimatedTDEE == nil)
    }

    @Test("TDEE fields can be set")
    @MainActor
    func testTDEEFieldsSettable() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        let calculationDate = Date()

        // When
        goal.initialEstimatedTDEE = 2200.0
        goal.lastCalculatedTDEE = 2150.0
        goal.lastTDEECalculationDate = calculationDate
        context.insert(goal)
        try context.save()

        // Then
        #expect(goal.initialEstimatedTDEE == 2200.0)
        #expect(goal.lastCalculatedTDEE == 2150.0)
        #expect(goal.lastTDEECalculationDate == calculationDate)
    }

    // MARK: - Projected End Date Tests

    @Test("projectedEndDate calculates correctly for weight loss")
    @MainActor
    func testProjectedEndDateLoss() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 100.0
        goal.targetWeightKg = 90.0  // 10kg to lose
        goal.weeklyWeightChangePaceKg = -0.5  // 0.5kg per week = 20 weeks
        context.insert(goal)

        // Then - should be approximately 20 weeks from creation
        let expectedWeeks = 20.0
        let expectedSeconds = expectedWeeks * 7 * 24 * 60 * 60

        #expect(goal.projectedEndDate != nil)
        if let projectedDate = goal.projectedEndDate {
            let diff = projectedDate.timeIntervalSince(goal.createdAt)
            #expect(abs(diff - expectedSeconds) < 60)  // Within 1 minute tolerance
        }
    }

    @Test("projectedEndDate returns nil for maintenance")
    @MainActor
    func testProjectedEndDateMaintenance() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.startingWeightKg = 75.0
        goal.targetWeightKg = 75.0  // No change
        goal.weeklyWeightChangePaceKg = 0.0
        context.insert(goal)

        // Then - should return nil for maintenance
        #expect(goal.projectedEndDate == nil)
    }

    // MARK: - Initial Daily Budget Tests

    @Test("initialDailyBudget calculates correctly for weight loss")
    @MainActor
    func testInitialDailyBudgetLoss() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.initialEstimatedTDEE = 2200.0
        goal.weeklyWeightChangePaceKg = -0.5  // 0.5kg/week loss
        context.insert(goal)

        // Then - should be TDEE minus daily deficit
        // Daily adjustment = -0.5 × 1100 = -550
        // Budget = 2200 - 550 = 1650
        #expect(goal.initialDailyBudget == 1650)
    }

    @Test("initialDailyBudget calculates correctly for weight gain")
    @MainActor
    func testInitialDailyBudgetGain() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        goal.initialEstimatedTDEE = 2200.0
        goal.weeklyWeightChangePaceKg = 0.25  // 0.25kg/week gain
        context.insert(goal)

        // Then - should be TDEE plus daily surplus
        // Daily adjustment = 0.25 × 1100 = 275
        // Budget = 2200 + 275 = 2475
        #expect(goal.initialDailyBudget == 2475)
    }

    @Test("initialDailyBudget returns nil without TDEE")
    @MainActor
    func testInitialDailyBudgetNoTDEE() throws {
        // Given
        let (context, container) = createTestContext()
        _ = container

        let goal = NutritionGoal()
        // No TDEE values set
        context.insert(goal)

        // Then - should return nil
        #expect(goal.initialDailyBudget == nil)
    }
}
