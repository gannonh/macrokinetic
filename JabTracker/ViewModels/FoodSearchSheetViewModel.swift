//
//  FoodSearchSheetViewModel.swift
//  JabTracker
//
//  ViewModel for the enhanced food search sheet.
//

import Foundation
import OSLog
import SwiftData

/// ViewModel managing state for the FoodSearchSheet
@Observable
@MainActor
final class FoodSearchSheetViewModel {
    enum SearchState: Equatable {
        case idle
        case debouncing(query: String)
        case searching(query: String)
        case completed(query: String)
        case failed(query: String, message: String)

        var query: String? {
            switch self {
            case .idle:
                return nil
            case let .debouncing(query), let .searching(query), let .completed(query), let .failed(query, _):
                return query
            }
        }

        var isExecuting: Bool {
            if case .searching = self {
                return true
            }
            return false
        }
    }

    typealias SearchProvider = (String, Int) async throws -> CategorizedSearchResults

    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "FoodSearchSheetViewModel")

    // MARK: - Dependencies

    private let foodService: FoodService
    private let mealLogService: MealLogService
    private let searchProvider: SearchProvider

    // MARK: - Search State

    /// Current search text
    var searchText = ""

    /// Selected search method (only .search is functional)
    var selectedMethod: SearchMethod = .search

    /// Selected time for the food entry
    var selectedTime: Date = Date()

    /// Current lifecycle state for the active search query.
    var searchState: SearchState = .idle
    var searchStartedAt: Date?

    // MARK: - Results (Grouped by Source)

    /// Results from user's food history (up to 15)
    var historyResults: [FoodSearchResult] = []

    /// Results from user-created custom foods (up to 15)
    var customResults: [FoodSearchResult] = []

    /// Results from USDA database - common foods (up to 15)
    var commonResults: [FoodSearchResult] = []

    /// Results from Open Food Facts - branded foods (up to 15)
    var brandedResults: [FoodSearchResult] = []

    // MARK: - Section Expansion State

    /// Whether the history section is expanded (shows all vs first 5)
    var historyExpanded = false

    /// Whether the custom section is expanded
    var customExpanded = false

    /// Whether the common section is expanded
    var commonExpanded = false

    /// Whether the branded section is expanded
    var brandedExpanded = false

    // MARK: - Recent Foods (Empty State)

    /// Recently accessed foods for empty state display
    var recentFoods: [Food] = []

    // MARK: - Daily Tracking

    /// Consumed calories for the day
    var consumedCalories: Double = 0

    /// Target calories for the day
    var targetCalories: Double = 0

    /// Consumed protein for the day
    var consumedProtein: Double = 0

    /// Target protein for the day
    var targetProtein: Double = 0

    /// Remaining calories for the day
    var remainingCalories: Double = 0

    /// Remaining protein for the day
    var remainingProtein: Double = 0

    // MARK: - Computed Properties

    /// Whether there are any search results
    var hasResults: Bool {
        !historyResults.isEmpty || !customResults.isEmpty || !commonResults.isEmpty || !brandedResults.isEmpty
    }

    // MARK: - Visible Results (respects expand/collapse state)

    /// Visible history results (5 when collapsed, up to 15 when expanded)
    var visibleHistoryResults: [FoodSearchResult] {
        historyExpanded ? historyResults : Array(historyResults.prefix(5))
    }

    /// Visible custom results
    var visibleCustomResults: [FoodSearchResult] {
        customExpanded ? customResults : Array(customResults.prefix(5))
    }

    /// Visible common results
    var visibleCommonResults: [FoodSearchResult] {
        commonExpanded ? commonResults : Array(commonResults.prefix(5))
    }

    /// Visible branded results
    var visibleBrandedResults: [FoodSearchResult] {
        brandedExpanded ? brandedResults : Array(brandedResults.prefix(5))
    }

    // MARK: - Remaining Counts (for "See X More" button)

    /// Number of additional history results that can be shown
    func remainingHistoryCount() -> Int {
        max(0, historyResults.count - 5)
    }

    /// Number of additional custom results that can be shown
    func remainingCustomCount() -> Int {
        max(0, customResults.count - 5)
    }

    /// Number of additional common results that can be shown
    func remainingCommonCount() -> Int {
        max(0, commonResults.count - 5)
    }

    /// Number of additional branded results that can be shown
    func remainingBrandedCount() -> Int {
        max(0, brandedResults.count - 5)
    }

    // MARK: - Toggle Expansion

    func toggleHistoryExpanded() {
        historyExpanded.toggle()
    }

    func toggleCustomExpanded() {
        customExpanded.toggle()
    }

    func toggleCommonExpanded() {
        commonExpanded.toggle()
    }

    func toggleBrandedExpanded() {
        brandedExpanded.toggle()
    }

    // MARK: - Private State

    /// Task handle for cancelling ongoing search
    private var searchTask: Task<Void, Never>?
    private var searchGeneration = 0

    // MARK: - Initialization

    init(
        foodService: FoodService,
        mealLogService: MealLogService,
        searchProvider: SearchProvider? = nil
    ) {
        self.foodService = foodService
        self.mealLogService = mealLogService
        self.searchProvider =
            searchProvider ?? { query, limit in
                try await foodService.searchCategorized(query: query, limit: limit)
            }
    }

    // MARK: - Public Methods

    /// Load initial data including recent foods and daily totals
    func loadInitialData(user: User, for date: Date) async {
        Self.logger.debug("Loading initial data for food search")

        // Set target values from user goals
        targetCalories = user.dailyCalorieGoal
        targetProtein = user.dailyProteinGoal

        // Load consumed and remaining macros
        do {
            let totals = try await mealLogService.getDailyTotals(for: date)
            consumedCalories = totals.calories
            consumedProtein = totals.protein
            remainingCalories = max(0, user.dailyCalorieGoal - totals.calories)
            remainingProtein = max(0, user.dailyProteinGoal - totals.protein)
            Self.logger.debug("Consumed: \(self.consumedCalories) cal, \(self.consumedProtein)g protein")
            Self.logger.debug("Remaining: \(self.remainingCalories) cal, \(self.remainingProtein)g protein")
        } catch {
            Self.logger.error("Failed to load daily totals: \(error.localizedDescription)")
            consumedCalories = 0
            consumedProtein = 0
            remainingCalories = user.dailyCalorieGoal
            remainingProtein = user.dailyProteinGoal
        }

        // Load recent foods
        do {
            recentFoods = try await foodService.getRecentFoods(limit: 10)
            Self.logger.debug("Loaded \(self.recentFoods.count) recent foods")
        } catch {
            Self.logger.error("Failed to load recent foods: \(error.localizedDescription)")
            recentFoods = []
        }
    }

    /// Notify the view model that the text input changed.
    ///
    /// This immediately invalidates the previous query so its results cannot remain
    /// visible during the debounce interval or publish after a replacement query.
    func searchTextDidChange() {
        searchTask?.cancel()
        searchGeneration += 1
        searchStartedAt = nil
        clearResults()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchState = .idle
            return
        }

        searchState = .debouncing(query: query)
        let generation = searchGeneration
        searchTask = Task { [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                await self.runSearch(query: query, generation: generation)
            } catch is CancellationError {
                // Cancellation is expected when the user replaces the query.
            } catch {
                // Task.sleep currently only throws CancellationError.
            }
        }
    }

    /// Perform search with the current search text.
    func performSearch() async {
        searchTask?.cancel()
        searchGeneration += 1
        let generation = searchGeneration

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Clear results if query is empty
        guard !query.isEmpty else {
            clearResults()
            searchStartedAt = nil
            searchState = .idle
            return
        }

        Self.logger.debug("Searching for: \(query)")
        clearResults()
        searchStartedAt = Date()
        searchState = .searching(query: query)

        let task = Task { [weak self] in
            guard let self else { return }
            await self.runSearch(query: query, generation: generation)
        }
        searchTask = task

        await task.value
    }

    /// Clear search text and results
    func clearSearch() {
        searchText = ""
        searchTask?.cancel()
        searchGeneration += 1
        searchStartedAt = nil
        clearResults()
        searchState = .idle
    }

    // MARK: - Private Methods

    private func runSearch(query: String, generation: Int) async {
        guard !Task.isCancelled,
            searchGeneration == generation,
            searchText.trimmingCharacters(in: .whitespacesAndNewlines) == query
        else { return }

        searchStartedAt = Date()
        searchState = .searching(query: query)

        do {
            // Search with categorized results (each source gets its own limit).
            // This ensures USDA common foods aren't drowned out by 1.7M OFF branded products.
            let results = try await searchProvider(query, 15)

            guard !Task.isCancelled,
                searchGeneration == generation,
                searchText.trimmingCharacters(in: .whitespacesAndNewlines) == query
            else { return }

            historyResults = results.historyResults
            customResults = results.customResults
            commonResults = results.commonResults
            brandedResults = results.brandedResults

            Self.logger.debug(
                """
                Search complete: \(results.totalCount) results \
                (history=\(results.historyResults.count), common=\(results.commonResults.count))
                """
            )
            searchState = .completed(query: query)
        } catch is CancellationError {
            // Cancellation is expected when the user replaces the query.
        } catch {
            guard !Task.isCancelled,
                searchGeneration == generation,
                searchText.trimmingCharacters(in: .whitespacesAndNewlines) == query
            else { return }

            Self.logger.error("Search failed: \(error.localizedDescription)")
            clearResults()
            searchState = .failed(query: query, message: error.localizedDescription)
        }
    }

    /// Clear all result arrays and reset expansion state
    private func clearResults() {
        historyResults = []
        customResults = []
        commonResults = []
        brandedResults = []

        // Reset expansion state when clearing results
        historyExpanded = false
        customExpanded = false
        commonExpanded = false
        brandedExpanded = false
    }
}
