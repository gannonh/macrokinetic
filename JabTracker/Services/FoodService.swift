//
//  FoodService.swift
//  JabTracker
//

import Foundation
import OSLog
import SwiftData

/// Unified food search result from any source
struct FoodSearchResult {
    let fdcId: Int?
    let barcode: String?
    let name: String
    let brand: String?
    let source: FoodSource
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double
    let category: String?
}

/// Service that orchestrates food search across multiple sources
/// Combines local USDA database, Open Food Facts API, and user-created foods
@MainActor
final class FoodService {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "FoodService")

    private let context: ModelContext
    private let localDatabase: LocalFoodDatabase
    private let openFoodFacts: OpenFoodFactsService

    /// Initialize with model context
    init(context: ModelContext) {
        self.context = context
        self.localDatabase = LocalFoodDatabase()
        self.openFoodFacts = OpenFoodFactsService()
    }

    /// Initialize with custom services (for testing)
    init(context: ModelContext, localDatabase: LocalFoodDatabase, openFoodFacts: OpenFoodFactsService) {
        self.context = context
        self.localDatabase = localDatabase
        self.openFoodFacts = openFoodFacts
    }

    // MARK: - Search Methods

    /// Search for foods across all sources
    /// - Parameters:
    ///   - query: Search term
    ///   - limit: Maximum results to return
    ///   - includeAPI: Whether to include Open Food Facts API results
    /// - Returns: Combined search results
    func search(query: String, limit: Int = 20, includeAPI: Bool = false) async throws -> [FoodSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        // Start with local database (fast)
        var results = try await searchLocalDatabase(query: trimmedQuery, limit: limit)

        // If API is enabled, always fetch API results
        if includeAPI {
            let apiResults = try await searchOpenFoodFacts(query: trimmedQuery, limit: limit)

            // Deduplicate by name similarity
            for apiResult in apiResults {
                let isDuplicate = results.contains { existing in
                    areSimilarFoods(existing.name, apiResult.name)
                }
                if !isDuplicate {
                    results.append(apiResult)
                }
            }
        }

        // Also check user-created foods from SwiftData
        let userFoods = try await searchUserCreatedFoods(query: trimmedQuery, limit: 5)
        for userFood in userFoods where !results.contains(where: { $0.name == userFood.name }) {
            results.insert(userFood, at: 0)  // User foods first
        }

        return Array(results.prefix(limit))
    }

    /// Search local USDA database only (fast)
    func searchLocal(query: String, limit: Int = 20) async throws -> [FoodSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        // Search local database
        var results = try await searchLocalDatabase(query: trimmedQuery, limit: limit)

        // Also check user-created foods
        let userFoods = try await searchUserCreatedFoods(query: trimmedQuery, limit: 5)
        for userFood in userFoods where !results.contains(where: { $0.name == userFood.name }) {
            results.insert(userFood, at: 0)
        }

        return Array(results.prefix(limit))
    }

    /// Search Open Food Facts API only (slower, has branded foods)
    func searchAPI(query: String, limit: Int = 20) async throws -> [FoodSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        return try await searchOpenFoodFacts(query: trimmedQuery, limit: limit)
    }

    /// Look up food by barcode
    /// - Parameter barcode: Product barcode
    /// - Returns: Food if found
    func lookupBarcode(_ barcode: String) async throws -> FoodSearchResult? {
        guard let result = try await openFoodFacts.lookup(barcode: barcode) else {
            return nil
        }

        return FoodSearchResult(
            fdcId: nil,
            barcode: result.barcode,
            name: result.name,
            brand: result.brand,
            source: .openFoodFacts,
            caloriesPer100g: result.caloriesPer100g,
            proteinPer100g: result.proteinPer100g,
            carbsPer100g: result.carbsPer100g,
            fatPer100g: result.fatPer100g,
            fiberPer100g: result.fiberPer100g,
            category: nil
        )
    }

    // MARK: - Food Model Conversion

    /// Create a Food model from a search result
    /// - Parameter result: Search result to convert
    /// - Returns: Food model (not yet inserted into context)
    func createFood(from result: FoodSearchResult) -> Food {
        let food = Food(
            name: result.name,
            brand: result.brand ?? "",
            caloriesPer100g: result.caloriesPer100g,
            proteinPer100g: result.proteinPer100g,
            carbsPer100g: result.carbsPer100g,
            fatPer100g: result.fatPer100g,
            fiberPer100g: result.fiberPer100g
        )
        food.foodSource = result.source
        food.barcode = result.barcode ?? ""

        if let fdcId = result.fdcId {
            food.fdcId = fdcId
        }

        return food
    }

    // MARK: - Recent Foods

    /// Save a food to recent foods (updates lastAccessedAt)
    /// - Parameter food: Food to save
    func saveRecentFood(_ food: Food) {
        food.lastAccessedAt = Date()
        context.insert(food)
        try? context.save()
    }

    /// Get recently accessed foods
    /// - Parameter limit: Maximum number to return
    /// - Returns: Recently accessed foods ordered by date
    func getRecentFoods(limit: Int = 10) async throws -> [Food] {
        var descriptor = FetchDescriptor<Food>(
            sortBy: [SortDescriptor(\.lastAccessedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try context.fetch(descriptor)
    }

    // MARK: - Private Search Helpers

    private func searchLocalDatabase(query: String, limit: Int) async throws -> [FoodSearchResult] {
        let localResults = try await localDatabase.search(query: query, limit: limit)

        return localResults.map { local in
            FoodSearchResult(
                fdcId: local.fdcId,
                barcode: nil,
                name: local.name,
                brand: local.brand,
                source: .local,
                caloriesPer100g: local.caloriesPer100g,
                proteinPer100g: local.proteinPer100g,
                carbsPer100g: local.carbsPer100g,
                fatPer100g: local.fatPer100g,
                fiberPer100g: local.fiberPer100g,
                category: local.category
            )
        }
    }

    private func searchOpenFoodFacts(query: String, limit: Int) async throws -> [FoodSearchResult] {
        do {
            let apiResults = try await openFoodFacts.search(query: query, limit: limit)

            return apiResults.map { api in
                FoodSearchResult(
                    fdcId: nil,
                    barcode: api.barcode,
                    name: api.name,
                    brand: api.brand,
                    source: .openFoodFacts,
                    caloriesPer100g: api.caloriesPer100g,
                    proteinPer100g: api.proteinPer100g,
                    carbsPer100g: api.carbsPer100g,
                    fatPer100g: api.fatPer100g,
                    fiberPer100g: api.fiberPer100g,
                    category: nil
                )
            }
        } catch {
            // API errors are non-fatal - log and continue with local results
            Self.logger.warning("Open Food Facts search failed: \(error.localizedDescription)")
            return []
        }
    }

    private func searchUserCreatedFoods(query: String, limit: Int) async throws -> [FoodSearchResult] {
        let lowercaseQuery = query.lowercased()

        var descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { food in
                food.source == "userCreated"
            }
        )
        descriptor.fetchLimit = 100  // Fetch more to filter locally

        let userFoods = try context.fetch(descriptor)

        // Filter by query
        let filtered =
            userFoods
            .filter { $0.name.lowercased().contains(lowercaseQuery) }
            .prefix(limit)

        return filtered.map { food in
            FoodSearchResult(
                fdcId: food.fdcId,
                barcode: food.barcode,
                name: food.name,
                brand: food.brand,
                source: .userCreated,
                caloriesPer100g: food.caloriesPer100g,
                proteinPer100g: food.proteinPer100g,
                carbsPer100g: food.carbsPer100g,
                fatPer100g: food.fatPer100g,
                fiberPer100g: food.fiberPer100g,
                category: nil
            )
        }
    }

    /// Check if two food names are similar enough to be duplicates
    private func areSimilarFoods(_ name1: String, _ name2: String) -> Bool {
        let normalized1 = name1.lowercased().trimmingCharacters(in: .whitespaces)
        let normalized2 = name2.lowercased().trimmingCharacters(in: .whitespaces)

        if normalized1 == normalized2 {
            return true
        }

        // Check if one contains the other
        if normalized1.contains(normalized2) || normalized2.contains(normalized1) {
            return true
        }

        return false
    }
}
