//
//  WeightTrendWidgetViewModelTests.swift
//  JabTrackerTests
//
//  Tests for WeightTrendWidgetViewModel - standard widget data source
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("WeightTrendWidgetViewModel Tests")
@MainActor
struct WeightTrendWidgetViewModelTests {

    // MARK: - Test Helpers

    private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([
            User.self, WeightEntry.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        return (container.mainContext, container)
    }

    private func createTestUser(in context: ModelContext, weightUnit: String = "lbs") -> User {
        let user = User(email: "test@example.com", name: "Test User")
        user.weight = 185.0
        user.weightUnit = weightUnit
        context.insert(user)
        return user
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

    // MARK: - Initial State Tests

    @Test("ViewModel initializes with loading state and empty data")
    func testInitialState() async {
        let (context, container) = createTestContext()
        _ = container

        let metricsService = MetricsService(context: context)
        let viewModel = WeightTrendWidgetViewModel(metricsService: metricsService, context: context)

        #expect(viewModel.isLoading == false)
        #expect(viewModel.dataPoints.isEmpty)
        #expect(viewModel.latestWeight == nil)
    }

    // MARK: - Data Loading Tests

    @Test("ViewModel loads 7 days of weight data")
    func testLoadsSevenDaysData() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: Weight entries for the last 7 days
        _ = createWeightEntry(in: context, weightKg: 84.0, daysAgo: 6)  // 185.2 lbs
        _ = createWeightEntry(in: context, weightKg: 83.9, daysAgo: 5)
        _ = createWeightEntry(in: context, weightKg: 83.8, daysAgo: 4)
        _ = createWeightEntry(in: context, weightKg: 83.7, daysAgo: 3)
        _ = createWeightEntry(in: context, weightKg: 83.6, daysAgo: 2)
        _ = createWeightEntry(in: context, weightKg: 83.5, daysAgo: 1)
        _ = createWeightEntry(in: context, weightKg: 83.4, daysAgo: 0)  // Today - 183.7 lbs
        try context.save()

        let metricsService = MetricsService(context: context)
        let viewModel = WeightTrendWidgetViewModel(metricsService: metricsService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: All 7 data points are loaded
        #expect(viewModel.dataPoints.count == 7)
        #expect(viewModel.latestWeight != nil)
    }

    @Test("ViewModel maps WeightEntry to DataPoint correctly")
    func testMapsWeightEntryToDataPoint() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: A single weight entry
        _ = createWeightEntry(in: context, weightKg: 83.4, daysAgo: 0)
        try context.save()

        let metricsService = MetricsService(context: context)
        let viewModel = WeightTrendWidgetViewModel(metricsService: metricsService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: DataPoint has correct values
        guard let dataPoint = viewModel.dataPoints.first else {
            Issue.record("Expected at least one data point")
            return
        }

        #expect(dataPoint.day >= 0)
        #expect(dataPoint.weight > 0)
    }

    @Test("ViewModel returns latest weight in user's preferred unit (lbs)")
    func testLatestWeightInLbs() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User prefers lbs and has a weight entry
        _ = createTestUser(in: context, weightUnit: "lbs")
        _ = createWeightEntry(in: context, weightKg: 83.4, daysAgo: 0)  // ~183.9 lbs
        try context.save()

        let metricsService = MetricsService(context: context)
        let viewModel = WeightTrendWidgetViewModel(metricsService: metricsService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Latest weight is in lbs
        guard let latestWeight = viewModel.latestWeight else {
            Issue.record("Expected latestWeight to be set")
            return
        }
        #expect(latestWeight > 180)  // ~183.9 lbs
        #expect(viewModel.unit == "lbs")
    }

    @Test("ViewModel returns latest weight in user's preferred unit (kg)")
    func testLatestWeightInKg() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User prefers kg and has a weight entry
        _ = createTestUser(in: context, weightUnit: "kg")
        _ = createWeightEntry(in: context, weightKg: 83.4, daysAgo: 0)
        try context.save()

        let metricsService = MetricsService(context: context)
        let viewModel = WeightTrendWidgetViewModel(metricsService: metricsService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Latest weight is in kg
        guard let latestWeight = viewModel.latestWeight else {
            Issue.record("Expected latestWeight to be set")
            return
        }
        #expect(abs(latestWeight - 83.4) < 0.1)
        #expect(viewModel.unit == "kg")
    }

    @Test("ViewModel handles empty data gracefully")
    func testHandlesEmptyData() async throws {
        let (context, container) = createTestContext()
        _ = container

        let metricsService = MetricsService(context: context)
        let viewModel = WeightTrendWidgetViewModel(metricsService: metricsService, context: context)

        // When: Loading with no weight entries
        await viewModel.loadData()

        // Then: Data is empty but no crash
        #expect(viewModel.dataPoints.isEmpty)
        #expect(viewModel.latestWeight == nil)
        #expect(viewModel.hasData == false)
    }

    @Test("ViewModel sorts data points chronologically")
    func testSortsDataChronologically() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: Weight entries in random order
        _ = createWeightEntry(in: context, weightKg: 83.4, daysAgo: 0)  // Most recent
        _ = createWeightEntry(in: context, weightKg: 84.0, daysAgo: 6)  // Oldest
        _ = createWeightEntry(in: context, weightKg: 83.7, daysAgo: 3)  // Middle
        try context.save()

        let metricsService = MetricsService(context: context)
        let viewModel = WeightTrendWidgetViewModel(metricsService: metricsService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Data points are sorted oldest to newest
        #expect(viewModel.dataPoints.count == 3)
        if viewModel.dataPoints.count >= 2 {
            #expect(viewModel.dataPoints.first!.day <= viewModel.dataPoints.last!.day)
        }
    }

    @Test("hasData returns true when data points exist")
    func testHasDataWithDataPoints() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: A weight entry
        _ = createWeightEntry(in: context, weightKg: 83.4, daysAgo: 0)
        try context.save()

        let metricsService = MetricsService(context: context)
        let viewModel = WeightTrendWidgetViewModel(metricsService: metricsService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: hasData returns true
        #expect(viewModel.hasData == true)
    }

    @Test("Preview instance can be created")
    func testPreviewInstance() async {
        // Verify preview factory method works
        let preview = WeightTrendWidgetViewModel.preview
        #expect(preview.isLoading == false)
        #expect(preview.dataPoints.isEmpty)
    }

    @Test("Loading state is false after load completes")
    func testLoadingStateAfterLoad() async throws {
        let (context, container) = createTestContext()
        _ = container

        let metricsService = MetricsService(context: context)
        let viewModel = WeightTrendWidgetViewModel(metricsService: metricsService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: isLoading is false after completion
        #expect(viewModel.isLoading == false)
    }

    @Test("Unit defaults to lbs without user")
    func testUnitDefaultsToLbs() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: No user
        _ = createWeightEntry(in: context, weightKg: 83.4, daysAgo: 0)
        try context.save()

        let metricsService = MetricsService(context: context)
        let viewModel = WeightTrendWidgetViewModel(metricsService: metricsService, context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Unit defaults to lbs
        #expect(viewModel.unit == "lbs")
    }
}
