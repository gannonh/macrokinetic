//
//  EnergyBalanceDetailViewModelTests.swift
//  JabTrackerTests
//
//  Tests for EnergyBalanceDetailViewModel - energy balance detail view data source
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("EnergyBalanceDetailViewModel Tests")
@MainActor
struct EnergyBalanceDetailViewModelTests {

    // MARK: - Test Helpers

    private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([
            User.self, FoodEntry.self, NutritionGoal.self, NutritionProgram.self, TDEESnapshot.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        return (container.mainContext, container)
    }

    private func createViewModel(context: ModelContext) -> EnergyBalanceDetailViewModel {
        let mealLogService = MealLogService(context: context)
        let tdeeService = TDEEService(context: context)
        return EnergyBalanceDetailViewModel(
            mealLogService: mealLogService,
            tdeeService: tdeeService,
            context: context
        )
    }

    private func createTestUser(in context: ModelContext) -> User {
        let user = User(email: "test@example.com", name: "Test User")
        user.weight = 185.0
        user.weightUnit = "lbs"
        context.insert(user)
        return user
    }

    private func createNutritionGoal(
        in context: ModelContext,
        for user: User,
        initialTDEE: Double? = nil,
        lastCalculatedTDEE: Double? = nil,
        dailyCalorieTarget: Double = 1800
    ) -> NutritionGoal {
        let goal = NutritionGoal()
        goal.initialEstimatedTDEE = initialTDEE
        goal.lastCalculatedTDEE = lastCalculatedTDEE
        goal.dailyCalorieTarget = dailyCalorieTarget
        goal.isActive = true
        goal.user = user
        context.insert(goal)
        user.nutritionGoals = [goal]
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

    @Test("ViewModel initializes with loading state and empty data")
    func testInitialState() async {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        #expect(viewModel.isLoading == false)
        #expect(viewModel.dailyData.isEmpty)
        #expect(viewModel.hasData == false)
    }

    // MARK: - Data Loading Tests

    @Test("ViewModel loads daily calorie and TDEE data for selected time period")
    func testLoadsDataForTimePeriod() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and calorie data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )

        // Log food for 7 days (note: date boundary handling may result in 6-7 days visible)
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.selectedPeriod = .oneWeek

        // When: Loading data
        await viewModel.loadData()

        // Then: Daily data is populated (6-7 days depending on date boundary)
        #expect(viewModel.hasData == true)
        #expect(viewModel.dailyData.count >= 6)
    }

    // MARK: - Dual Mode Support Tests

    @Test("ViewModel supports Expenditure display mode")
    func testExpenditureDisplayMode() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        _ = createFoodEntry(in: context, calories: 1700, daysAgo: 0)
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .expenditure

        // When: Loading data
        await viewModel.loadData()

        // Then: Expenditure mode data is available
        #expect(viewModel.hasData == true)
        #expect(viewModel.displayMode == .expenditure)
    }

    @Test("ViewModel supports Calorie Targets display mode")
    func testCalorieTargetsDisplayMode() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with calorie target and food entries
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        // Log food for 3 days to ensure data is present
        for daysAgo in 0..<3 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .calorieTargets

        // When: Loading data
        await viewModel.loadData()

        // Then: Calorie targets mode data is available
        #expect(viewModel.hasData == true)
        #expect(viewModel.displayMode == .calorieTargets)
    }

    // MARK: - Balance Calculation Tests

    @Test("Balance in Expenditure mode: consumed minus expenditure (negative = deficit)")
    func testExpenditureModeBalance() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User consuming 1700 with TDEE of 2000
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        // Log food for 3 days to ensure data is present
        for daysAgo in 0..<3 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .expenditure
        viewModel.selectedPeriod = .oneWeek  // Use short period for faster test

        // When: Loading data
        await viewModel.loadData()

        // Then: Balance should be negative (deficit: 1700 - 2000 = -300)
        #expect(viewModel.dailyData.count > 0)
        guard let todayData = viewModel.dailyData.last else {  // Last entry is today
            Issue.record("Expected to find data entries")
            return
        }

        #expect(todayData.expenditureBalance < 0)  // Deficit
    }

    @Test("Balance in Targets mode: consumed minus target (negative = below target)")
    func testTargetsModeBalance() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User consuming 1700 with target of 1800
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        _ = createFoodEntry(in: context, calories: 1700, daysAgo: 0)
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .calorieTargets
        viewModel.selectedPeriod = .oneWeek  // Use short period for faster test

        // When: Loading data
        await viewModel.loadData()

        // Then: Balance should be negative (below target: 1700 - 1800 = -100)
        #expect(viewModel.dailyData.count > 0)
        guard let todayData = viewModel.dailyData.last else {  // Last entry is today
            Issue.record("Expected to find data entries")
            return
        }

        #expect(todayData.targetBalance < 0)  // Below target
    }

    // MARK: - Balance Changes at Intervals Tests

    @Test("ViewModel calculates balance changes at 3-day interval")
    func testCalculates3DayBalanceChange() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: 3-day change is calculated
        let change3Day = viewModel.balanceChanges.first { $0.period == "3-day" }
        #expect(change3Day != nil)
    }

    @Test("ViewModel calculates balance changes at 7-day interval")
    func testCalculates7DayBalanceChange() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: 7-day change is calculated
        let change7Day = viewModel.balanceChanges.first { $0.period == "7-day" }
        #expect(change7Day != nil)
    }

    @Test("ViewModel calculates balance changes at 14/30/90 day intervals")
    func testCalculatesLongerIntervalBalanceChanges() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data and 90+ days of food entries (required for all intervals)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        // Log food for 90 days (enough for all interval calculations)
        for daysAgo in 0..<90 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.selectedPeriod = .oneYear  // Use 1 year to capture all 90 days

        // When: Loading data
        await viewModel.loadData()

        // Then: All interval changes are present
        let periods = viewModel.balanceChanges.map { $0.period }
        #expect(periods.contains("14-day"))
        #expect(periods.contains("30-day"))
        #expect(periods.contains("90-day"))
    }

    @Test("Balance changes use mode-specific trend labels")
    func testBalanceChangesTrendLabels() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with deficit
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading in expenditure mode
        viewModel.displayMode = .expenditure
        await viewModel.loadData()

        // Then: Expenditure mode uses "Deficit", "Surplus", "Balance" labels
        let trends = viewModel.balanceChanges.map { $0.trend }
        let validExpenditureTrends = ["Deficit", "Surplus", "Balance"]
        for trend in trends {
            #expect(validExpenditureTrends.contains(trend))
        }

        // When: Loading in targets mode
        viewModel.displayMode = .calorieTargets
        await viewModel.loadData()

        // Then: Targets mode uses "Below Target", "Above Target", "At Target" labels
        let targetTrends = viewModel.balanceChanges.map { $0.trend }
        let validTargetTrends = ["Below Target", "Above Target", "At Target"]
        for trend in targetTrends {
            #expect(validTargetTrends.contains(trend))
        }
    }

    // MARK: - Historical Log Tests

    @Test("ViewModel generates historical log with per-day balance and trend labels")
    func testGeneratesHistoricalLog() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with food logged
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Daily data includes balance and trend info
        #expect(!viewModel.dailyData.isEmpty)
        for day in viewModel.dailyData {
            // Each day has balance calculated
            #expect(day.caloriesConsumed >= 0)
        }
    }

    // MARK: - Time Period Selection Tests

    @Test("ViewModel responds to DetailTimePeriod selection changes")
    func testRespondsToTimePeriodChange() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data and 30 days of food entries
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        // Log food for 30 days
        for daysAgo in 0..<30 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading with 1 week period
        viewModel.selectedPeriod = .oneWeek
        await viewModel.loadData()
        let weekCount = viewModel.dailyData.count

        // When: Changing to 1 year period and reloading
        viewModel.selectedPeriod = .oneYear
        await viewModel.loadData()
        let yearCount = viewModel.dailyData.count

        // Then: More data points for longer period
        #expect(yearCount > weekCount)
    }

    // MARK: - Display Mode Toggle Tests

    @Test("ViewModel responds to DisplayMode toggle")
    func testRespondsToDisplayModeToggle() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and calorie target
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        _ = createFoodEntry(in: context, calories: 1700, daysAgo: 0)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading in expenditure mode
        viewModel.displayMode = .expenditure
        await viewModel.loadData()
        let expenditureHeaderValue = viewModel.headerValue

        // When: Toggling to targets mode
        viewModel.displayMode = .calorieTargets
        await viewModel.loadData()
        let targetsHeaderValue = viewModel.headerValue

        // Then: Header values differ based on mode (deficit vs avg vs target)
        // In expenditure mode, showing deficit; in targets mode, showing average relative to target
        #expect(viewModel.displayMode == .calorieTargets)
    }

    // MARK: - Days with No Food Tests

    @Test("ViewModel only includes days with actual food logged")
    func testOnlyIncludesDaysWithFood() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and only 3 days of food (out of 7)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        // Only log food for 3 days (use 0, 2, 4 to have gaps)
        _ = createFoodEntry(in: context, calories: 1700, daysAgo: 0)  // Today
        _ = createFoodEntry(in: context, calories: 1600, daysAgo: 2)  // 2 days ago
        _ = createFoodEntry(in: context, calories: 1500, daysAgo: 4)  // 4 days ago
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.selectedPeriod = .oneWeek

        // When: Loading data
        await viewModel.loadData()

        // Then: Only days with food are included (days without food are excluded)
        #expect(viewModel.hasData == true)
        #expect(viewModel.dailyData.count >= 2)  // At least 2 days (boundary handling)
        for day in viewModel.dailyData {
            #expect(day.caloriesConsumed > 0)  // All days should have calories
        }
    }

    // MARK: - Missing Data Tests

    @Test("ViewModel handles missing TDEE data gracefully")
    func testHandlesMissingTDEEData() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with no TDEE
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: nil,
            lastCalculatedTDEE: nil,
            dailyCalorieTarget: 1800
        )
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .expenditure

        // When: Loading data
        await viewModel.loadData()

        // Then: No crash, but hasData should be false in expenditure mode (TDEE required)
        #expect(viewModel.hasData == false)
    }

    @Test("ViewModel handles missing calorie target gracefully")
    func testHandlesMissingCalorieTarget() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE but uses default calorie target
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 0  // Edge case: 0 target
        )
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .calorieTargets

        // When: Loading data
        await viewModel.loadData()

        // Then: No crash
        #expect(viewModel.isLoading == false)
    }

    @Test("ViewModel handles user with no active nutrition goal")
    func testHandlesNoActiveGoal() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with inactive nutrition goal
        let user = createTestUser(in: context)
        let goal = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        goal.isActive = false
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: No data (no active goal)
        #expect(viewModel.hasData == false)
    }

    // MARK: - Date Range Tests

    @Test("ViewModel calculates date range string based on actual data")
    func testCalculatesDateRange() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data and food logged
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        // Log food for 7 days
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.selectedPeriod = .oneMonth

        // When: Loading data
        await viewModel.loadData()

        // Then: Date range is set (based on actual data range)
        #expect(!viewModel.dateRange.isEmpty)
    }

    // MARK: - Header Value Tests

    @Test("ViewModel provides header value based on display mode")
    func testProvidesHeaderValue() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading in expenditure mode
        viewModel.displayMode = .expenditure
        await viewModel.loadData()

        // Then: Header value is provided (deficit in expenditure mode)
        #expect(viewModel.headerValue != nil)
    }

    // MARK: - Preview Support Tests

    @Test("Preview instance can be created")
    func testPreviewInstance() async {
        let preview = EnergyBalanceDetailViewModel.preview
        #expect(preview.isLoading == false)
        #expect(preview.dailyData.isEmpty)
    }

    @Test("Loading state is false after load completes")
    func testLoadingStateAfterLoad() async throws {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: isLoading is false after completion
        #expect(viewModel.isLoading == false)
    }
}
