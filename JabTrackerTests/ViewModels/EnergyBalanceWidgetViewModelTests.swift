//
//  EnergyBalanceWidgetViewModelTests.swift
//  JabTrackerTests
//
//  Tests for EnergyBalanceWidgetViewModel - standard widget balance calculations
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("EnergyBalanceWidgetViewModel Tests")
@MainActor
struct EnergyBalanceWidgetViewModelTests {

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

    private func createTestUser(in context: ModelContext) -> User {
        let user = User(
            email: "test@example.com",
            name: "Test User"
        )
        context.insert(user)
        return user
    }

    private func createNutritionGoal(
        in context: ModelContext,
        user: User,
        tdee: Double
    ) -> NutritionGoal {
        let goal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1800
        )
        goal.initialEstimatedTDEE = tdee
        goal.lastCalculatedTDEE = tdee
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

    @Test("ViewModel initializes with no data")
    func testInitialState() async {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        #expect(viewModel.isLoading == false)
        #expect(viewModel.dailyBalances.isEmpty)
        #expect(viewModel.netBalance == 0)
        #expect(viewModel.hasData == false)
    }

    // MARK: - Balance Calculation Tests

    @Test("ViewModel calculates daily balance correctly")
    func testCalculatesDailyBalance() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE of 2000 and food logged today
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 0)  // Today: 1800 consumed
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Net balance is deficit (consumed - TDEE = 1800 - 2000 = -200)
        #expect(viewModel.hasData == true)
        #expect(viewModel.isDeficit == true)  // Eating less than TDEE
    }

    @Test("ViewModel calculates net balance for 7 days")
    func testCalculatesSevenDayNetBalance() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE of 2000 and food logged over 7 days
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)

        // Log food for each of the last 7 days (varying amounts)
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 0)  // -200 deficit
        _ = createFoodEntry(in: context, calories: 1700, daysAgo: 1)  // -300 deficit
        _ = createFoodEntry(in: context, calories: 1900, daysAgo: 2)  // -100 deficit
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 3)  // -200 deficit
        _ = createFoodEntry(in: context, calories: 1700, daysAgo: 4)  // -300 deficit
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 5)  // -200 deficit
        _ = createFoodEntry(in: context, calories: 1900, daysAgo: 6)  // -100 deficit
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Net balance is sum of all deficits (1400 kcal deficit)
        #expect(viewModel.dailyBalances.count == 7)
        #expect(viewModel.netBalance != 0)
        #expect(viewModel.isDeficit == true)
    }

    @Test("ViewModel handles days with no food logged as 0 calories")
    func testHandlesNoFoodAsZeroCalories() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE but no food logged
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Balance shows full TDEE as deficit (0 - 2000 = -2000 per day)
        #expect(viewModel.hasData == true)
        #expect(viewModel.isDeficit == true)
        // Net deficit for 7 days with no food = 7 * 2000 = 14000
        #expect(viewModel.netBalance == 14000)
    }

    @Test("ViewModel shows surplus when eating above TDEE consistently")
    func testShowsSurplus() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE of 2000 but consuming more every day
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)

        // Log surplus calories for all 7 days
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 2500, daysAgo: daysAgo)  // +500 surplus each day
        }
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Shows as surplus (7 days * 500 = 3500 surplus)
        #expect(viewModel.isDeficit == false)
        #expect(viewModel.netBalance == 3500)
    }

    @Test("ViewModel handles missing TDEE gracefully")
    func testHandlesMissingTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User without TDEE (no NutritionGoal)
        _ = createTestUser(in: context)
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 0)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Has no data since TDEE is required for balance calculation
        #expect(viewModel.hasData == false)
    }

    @Test("ViewModel handles empty data gracefully")
    func testHandlesEmptyData() async throws {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading with no user
        await viewModel.loadData()

        // Then: No crash, no data
        #expect(viewModel.dailyBalances.isEmpty)
        #expect(viewModel.netBalance == 0)
        #expect(viewModel.hasData == false)
        #expect(viewModel.isLoading == false)
    }
}
