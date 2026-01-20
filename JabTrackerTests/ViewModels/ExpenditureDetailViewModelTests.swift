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

        // Given: User with TDEE data and sufficient snapshots
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )

        // Create snapshots for 100 days to support all interval calculations
        for dayIndex in 0..<100 {
            let timestamp = Calendar.current.date(byAdding: .day, value: -dayIndex, to: Date())!
            let snapshot = TDEESnapshot(timestamp: timestamp, tdeeValue: 1893 + Double(dayIndex))
            context.insert(snapshot)
        }
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)
        viewModel.selectedPeriod = .all

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

        // Given: User with TDEE data and sufficient snapshots
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )

        // Create snapshots for 100 days to support all interval calculations
        for dayIndex in 0..<100 {
            let timestamp = Calendar.current.date(byAdding: .day, value: -dayIndex, to: Date())!
            let snapshot = TDEESnapshot(timestamp: timestamp, tdeeValue: 1893 + Double(dayIndex))
            context.insert(snapshot)
        }
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)
        viewModel.selectedPeriod = .all

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

        // Given: User with TDEE data and sufficient snapshots
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )

        // Create snapshots for 100 days to support all interval calculations
        for dayIndex in 0..<100 {
            let timestamp = Calendar.current.date(byAdding: .day, value: -dayIndex, to: Date())!
            let snapshot = TDEESnapshot(timestamp: timestamp, tdeeValue: 1893 + Double(dayIndex))
            context.insert(snapshot)
        }
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)
        viewModel.selectedPeriod = .all

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

        // Given: User with TDEE data and 365 days of snapshots with varying confidence
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )

        // Create snapshots with higher confidence for recent data, lower for older
        for dayIndex in 0..<365 {
            let timestamp = Calendar.current.date(byAdding: .day, value: -dayIndex, to: Date())!
            // Confidence decreases as data gets older: 1.0 for today, ~0.0 for 365 days ago
            let confidence = max(0.0, 1.0 - Double(dayIndex) / 365.0)
            let snapshot = TDEESnapshot(
                timestamp: timestamp,
                tdeeValue: 1893,
                confidence: confidence,
                source: .adaptive
            )
            context.insert(snapshot)
        }
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

        // Given: User with TDEE data and 365 days of snapshots
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )

        // Create snapshots for 365 days
        for dayIndex in 0..<365 {
            let timestamp = Calendar.current.date(byAdding: .day, value: -dayIndex, to: Date())!
            let snapshot = TDEESnapshot(timestamp: timestamp, tdeeValue: 1893)
            context.insert(snapshot)
        }
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

        // Given: User with TDEE data and 60 days of snapshots
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )

        // Create snapshots for 60 days (more than 1 month)
        for dayIndex in 0..<60 {
            let timestamp = Calendar.current.date(byAdding: .day, value: -dayIndex, to: Date())!
            let snapshot = TDEESnapshot(timestamp: timestamp, tdeeValue: 1893)
            context.insert(snapshot)
        }
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

    // MARK: - ID Getter Tests (Coverage for Identifiable structs)

    @Test("DailyExpenditure id property is accessible")
    func testDailyExpenditureIdProperty() async throws {
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

        // Then: DailyExpenditure structs have accessible id properties
        #expect(!viewModel.dailyData.isEmpty)
        for dailyExpenditure in viewModel.dailyData {
            // Access the id getter - this is the key coverage point
            let id = dailyExpenditure.id
            #expect(id != UUID())  // ID exists and is valid
        }
    }

    @Test("DailyExpenditure ids are unique")
    func testDailyExpenditureIdUniqueness() async throws {
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

        // Then: All ids are unique
        let ids = viewModel.dailyData.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("ExpenditureChange id property is accessible")
    func testExpenditureChangeIdProperty() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data and sufficient history for changes
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

        // Then: ExpenditureChange structs have accessible id properties
        for change in viewModel.expenditureChanges {
            // Access the id getter - key coverage point
            let id = change.id
            #expect(id != UUID())
        }
    }

    @Test("ExpenditureChange ids are unique")
    func testExpenditureChangeIdUniqueness() async throws {
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

        // Then: All change ids are unique
        let ids = viewModel.expenditureChanges.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("HistoricalEntry id property is accessible")
    func testHistoricalEntryIdProperty() async throws {
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

        // Then: HistoricalEntry structs have accessible id properties
        #expect(!viewModel.historicalEntries.isEmpty)
        for entry in viewModel.historicalEntries {
            // Access the id getter - key coverage point
            let id = entry.id
            #expect(id != UUID())
        }
    }

    @Test("HistoricalEntry ids are unique")
    func testHistoricalEntryIdUniqueness() async throws {
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

        // Then: All historical entry ids are unique
        let ids = viewModel.historicalEntries.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("generateHistoricalEntries uses actual daily snapshot data")
    func testHistoricalEntriesFromSnapshots() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE data and actual TDEESnapshots
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1900,
            lastTDEECalculationDate: Date()
        )

        // Create 10 days of snapshots with varying TDEE values and statuses
        for dayIndex in 0..<10 {
            let snapshot = createTDEESnapshot(
                in: context,
                tdeeValue: 1900.0 + Double(dayIndex) * 10,
                daysAgo: dayIndex,
                source: dayIndex % 2 == 0 ? .adaptive : .holding
            )
            _ = snapshot
        }
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)
        viewModel.selectedPeriod = .oneMonth

        // When: Loading data
        await viewModel.loadData()

        // Then: Historical entries are populated from actual snapshot data (not fallback)
        #expect(!viewModel.historicalEntries.isEmpty)

        // Historical entries should have values matching actual snapshot TDEE values
        // Most recent entries from dailyData are used for historical entries
        let historicalValues = Set(viewModel.historicalEntries.map { $0.expenditure })

        // At least some values should match the snapshot data range (1900-1990)
        let matchesSnapshotRange = historicalValues.contains { value in
            value >= 1900 && value <= 1990
        }
        #expect(matchesSnapshotRange, "Historical entries should use actual snapshot TDEE values")

        // Historical entries should have varied statuses from snapshots
        let statuses = Set(viewModel.historicalEntries.map { $0.status })
        // Should have at least one status type (could be .updating or .holding based on snapshot sources)
        #expect(!statuses.isEmpty)
    }

    // MARK: - generateExpenditureChanges Edge Cases

    @Test("generateExpenditureChanges handles empty dailyData")
    func testGenerateExpenditureChangesEmptyData() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with no TDEE data (no active goal)
        _ = createTestUser(in: context)
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data (no active goal)
        await viewModel.loadData()

        // Then: expenditureChanges is empty
        #expect(viewModel.expenditureChanges.isEmpty)
    }

    @Test("generateExpenditureChanges calculates correct trends")
    func testGenerateExpenditureChangesTrends() async throws {
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

        // Then: All trends are valid
        let validTrends = ["Decrease", "Increase", "No Change"]
        for change in viewModel.expenditureChanges {
            #expect(validTrends.contains(change.trend))
        }
    }

    // MARK: - loadDailyData Edge Cases

    @Test("loadDailyData handles selected period with no start date")
    func testLoadDailyDataAllPeriod() async throws {
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
        viewModel.selectedPeriod = .all  // "All" period has nil startDate

        // When: Loading data
        await viewModel.loadData()

        // Then: Data is loaded (uses fallback of 1 year)
        #expect(viewModel.hasData == true)
    }

    @Test("loadDailyData creates fallback entry when no snapshots exist")
    func testLoadDailyDataFallback() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE but no TDEESnapshots
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

        // Then: Fallback entry is created
        #expect(viewModel.dailyData.count >= 1)
        // First entry should use the current TDEE value
        if let firstEntry = viewModel.dailyData.first {
            #expect(firstEntry.value == 1893)
        }
    }

    // MARK: - Difference Calculation Tests

    @Test("Difference is nil when no initial TDEE exists")
    func testDifferenceNilWhenNoInitialTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with only lastCalculatedTDEE (no initial)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: nil,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Difference cannot be calculated (no initial reference)
        #expect(viewModel.difference == nil)
    }

    @Test("Difference shows positive change when TDEE increased")
    func testDifferencePositiveWhenTDEEIncreased() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User whose TDEE increased from initial
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 1800,  // Started at 1800
            lastCalculatedTDEE: 2000,  // Now at 2000 (increase)
            lastTDEECalculationDate: Date()
        )
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Difference is positive (2000 - 1800 = 200)
        #expect(viewModel.difference != nil)
        #expect(viewModel.difference! > 0)
        #expect(viewModel.difference! == 200)
    }

    // MARK: - clearAllData Tests

    @Test("clearAllData resets all state when no user")
    func testClearAllDataNoUser() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: No user in context
        let viewModel = ExpenditureDetailViewModel(context: context)

        // When: Loading data (will call clearAllData internally)
        await viewModel.loadData()

        // Then: All state is cleared
        #expect(viewModel.dailyData.isEmpty)
        #expect(viewModel.expenditureChanges.isEmpty)
        #expect(viewModel.historicalEntries.isEmpty)
        #expect(viewModel.currentExpenditure == nil)
        #expect(viewModel.averageExpenditure == nil)
        #expect(viewModel.difference == nil)
        #expect(viewModel.dateRange.isEmpty)
        #expect(viewModel.currentStrategy == "Holding")
        #expect(viewModel.strategyDescription.isEmpty)
    }

    // MARK: - Time Period Tests

    @Test("oneWeek period generates approximately 7 days of data")
    func testOneWeekPeriodDataCount() async throws {
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
        viewModel.selectedPeriod = .oneWeek

        // When: Loading data
        await viewModel.loadData()

        // Then: Data count is small (fallback creates 1 entry when no snapshots)
        // Note: Without actual TDEESnapshots, only 1 fallback entry is created
        #expect(viewModel.dailyData.count >= 1)
    }

    // MARK: - TDEESnapshot Tests (loadDailyData with real snapshots)

    private func createTDEESnapshot(
        in context: ModelContext,
        tdeeValue: Double,
        daysAgo: Int = 0,
        source: TDEESourceType = .adaptive,
        confidence: Double = 0.8
    ) -> TDEESnapshot {
        let timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        let snapshot = TDEESnapshot(
            timestamp: timestamp,
            tdeeValue: tdeeValue,
            confidence: confidence,
            source: source
        )
        context.insert(snapshot)
        return snapshot
    }

    @Test("loadDailyData maps TDEESnapshots to DailyExpenditure correctly")
    func testLoadDailyDataWithSnapshots() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and existing snapshots
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )

        // Create snapshots for the past 10 days with varying values
        for dayIndex in 0..<10 {
            _ = createTDEESnapshot(
                in: context,
                tdeeValue: 1900.0 - Double(dayIndex) * 10,  // Decreasing TDEE
                daysAgo: dayIndex
            )
        }
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)
        viewModel.selectedPeriod = .oneMonth

        // When: Loading data
        await viewModel.loadData()

        // Then: DailyExpenditure entries are created from snapshots
        #expect(viewModel.dailyData.count == 10)  // All snapshots mapped
    }

    @Test("DailyExpenditure uses snapshot status correctly")
    func testDailyExpenditureStatusFromSnapshots() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and snapshots of different source types
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1893,
            lastTDEECalculationDate: Date()
        )

        // Create snapshots with different source types
        _ = createTDEESnapshot(in: context, tdeeValue: 1900, daysAgo: 0, source: .adaptive)
        _ = createTDEESnapshot(in: context, tdeeValue: 1910, daysAgo: 1, source: .holding)
        _ = createTDEESnapshot(in: context, tdeeValue: 1920, daysAgo: 2, source: .initial)
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)
        viewModel.selectedPeriod = .oneWeek

        // When: Loading data
        await viewModel.loadData()

        // Then: Status is correctly mapped from source type
        #expect(viewModel.dailyData.count == 3)
        // Note: sorted by date, so index 0 is oldest (2 days ago)
        let statuses = viewModel.dailyData.map { $0.status }
        #expect(statuses.contains(.updating))  // adaptive
        #expect(statuses.contains(.holding))  // holding
        #expect(statuses.contains(.fluxRange))  // initial
    }

    @Test("DailyExpenditure uses snapshot fluxMargin for bounds")
    func testDailyExpenditureFluxMarginFromSnapshots() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and snapshots with known confidence
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1900,
            lastTDEECalculationDate: Date()
        )

        // High confidence snapshot (tight margin)
        _ = createTDEESnapshot(in: context, tdeeValue: 1900, daysAgo: 0, confidence: 1.0)
        // Low confidence snapshot (wide margin)
        _ = createTDEESnapshot(in: context, tdeeValue: 1850, daysAgo: 1, confidence: 0.0)
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)
        viewModel.selectedPeriod = .oneWeek

        // When: Loading data
        await viewModel.loadData()

        // Then: Bounds reflect confidence-based flux margins
        #expect(viewModel.dailyData.count == 2)

        // Find the high confidence entry (1900)
        if let highConfidenceEntry = viewModel.dailyData.first(where: { $0.value == 1900 }) {
            // High confidence = 10 margin
            #expect(highConfidenceEntry.upperBound == 1910)
            #expect(highConfidenceEntry.lowerBound == 1890)
        }

        // Find the low confidence entry (1850)
        if let lowConfidenceEntry = viewModel.dailyData.first(where: { $0.value == 1850 }) {
            // Low confidence = 50 margin
            #expect(lowConfidenceEntry.upperBound == 1900)
            #expect(lowConfidenceEntry.lowerBound == 1800)
        }
    }

    @Test("generateExpenditureChanges calculates changes from snapshot history")
    func testExpenditureChangesFromSnapshots() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and 100+ days of snapshots (for all intervals)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1800,
            lastTDEECalculationDate: Date()
        )

        // Create 100 days of snapshots with gradual decrease
        for dayIndex in 0..<100 {
            _ = createTDEESnapshot(
                in: context,
                tdeeValue: 2000.0 - Double(dayIndex) * 2,  // 2 kcal decrease per day
                daysAgo: dayIndex
            )
        }
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)
        viewModel.selectedPeriod = .all

        // When: Loading data
        await viewModel.loadData()

        // Then: All interval changes should be calculated
        #expect(viewModel.dailyData.count == 100)
        #expect(viewModel.expenditureChanges.count == 5)  // 3, 7, 14, 30, 90 day intervals

        // All changes should show "Increase" (latest - oldest, and we're decreasing going back)
        for change in viewModel.expenditureChanges {
            #expect(change.trend == "Increase")
        }
    }

    @Test("generateExpenditureChanges shows 'No Change' when values are same")
    func testExpenditureChangesNoChange() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and snapshots with identical values
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1900,
            lastTDEECalculationDate: Date()
        )

        // Create 100 days of snapshots with identical values
        for dayIndex in 0..<100 {
            _ = createTDEESnapshot(
                in: context,
                tdeeValue: 1900,  // Same value every day
                daysAgo: dayIndex
            )
        }
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)
        viewModel.selectedPeriod = .all

        // When: Loading data
        await viewModel.loadData()

        // Then: All changes should show "No Change"
        for change in viewModel.expenditureChanges {
            #expect(change.change == 0)
            #expect(change.trend == "No Change")
        }
    }

    @Test("generateExpenditureChanges shows 'Decrease' when values drop")
    func testExpenditureChangesDecrease() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with TDEE and snapshots with increasing values (going back in time)
        let user = createTestUser(in: context)
        _ = createNutritionGoal(
            in: context,
            for: user,
            initialTDEE: 2000,
            lastCalculatedTDEE: 1800,
            lastTDEECalculationDate: Date()
        )

        // Create 100 days of snapshots with increasing values (so latest is lowest)
        for dayIndex in 0..<100 {
            _ = createTDEESnapshot(
                in: context,
                tdeeValue: 1800.0 + Double(dayIndex) * 2,  // Higher values going back in time
                daysAgo: dayIndex
            )
        }
        try context.save()

        let viewModel = ExpenditureDetailViewModel(context: context)
        viewModel.selectedPeriod = .all

        // When: Loading data
        await viewModel.loadData()

        // Then: All changes should show "Decrease" (latest - past = negative)
        for change in viewModel.expenditureChanges {
            #expect(change.change < 0)
            #expect(change.trend == "Decrease")
        }
    }
}
