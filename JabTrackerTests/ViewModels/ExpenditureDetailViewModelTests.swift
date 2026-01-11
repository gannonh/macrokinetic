//
//  ExpenditureDetailViewModelTests.swift
//  JabTrackerTests
//
//  Tests for ExpenditureDetailViewModel - expenditure detail view data source
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("ExpenditureDetailViewModel Tests")
@MainActor
struct ExpenditureDetailViewModelTests {

    // MARK: - Test Helpers

    private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([
            User.self, NutritionGoal.self, NutritionProgram.self, WeightEntry.self, FoodEntry.self,
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
        lastTDEECalculationDate: Date? = nil
    ) -> NutritionGoal {
        let goal = NutritionGoal()
        goal.initialEstimatedTDEE = initialTDEE
        goal.lastCalculatedTDEE = lastCalculatedTDEE
        goal.lastTDEECalculationDate = lastTDEECalculationDate
        goal.isActive = true
        goal.user = user
        context.insert(goal)
        user.nutritionGoals = [goal]
        return goal
    }

    private func createWeightEntry(
        in context: ModelContext,
        weightKg: Double,
        daysAgo: Int = 0
    ) -> WeightEntry {
        let timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        let entry = WeightEntry(
            timestamp: timestamp,
            weightKg: weightKg
        )
        context.insert(entry)
        return entry
    }

    private func createFoodEntry(
        in context: ModelContext,
        calories: Double,
        daysAgo: Int = 0
    ) -> FoodEntry {
        let loggedAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        let entry = FoodEntry(
            foodName: "Test Food",
            loggedAt: loggedAt,
            servingGrams: 100,
            caloriesPer100g: calories,
            proteinPer100g: 20,
            carbsPer100g: 30,
            fatPer100g: 10
        )
        context.insert(entry)
        return entry
    }

    // MARK: - Initial State Tests

    @Test("ViewModel initializes with loading state and empty data")
    func testInitialState() async {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = ExpenditureDetailViewModel(context: context)

        #expect(viewModel.isLoading == false)
        #expect(viewModel.dailyData.isEmpty)
        #expect(viewModel.hasData == false)
    }

    // MARK: - Data Loading Tests

    @Test("ViewModel loads TDEE data from active NutritionGoal")
    func testLoadsDataFromNutritionGoal() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with active nutrition goal and TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: TDEE data is available
        #expect(viewModel.hasData == true)
        #expect(viewModel.currentExpenditure != nil)
        #expect(viewModel.currentExpenditure == 1893)
    }

    @Test("ViewModel uses initialEstimatedTDEE when lastCalculatedTDEE is nil")
    func testFallsBackToInitialTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with only initial TDEE estimate
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2100,
            lastCalculatedTDEE: nil,
            lastTDEECalculationDate: nil
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Falls back to initial TDEE
        #expect(viewModel.currentExpenditure == 2100)
    }

    // MARK: - TDEE Average Calculation Tests

    @Test("ViewModel calculates average TDEE over selected time period")
    func testCalculatesAverageTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Average expenditure is calculated
        #expect(viewModel.averageExpenditure != nil)
        // Since we only have one TDEE value, average equals current
        #expect(viewModel.averageExpenditure == viewModel.currentExpenditure)
    }

    // MARK: - TDEE Change Interval Tests

    @Test("ViewModel calculates TDEE changes at 3-day interval")
    func testCalculates3DayChange() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: 3-day change is calculated
        let change3Day = viewModel.expenditureChanges.first { $0.period == "3-day" }
        #expect(change3Day != nil)
    }

    @Test("ViewModel calculates TDEE changes at 7-day interval")
    func testCalculates7DayChange() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: 7-day change is calculated
        let change7Day = viewModel.expenditureChanges.first { $0.period == "7-day" }
        #expect(change7Day != nil)
    }

    @Test("ViewModel calculates TDEE changes at 14/30/90 day intervals")
    func testCalculatesLongerIntervalChanges() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: All interval changes are present
        let periods = viewModel.expenditureChanges.map { $0.period }
        #expect(periods.contains("14-day"))
        #expect(periods.contains("30-day"))
        #expect(periods.contains("90-day"))
    }

    // MARK: - Flux Range Tests

    @Test("ViewModel calculates flux range (uncertainty margin)")
    func testCalculatesFluxRange() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Daily data includes flux range (upper/lower bounds)
        guard let firstDay = viewModel.dailyData.first else {
            Issue.record("Expected daily data to have entries")
            return
        }

        #expect(firstDay.upperBound >= firstDay.value)
        #expect(firstDay.lowerBound <= firstDay.value)
    }

    @Test("Flux range is tighter for recent data, wider for older data")
    func testFluxRangeVariesByRecency() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)
        viewModel.selectedPeriod = .oneYear

        // When: Loading data
        await viewModel.loadData()

        // Then: Flux range should vary by recency
        guard viewModel.dailyData.count > 100 else {
            Issue.record("Expected at least 100 days of daily data")
            return
        }

        // Get recent (last 14 days) and older (60+ days) data
        let recentData = viewModel.dailyData.suffix(14)
        let olderData = viewModel.dailyData.prefix(100)

        // Calculate average flux range widths
        let recentAvgRange = recentData.map { $0.upperBound - $0.lowerBound }.reduce(0, +) / recentData.count
        let olderAvgRange = olderData.map { $0.upperBound - $0.lowerBound }.reduce(0, +) / olderData.count

        // Older data should have wider flux range
        #expect(olderAvgRange >= recentAvgRange)
    }

    // MARK: - Strategy Status Tests

    @Test("ViewModel determines 'Holding' status when insufficient data")
    func testDeterminesHoldingStatus() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE but very recent calculation (insufficient history)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()  // Just calculated today
        )
        // No weight or food data - insufficient for updating
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Strategy should be "Holding" due to insufficient data
        #expect(viewModel.currentStrategy == "Holding")
    }

    @Test("ViewModel determines 'Updating' status when actively refining")
    func testDeterminesUpdatingStatus() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with sufficient data for active TDEE refinement
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())
        )

        // Add sufficient weight data (7 entries in past 2 weeks)
        for dayIndex in 0..<7 {
            _ = createWeightEntry(in: context, weightKg: 84.0 - Double(dayIndex) * 0.1, daysAgo: dayIndex * 2)
        }

        // Add sufficient food data (10 days of food logging)
        for dayIndex in 0..<10 {
            _ = createFoodEntry(in: context, calories: 1800, daysAgo: dayIndex)
        }

        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Strategy should be "Updating" with sufficient data
        #expect(viewModel.currentStrategy == "Updating")
    }

    // MARK: - Time Period Selection Tests

    @Test("ViewModel responds to DetailTimePeriod selection changes")
    func testRespondsToTimePeriodChange() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

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

    @Test("ViewModel generates data for selected time period only")
    func testGeneratesDataForSelectedPeriod() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading with 1 month period
        viewModel.selectedPeriod = .oneMonth
        await viewModel.loadData()

        // Then: Data spans approximately 30 days (can be 28-32 depending on month)
        #expect(viewModel.dailyData.count >= 28)
        #expect(viewModel.dailyData.count <= 32)
    }

    // MARK: - Missing Data Tests

    @Test("ViewModel handles missing TDEE data gracefully")
    func testHandlesMissingTDEEData() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with no nutrition goal
        _ = createTestUser(in: context)
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: No crash, empty state
        #expect(viewModel.hasData == false)
        #expect(viewModel.currentExpenditure == nil)
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
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        goal.isActive = false
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: No data (no active goal)
        #expect(viewModel.hasData == false)
    }

    // MARK: - Historical Entries Tests

    @Test("ViewModel provides historical entries for display")
    func testProvidesHistoricalEntries() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Historical entries are populated
        #expect(!viewModel.historicalEntries.isEmpty)
    }

    // MARK: - Date Range Tests

    @Test("ViewModel calculates date range string")
    func testCalculatesDateRange() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)
        viewModel.selectedPeriod = .oneMonth

        // When: Loading data
        await viewModel.loadData()

        // Then: Date range is set
        #expect(!viewModel.dateRange.isEmpty)
    }

    // MARK: - Difference Calculation Tests

    @Test("ViewModel calculates difference from period start")
    func testCalculatesDifference() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE showing change from initial
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,  // Started at 2000
            lastCalculatedTDEE: 1893,  // Now at 1893
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Difference is calculated (1893 - 2000 = -107)
        #expect(viewModel.difference != nil)
        if let diff = viewModel.difference {
            #expect(diff < 0)  // TDEE decreased
        }
    }

    // MARK: - Preview Support Tests

    @Test("Preview instance can be created")
    func testPreviewInstance() async {
        let preview = ExpenditureDetailViewModel.preview
        #expect(preview.isLoading == false)
        #expect(preview.dailyData.isEmpty)
    }

    @Test("Loading state is false after load completes")
    func testLoadingStateAfterLoad() async throws {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: isLoading is false after completion
        #expect(viewModel.isLoading == false)
    }

    // MARK: - Strategy Description Tests

    @Test("ViewModel provides strategy description")
    func testProvidesStrategyDescription() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Strategy description is provided
        #expect(!viewModel.strategyDescription.isEmpty)
    }
}
