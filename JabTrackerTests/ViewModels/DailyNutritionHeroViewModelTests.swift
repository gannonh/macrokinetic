//
//  DailyNutritionHeroViewModelTests.swift
//  JabTrackerTests
//
//  Tests for DailyNutritionHeroViewModel - daily nutrition widget data source
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("DailyNutritionHeroViewModel Tests")
@MainActor
struct DailyNutritionHeroViewModelTests {

    // MARK: - Test Helpers

    private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([
            User.self, Dose.self, Food.self, FoodEntry.self, NutritionGoal.self, NutritionProgram.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        return (container.mainContext, container)
    }

    private func createTestUser(in context: ModelContext) -> User {
        let user = User(
            email: "test@example.com",
            name: "Test User",
            appleUserId: "test-apple-id",
            dailyCalorieGoal: 2000,
            dailyProteinGoal: 150,
            dailyCarbGoal: 200,
            dailyFatGoal: 65
        )
        context.insert(user)
        return user
    }

    private func createFoodEntry(
        in context: ModelContext,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        loggedAt: Date = Date()
    ) -> FoodEntry {
        let entry = FoodEntry(
            foodId: UUID(),
            foodName: "Test Food",
            foodBrand: nil,
            mealSection: .lunch,
            loggedAt: loggedAt,
            servingGrams: 100,
            servingDescription: nil,
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            fiberPer100g: 0,
            notes: nil
        )
        context.insert(entry)
        return entry
    }

    // MARK: - Initial State Tests

    @Test("ViewModel initializes with loading state")
    func testInitialState() async {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = DailyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        #expect(viewModel.isLoading == false)
        #expect(viewModel.caloriesConsumed == 0)
        #expect(viewModel.proteinConsumed == 0)
        #expect(viewModel.fatConsumed == 0)
        #expect(viewModel.carbsConsumed == 0)
    }

    // MARK: - Data Loading Tests

    @Test("ViewModel loads today's nutrition data")
    func testLoadsTodayData() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: Food entries logged today
        _ = createFoodEntry(in: context, calories: 300, protein: 25, carbs: 40, fat: 10)
        _ = createFoodEntry(in: context, calories: 200, protein: 15, carbs: 20, fat: 8)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = DailyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Consumed values match food entries
        #expect(viewModel.caloriesConsumed == 500)
        #expect(viewModel.proteinConsumed == 40)
        #expect(viewModel.carbsConsumed == 60)
        #expect(viewModel.fatConsumed == 18)
    }

    @Test("ViewModel gets targets from User's nutrition goals")
    func testLoadsTargetsFromUser() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with nutrition goals
        let user = createTestUser(in: context)
        user.dailyCalorieGoal = 1800
        user.dailyProteinGoal = 130
        user.dailyCarbGoal = 180
        user.dailyFatGoal = 60
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = DailyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Targets match user's goals
        #expect(viewModel.caloriesTarget == 1800)
        #expect(viewModel.proteinTarget == 130)
        #expect(viewModel.carbsTarget == 180)
        #expect(viewModel.fatTarget == 60)
    }

    @Test("ViewModel calculates remaining calories correctly")
    func testCalculatesRemaining() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with goals and some consumption
        let user = createTestUser(in: context)
        user.dailyCalorieGoal = 2000
        _ = createFoodEntry(in: context, calories: 500, protein: 30, carbs: 50, fat: 20)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = DailyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Remaining is target minus consumed
        #expect(viewModel.caloriesRemaining == 1500)
    }

    @Test("ViewModel handles empty data gracefully")
    func testHandlesEmptyData() async throws {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = DailyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading with no food entries
        await viewModel.loadData()

        // Then: All consumed values are zero, targets are defaults
        #expect(viewModel.caloriesConsumed == 0)
        #expect(viewModel.proteinConsumed == 0)
        #expect(viewModel.fatConsumed == 0)
        #expect(viewModel.carbsConsumed == 0)
        #expect(viewModel.isLoading == false)
    }

    @Test("ViewModel ignores entries from other days")
    func testIgnoresOtherDays() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: Food entry from yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        _ = createFoodEntry(in: context, calories: 500, protein: 30, carbs: 50, fat: 20, loggedAt: yesterday)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = DailyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Yesterday's data is not included
        #expect(viewModel.caloriesConsumed == 0)
    }

    // MARK: - Active NutritionGoal Tests

    @Test("ViewModel uses active NutritionGoal targets when available")
    func testUsesActiveNutritionGoal() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with active NutritionGoal
        let user = createTestUser(in: context)
        user.dailyCalorieGoal = 2000  // Fallback values

        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500,
            dailyProteinTargetGrams: 120,
            dailyCarbTargetGrams: 150,
            dailyFatTargetGrams: 50
        )
        nutritionGoal.user = user
        context.insert(nutritionGoal)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = DailyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Targets come from active NutritionGoal
        #expect(viewModel.caloriesTarget == 1500)
        #expect(viewModel.proteinTarget == 120)
        #expect(viewModel.carbsTarget == 150)
        #expect(viewModel.fatTarget == 50)
    }
}
