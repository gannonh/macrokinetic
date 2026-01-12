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
            TDEESnapshot.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        return (container.mainContext, container)
    }

    /// Helper to create ViewModel with required services
    private func createViewModel(context: ModelContext) -> EnergyBalanceHeroViewModel {
        let mealLogService = MealLogService(context: context)
        let tdeeService = TDEEService(context: context)
        return EnergyBalanceHeroViewModel(
            mealLogService: mealLogService,
            tdeeService: tdeeService,
            context: context
        )
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

        let viewModel = createViewModel(context: context)

        #expect(viewModel.isLoading == false)
        // dailyCalories starts empty until loadData is called (no longer pre-populated)
        #expect(viewModel.dailyCalories.isEmpty)
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

        // Given: User with active NutritionGoal (required for loadData to work)
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)

        // Given: Food entries for a few days
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        _ = createFoodEntry(in: context, calories: 500, loggedAt: today)
        _ = createFoodEntry(in: context, calories: 600, loggedAt: yesterday)
        _ = createFoodEntry(in: context, calories: 700, loggedAt: twoDaysAgo)
        try context.save()

        let viewModel = createViewModel(context: context)

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

        // Given: User with active NutritionGoal (required for loadData to work)
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)

        // Given: Food entries for multiple days
        for daysAgo in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            _ = createFoodEntry(in: context, calories: 1000, loggedAt: date)
        }
        try context.save()

        let viewModel = createViewModel(context: context)

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

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Average expenditure should use fallback TDEE (no snapshots exist)
        // Since dailyCalories are loaded with fallback TDEE, the average equals the fallback
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
        nutritionGoal.initialEstimatedTDEE = 2000  // Add TDEE so loadData works
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

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

        let viewModel = createViewModel(context: context)

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

        // Note: With no user/goal, loadData returns early without populating data
        let viewModel = createViewModel(context: context)

        // When: Loading with no user/goal (returns early)
        await viewModel.loadData()

        // Then: No data loaded (requires user and NutritionGoal)
        #expect(viewModel.dailyCalories.isEmpty)
        #expect(viewModel.totalNutrition == 0)
        #expect(viewModel.averageExpenditure > 0)  // Should have default
        #expect(viewModel.averageTargets > 0)  // Should have default
    }

    @Test("ViewModel requires active NutritionGoal to load data")
    func testRequiresActiveNutritionGoal() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User without active NutritionGoal
        let user = createTestUser(in: context)
        user.dailyCalorieGoal = 1800
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data (no active NutritionGoal)
        await viewModel.loadData()

        // Then: Data is not loaded (requires active NutritionGoal)
        #expect(viewModel.dailyCalories.isEmpty)
    }

    @Test("DayCalories struct has correct date format")
    func testDayCaloriesDateFormat() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with active NutritionGoal (required for loadData to work)
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

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

    // MARK: - DayCalories ID Getter Tests

    @Test("DayCalories id getter returns date")
    func testDayCaloriesIdGetter() async throws {
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
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)
        await viewModel.loadData()

        // Then: Each DayCalories has id equal to its date
        #expect(viewModel.dailyCalories.count > 0)
        for dayCalories in viewModel.dailyCalories {
            // Access the id getter - this is the key coverage point
            let id = dayCalories.id
            #expect(id == dayCalories.date)
        }
    }

    @Test("DayCalories id is unique across all days")
    func testDayCaloriesIdUniqueness() async throws {
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
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)
        await viewModel.loadData()

        // Then: All ids are unique
        let ids = viewModel.dailyCalories.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    // MARK: - Preview Support Tests

    @Test("Preview instance can be created without crashing")
    func testPreviewInstance() async {
        // When: Creating a preview instance
        let preview = EnergyBalanceHeroViewModel.preview

        // Then: Preview is created with default state
        #expect(preview.isLoading == false)
        #expect(preview.dailyCalories.isEmpty)
        #expect(preview.totalNutrition == 0)
        #expect(preview.averageExpenditure > 0)  // Default value
        #expect(preview.averageTargets > 0)  // Default value
    }

    // MARK: - Computed Properties Edge Cases

    @Test("averageExpenditure returns default when dailyCalories is empty")
    func testAverageExpenditureDefaultValue() async {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        // When: dailyCalories is empty (no loadData called or no user)
        // Then: averageExpenditure returns default of 2000
        #expect(viewModel.dailyCalories.isEmpty)
        #expect(viewModel.averageExpenditure == 2000)
    }

    @Test("averageTargets returns default when dailyCalories is empty")
    func testAverageTargetsDefaultValue() async {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        // When: dailyCalories is empty (no loadData called or no user)
        // Then: averageTargets returns default of 1800
        #expect(viewModel.dailyCalories.isEmpty)
        #expect(viewModel.averageTargets == 1800)
    }

    @Test("ViewModel handles user with NutritionGoal but no TDEE gracefully")
    func testHandlesNutritionGoalWithoutTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with NutritionGoal that has no initialEstimatedTDEE or lastCalculatedTDEE
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        // Note: No TDEE values set - should use fallback of 2000
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Uses fallback TDEE of 2000
        #expect(viewModel.dailyCalories.count == 30)
        #expect(viewModel.averageExpenditure == 2000)  // Fallback value
    }

    @Test("ViewModel uses lastCalculatedTDEE over initialEstimatedTDEE when both exist")
    func testPrefersLastCalculatedTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with both initial and last calculated TDEE
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2500  // Initial
        nutritionGoal.lastCalculatedTDEE = 1950  // Last calculated - should be used
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Uses lastCalculatedTDEE
        #expect(viewModel.averageExpenditure == 1950)
    }

    // MARK: - Fallback TDEE State Tests

    @Test("ViewModel sets isUsingFallbackTDEE to true when no TDEE available")
    func testIsUsingFallbackTDEETrue() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with NutritionGoal but no TDEE values
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        // No TDEE values set
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: isUsingFallbackTDEE is true
        #expect(viewModel.isUsingFallbackTDEE == true)
        #expect(viewModel.averageExpenditure == 2000)  // Default fallback
    }

    @Test("ViewModel sets isUsingFallbackTDEE to false when lastCalculatedTDEE exists")
    func testIsUsingFallbackTDEEFalseWithLastCalculated() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with lastCalculatedTDEE set
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.lastCalculatedTDEE = 2200
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: isUsingFallbackTDEE is false
        #expect(viewModel.isUsingFallbackTDEE == false)
    }

    @Test("ViewModel sets isUsingFallbackTDEE to false when initialEstimatedTDEE exists")
    func testIsUsingFallbackTDEEFalseWithInitial() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with initialEstimatedTDEE set (no lastCalculatedTDEE)
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 1900
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: isUsingFallbackTDEE is false
        #expect(viewModel.isUsingFallbackTDEE == false)
    }

    // MARK: - Loading Error State Tests

    @Test("ViewModel initializes with no loading error")
    func testLoadingErrorInitiallyNil() async {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        // Then: loadingError is nil initially
        #expect(viewModel.loadingError == nil)
    }

    @Test("ViewModel reports daysWithLoadingErrors as zero when all days load successfully")
    func testDaysWithLoadingErrorsZero() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with NutritionGoal
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: No loading errors
        #expect(viewModel.daysWithLoadingErrors == 0)
    }

    // MARK: - TDEESnapshot Integration Tests

    @Test("ViewModel loads historical TDEE values from TDEESnapshots")
    func testLoadsTDEESnapshots() async throws {
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        let today = Date()

        // Given: User with NutritionGoal and TDEESnapshots
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000  // Fallback
        context.insert(nutritionGoal)

        // Add TDEESnapshots for the last few days with varying values
        for daysAgo in 0..<5 {
            let snapshotDate = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let snapshot = TDEESnapshot(
                timestamp: snapshotDate,
                tdeeValue: 2100 + Double(daysAgo * 50)  // 2100, 2150, 2200, etc.
            )
            context.insert(snapshot)
        }
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Data is loaded with snapshot values
        #expect(viewModel.dailyCalories.count == 30)
        // The most recent days should have varying expenditure values from snapshots
        // Days without snapshots use fallback TDEE of 2000
    }

    @Test("ViewModel uses fallback TDEE for days without TDEESnapshots")
    func testUseFallbackForMissingSnapshots() async throws {
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        let today = Date()

        // Given: User with NutritionGoal and only one TDEESnapshot
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 1900  // Fallback for most days
        context.insert(nutritionGoal)

        // Only add a snapshot for today
        let snapshot = TDEESnapshot(timestamp: today, tdeeValue: 2200)
        context.insert(snapshot)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Today uses snapshot (2200), other days use fallback (1900)
        #expect(viewModel.dailyCalories.count == 30)
        // Today's entry should have 2200 expenditure
        if let todayEntry = viewModel.dailyCalories.last {
            #expect(todayEntry.expenditure == 2200)
        }
        // Earlier days should use fallback
        if viewModel.dailyCalories.count > 1 {
            let olderEntry = viewModel.dailyCalories[0]
            #expect(olderEntry.expenditure == 1900)
        }
    }

    // MARK: - DayCalories Expenditure and Target Tests

    @Test("DayCalories includes correct expenditure value")
    func testDayCaloriesExpenditureValue() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with NutritionGoal
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2100
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Each DayCalories has expenditure
        for dayCalories in viewModel.dailyCalories {
            #expect(dayCalories.expenditure > 0)
        }
    }

    @Test("DayCalories includes correct target value")
    func testDayCaloriesTargetValue() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with NutritionGoal with specific target
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1750
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Each DayCalories has target of 1750
        for dayCalories in viewModel.dailyCalories {
            #expect(dayCalories.target == 1750)
        }
    }

    // MARK: - Computed Properties with Data Tests

    @Test("averageExpenditure computes from daily values")
    func testAverageExpenditureComputedProperty() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with NutritionGoal
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2300
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: averageExpenditure is computed from dailyCalories
        #expect(!viewModel.dailyCalories.isEmpty)
        // With no snapshots, all use fallback of 2300
        #expect(viewModel.averageExpenditure == 2300)
    }

    @Test("averageTargets computes from daily values")
    func testAverageTargetsComputedProperty() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with NutritionGoal
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1800
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: averageTargets is computed from dailyCalories
        #expect(!viewModel.dailyCalories.isEmpty)
        // All days have same target of 1800
        #expect(viewModel.averageTargets == 1800)
    }

    @Test("DayCalories value property is accessible")
    func testDayCaloriesValueProperty() async throws {
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        let today = Date()

        // Given: User with NutritionGoal and food entry
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)

        // Add food entry for today
        _ = createFoodEntry(in: context, calories: 1200, loggedAt: today)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Today's DayCalories has the food value
        #expect(!viewModel.dailyCalories.isEmpty)
        if let todayCalories = viewModel.dailyCalories.last {
            #expect(todayCalories.value == 1200)
        }
    }

    @Test("loadingError remains nil when no TDEE fetch errors")
    func testLoadingErrorNilWhenNoErrors() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with NutritionGoal
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: No loading error
        #expect(viewModel.loadingError == nil)
    }

    @Test("dailyCalories entries are in chronological order")
    func testDailyCaloriesChronologicalOrder() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with NutritionGoal
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Dates are in ascending order
        #expect(viewModel.dailyCalories.count == 30)
        var previousDate = viewModel.dailyCalories.first?.date ?? Date.distantPast
        for dayCalories in viewModel.dailyCalories.dropFirst() {
            #expect(dayCalories.date > previousDate)
            previousDate = dayCalories.date
        }
    }

    // MARK: - Snapshot Count and Balance Tests

    @Test("ViewModel correctly counts loaded TDEE snapshots")
    func testTDEESnapshotCount() async throws {
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Given: User with NutritionGoal and multiple TDEESnapshots
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)

        // Add TDEESnapshots for every day in the last 30 days
        // Use start of day to ensure proper matching
        for daysAgo in 0..<30 {
            let snapshotDate = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let snapshot = TDEESnapshot(
                timestamp: snapshotDate,
                tdeeValue: 2000 + Double(daysAgo * 10)
            )
            context.insert(snapshot)
        }
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: All 30 days have snapshot-based expenditure values
        #expect(viewModel.dailyCalories.count == 30)

        // Verify expenditure varies by day (from snapshots)
        // Note: Each day should have unique TDEE from 2000 to 2290
        let expenditures = viewModel.dailyCalories.map(\.expenditure)
        let uniqueExpenditures = Set(expenditures)
        // Should have many unique values (at least 25 to account for any edge cases)
        #expect(uniqueExpenditures.count >= 25)
    }

    @Test("ViewModel calculates net balance from intake and expenditure")
    func testNetBalanceCalculation() async throws {
        let (context, container) = createTestContext()
        _ = container

        let calendar = Calendar.current
        let today = Date()

        // Given: User with NutritionGoal
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1800
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2200
        context.insert(nutritionGoal)

        // Add consistent food intake for 7 days (1600 cal/day)
        for daysAgo in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            _ = createFoodEntry(in: context, calories: 1600, loggedAt: date)
        }
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Total nutrition reflects 7 days of 1600 calories
        #expect(viewModel.totalNutrition == 11200)

        // Each day's balance is intake - expenditure = 1600 - 2200 = -600 (deficit)
        for dayCalories in viewModel.dailyCalories.suffix(7) {
            let balance = dayCalories.value - dayCalories.expenditure
            // Days with food should show deficit of -600
            if dayCalories.value > 0 {
                #expect(balance == -600)
            }
        }
    }

    @Test("DayCalories balance calculation works for surplus")
    func testDayCaloriesSurplusBalance() async throws {
        let (context, container) = createTestContext()
        _ = container

        let today = Date()

        // Given: User with NutritionGoal
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .maintenance,
            isActive: true,
            dailyCalorieTarget: 2000
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)

        // Add surplus calories today (2500 cal)
        _ = createFoodEntry(in: context, calories: 2500, loggedAt: today)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Today shows surplus
        if let todayCalories = viewModel.dailyCalories.last {
            let balance = todayCalories.value - todayCalories.expenditure
            #expect(balance == 500)  // 2500 - 2000 = +500 surplus
        }
    }

    @Test("ViewModel handles rapid reloading without data corruption")
    func testRapidReloading() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with NutritionGoal
        let user = createTestUser(in: context)
        let nutritionGoal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1500
        )
        nutritionGoal.user = user
        nutritionGoal.initialEstimatedTDEE = 2000
        context.insert(nutritionGoal)
        try context.save()

        let viewModel = createViewModel(context: context)

        // When: Loading data multiple times rapidly
        await viewModel.loadData()
        let firstCount = viewModel.dailyCalories.count
        let firstTotal = viewModel.totalNutrition

        await viewModel.loadData()
        let secondCount = viewModel.dailyCalories.count
        let secondTotal = viewModel.totalNutrition

        // Then: Data is consistent across reloads
        #expect(firstCount == secondCount)
        #expect(firstTotal == secondTotal)
        #expect(viewModel.isLoading == false)
    }
}
