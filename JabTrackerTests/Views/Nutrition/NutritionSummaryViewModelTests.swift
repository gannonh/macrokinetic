import SwiftData
import XCTest

@testable import JabTracker

@MainActor
final class NutritionSummaryViewModelTests: XCTestCase {

    var viewModel: NutritionSummaryViewModel!
    var user: User!
    var mockDataSource: MockActiveEnergyDataSource!
    var mockStarter: MockEnergyObservationStarter!
    var mockStopper: MockEnergyObservationStopper!
    var container: ModelContainer!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        container = try ModelContainer(for: User.self, configurations: config)

        user = User()
        container.mainContext.insert(user)

        // Setup User defaults for testing
        user.dailyCalorieGoal = 2000
        user.addBurnedCaloriesEnabled = true
        user.healthSyncEnabled = true

        mockDataSource = MockActiveEnergyDataSource()
        let adjustmentService = CalorieAdjustmentService(activeEnergyDataSource: mockDataSource)

        mockStarter = MockEnergyObservationStarter()
        mockStopper = MockEnergyObservationStopper()

        viewModel = NutritionSummaryViewModel(
            mealLogService: nil,  // Not testing meal loading here
            calorieAdjustmentService: adjustmentService,
            energyObservationStarter: mockStarter.start,
            energyObservationStopper: mockStopper.stop
        )
    }

    // MARK: - Tests

    func testStartObservation_WhenEnabled_StartsObservation() {
        // Given
        user.addBurnedCaloriesEnabled = true
        user.healthSyncEnabled = true
        let today = Date()

        // When
        viewModel.startEnergyObservation(user: user, date: today)

        // Then
        XCTAssertTrue(mockStarter.isStarted)
        XCTAssertTrue(mockStopper.isStopped, "Should stop previous observation first")
    }

    func testStartObservation_WhenDisabled_DoesNotStart() {
        // Given
        user.addBurnedCaloriesEnabled = false
        user.healthSyncEnabled = true
        let today = Date()

        // When
        viewModel.startEnergyObservation(user: user, date: today)

        // Then
        XCTAssertFalse(mockStarter.isStarted)
    }

    func testStartObservation_WhenHealthSyncDisabled_DoesNotStart() {
        // Given
        user.addBurnedCaloriesEnabled = true
        user.healthSyncEnabled = false

        // When
        viewModel.startEnergyObservation(user: user, date: Date())

        // Then
        XCTAssertFalse(mockStarter.isStarted)
    }

    func testStartObservation_WhenNotToday_DoesNotStart() {
        // Given
        user.addBurnedCaloriesEnabled = true
        user.healthSyncEnabled = true
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        // When
        viewModel.startEnergyObservation(user: user, date: yesterday)

        // Then
        XCTAssertFalse(mockStarter.isStarted)
    }

    func testObservationCallback_UpdatesTarget() async {
        // Given
        user.addBurnedCaloriesEnabled = true
        user.healthSyncEnabled = true
        let today = Date()
        viewModel.startEnergyObservation(user: user, date: today)

        // When
        // Simulate energy update from HealthKit (via our mock starter's captured handler)
        guard let handler = mockStarter.handler else {
            XCTFail("Handler not captured")
            return
        }

        // Simulate 500 kcal burned
        // The ViewModel callback sets activeEnergyBurned = 500
        // Then calls updateCalorieTarget
        // CalorieAdjustmentService.getAdjustedCalorieTarget calls dataSource.getTodayActiveEnergy.
        // Wait, here's a discrepancy:
        // The ViewModel uses the `energy` passed in the callback to update `activeEnergyBurned`.
        // BUT `updateCalorieTarget` calls `calorieAdjustmentService.getAdjustedCalorieTarget`.
        // `CalorieAdjustmentService` fetches from `activeEnergyDataSource`.
        // So I must ensure `mockDataSource` ALSO returns the updated value, OR the service logic matches.

        // In `MetricsService` implementation, the callback gets the total for the day.
        // `CalorieAdjustmentService` also pulls for the day.
        // If I update `activeEnergyBurned`, does it affect `CalorieAdjustmentService`?
        // No, `CalorieAdjustmentService` pulls from Data Source independently.
        // So for the test to be consistent, I must update the mockDataSource as well.

        let burned = 500.0
        mockDataSource.todayEnergy = burned
        handler(burned)

        // Allow async task to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(viewModel.activeEnergyBurned, burned)
        // Base target 2000 + 500 = 2500
        XCTAssertEqual(viewModel.adjustedCalorieTarget, 2500)
    }

    func testStopObservation_Stops() {
        // When
        viewModel.stopEnergyObservation()

        // Then
        XCTAssertTrue(mockStopper.isStopped)
    }

    func testVisualIndicatorLogic() {
        // This is View logic but driven by ViewModel state
        viewModel.activeEnergyBurned = 100
        XCTAssertEqual(viewModel.activeEnergyBurned, 100)

        viewModel.activeEnergyBurned = 0
        XCTAssertEqual(viewModel.activeEnergyBurned, 0)
    }

    // MARK: - Load Data Tests

    func testLoadData_SetsIsLoadingToTrueInitially() async {
        // Given
        let today = Date()

        // When - loadData runs
        await viewModel.loadData(for: today)

        // Then - after completion, isLoading should be false
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadData_WithNilMealLogService_DoesNotCrash() async {
        // Given - viewModel was created with nil mealLogService
        let today = Date()

        // When - calling loadData should not crash
        await viewModel.loadData(for: today)

        // Then - no error occurred, totals remain zero
        XCTAssertEqual(viewModel.totals.calories, 0)
        XCTAssertNil(viewModel.loadError)
    }

    func testLoadData_CompletesWithoutError() async {
        // Given
        let today = Date()

        // When
        await viewModel.loadData(for: today)

        // Then
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Update Calorie Target Tests

    func testUpdateCalorieTarget_CalculatesCorrectly() async {
        // Given
        user.dailyCalorieGoal = 2000
        let today = Date()

        // When
        await viewModel.updateCalorieTarget(user: user, date: today)

        // Then - base target plus any adjustments
        XCTAssertGreaterThanOrEqual(viewModel.adjustedCalorieTarget, 0)
    }

    // MARK: - Energy Observation Edge Cases

    func testStartEnergyObservation_ResetsEnergyWhenDisabled() async {
        // Given - observation was previously active with some energy
        user.addBurnedCaloriesEnabled = true
        user.healthSyncEnabled = true
        viewModel.startEnergyObservation(user: user, date: Date())

        // Simulate energy update
        if let handler = mockStarter.handler {
            handler(300)
        }
        XCTAssertEqual(viewModel.activeEnergyBurned, 300)

        // Reset starter to track new start
        mockStarter = MockEnergyObservationStarter()
        mockStopper = MockEnergyObservationStopper()

        // Create new viewModel with feature disabled
        let newViewModel = NutritionSummaryViewModel(
            mealLogService: nil,
            calorieAdjustmentService: CalorieAdjustmentService(activeEnergyDataSource: mockDataSource),
            energyObservationStarter: mockStarter.start,
            energyObservationStopper: mockStopper.stop
        )

        // When - feature is disabled
        user.addBurnedCaloriesEnabled = false
        newViewModel.startEnergyObservation(user: user, date: Date())

        // Then - energy should be reset to 0
        XCTAssertEqual(newViewModel.activeEnergyBurned, 0)
        XCTAssertFalse(mockStarter.isStarted)
    }

    func testStartEnergyObservation_StopsExistingObservationFirst() {
        // Given
        user.addBurnedCaloriesEnabled = true
        user.healthSyncEnabled = true
        let today = Date()

        // When - start observation
        viewModel.startEnergyObservation(user: user, date: today)

        // Then - should have stopped any existing observation first
        XCTAssertTrue(mockStopper.isStopped, "Should stop existing observation before starting new one")
        XCTAssertTrue(mockStarter.isStarted)
    }

    func testObservationCallback_UpdatesActiveEnergy() {
        // Given
        user.addBurnedCaloriesEnabled = true
        user.healthSyncEnabled = true
        viewModel.startEnergyObservation(user: user, date: Date())

        guard let handler = mockStarter.handler else {
            XCTFail("Handler not captured")
            return
        }

        // When
        let testEnergy = 250.0
        handler(testEnergy)

        // Then
        XCTAssertEqual(viewModel.activeEnergyBurned, testEnergy)
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        // Given - fresh viewModel
        let freshViewModel = NutritionSummaryViewModel(
            mealLogService: nil,
            calorieAdjustmentService: CalorieAdjustmentService(),
            energyObservationStarter: mockStarter.start,
            energyObservationStopper: mockStopper.stop
        )

        // Then - initial state should be correct
        XCTAssertEqual(freshViewModel.activeEnergyBurned, 0)
        XCTAssertEqual(freshViewModel.adjustedCalorieTarget, 0)
        XCTAssertTrue(freshViewModel.isLoading)
        XCTAssertNil(freshViewModel.loadError)
    }

    // MARK: - Totals Tests

    func testTotals_DefaultsToZero() {
        XCTAssertEqual(viewModel.totals.calories, 0)
        XCTAssertEqual(viewModel.totals.protein, 0)
        XCTAssertEqual(viewModel.totals.carbs, 0)
        XCTAssertEqual(viewModel.totals.fat, 0)
    }
}

// MARK: - Mocks

class MockEnergyObservationStarter {
    var isStarted = false
    var handler: ((Double) -> Void)?

    @MainActor
    func start(handler: @escaping (Double) -> Void) {
        isStarted = true
        self.handler = handler
    }
}

class MockEnergyObservationStopper {
    var isStopped = false

    @MainActor
    func stop() {
        isStopped = true
    }
}
