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
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "FoodSearchSheetViewModel")

    // MARK: - Dependencies

    private let foodService: FoodService
    private let mealLogService: MealLogService

    // MARK: - Search State

    /// Current search text
    var searchText = ""

    /// Selected search method (only .search is functional)
    var selectedMethod: SearchMethod = .search

    /// Selected time for the food entry
    var selectedTime: Date = Date()

    /// Whether a search is in progress
    var isSearching = false

    /// Error message from the last operation
    var errorMessage: String?

    // MARK: - Results (Grouped by Source)

    /// Results from user's food history
    var historyResults: [FoodSearchResult] = []

    /// Results from user-created custom foods
    var customResults: [FoodSearchResult] = []

    /// Results from USDA database (common foods)
    var commonResults: [FoodSearchResult] = []

    /// Results from Open Food Facts (branded foods)
    var brandedResults: [FoodSearchResult] = []

    // MARK: - Recent Foods (Empty State)

    /// Recently accessed foods for empty state display
    var recentFoods: [Food] = []

    // MARK: - Daily Tracking

    /// Remaining calories for the day
    var remainingCalories: Double = 0

    /// Remaining protein for the day
    var remainingProtein: Double = 0

    // MARK: - Computed Properties

    /// Whether there are any search results
    var hasResults: Bool {
        !historyResults.isEmpty || !customResults.isEmpty || !commonResults.isEmpty || !brandedResults.isEmpty
    }

    // MARK: - Private State

    /// Task handle for cancelling ongoing search
    private var searchTask: Task<Void, Never>?

    // MARK: - Initialization

    init(foodService: FoodService, mealLogService: MealLogService) {
        self.foodService = foodService
        self.mealLogService = mealLogService
    }

    // MARK: - Public Methods

    /// Load initial data including recent foods and daily totals
    func loadInitialData(user: User, for date: Date) async {
        Self.logger.debug("Loading initial data for food search")

        // Load remaining macros
        do {
            let totals = try await mealLogService.getDailyTotals(for: date)
            remainingCalories = max(0, user.dailyCalorieGoal - totals.calories)
            remainingProtein = max(0, user.dailyProteinGoal - totals.protein)
            Self.logger.debug("Remaining: \(self.remainingCalories) cal, \(self.remainingProtein)g protein")
        } catch {
            Self.logger.error("Failed to load daily totals: \(error.localizedDescription)")
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

    /// Perform search with the current search text
    func performSearch() async {
        // Cancel any ongoing search
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Clear results if query is empty
        guard !query.isEmpty else {
            clearResults()
            return
        }

        Self.logger.debug("Searching for: \(query)")
        isSearching = true
        errorMessage = nil

        searchTask = Task {
            do {
                // Search local database only (1.7M+ foods available offline)
                let results = try await foodService.searchLocal(query: query, limit: 30)

                guard !Task.isCancelled else { return }

                // Group results by source
                groupResults(results)

                Self.logger.debug("Search complete: \(results.count) results")
            } catch {
                guard !Task.isCancelled else { return }

                Self.logger.error("Search failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }

            isSearching = false
        }

        await searchTask?.value
    }

    /// Clear search text and results
    func clearSearch() {
        searchText = ""
        isSearching = false
        searchTask?.cancel()
        clearResults()
    }

    // MARK: - Private Methods

    /// Clear all result arrays
    private func clearResults() {
        historyResults = []
        customResults = []
        commonResults = []
        brandedResults = []
    }

    /// Group search results by their source
    private func groupResults(_ results: [FoodSearchResult]) {
        clearResults()

        for result in results {
            switch result.source {
            case .userCreated:
                customResults.append(result)
            case .local:
                commonResults.append(result)
            case .openFoodFacts:
                brandedResults.append(result)
            }
        }

        // Note: historyResults would require tracking food access history
        // For now, this is populated from recent foods feature
        // In a full implementation, we'd check if any results were recently logged
    }
}
