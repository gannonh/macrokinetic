//
//  GoalProgressWidgetViewModelTests.swift
//  JabTrackerTests
//
//  Tests for GoalProgressWidgetViewModel - daily nutrition goal progress
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("GoalProgressWidgetViewModel Tests")
@MainActor
struct GoalProgressWidgetViewModelTests {

    // MARK: - Test Helpers

    private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([
            User.self, FoodEntry.self, NutritionGoal.self, NutritionProgram.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        return (container.mainContext, container)
    }

    private func createTestUser(in context: ModelContext, calorieGoal: Double = 2000) -> User {
        let user = User(email: "test@example.com", name: "Test User")
        user.dailyCalorieGoal = calorieGoal
        context.insert(user)
        return user
    }

    private func createNutritionGoal(
        in context: ModelContext,
        user: User,
        calorieTarget: Double
    ) -> NutritionGoal {
        let goal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: calorieTarget
        )
        goal.user = user
        context.insert(goal)
        return goal
    }

    private func createFoodEntry(
        in context: ModelContext,
        calories: Double,
        daysAgo: Int = 0
    ) -> FoodEntry {
        let loggedAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        let entry = FoodEntry(
            foodId: UUID(),
            foodName: "Test Food",
            foodBrand: nil,
            mealSection: .lunch,
            loggedAt: loggedAt,
            servingGrams: 100,
            servingDescription: nil,
            caloriesPer100g: calories,
            proteinPer100g: 10,
            carbsPer100g: 20,
            fatPer100g: 5,
            fiberPer100g: 0,
            notes: nil
        )
        context.insert(entry)
        return entry
    }

    // MARK: - Initial State Tests

    @Test("ViewModel initializes with zero progress")
    func testInitialState() async {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = GoalProgressWidgetViewModel(mealLogService: mealLogService, context: context)

        #expect(viewModel.isLoading == false)
        #expect(viewModel.progressPercentage == 0)
        #expect(viewModel.targetPercentage == 1.0)
        #expect(viewModel.displayPercentage == 0)
    }

    // MARK: - Progress Calculation Tests

    @Test("ViewModel calculates progress percentage correctly")
    func testCalculatesProgress() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with 2000 calorie goal and 1000 calories logged
        let user = createTestUser(in: context, calorieGoal: 2000)
        _ = createNutritionGoal(in: context, user: user, calorieTarget: 2000)
        _ = createFoodEntry(in: context, calories: 1000, daysAgo: 0)  // 50% of goal
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = GoalProgressWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Progress is 50%
        #expect(abs(viewModel.progressPercentage - 0.5) < 0.01)
        #expect(viewModel.displayPercentage == 50)
    }

    @Test("ViewModel uses NutritionGoal target when available")
    func testUsesNutritionGoalTarget() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with different goal in NutritionGoal vs User
        let user = createTestUser(in: context, calorieGoal: 2000)  // Fallback
        _ = createNutritionGoal(in: context, user: user, calorieTarget: 1500)  // Active goal
        _ = createFoodEntry(in: context, calories: 750, daysAgo: 0)  // 50% of NutritionGoal
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = GoalProgressWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Progress calculated against NutritionGoal (1500) not User (2000)
        #expect(abs(viewModel.progressPercentage - 0.5) < 0.01)
        #expect(viewModel.displayPercentage == 50)
    }

    @Test("ViewModel falls back to User goal without NutritionGoal")
    func testFallsBackToUserGoal() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with goal but no NutritionGoal
        _ = createTestUser(in: context, calorieGoal: 2000)
        _ = createFoodEntry(in: context, calories: 1000, daysAgo: 0)  // 50% of user goal
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = GoalProgressWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Progress calculated against User goal (2000)
        #expect(abs(viewModel.progressPercentage - 0.5) < 0.01)
        #expect(viewModel.displayPercentage == 50)
    }

    @Test("ViewModel handles empty data gracefully")
    func testHandlesEmptyData() async throws {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = GoalProgressWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading with no data
        await viewModel.loadData()

        // Then: Progress is 0
        #expect(viewModel.progressPercentage == 0)
        #expect(viewModel.displayPercentage == 0)
        #expect(viewModel.isLoading == false)
    }

    @Test("ViewModel can exceed 100% progress")
    func testExceedsHundredPercent() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with 1000 calorie goal and 1500 calories logged
        let user = createTestUser(in: context, calorieGoal: 1000)
        _ = createNutritionGoal(in: context, user: user, calorieTarget: 1000)
        _ = createFoodEntry(in: context, calories: 1500, daysAgo: 0)  // 150% of goal
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = GoalProgressWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Progress exceeds 100%
        #expect(abs(viewModel.progressPercentage - 1.5) < 0.01)
        #expect(viewModel.displayPercentage == 150)
    }

    @Test("ViewModel ignores entries from other days")
    func testIgnoresOtherDays() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with food logged yesterday only
        let user = createTestUser(in: context, calorieGoal: 2000)
        _ = createNutritionGoal(in: context, user: user, calorieTarget: 2000)
        _ = createFoodEntry(in: context, calories: 1000, daysAgo: 1)  // Yesterday
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = GoalProgressWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Progress is 0 (yesterday's data ignored)
        #expect(viewModel.progressPercentage == 0)
        #expect(viewModel.displayPercentage == 0)
    }

    @Test("ViewModel handles zero calorie target gracefully")
    func testHandlesZeroCalorieTarget() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with 0 calorie target
        let user = createTestUser(in: context, calorieGoal: 0)
        _ = createNutritionGoal(in: context, user: user, calorieTarget: 0)
        _ = createFoodEntry(in: context, calories: 1000, daysAgo: 0)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = GoalProgressWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Progress is 0 (avoids division by zero)
        #expect(viewModel.progressPercentage == 0)
        #expect(viewModel.displayPercentage == 0)
    }

    @Test("ViewModel uses default target without user")
    func testUsesDefaultTargetWithoutUser() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: No user, just food entries
        _ = createFoodEntry(in: context, calories: 1000, daysAgo: 0)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = GoalProgressWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Progress calculated against default 2000 calorie target
        #expect(abs(viewModel.progressPercentage - 0.5) < 0.01)
        #expect(viewModel.displayPercentage == 50)
    }

    @Test("hasData always returns true")
    func testHasDataAlwaysTrue() async {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = GoalProgressWidgetViewModel(mealLogService: mealLogService, context: context)

        // hasData is always true for this widget
        #expect(viewModel.hasData == true)

        // Even after loading
        await viewModel.loadData()
        #expect(viewModel.hasData == true)
    }

    @Test("Preview instance can be created")
    func testPreviewInstance() async {
        // Verify preview factory method works
        let preview = GoalProgressWidgetViewModel.preview
        #expect(preview.isLoading == false)
        #expect(preview.progressPercentage == 0)
    }
}
