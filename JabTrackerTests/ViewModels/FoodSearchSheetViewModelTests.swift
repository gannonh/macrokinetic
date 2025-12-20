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

@Suite("FoodSearchSheetViewModel Tests")
struct FoodSearchSheetViewModelTests {

    // MARK: - Test Setup

    @MainActor
    func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([User.self, Food.self, FoodEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
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
        #expect(!viewModel.isSearching)
        #expect(viewModel.errorMessage == nil)
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
        viewModel.isSearching = true

        // Clear
        viewModel.clearSearch()

        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.isSearching == false)
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
}

// MARK: - SearchMethod Tests

@Suite("SearchMethod Tests")
struct SearchMethodTests {

    @Test("SearchMethod has 5 cases")
    func searchMethodHasFiveCases() {
        #expect(SearchMethod.allCases.count == 5)
    }

    @Test("SearchMethod.search is only enabled method")
    func searchMethodOnlySearchEnabled() {
        for method in SearchMethod.allCases {
            if method == .search {
                #expect(method.isEnabled == true)
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
