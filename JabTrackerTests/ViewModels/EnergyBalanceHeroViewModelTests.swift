//
//  EnergyBalanceHeroViewModelTests.swift
//  JabTrackerTests
//
//  Tests for EnergyBalanceHeroViewModel - 30-day energy balance widget data source
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("EnergyBalanceHeroViewModel Tests")
@MainActor
struct EnergyBalanceHeroViewModelTests {

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

    @Test("ViewModel initializes with correct default state")
    func testInitialState() async {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceHeroViewModel(mealLogService: mealLogService, context: context)

        #expect(viewModel.isLoading == false)
        #expect(viewModel.dailyCalories.count == 30)
        #expect(viewModel.averageExpenditure > 0)  // Should have default
        #expect(viewModel.averageTargets > 0)  // Should have default
    }

    // MARK: - 30-Day Data Loading Tests

    @Test("ViewModel loads 30 days of calorie data")
    func testLoads30DaysData() async throws {
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        let today = Date()

        // Given: Food entries for a few days
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        _ = createFoodEntry(in: context, calories: 500, loggedAt: today)
        _ = createFoodEntry(in: context, calories: 600, loggedAt: yesterday)
        _ = createFoodEntry(in: context, calories: 700, loggedAt: twoDaysAgo)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Data array has 30 elements with recent days having values
        #expect(viewModel.dailyCalories.count == 30)
        #expect(viewModel.totalNutrition > 0)
    }

    @Test("ViewModel calculates total nutrition correctly")
    func testCalculatesTotalNutrition() async throws {
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        let today = Date()

        // Given: Food entries for multiple days
        for daysAgo in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            _ = createFoodEntry(in: context, calories: 1000, loggedAt: date)
        }
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Total nutrition is sum of all entries
        #expect(viewModel.totalNutrition == 5000)
    }

    @Test("ViewModel loads expenditure from User's TDEE")
    func testLoadsExpenditureFromTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with active NutritionGoal that has TDEE
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2200  // User's TDEE
        context.insert(nutritionGoal)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Expenditure is from TDEE
        #expect(viewModel.averageExpenditure == 2200)
    }

    @Test("ViewModel loads targets from NutritionGoal")
    func testLoadsTargetsFromNutritionGoal() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with active NutritionGoal
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        context.insert(nutritionGoal)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Targets is from daily calorie target
        #expect(viewModel.averageTargets == 1500)
    }

    @Test("ViewModel calculates balance correctly")
    func testCalculatesBalance() async throws {
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        let today = Date()

        // Given: User with goals and food entries
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)

        // Add 10 days of 1400 calories (under target)
        for daysAgo in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            _ = createFoodEntry(in: context, calories: 1400, loggedAt: date)
        }
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Balance calculations work
        // Average daily nutrition: 14000 / 30 = 467 (since only 10 days have data)
        // Expenditure-based balance: 467 - 2000 = -1533 (deficit)
        let avgNutrition = viewModel.totalNutrition / 30
        let expenditureBalance = avgNutrition - Int(viewModel.averageExpenditure)
        #expect(expenditureBalance < 0)  // Should be in deficit
    }

    @Test("ViewModel handles empty data gracefully")
    func testHandlesEmptyData() async {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading with no food entries
        await viewModel.loadData()

        // Then: All values are zeros or defaults
        #expect(viewModel.dailyCalories.allSatisfy { $0.value == 0 })
        #expect(viewModel.totalNutrition == 0)
        #expect(viewModel.averageExpenditure > 0)  // Should have default
        #expect(viewModel.averageTargets > 0)  // Should have default
    }

    @Test("ViewModel uses User fallback when no active NutritionGoal")
    func testUsesUserFallbackForTargets() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User without active NutritionGoal
        let user = createTestUser(in: context)
        user.dailyCalorieGoal = 1800
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Falls back to User's daily calorie goal for targets
        #expect(viewModel.averageTargets == 1800)
    }

    @Test("DayCalories struct has correct date format")
    func testDayCaloriesDateFormat() async throws {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = EnergyBalanceHeroViewModel(mealLogService: mealLogService, context: context)

        await viewModel.loadData()

        // All 30 days should have dates
        #expect(viewModel.dailyCalories.count == 30)

        // First entry should be ~30 days ago, last should be today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: today)!

        // First date should be approximately 30 days ago
        let firstDate = calendar.startOfDay(for: viewModel.dailyCalories.first!.date)
        #expect(calendar.isDate(firstDate, equalTo: thirtyDaysAgo, toGranularity: .day))

        // Last date should be today
        let lastDate = calendar.startOfDay(for: viewModel.dailyCalories.last!.date)
        #expect(calendar.isDate(lastDate, equalTo: today, toGranularity: .day))
    }
}
