//
//  WeeklyNutritionHeroViewModelTests.swift
//  JabTrackerTests
//
//  Tests for WeeklyNutritionHeroViewModel - 7-day nutrition widget data source
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("WeeklyNutritionHeroViewModel Tests")
@MainActor
struct WeeklyNutritionHeroViewModelTests {

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

    /// Get start of the current week (Monday)
    private func startOfWeek() -> Date {
        let calendar = Calendar.current
        let today = Date()
        // Get current weekday (1=Sunday, 2=Monday, ..., 7=Saturday)
        let weekday = calendar.component(.weekday, from: today)
        // Convert to 0=Monday format
        let daysFromMonday = weekday == 1 ? 6 : weekday - 2
        return calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: today))!
    }

    // MARK: - Initial State Tests

    @Test("ViewModel initializes with correct default state")
    func testInitialState() async {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = WeeklyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        #expect(viewModel.isLoading == false)
        #expect(viewModel.calories.count == 7)
        #expect(viewModel.protein.count == 7)
        #expect(viewModel.fat.count == 7)
        #expect(viewModel.carbs.count == 7)
    }

    // MARK: - 7-Day Data Loading Tests

    @Test("ViewModel loads 7 days of nutrition data")
    func testLoads7DaysData() async throws {
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        let weekStart = startOfWeek()

        // Given: Food entries for Monday and Tuesday of this week
        let monday = weekStart
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!

        let mondayEntry = createFoodEntry(
            in: context, calories: 500, protein: 30, carbs: 50, fat: 20, loggedAt: monday)
        let tuesdayEntry = createFoodEntry(
            in: context, calories: 600, protein: 40, carbs: 60, fat: 25, loggedAt: tuesday)
        try context.save()

        // Verify entries were saved correctly
        #expect(mondayEntry.calories == 500, "Monday entry should have 500 calories")
        #expect(tuesdayEntry.calories == 600, "Tuesday entry should have 600 calories")

        let mealLogService = MealLogService(context: context)
        let viewModel = WeeklyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Data arrays have 7 elements
        #expect(viewModel.calories.count == 7)

        // Find the today index to verify we're checking the right days
        // Only days up to and including today will have been loaded
        let todayIndex = viewModel.todayIndex

        // Monday is index 0, Tuesday is index 1
        // Both should be in range if today is Tuesday or later in the week
        if todayIndex >= 0 {
            #expect(viewModel.calories[0] == 500, "Monday (index 0) should have 500 calories")
        }
        if todayIndex >= 1 {
            #expect(viewModel.calories[1] == 600, "Tuesday (index 1) should have 600 calories")
        }
    }

    @Test("ViewModel calculates today index correctly")
    func testTodayIndex() async {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = WeeklyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        await viewModel.loadData()

        // Today index should be between 0 (Monday) and 6 (Sunday)
        #expect(viewModel.todayIndex >= 0)
        #expect(viewModel.todayIndex <= 6)

        // Verify today index calculation
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let expectedIndex = weekday == 1 ? 6 : weekday - 2  // Convert 1=Sunday to 0=Monday format
        #expect(viewModel.todayIndex == expectedIndex)
    }

    @Test("ViewModel sets future days to zero")
    func testFutureDaysAreZero() async throws {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = WeeklyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        await viewModel.loadData()

        // Days after today should be 0
        for dayIndex in (viewModel.todayIndex + 1)..<7 {
            #expect(viewModel.calories[dayIndex] == 0)
            #expect(viewModel.protein[dayIndex] == 0)
            #expect(viewModel.fat[dayIndex] == 0)
            #expect(viewModel.carbs[dayIndex] == 0)
        }
    }

    @Test("ViewModel loads targets from User")
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
        let viewModel = WeeklyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Targets match user's goals
        #expect(viewModel.caloriesTarget == 1800)
        #expect(viewModel.proteinTarget == 130)
        #expect(viewModel.carbsTarget == 180)
        #expect(viewModel.fatTarget == 60)
    }

    @Test("ViewModel handles empty data gracefully")
    func testHandlesEmptyData() async {
        let (context, container) = createTestContext()
        _ = container

        let mealLogService = MealLogService(context: context)
        let viewModel = WeeklyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading with no food entries
        await viewModel.loadData()

        // Then: All arrays are zeros
        #expect(viewModel.calories.allSatisfy { $0 == 0 })
        #expect(viewModel.protein.allSatisfy { $0 == 0 })
        #expect(viewModel.fat.allSatisfy { $0 == 0 })
        #expect(viewModel.carbs.allSatisfy { $0 == 0 })
    }

    @Test("ViewModel aggregates multiple entries per day")
    func testAggregatesMultipleEntriesPerDay() async throws {
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        let weekStart = startOfWeek()
        let monday = weekStart

        // Given: Multiple food entries on Monday
        _ = createFoodEntry(in: context, calories: 300, protein: 20, carbs: 30, fat: 10, loggedAt: monday)
        _ = createFoodEntry(
            in: context, calories: 400, protein: 25, carbs: 40, fat: 15,
            loggedAt: calendar.date(byAdding: .hour, value: 2, to: monday)!
        )
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = WeeklyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Monday values are aggregated
        #expect(viewModel.calories[0] == 700)  // 300 + 400
        #expect(viewModel.protein[0] == 45)  // 20 + 25
        #expect(viewModel.carbs[0] == 70)  // 30 + 40
        #expect(viewModel.fat[0] == 25)  // 10 + 15
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
        let viewModel = WeeklyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Targets come from active NutritionGoal
        #expect(viewModel.caloriesTarget == 1500)
        #expect(viewModel.proteinTarget == 120)
        #expect(viewModel.carbsTarget == 150)
        #expect(viewModel.fatTarget == 50)
    }

    // MARK: - Preview Tests

    @Test("Preview instance can be created")
    func testPreviewCreation() async {
        let preview = WeeklyNutritionHeroViewModel.preview

        // Verify preview has expected default state
        #expect(preview.calories.count == 7)
        #expect(preview.protein.count == 7)
        #expect(preview.carbs.count == 7)
        #expect(preview.fat.count == 7)
        #expect(preview.caloriesTarget == 2000)
        #expect(preview.todayIndex >= 0)
        #expect(preview.todayIndex <= 6)
    }

    // MARK: - Edge Case Tests

    @Test("ViewModel handles blank day with no entries and no fasting flag")
    func testHandlesBlankDayNotFasting() async throws {
        // Need to add DayStatus to schema for this test
        let schema = Schema([
            User.self, Dose.self, Food.self, FoodEntry.self, NutritionGoal.self, NutritionProgram.self,
            DayStatus.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let calendar = Calendar.current
        let weekStart = startOfWeek()

        // Given: Today is at least Wednesday (index 2+)
        // We'll add food for Monday but leave Tuesday blank (not fasting)
        let monday = weekStart
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!

        // Add food for Monday only
        _ = createFoodEntry(in: context, calories: 500, protein: 30, carbs: 50, fat: 20, loggedAt: monday)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let dayStatusService = DayStatusService(context: context)
        let viewModel = WeeklyNutritionHeroViewModel(
            mealLogService: mealLogService,
            dayStatusService: dayStatusService,
            context: context
        )

        // When: Loading data
        await viewModel.loadData()

        // Then: Monday should have data, Tuesday (blank day, not fasting) should be 0
        // and the code path for blank days should be exercised
        if viewModel.todayIndex >= 0 {
            #expect(viewModel.calories[0] == 500, "Monday should have 500 calories")
        }
        if viewModel.todayIndex >= 1 {
            // Tuesday is blank (no entries, not marked as fasting)
            // The code continues past it, leaving it at 0
            #expect(viewModel.calories[1] == 0, "Blank Tuesday should have 0 calories")
        }

        // Verify DayStatus service was used (Tuesday not fasting)
        let isTuesdayFasting = try dayStatusService.isFasting(for: calendar.startOfDay(for: tuesday))
        #expect(isTuesdayFasting == false, "Tuesday should not be marked as fasting")
    }

    @Test("ViewModel uses DayStatusService to identify fasting days")
    func testUsesDayStatusServiceForFastingDays() async throws {
        // Need to add DayStatus to schema for this test
        let schema = Schema([
            User.self, Dose.self, Food.self, FoodEntry.self, NutritionGoal.self, NutritionProgram.self,
            DayStatus.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let calendar = Calendar.current
        let weekStart = startOfWeek()

        // Given: Monday has food, Tuesday is marked as fasting (no entries)
        let monday = weekStart
        let tuesday = calendar.date(byAdding: .day, value: 1, to: monday)!

        _ = createFoodEntry(in: context, calories: 600, protein: 40, carbs: 60, fat: 25, loggedAt: monday)

        // Mark Tuesday as fasting
        let dayStatusService = DayStatusService(context: context)
        try dayStatusService.setFasting(for: calendar.startOfDay(for: tuesday), isFasting: true)
        try context.save()

        let mealLogService = MealLogService(context: context)
        let viewModel = WeeklyNutritionHeroViewModel(
            mealLogService: mealLogService,
            dayStatusService: dayStatusService,
            context: context
        )

        // When: Loading data
        await viewModel.loadData()

        // Then: Fasting day Tuesday should have 0 but still be "valid" (not skipped as blank)
        if viewModel.todayIndex >= 0 {
            #expect(viewModel.calories[0] == 600, "Monday should have 600 calories")
        }
        if viewModel.todayIndex >= 1 {
            // Tuesday is fasting - shows as 0 intentionally
            #expect(viewModel.calories[1] == 0, "Fasting Tuesday should have 0 calories")
        }

        // Verify the fasting flag is set
        let isTuesdayFasting = try dayStatusService.isFasting(for: calendar.startOfDay(for: tuesday))
        #expect(isTuesdayFasting == true, "Tuesday should be marked as fasting")
    }

    @Test("ViewModel handles daysWithLoadingErrors counter")
    func testTracksDaysWithLoadingErrors() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: No food entries (empty data)
        let mealLogService = MealLogService(context: context)
        let viewModel = WeeklyNutritionHeroViewModel(mealLogService: mealLogService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: daysWithLoadingErrors should be 0 (no actual errors, just empty data)
        #expect(viewModel.daysWithLoadingErrors == 0, "Should have no loading errors with empty data")
    }

    @Test("ViewModel without DayStatusService still loads data")
    func testLoadsDataWithoutDayStatusService() async throws {
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        let weekStart = startOfWeek()
        let monday = weekStart

        // Given: Food entries but no DayStatusService provided (nil)
        _ = createFoodEntry(in: context, calories: 400, protein: 25, carbs: 40, fat: 15, loggedAt: monday)
        try context.save()

        let mealLogService = MealLogService(context: context)
        // Initialize without dayStatusService (uses nil default)
        let viewModel = WeeklyNutritionHeroViewModel(
            mealLogService: mealLogService,
            dayStatusService: nil,
            context: context
        )

        // When: Loading data
        await viewModel.loadData()

        // Then: Data should still load correctly (fastingDates = empty set)
        if viewModel.todayIndex >= 0 {
            #expect(viewModel.calories[0] == 400, "Monday should have 400 calories without DayStatusService")
        }
    }
}
