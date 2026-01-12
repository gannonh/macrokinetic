//
//  ExpenditureWidgetViewModelTests.swift
//  JabTrackerTests
//
//  Tests for ExpenditureWidgetViewModel - standard widget TDEE data source
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("ExpenditureWidgetViewModel Tests")
@MainActor
struct ExpenditureWidgetViewModelTests {

    // MARK: - Test Helpers

    private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([
            User.self, NutritionGoal.self, NutritionProgram.self,
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

    // MARK: - Initial State Tests

    @Test("ViewModel initializes with default state and no data")
    func testInitialState() async {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = ExpenditureWidgetViewModel(context: context)

        #expect(viewModel.isLoading == false)
        #expect(viewModel.tdee == nil)
        #expect(viewModel.hasData == false)
    }

    // MARK: - Data Loading Tests

    @Test("ViewModel loads TDEE from active NutritionGoal")
    func testLoadsTDEEFromGoal() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with active NutritionGoal containing TDEE
        let user = createTestUser(in: context)
        _ = createNutritionGoal(in: context, user: user, tdee: 2100)
        try context.save()

        let viewModel = ExpenditureWidgetViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: TDEE is loaded from goal
        #expect(viewModel.tdee == 2100)
        #expect(viewModel.hasData == true)
    }

    @Test("ViewModel handles user without nutrition goal")
    func testHandlesNoGoal() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User without NutritionGoal
        _ = createTestUser(in: context)
        try context.save()

        let viewModel = ExpenditureWidgetViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: TDEE is nil
        #expect(viewModel.tdee == nil)
        #expect(viewModel.hasData == false)
    }

    @Test("ViewModel handles empty data gracefully")
    func testHandlesEmptyData() async throws {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = ExpenditureWidgetViewModel(context: context)

        // When: Loading with no user
        await viewModel.loadData()

        // Then: No crash, no data
        #expect(viewModel.tdee == nil)
        #expect(viewModel.hasData == false)
        #expect(viewModel.isLoading == false)
    }

    @Test("ViewModel uses lastCalculatedTDEE when available")
    func testUsesLastCalculatedTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: Goal with both initial and last calculated TDEE
        let user = createTestUser(in: context)
        let goal = createNutritionGoal(in: context, user: user, tdee: 2000)
        goal.lastCalculatedTDEE = 2150  // Updated value
        try context.save()

        let viewModel = ExpenditureWidgetViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Uses lastCalculatedTDEE
        #expect(viewModel.tdee == 2150)
    }

    @Test("ViewModel falls back to initialEstimatedTDEE")
    func testFallsBackToInitialTDEE() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: Goal with only initial TDEE
        let user = createTestUser(in: context)
        let goal = createNutritionGoal(in: context, user: user, tdee: 2000)
        goal.lastCalculatedTDEE = nil  // Clear last calculated
        try context.save()

        let viewModel = ExpenditureWidgetViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: Uses initialEstimatedTDEE
        #expect(viewModel.tdee == 2000)
    }

    @Test("ViewModel ignores inactive goals")
    func testIgnoresInactiveGoals() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: User with inactive NutritionGoal
        let user = createTestUser(in: context)
        let goal = createNutritionGoal(in: context, user: user, tdee: 2100)
        goal.isActive = false
        try context.save()

        let viewModel = ExpenditureWidgetViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: TDEE is nil (inactive goal ignored)
        #expect(viewModel.tdee == nil)
        #expect(viewModel.hasData == false)
    }

    @Test("Loading state is false after load completes")
    func testLoadingStateAfterLoad() async throws {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = ExpenditureWidgetViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: isLoading is false after completion
        #expect(viewModel.isLoading == false)
    }

    @Test("Preview instance can be created")
    func testPreviewInstance() async {
        // Verify preview factory method works
        let preview = ExpenditureWidgetViewModel.preview
        #expect(preview.isLoading == false)
        #expect(preview.tdee == nil)
    }

    @Test("ViewModel handles goal with nil TDEE values")
    func testHandlesNilTDEEValues() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Given: Goal with no TDEE values at all
        let user = createTestUser(in: context)
        let goal = NutritionGoal(
            goalType: .weightLoss,
            isActive: true,
            dailyCalorieTarget: 1800
        )
        goal.initialEstimatedTDEE = nil
        goal.lastCalculatedTDEE = nil
        goal.user = user
        context.insert(goal)
        try context.save()

        let viewModel = ExpenditureWidgetViewModel(context: context)

        // When: Loading data
        await viewModel.loadData()

        // Then: TDEE is nil
        #expect(viewModel.tdee == nil)
        #expect(viewModel.hasData == false)
    }
}
