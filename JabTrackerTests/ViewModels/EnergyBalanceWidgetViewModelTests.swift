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
        let config = InMemoryTestStore.configuration(schema: schema)
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
        #expect(viewModel.averageDailyBalance == 0)
        #expect(viewModel.hasData == false)
    }

    // MARK: - Balance Calculation Tests

    @Test("ViewModel calculates daily balance correctly")
    func testCalculatesDailyBalance() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE of 2000 and food logged yesterday (widget excludes today)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 1)  // Yesterday: 1800 consumed
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

        // Given: User with TDEE of 2000 and food logged over 7 days (excluding today)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)

        // Note: Widget excludes today, so log food for daysAgo 1-7 (not 0-6)
        _ = createFoodEntry(in: context, calories: 1700, daysAgo: 1)  // -300 deficit
        _ = createFoodEntry(in: context, calories: 1900, daysAgo: 2)  // -100 deficit
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 3)  // -200 deficit
        _ = createFoodEntry(in: context, calories: 1700, daysAgo: 4)  // -300 deficit
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 5)  // -200 deficit
        _ = createFoodEntry(in: context, calories: 1900, daysAgo: 6)  // -100 deficit
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 7)  // -200 deficit
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Net balance is sum of all deficits (1400 kcal deficit)
        #expect(viewModel.dailyBalances.count == 7)
        #expect(viewModel.averageDailyBalance != 0)
        #expect(viewModel.isDeficit == true)
    }

    @Test("ViewModel handles days with no food logged as no meaningful data")
    func testHandlesNoFoodAsNoData() async throws {
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

        // Then: With Phase 39, no food = no meaningful data (days without food/fasting are excluded)
        #expect(viewModel.hasData == false, "No food logged means no meaningful data")
        #expect(viewModel.dailyBalances.isEmpty, "Should have no balances without food data")
        #expect(viewModel.averageDailyBalance == 0, "Average should be 0 with no data")
    }

    @Test("ViewModel shows surplus when eating above TDEE consistently")
    func testShowsSurplus() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE of 2000 but consuming more every day
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)

        // Note: Widget excludes today, so log surplus calories for daysAgo 1-7
        for daysAgo in 1...7 {
            _ = createFoodEntry(in: context, calories: 2500, daysAgo: daysAgo)  // +500 surplus each day
        }
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Shows as surplus (average of 500 kcal/day surplus)
        #expect(viewModel.isDeficit == false)
        #expect(viewModel.averageDailyBalance == 500)
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
        #expect(viewModel.averageDailyBalance == 0)
        #expect(viewModel.hasData == false)
        #expect(viewModel.isLoading == false)
    }

    @Test("Loading state is false after load completes")
    func testLoadingStateAfterLoad() async throws {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: isLoading is false after completion
        #expect(viewModel.isLoading == false)
    }

    @Test("Preview instance can be created")
    func testPreviewInstance() async {
        // Verify preview factory method works
        let preview = EnergyBalanceWidgetViewModel.preview
        #expect(preview.isLoading == false)
        #expect(preview.dailyBalances.isEmpty)
    }

    @Test("hasData returns true when balances exist")
    func testHasDataWithBalances() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and food logged (widget excludes today)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 1)  // Yesterday
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: hasData returns true
        #expect(viewModel.hasData == true)
    }

    @Test("ViewModel uses lastCalculatedTDEE when available")
    func testUsesLastCalculatedTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: Goal with both initial and last calculated TDEE
        let user = createTestUser(in: context)
        let goal = createNutritionGoal(in: context, user: user, tdee: 2000)
        goal.lastCalculatedTDEE = 2100  // Updated value
        // Widget excludes today, so log food for yesterday
        _ = createFoodEntry(in: context, calories: 2100, daysAgo: 1)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Uses lastCalculatedTDEE (2100)
        #expect(viewModel.dailyBalances.count >= 1, "Should have at least one day's balance")
        #expect(viewModel.tdee == 2100, "Should use lastCalculatedTDEE")
    }

    // MARK: - Daily Intake Tests

    @Test("ViewModel populates dailyIntake array with values for days with data")
    func testDailyIntakeArray() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and food for the last 7 days (excluding today)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)
        // Note: Widget excludes today, so log food for daysAgo 1-7 (not 0-6)
        for daysAgo in 1...7 {
            _ = createFoodEntry(in: context, calories: 1800, daysAgo: daysAgo)
        }
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: dailyIntake has 7 values (one for each day with data, excluding today)
        #expect(viewModel.dailyIntake.count == 7)
    }

    @Test("ViewModel stores TDEE value correctly")
    func testTDEEProperty() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with specific TDEE
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2350)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: TDEE is stored correctly
        #expect(viewModel.tdee == 2350)
    }

    @Test("ViewModel tracks daysWithLoadingErrors as zero when no errors")
    func testDaysWithLoadingErrorsZero() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: No loading errors
        #expect(viewModel.daysWithLoadingErrors == 0)
    }

    @Test("ViewModel calculates dailyIntake values correctly")
    func testDailyIntakeValues() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and food for yesterday (widget excludes today)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)
        _ = createFoodEntry(in: context, calories: 1500, daysAgo: 1)  // Yesterday
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: With Phase 39, only days with meaningful data are returned
        #expect(viewModel.dailyIntake.count >= 1, "Should have at least yesterday's intake")
        // The entry for yesterday should be 1500 (last entry in array)
        if let yesterdayIntake = viewModel.dailyIntake.last {
            #expect(yesterdayIntake == 1500, "Yesterday's intake should be 1500")
        }
    }

    @Test("ViewModel calculates balances for each day")
    func testDailyBalancesCalculation() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE of 2000 and food logged for all 7 days (excluding today)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)
        // Note: Widget excludes today, so log food for daysAgo 1-7
        // Array is ordered oldest to newest, so index 0 = 7 days ago, index 6 = yesterday
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 1)  // -200 balance (yesterday) -> index 6
        _ = createFoodEntry(in: context, calories: 2200, daysAgo: 2)  // +200 balance -> index 5
        _ = createFoodEntry(in: context, calories: 2000, daysAgo: 3)  // 0 balance -> index 4
        _ = createFoodEntry(in: context, calories: 2000, daysAgo: 4)  // 0 balance -> index 3
        _ = createFoodEntry(in: context, calories: 2000, daysAgo: 5)  // 0 balance -> index 2
        _ = createFoodEntry(in: context, calories: 2000, daysAgo: 6)  // 0 balance -> index 1
        _ = createFoodEntry(in: context, calories: 2000, daysAgo: 7)  // 0 balance -> index 0
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Balances reflect intake - TDEE
        #expect(viewModel.dailyBalances.count == 7, "Should have 7 days of balances")
        // Yesterday (index 6) should be 1800 - 2000 = -200
        #expect(viewModel.dailyBalances[6] == -200, "Yesterday's balance should be -200")
        // Two days ago (index 5) should be 2200 - 2000 = 200
        #expect(viewModel.dailyBalances[5] == 200, "Two days ago balance should be +200")
    }

    @Test("ViewModel initializes TDEE to zero")
    func testInitialTDEEValue() async {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // Then: TDEE starts at 0 before loading
        #expect(viewModel.tdee == 0)
    }

    @Test("ViewModel initializes daysWithLoadingErrors to zero")
    func testInitialDaysWithLoadingErrors() async {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // Then: daysWithLoadingErrors starts at 0
        #expect(viewModel.daysWithLoadingErrors == 0)
    }

    @Test("ViewModel uses fallback to initial TDEE when no lastCalculated")
    func testFallsBackToInitialTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: Goal with only initial TDEE
        let user = createTestUser(in: context)
        let goal = createNutritionGoal(in: context, user: user, tdee: 1950)
        goal.lastCalculatedTDEE = nil
        goal.initialEstimatedTDEE = 1950
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Uses initial TDEE
        #expect(viewModel.tdee == 1950)
    }

    // MARK: - Additional Balance Tests

    @Test("ViewModel tracks isDeficit correctly for mixed week")
    func testIsDeficitMixedWeek() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE of 2000
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)

        // Note: Widget excludes today, so log food for daysAgo 1-7
        // Days 1-4: 1800 cal (deficit)
        // Days 5-7: 2100 cal (surplus)
        // Net: 4*1800 + 3*2100 = 7200 + 6300 = 13500, TDEE = 14000, so deficit
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 1)
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 2)
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 3)
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 4)
        _ = createFoodEntry(in: context, calories: 2100, daysAgo: 5)
        _ = createFoodEntry(in: context, calories: 2100, daysAgo: 6)
        _ = createFoodEntry(in: context, calories: 2100, daysAgo: 7)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Net deficit should be detected
        // Total intake: 13500, Total TDEE: 14000, Net: -500
        #expect(viewModel.isDeficit == true)
        #expect(viewModel.averageDailyBalance < 0)
    }

    @Test("ViewModel calculates correct average daily balance")
    func testAverageDailyBalanceCalculation() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE of 2000 eating exactly maintenance
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)

        // Note: Widget excludes today, so log exactly 2000 calories for daysAgo 1-7
        for daysAgo in 1...7 {
            _ = createFoodEntry(in: context, calories: 2000, daysAgo: daysAgo)
        }
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Average balance should be 0 (maintenance)
        #expect(viewModel.averageDailyBalance == 0)
    }

    @Test("ViewModel handles rapid reloading")
    func testRapidReloading() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and food logged (widget excludes today)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)
        _ = createFoodEntry(in: context, calories: 1800, daysAgo: 1)  // Yesterday
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data multiple times
        await viewModel.loadData()
        let firstBalance = viewModel.averageDailyBalance

        await viewModel.loadData()
        let secondBalance = viewModel.averageDailyBalance

        // Then: Results are consistent
        #expect(firstBalance == secondBalance)
        #expect(viewModel.isLoading == false)
    }

    @Test("ViewModel correctly stores all 7 daily balance values when all days have data")
    func testDailyBalancesCount() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and food logged for all 7 days (excluding today)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2000)
        // Note: Widget excludes today, so log food for daysAgo 1-7 (not 0-6)
        for daysAgo in 1...7 {
            _ = createFoodEntry(in: context, calories: 1800, daysAgo: daysAgo)
        }
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceWidgetViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: 7 daily balances are stored (one for each day with data)
        #expect(viewModel.dailyBalances.count == 7, "Should have 7 daily balances")
        #expect(viewModel.dailyIntake.count == 7, "Should have 7 daily intake values")
    }
}
