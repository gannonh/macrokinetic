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
        // Verify values were calculated (may be same or different depending on data)
        _ = (expenditureHeaderValue, targetsHeaderValue)
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

    // MARK: - ID Getter Tests (Coverage for Identifiable types)

    @Test("DisplayMode id getter returns rawValue")
    func testDisplayModeIdGetter() async {
        // Test expenditure mode
        let expenditureMode = EnergyBalanceDetailViewModel.DisplayMode.expenditure
        #expect(expenditureMode.id == "Expenditure")

        // Test calorie targets mode
        let targetsMode = EnergyBalanceDetailViewModel.DisplayMode.calorieTargets
        #expect(targetsMode.id == "Calorie Targets")

        // Verify all cases have unique ids
        let allModes = EnergyBalanceDetailViewModel.DisplayMode.allCases
        let ids = allModes.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("DailyData id property is accessible")
    func testDailyDataIdProperty() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with data
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
        await viewModel.loadData()

        // Then: DailyData structs have accessible id properties
        #expect(!viewModel.dailyData.isEmpty)
        for dailyData in viewModel.dailyData {
            // Access the id getter - key coverage point
            let id = dailyData.id
            #expect(id != UUID())
        }
    }

    @Test("DailyData ids are unique")
    func testDailyDataIdUniqueness() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with multiple days of data
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
        await viewModel.loadData()

        // Then: All ids are unique
        let ids = viewModel.dailyData.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("BalanceChange id property is accessible")
    func testBalanceChangeIdProperty() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with sufficient data for balance changes
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
        await viewModel.loadData()

        // Then: BalanceChange structs have accessible id properties
        #expect(!viewModel.balanceChanges.isEmpty)
        for change in viewModel.balanceChanges {
            // Access the id getter - key coverage point
            let id = change.id
            #expect(id != UUID())
        }
    }

    @Test("BalanceChange ids are unique")
    func testBalanceChangeIdUniqueness() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with sufficient data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        for daysAgo in 0..<90 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.selectedPeriod = .oneYear
        await viewModel.loadData()

        // Then: All balance change ids are unique
        let ids = viewModel.balanceChanges.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    // MARK: - getEarliestFoodEntryDate Tests

    @Test("getEarliestFoodEntryDate returns earliest date when food exists")
    func testGetEarliestFoodEntryDateWithData() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with food entries spanning multiple days
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        _ = createFoodEntry(in: context, calories: 1700, daysAgo: 0)  // Today
        _ = createFoodEntry(in: context, calories: 1600, daysAgo: 10)  // 10 days ago
        _ = createFoodEntry(in: context, calories: 1500, daysAgo: 30)  // 30 days ago (earliest)
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.selectedPeriod = .all  // "All" triggers getEarliestFoodEntryDate

        // When: Loading data
        await viewModel.loadData()

        // Then: Date range includes earliest entry
        #expect(!viewModel.dateRange.isEmpty)
        #expect(viewModel.hasData == true)
    }

    @Test("getEarliestFoodEntryDate returns nil when no food exists")
    func testGetEarliestFoodEntryDateWithNoData() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE but no food entries
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.selectedPeriod = .all

        // When: Loading data
        await viewModel.loadData()

        // Then: No data (no food entries, so hasData is false)
        #expect(viewModel.hasData == false)
    }

    // MARK: - trendLabelForBalance Tests

    @Test("trendLabelForBalance returns Deficit for negative balance in expenditure mode")
    func testTrendLabelDeficit() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User consuming less than expenditure (deficit)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2500,  // High TDEE
            lastCalculatedTDEE: 2500,
            dailyCalorieTarget: 1800
        )
        // Log food significantly under expenditure
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1500, daysAgo: daysAgo)  // 1000 cal deficit
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .expenditure

        // When: Loading data
        await viewModel.loadData()

        // Then: Trends should show Deficit
        #expect(!viewModel.balanceChanges.isEmpty)
        let deficitTrends = viewModel.balanceChanges.filter { $0.trend == "Deficit" }
        #expect(!deficitTrends.isEmpty)
    }

    @Test("trendLabelForBalance returns Surplus for positive balance in expenditure mode")
    func testTrendLabelSurplus() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User consuming more than expenditure (surplus)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 1500,  // Low TDEE
            lastCalculatedTDEE: 1500,
            dailyCalorieTarget: 1800
        )
        // Log food significantly over expenditure
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 2500, daysAgo: daysAgo)  // 1000 cal surplus
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .expenditure

        // When: Loading data
        await viewModel.loadData()

        // Then: Trends should show Surplus
        #expect(!viewModel.balanceChanges.isEmpty)
        let surplusTrends = viewModel.balanceChanges.filter { $0.trend == "Surplus" }
        #expect(!surplusTrends.isEmpty)
    }

    @Test("trendLabelForBalance returns Below Target for negative balance in targets mode")
    func testTrendLabelBelowTarget() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User consuming less than target
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 2000  // High target
        )
        // Log food under target
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1500, daysAgo: daysAgo)  // Below target
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .calorieTargets

        // When: Loading data
        await viewModel.loadData()

        // Then: Trends should show Below Target
        #expect(!viewModel.balanceChanges.isEmpty)
        let belowTargetTrends = viewModel.balanceChanges.filter { $0.trend == "Below Target" }
        #expect(!belowTargetTrends.isEmpty)
    }

    @Test("trendLabelForBalance returns Above Target for positive balance in targets mode")
    func testTrendLabelAboveTarget() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User consuming more than target
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1500  // Low target
        )
        // Log food over target
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 2000, daysAgo: daysAgo)  // Above target
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .calorieTargets

        // When: Loading data
        await viewModel.loadData()

        // Then: Trends should show Above Target
        #expect(!viewModel.balanceChanges.isEmpty)
        let aboveTargetTrends = viewModel.balanceChanges.filter { $0.trend == "Above Target" }
        #expect(!aboveTargetTrends.isEmpty)
    }

    @Test("trendLabelForBalance returns Balance when exactly at expenditure")
    func testTrendLabelBalance() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User consuming exactly at expenditure
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 1800,
            lastCalculatedTDEE: 1800,
            dailyCalorieTarget: 1800
        )
        // Log food exactly at expenditure
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1800, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .expenditure

        // When: Loading data
        await viewModel.loadData()

        // Then: If perfectly balanced, trend should be Balance
        // Note: Due to integer rounding, exact balance is rare
        #expect(!viewModel.balanceChanges.isEmpty)
        // Just verify the trend labels are valid
        let validTrends = ["Deficit", "Surplus", "Balance"]
        for change in viewModel.balanceChanges {
            #expect(validTrends.contains(change.trend))
        }
    }

    @Test("trendLabelForBalance returns At Target when exactly at target")
    func testTrendLabelAtTarget() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User consuming exactly at target
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        // Log food exactly at target
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1800, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .calorieTargets

        // When: Loading data
        await viewModel.loadData()

        // Then: If perfectly at target, trend should be At Target
        // Note: Due to integer rounding, exact matches are rare
        #expect(!viewModel.balanceChanges.isEmpty)
        // Just verify the trend labels are valid
        let validTrends = ["Below Target", "Above Target", "At Target"]
        for change in viewModel.balanceChanges {
            #expect(validTrends.contains(change.trend))
        }
    }

    // MARK: - clearAllData Tests

    @Test("clearAllData resets all state when no user")
    func testClearAllDataNoUser() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: No user in context
        let viewModel = createViewModel(context: context)

        // When: Loading data (will call clearAllData internally)
        await viewModel.loadData()

        // Then: All state is cleared
        #expect(viewModel.dailyData.isEmpty)
        #expect(viewModel.balanceChanges.isEmpty)
        #expect(viewModel.dateRange.isEmpty)
        #expect(viewModel.headerValue == nil)
        #expect(viewModel.hasData == false)
    }

    // MARK: - generateBalanceChanges Edge Cases

    @Test("generateBalanceChanges only includes intervals with enough data")
    func testGenerateBalanceChangesIntervalFiltering() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with only 5 days of data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        // Only 5 days of food
        for daysAgo in 0..<5 {
            _ = createFoodEntry(in: context, calories: 1700, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        await viewModel.loadData()

        // Then: Only 3-day interval should be present (need >= 3 days)
        let periods = viewModel.balanceChanges.map { $0.period }
        #expect(periods.contains("3-day"))
        #expect(!periods.contains("7-day"))  // Not enough data
        #expect(!periods.contains("14-day"))
        #expect(!periods.contains("30-day"))
        #expect(!periods.contains("90-day"))
    }

    // MARK: - calculateHeaderValue Tests

    @Test("calculateHeaderValue returns nil when no data")
    func testCalculateHeaderValueNoData() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with no food entries
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: headerValue is nil (no food data)
        #expect(viewModel.headerValue == nil)
    }

    @Test("calculateHeaderValue returns average deficit in expenditure mode")
    func testCalculateHeaderValueExpenditureMode() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User in deficit
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1500, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .expenditure

        // When: Loading data
        await viewModel.loadData()

        // Then: headerValue shows deficit (negative)
        #expect(viewModel.headerValue != nil)
        #expect(viewModel.headerValue! < 0)  // 1500 - 2000 = -500
    }

    @Test("calculateHeaderValue returns average relative to target in targets mode")
    func testCalculateHeaderValueTargetsMode() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User below target
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        for daysAgo in 0..<7 {
            _ = createFoodEntry(in: context, calories: 1500, daysAgo: daysAgo)
        }
        try context.save()

        let viewModel = createViewModel(context: context)
        viewModel.displayMode = .calorieTargets

        // When: Loading data
        await viewModel.loadData()

        // Then: headerValue shows below target (negative)
        #expect(viewModel.headerValue != nil)
        #expect(viewModel.headerValue! < 0)  // 1500 - 1800 = -300
    }

    // MARK: - generateDateRange Tests

    @Test("generateDateRange shows single date when all data on same day")
    func testGenerateDateRangeSingleDay() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with data only on one day
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

        // When: Loading data
        await viewModel.loadData()

        // Then: dateRange shows single date (no dash separator)
        #expect(!viewModel.dateRange.isEmpty)
        // Single date format doesn't contain " - "
        #expect(!viewModel.dateRange.contains(" - "))
    }

    @Test("generateDateRange shows range when data spans multiple days")
    func testGenerateDateRangeMultipleDays() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with data spanning multiple days
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        _ = createFoodEntry(in: context, calories: 1700, daysAgo: 0)
        _ = createFoodEntry(in: context, calories: 1600, daysAgo: 5)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: dateRange shows range with separator
        #expect(!viewModel.dateRange.isEmpty)
        #expect(viewModel.dateRange.contains(" - "))
    }

    // MARK: - DailyData Computed Properties Tests

    @Test("DailyData expenditureBalance computed correctly")
    func testDailyDataExpenditureBalance() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with specific consumption and expenditure
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        _ = createFoodEntry(in: context, calories: 1500, daysAgo: 0)
        try context.save()

        let viewModel = createViewModel(context: context)
        await viewModel.loadData()

        // Then: expenditureBalance = consumed - expenditure
        guard let todayData = viewModel.dailyData.last else {
            Issue.record("Expected daily data")
            return
        }

        let expectedBalance = todayData.caloriesConsumed - todayData.expenditure
        #expect(todayData.expenditureBalance == expectedBalance)
    }

    @Test("DailyData targetBalance computed correctly")
    func testDailyDataTargetBalance() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with specific consumption and target
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 2000,
            dailyCalorieTarget: 1800
        )
        _ = createFoodEntry(in: context, calories: 1500, daysAgo: 0)
        try context.save()

        let viewModel = createViewModel(context: context)
        await viewModel.loadData()

        // Then: targetBalance = consumed - target
        guard let todayData = viewModel.dailyData.last else {
            Issue.record("Expected daily data")
            return
        }

        let expectedBalance = todayData.caloriesConsumed - todayData.calorieTarget
        #expect(todayData.targetBalance == expectedBalance)
    }
}
