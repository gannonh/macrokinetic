//
//  GoalProgramServiceTests.swift
//  JabTrackerTests
//
//  Unit tests for GoalProgramService smart defaults and entity creation.
//

import SwiftData
import Testing

@testable import JabTracker

@Suite("GoalProgramService Tests")
struct GoalProgramServiceTests {
    // MARK: - Test Setup

    /// Creates an in-memory SwiftData context for testing
    /// Returns both context and container (container must stay alive)
    @MainActor
    private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([User.self, NutritionGoal.self, NutritionProgram.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        return (container.mainContext, container)
    }

    /// Creates a test user in the given context
    @MainActor
    private func createTestUser(in context: ModelContext) -> User {
        let user = User(
            email: "test@example.com",
            name: "Test User",
            appleUserId: "test-apple-id"
        )
        context.insert(user)
        return user
    }

    // MARK: - Weight Loss Smart Defaults Tests

    @Test("Weight loss defaults: target weight is starting - 10kg")
    @MainActor
    func testWeightLossTargetWeight() async {
        // Given
        let service = GoalProgramService()
        let startingWeight = 80.0

        // When
        let defaults = service.calculateDefaults(for: .weightLoss, startingWeight: startingWeight)

        // Then
        #expect(defaults.targetWeight == 70.0, "Target should be 10kg less than starting")
    }

    @Test("Weight loss defaults: weekly rate is -0.5 kg/week")
    @MainActor
    func testWeightLossWeeklyRate() async {
        // Given
        let service = GoalProgramService()

        // When
        let defaults = service.calculateDefaults(for: .weightLoss, startingWeight: 80.0)

        // Then
        #expect(defaults.weeklyRate == -0.5, "Weekly rate should be -0.5 kg/week")
    }

    // MARK: - Maintenance Smart Defaults Tests

    @Test("Maintenance defaults: target weight equals starting weight")
    @MainActor
    func testMaintenanceTargetWeight() async {
        // Given
        let service = GoalProgramService()
        let startingWeight = 75.0

        // When
        let defaults = service.calculateDefaults(for: .maintenance, startingWeight: startingWeight)

        // Then
        #expect(defaults.targetWeight == 75.0, "Target should equal starting weight")
    }

    @Test("Maintenance defaults: weekly rate is 0")
    @MainActor
    func testMaintenanceWeeklyRate() async {
        // Given
        let service = GoalProgramService()

        // When
        let defaults = service.calculateDefaults(for: .maintenance, startingWeight: 75.0)

        // Then
        #expect(defaults.weeklyRate == 0, "Weekly rate should be 0 for maintenance")
    }

    // MARK: - Muscle Gain Smart Defaults Tests

    @Test("Muscle gain defaults: target weight is starting + 5kg")
    @MainActor
    func testMuscleGainTargetWeight() async {
        // Given
        let service = GoalProgramService()
        let startingWeight = 70.0

        // When
        let defaults = service.calculateDefaults(for: .muscleGain, startingWeight: startingWeight)

        // Then
        #expect(defaults.targetWeight == 75.0, "Target should be 5kg more than starting")
    }

    @Test("Muscle gain defaults: weekly rate is +0.25 kg/week")
    @MainActor
    func testMuscleGainWeeklyRate() async {
        // Given
        let service = GoalProgramService()

        // When
        let defaults = service.calculateDefaults(for: .muscleGain, startingWeight: 70.0)

        // Then
        #expect(defaults.weeklyRate == 0.25, "Weekly rate should be +0.25 kg/week")
    }

    // MARK: - Macro Defaults Tests

    @Test("Macro defaults are consistent across all goal types")
    @MainActor
    func testMacroDefaultsAreConsistent() async {
        // Given
        let service = GoalProgramService()

        // When
        let weightLossDefaults = service.calculateDefaults(for: .weightLoss, startingWeight: 80.0)
        let maintenanceDefaults = service.calculateDefaults(for: .maintenance, startingWeight: 80.0)
        let muscleGainDefaults = service.calculateDefaults(for: .muscleGain, startingWeight: 80.0)

        // Then - all should have same base macros
        #expect(weightLossDefaults.calories == 2000.0)
        #expect(maintenanceDefaults.calories == 2000.0)
        #expect(muscleGainDefaults.calories == 2000.0)

        #expect(weightLossDefaults.protein == 150.0)
        #expect(weightLossDefaults.carbs == 200.0)
        #expect(weightLossDefaults.fat == 67.0)
    }

    // MARK: - Entity Creation Tests

    @Test("createGoalAndProgram creates goal linked to user")
    @MainActor
    func testGoalLinkedToUser() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container  // Keep container alive
        let service = GoalProgramService()
        let user = createTestUser(in: context)

        // When
        let (goal, _) = try service.createGoalAndProgram(
            for: user,
            goalType: .weightLoss,
            programStyle: .coached,
            startingWeightKg: 80.0,
            in: context
        )

        // Then
        #expect(goal.user === user, "Goal should be linked to user")
    }

    @Test("createGoalAndProgram creates program linked to goal")
    @MainActor
    func testProgramLinkedToGoal() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container  // Keep container alive
        let service = GoalProgramService()
        let user = createTestUser(in: context)

        // When
        let (goal, program) = try service.createGoalAndProgram(
            for: user,
            goalType: .maintenance,
            programStyle: .collaborative,
            startingWeightKg: 75.0,
            in: context
        )

        // Then
        #expect(program.goal === goal, "Program should be linked to goal")
        #expect(goal.program === program, "Goal should have program reference")
    }

    @Test("createGoalAndProgram persists correct goal type")
    @MainActor
    func testCorrectGoalTypePersisted() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container  // Keep container alive
        let service = GoalProgramService()
        let user = createTestUser(in: context)

        // When
        let (goal, _) = try service.createGoalAndProgram(
            for: user,
            goalType: .muscleGain,
            programStyle: .manual,
            startingWeightKg: 70.0,
            in: context
        )

        // Then
        #expect(goal.goalType == .muscleGain, "Goal type should match input")
    }

    @Test("createGoalAndProgram persists correct program style")
    @MainActor
    func testCorrectProgramStylePersisted() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container  // Keep container alive
        let service = GoalProgramService()
        let user = createTestUser(in: context)

        // When
        let (_, program) = try service.createGoalAndProgram(
            for: user,
            goalType: .weightLoss,
            programStyle: .coached,
            startingWeightKg: 80.0,
            in: context
        )

        // Then
        #expect(program.style == .coached, "Program style should match input")
    }

    @Test("createGoalAndProgram uses balanced diet and standard calorie floor by default")
    @MainActor
    func testDefaultProgramSettings() async throws {
        // Given
        let (context, container) = createTestContext()
        _ = container  // Keep container alive
        let service = GoalProgramService()
        let user = createTestUser(in: context)

        // When
        let (_, program) = try service.createGoalAndProgram(
            for: user,
            goalType: .weightLoss,
            programStyle: .coached,
            startingWeightKg: 80.0,
            in: context
        )

        // Then
        #expect(program.diet == .balanced, "Diet preference should default to balanced")
        #expect(program.calorieFloor == .standard, "Calorie floor should default to standard")
        #expect(program.training == .none, "Training level should default to none")
        #expect(program.distributionMode == .even, "Distribution mode should default to even")
        #expect(program.protein == .moderate, "Protein level should default to moderate")
    }
}
