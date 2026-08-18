//
//  FoodSearchSheetViewModelTests.swift
//  JabTrackerTests
//
//  Tests for the FoodSearchSheetViewModel.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

private enum SearchTestError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        "Search service unavailable"
    }
}

private actor SearchResultGate {
    private var pending: [String: CheckedContinuation<CategorizedSearchResults, Never>] = [:]

    func wait(for query: String) async -> CategorizedSearchResults {
        await withCheckedContinuation { continuation in
            if let previous = pending.removeValue(forKey: query) {
                previous.resume(
                    returning: CategorizedSearchResults(
                        historyResults: [],
                        customResults: [],
                        commonResults: [],
                        brandedResults: []
                    )
                )
            }
            pending[query] = continuation
        }
    }

    func hasPending(for query: String) -> Bool {
        pending[query] != nil
    }

    func release(query: String, with results: CategorizedSearchResults) {
        pending.removeValue(forKey: query)?.resume(returning: results)
    }
}

private actor RetrySearchProvider {
    private let successfulResults: CategorizedSearchResults
    private var attemptCount = 0

    init(successfulResults: CategorizedSearchResults) {
        self.successfulResults = successfulResults
    }

    func search(query: String, limit: Int) throws -> CategorizedSearchResults {
        _ = query
        _ = limit
        attemptCount += 1
        if attemptCount == 1 {
            throw SearchTestError.unavailable
        }
        return successfulResults
    }

    func attempts() -> Int {
        attemptCount
    }
}

@Suite("FoodSearchSheetViewModel Tests")
struct FoodSearchSheetViewModelTests {

    // MARK: - Test Setup

    @MainActor
    func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([User.self, Food.self, FoodEntry.self])
        let config = InMemoryTestStore.configuration(schema: schema)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            return (container.mainContext, container)
        } catch {
            fatalError("Failed to create test container: \(error)")
        }
    }

    @MainActor
    func createTestUser(context: ModelContext) -> User {
        let user = User()
        user.dailyCalorieGoal = 2000.0
        user.dailyProteinGoal = 150.0
        context.insert(user)
        try? context.save()
        return user
    }

    // MARK: - Initialization Tests

    @Test("ViewModel initializes with default values")
    @MainActor
    func viewModelInitializesWithDefaults() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectedMethod == .search)
        #expect(viewModel.searchState == .idle)
    }

    @Test("ViewModel selectedTime defaults to now")
    @MainActor
    func viewModelSelectedTimeDefaultsToNow() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        let timeDifference = abs(viewModel.selectedTime.timeIntervalSince(Date()))
        #expect(timeDifference < 2.0, "Selected time should be approximately now")
    }

    // MARK: - Search Results Tests

    @Test("ViewModel results arrays initialize empty")
    @MainActor
    func viewModelResultsArraysInitializeEmpty() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        #expect(viewModel.historyResults.isEmpty)
        #expect(viewModel.customResults.isEmpty)
        #expect(viewModel.commonResults.isEmpty)
        #expect(viewModel.brandedResults.isEmpty)
        #expect(viewModel.recentFoods.isEmpty)
    }

    @Test("ViewModel hasResults returns false when all empty")
    @MainActor
    func viewModelHasResultsReturnsFalseWhenEmpty() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        #expect(viewModel.hasResults == false)
    }

    // MARK: - Remaining Macros Tests

    @Test("ViewModel calculates remaining calories correctly")
    @MainActor
    func viewModelCalculatesRemainingCalories() async {
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(context: context)
        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        // Load initial data with goals but no entries
        await viewModel.loadInitialData(user: user, for: Date())

        // With no food logged, remaining should equal goal
        #expect(viewModel.remainingCalories == 2000.0)
        #expect(viewModel.remainingProtein == 150.0)
    }

    // MARK: - Clear Search Tests

    @Test("clearSearch resets search text and results")
    @MainActor
    func clearSearchResetsState() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        // Set some search state
        viewModel.searchText = "Burger"
        viewModel.searchTextDidChange()

        // Clear
        viewModel.clearSearch()

        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.searchState == .idle)
        #expect(viewModel.historyResults.isEmpty)
        #expect(viewModel.customResults.isEmpty)
        #expect(viewModel.commonResults.isEmpty)
        #expect(viewModel.brandedResults.isEmpty)
    }

    // MARK: - Method Selection Tests

    @Test("ViewModel defaults to search method")
    @MainActor
    func viewModelDefaultsToSearchMethod() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        #expect(viewModel.selectedMethod == .search)
    }

    @Test("ViewModel can change selected method")
    @MainActor
    func viewModelCanChangeSelectedMethod() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.selectedMethod = .scan

        #expect(viewModel.selectedMethod == .scan)
    }

    // MARK: - Expansion State Tests

    @Test("Expansion states initialize to false")
    @MainActor
    func expansionStatesInitializeToFalse() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        #expect(viewModel.historyExpanded == false)
        #expect(viewModel.customExpanded == false)
        #expect(viewModel.commonExpanded == false)
        #expect(viewModel.brandedExpanded == false)
    }

    @Test("Toggle history expanded flips state")
    @MainActor
    func toggleHistoryExpandedFlipsState() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        #expect(viewModel.historyExpanded == false)

        viewModel.toggleHistoryExpanded()
        #expect(viewModel.historyExpanded == true)

        viewModel.toggleHistoryExpanded()
        #expect(viewModel.historyExpanded == false)
    }

    @Test("Toggle custom expanded flips state")
    @MainActor
    func toggleCustomExpandedFlipsState() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.toggleCustomExpanded()
        #expect(viewModel.customExpanded == true)
    }

    @Test("Toggle common expanded flips state")
    @MainActor
    func toggleCommonExpandedFlipsState() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.toggleCommonExpanded()
        #expect(viewModel.commonExpanded == true)
    }

    @Test("Toggle branded expanded flips state")
    @MainActor
    func toggleBrandedExpandedFlipsState() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.toggleBrandedExpanded()
        #expect(viewModel.brandedExpanded == true)
    }

    // MARK: - Visible Results Tests

    @Test("Visible common results shows 5 when collapsed")
    @MainActor
    func visibleCommonResultsShows5WhenCollapsed() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        // Populate with more than 5 results
        viewModel.commonResults = createMockResults(count: 10)

        #expect(viewModel.commonExpanded == false)
        #expect(viewModel.visibleCommonResults.count == 5)
    }

    @Test("Visible common results shows all when expanded")
    @MainActor
    func visibleCommonResultsShowsAllWhenExpanded() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        // Populate with 10 results and expand
        viewModel.commonResults = createMockResults(count: 10)
        viewModel.toggleCommonExpanded()

        #expect(viewModel.commonExpanded == true)
        #expect(viewModel.visibleCommonResults.count == 10)
    }

    @Test("Visible results shows all if fewer than 5")
    @MainActor
    func visibleResultsShowsAllIfFewerThan5() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        // Populate with only 3 results
        viewModel.commonResults = createMockResults(count: 3)

        #expect(viewModel.commonExpanded == false)
        #expect(viewModel.visibleCommonResults.count == 3)
    }

    @Test("Visible history results respects expansion state")
    @MainActor
    func visibleHistoryResultsRespectsExpansionState() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.historyResults = createMockResults(count: 12)

        #expect(viewModel.visibleHistoryResults.count == 5)

        viewModel.toggleHistoryExpanded()
        #expect(viewModel.visibleHistoryResults.count == 12)
    }

    @Test("Visible branded results respects expansion state")
    @MainActor
    func visibleBrandedResultsRespectsExpansionState() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.brandedResults = createMockResults(count: 15)

        #expect(viewModel.visibleBrandedResults.count == 5)

        viewModel.toggleBrandedExpanded()
        #expect(viewModel.visibleBrandedResults.count == 15)
    }

    // MARK: - Remaining Count Tests

    @Test("Remaining count returns correct value")
    @MainActor
    func remainingCountReturnsCorrectValue() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.commonResults = createMockResults(count: 12)

        // 12 total - 5 shown = 7 remaining
        #expect(viewModel.remainingCommonCount() == 7)
    }

    @Test("Remaining count returns 0 when 5 or fewer")
    @MainActor
    func remainingCountReturns0WhenFiveOrFewer() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.commonResults = createMockResults(count: 5)
        #expect(viewModel.remainingCommonCount() == 0)

        viewModel.commonResults = createMockResults(count: 3)
        #expect(viewModel.remainingCommonCount() == 0)
    }

    @Test("Remaining count works for all sections")
    @MainActor
    func remainingCountWorksForAllSections() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.historyResults = createMockResults(count: 8)
        viewModel.customResults = createMockResults(count: 6)
        viewModel.commonResults = createMockResults(count: 15)
        viewModel.brandedResults = createMockResults(count: 3)

        #expect(viewModel.remainingHistoryCount() == 3)
        #expect(viewModel.remainingCustomCount() == 1)
        #expect(viewModel.remainingCommonCount() == 10)
        #expect(viewModel.remainingBrandedCount() == 0)
    }

    // MARK: - hasResults Tests

    @Test("hasResults returns true when history has results")
    @MainActor
    func hasResultsReturnsTrueWhenHistoryHasResults() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.historyResults = createMockResults(count: 1)
        #expect(viewModel.hasResults == true)
    }

    @Test("hasResults returns true when custom has results")
    @MainActor
    func hasResultsReturnsTrueWhenCustomHasResults() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.customResults = createMockResults(count: 1)
        #expect(viewModel.hasResults == true)
    }

    @Test("hasResults returns true when branded has results")
    @MainActor
    func hasResultsReturnsTrueWhenBrandedHasResults() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.brandedResults = createMockResults(count: 1)
        #expect(viewModel.hasResults == true)
    }

    // MARK: - visibleCustomResults Tests

    @Test("Visible custom results shows 5 when collapsed")
    @MainActor
    func visibleCustomResultsShows5WhenCollapsed() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.customResults = createMockResults(count: 10)

        #expect(viewModel.customExpanded == false)
        #expect(viewModel.visibleCustomResults.count == 5)
    }

    @Test("Visible custom results shows all when expanded")
    @MainActor
    func visibleCustomResultsShowsAllWhenExpanded() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.customResults = createMockResults(count: 10)
        viewModel.toggleCustomExpanded()

        #expect(viewModel.customExpanded == true)
        #expect(viewModel.visibleCustomResults.count == 10)
    }

    // MARK: - performSearch Tests

    @Test("Changing search text enters debounce and clears previous results")
    @MainActor
    func changingSearchTextEntersDebounceAndClearsPreviousResults() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService,
            searchProvider: { _, _ in
                CategorizedSearchResults(
                    historyResults: [],
                    customResults: [],
                    commonResults: [],
                    brandedResults: []
                )
            }
        )

        viewModel.commonResults = createMockResults(count: 1)
        viewModel.searchText = "Pizza"
        viewModel.searchTextDidChange()

        #expect(viewModel.searchState == .debouncing(query: "Pizza"))
        #expect(viewModel.hasResults == false)
    }

    @Test("Debounced search stays searching until the current query completes")
    @MainActor
    func searchStaysSearchingUntilCurrentQueryCompletes() async {
        let gate = SearchResultGate()
        let viewModel = makeViewModel { query, _ in
            await gate.wait(for: query)
        }

        viewModel.searchText = "Pizza"
        viewModel.searchTextDidChange()
        #expect(viewModel.searchState == .debouncing(query: "Pizza"))

        while !(await gate.hasPending(for: "Pizza")) {
            await Task.yield()
        }

        #expect(viewModel.searchState == .searching(query: "Pizza"))

        await gate.release(
            query: "Pizza",
            with: CategorizedSearchResults(
                historyResults: [],
                customResults: [],
                commonResults: [],
                brandedResults: []
            )
        )

        while viewModel.searchState != .completed(query: "Pizza") {
            await Task.yield()
        }

        #expect(viewModel.searchState == .completed(query: "Pizza"))
        #expect(viewModel.hasResults == false)
    }

    @Test("Failed search is retryable and never exposes empty results")
    @MainActor
    func failedSearchIsRetryableAndNeverExposesEmptyResults() async {
        let viewModel = makeViewModel { _, _ in
            throw SearchTestError.unavailable
        }

        viewModel.searchText = "Pizza"
        viewModel.searchTextDidChange()
        await viewModel.performSearch()

        #expect(
            viewModel.searchState
                == .failed(
                    query: "Pizza",
                    message: "Search service unavailable"
                )
        )
        #expect(viewModel.hasResults == false)
    }

    @Test("Unexpected search cancellation is retryable")
    @MainActor
    func unexpectedSearchCancellationIsRetryable() async {
        let viewModel = makeViewModel { _, _ in
            throw CancellationError()
        }

        viewModel.searchText = "Pizza"
        viewModel.searchTextDidChange()
        await viewModel.performSearch()

        #expect(
            viewModel.searchState
                == .failed(
                    query: "Pizza",
                    message: "Search was cancelled unexpectedly."
                )
        )
        #expect(viewModel.hasResults == false)
    }

    @Test("Retrying a failed search publishes results after the next attempt succeeds")
    @MainActor
    func retryingFailedSearchPublishesResultsAfterNextAttemptSucceeds() async {
        let provider = RetrySearchProvider(
            successfulResults: CategorizedSearchResults(
                historyResults: [],
                customResults: [],
                commonResults: [makeResult(name: "Pizza", source: .local)],
                brandedResults: []
            )
        )
        let viewModel = makeViewModel { query, limit in
            try await provider.search(query: query, limit: limit)
        }

        viewModel.searchText = "Pizza"
        viewModel.searchTextDidChange()
        await viewModel.performSearch()
        #expect(viewModel.searchState == .failed(query: "Pizza", message: "Search service unavailable"))

        // The UI retry button delegates to performSearch(), so exercise that public retry path directly.
        await viewModel.performSearch()

        #expect(viewModel.searchState == .completed(query: "Pizza"))
        #expect(viewModel.commonResults.map(\.name) == ["Pizza"])
        let attempts = await provider.attempts()
        #expect(attempts == 2)
    }

    @Test("Late results from a replaced query are ignored")
    @MainActor
    func lateResultsFromReplacedQueryAreIgnored() async {
        let gate = SearchResultGate()
        let viewModel = makeViewModel { query, _ in
            await gate.wait(for: query)
        }

        viewModel.searchText = "Pizza"
        viewModel.searchTextDidChange()
        let firstSearch = Task { await viewModel.performSearch() }
        while !(await gate.hasPending(for: "Pizza")) {
            await Task.yield()
        }

        viewModel.searchText = "Chicken"
        viewModel.searchTextDidChange()
        #expect(viewModel.searchState == .debouncing(query: "Chicken"))
        #expect(viewModel.hasResults == false)

        let secondSearch = Task { await viewModel.performSearch() }
        while !(await gate.hasPending(for: "Chicken")) {
            await Task.yield()
        }

        await gate.release(
            query: "Pizza",
            with: CategorizedSearchResults(
                historyResults: [],
                customResults: [],
                commonResults: [makeResult(name: "Old pizza", source: .local)],
                brandedResults: []
            )
        )
        await firstSearch.value

        #expect(viewModel.searchState == .searching(query: "Chicken"))
        #expect(viewModel.hasResults == false)

        await gate.release(
            query: "Chicken",
            with: CategorizedSearchResults(
                historyResults: [],
                customResults: [],
                commonResults: [],
                brandedResults: [makeResult(name: "New chicken", source: .openFoodFacts)]
            )
        )
        await secondSearch.value

        #expect(viewModel.searchState == .completed(query: "Chicken"))
        #expect(viewModel.commonResults.isEmpty)
        #expect(viewModel.brandedResults.map(\.name) == ["New chicken"])
    }

    @Test("Completed search preserves category and result ordering")
    @MainActor
    func completedSearchPreservesCategoryAndResultOrdering() async {
        let history = [
            makeResult(name: "History first", source: .userCreated),
            makeResult(name: "History second", source: .userCreated),
        ]
        let custom = [makeResult(name: "My food", source: .userCreated)]
        let common = [
            makeResult(name: "Common first", source: .local),
            makeResult(name: "Common second", source: .local),
        ]
        let branded = [makeResult(name: "Branded first", source: .openFoodFacts)]

        let viewModel = makeViewModel { _, _ in
            CategorizedSearchResults(
                historyResults: history,
                customResults: custom,
                commonResults: common,
                brandedResults: branded
            )
        }

        viewModel.searchText = "food"
        viewModel.searchTextDidChange()
        await viewModel.performSearch()

        #expect(viewModel.historyResults.map(\.name) == ["History first", "History second"])
        #expect(viewModel.customResults.map(\.name) == ["My food"])
        #expect(viewModel.commonResults.map(\.name) == ["Common first", "Common second"])
        #expect(viewModel.brandedResults.map(\.name) == ["Branded first"])
    }

    @Test("performSearch clears results when query is empty")
    @MainActor
    func performSearchClearsResultsWhenQueryEmpty() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        // Set up some existing results
        viewModel.commonResults = createMockResults(count: 5)
        viewModel.historyExpanded = true
        viewModel.searchText = ""

        await viewModel.performSearch()

        #expect(viewModel.commonResults.isEmpty)
        #expect(viewModel.historyExpanded == false)
    }

    @Test("performSearch clears results when query is whitespace only")
    @MainActor
    func performSearchClearsResultsWhenQueryWhitespace() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        viewModel.commonResults = createMockResults(count: 5)
        viewModel.searchText = "   "

        await viewModel.performSearch()

        #expect(viewModel.commonResults.isEmpty)
    }

    @Test("performSearch completes the current query lifecycle")
    @MainActor
    func performSearchCompletesCurrentQueryLifecycle() async {
        let viewModel = makeViewModel { _, _ in
            CategorizedSearchResults(
                historyResults: [],
                customResults: [],
                commonResults: [],
                brandedResults: []
            )
        }

        viewModel.searchText = "chicken"
        viewModel.searchTextDidChange()
        await viewModel.performSearch()

        #expect(viewModel.searchState == .completed(query: "chicken"))
    }

    // MARK: - Clear Search Resets Expansion Tests

    @Test("Clear search resets expansion state")
    @MainActor
    func clearSearchResetsExpansionState() async {
        let (context, container) = createTestContext()
        _ = container

        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)
        let viewModel = FoodSearchSheetViewModel(
            foodService: foodService,
            mealLogService: mealLogService
        )

        // Expand all sections
        viewModel.toggleHistoryExpanded()
        viewModel.toggleCustomExpanded()
        viewModel.toggleCommonExpanded()
        viewModel.toggleBrandedExpanded()

        #expect(viewModel.historyExpanded == true)
        #expect(viewModel.customExpanded == true)
        #expect(viewModel.commonExpanded == true)
        #expect(viewModel.brandedExpanded == true)

        // Clear search
        viewModel.clearSearch()

        #expect(viewModel.historyExpanded == false)
        #expect(viewModel.customExpanded == false)
        #expect(viewModel.commonExpanded == false)
        #expect(viewModel.brandedExpanded == false)
    }

    // MARK: - Helper Methods

    @MainActor
    private func makeViewModel(
        searchProvider: @escaping FoodSearchSheetViewModel.SearchProvider
    ) -> FoodSearchSheetViewModel {
        let (context, container) = createTestContext()
        _ = container

        return FoodSearchSheetViewModel(
            foodService: FoodService(context: context),
            mealLogService: MealLogService(context: context),
            searchProvider: searchProvider
        )
    }

    private func makeResult(name: String, source: FoodSource) -> FoodSearchResult {
        FoodSearchResult(
            fdcId: nil,
            barcode: nil,
            name: name,
            brand: nil,
            source: source,
            caloriesPer100g: 100,
            proteinPer100g: 10,
            carbsPer100g: 20,
            fatPer100g: 5,
            fiberPer100g: 2,
            category: nil
        )
    }

    @MainActor
    private func createMockResults(count: Int) -> [FoodSearchResult] {
        (0..<count).map { index in
            FoodSearchResult(
                fdcId: index,
                barcode: nil,
                name: "Food \(index)",
                brand: nil,
                source: .local,
                caloriesPer100g: 100,
                proteinPer100g: 10,
                carbsPer100g: 20,
                fatPer100g: 5,
                fiberPer100g: 2,
                category: nil
            )
        }
    }
}

// MARK: - SearchMethod Tests

@Suite("SearchMethod Tests")
struct SearchMethodTests {

    @Test("SearchMethod has 5 cases")
    func searchMethodHasFiveCases() {
        #expect(SearchMethod.allCases.count == 5)
    }

    @Test("SearchMethod.search, .scan, .library, and .quickAdd are enabled")
    func searchMethodSearchScanLibraryAndQuickAddEnabled() {
        for method in SearchMethod.allCases {
            if method == .search || method == .scan || method == .library || method == .quickAdd {
                #expect(method.isEnabled == true, "Method \(method.rawValue) should be enabled")
            } else {
                #expect(method.isEnabled == false, "Method \(method.rawValue) should be disabled")
            }
        }
    }

    @Test("SearchMethod has correct display names")
    func searchMethodHasCorrectDisplayNames() {
        #expect(SearchMethod.scan.displayName == "Scan")
        #expect(SearchMethod.search.displayName == "Search")
        #expect(SearchMethod.ai.displayName == "AI")
        #expect(SearchMethod.quickAdd.displayName == "Quick Add")
        #expect(SearchMethod.library.displayName == "Library")
    }

    @Test("SearchMethod has correct icons")
    func searchMethodHasCorrectIcons() {
        #expect(SearchMethod.scan.icon == "barcode.viewfinder")
        #expect(SearchMethod.search.icon == "magnifyingglass")
        #expect(SearchMethod.ai.icon == "sparkles")
        #expect(SearchMethod.quickAdd.icon == "plus.circle")
        #expect(SearchMethod.library.icon == "books.vertical")
    }

    @Test("SearchMethod is identifiable by raw value")
    func searchMethodIsIdentifiableByRawValue() {
        #expect(SearchMethod.search.id == "search")
        #expect(SearchMethod.scan.id == "scan")
    }
}
