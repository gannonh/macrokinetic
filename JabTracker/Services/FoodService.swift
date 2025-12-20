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
    let servingSize: Double  // Default serving size in grams
    let servingOptions: [ServingOption]  // Available serving options

    /// Initialize with all parameters
    init(
        fdcId: Int?,
        barcode: String?,
        name: String,
        brand: String?,
        source: FoodSource,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        fiberPer100g: Double,
        category: String?,
        servingSize: Double = 100.0,
        servingOptions: [ServingOption] = []
    ) {
        self.fdcId = fdcId
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.source = source
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.category = category
        self.servingSize = servingSize
        self.servingOptions = servingOptions
    }

    // MARK: - Serving-Based Computed Properties

    /// Default serving option (prefer item over grams)
    var defaultServing: ServingOption {
        // Prefer "item" or similar serving over raw grams
        if let itemServing = servingOptions.first(where: { !$0.label.hasSuffix("g") }) {
            return itemServing
        }
        // Use food's serving size if meaningful
        if servingSize > 0 && servingSize != 100 {
            return ServingOption(label: "\(Int(servingSize))g", grams: servingSize)
        }
        return servingOptions.first ?? ServingOption(label: "100g", grams: 100)
    }

    /// Whether this food has item-based serving (e.g., "1 item" vs just grams)
    var hasItemServing: Bool {
        servingOptions.contains { !$0.label.hasSuffix("g") }
    }

    /// Calories for the default serving
    var caloriesPerServing: Double {
        (caloriesPer100g * defaultServing.grams) / 100.0
    }

    /// Protein for the default serving
    var proteinPerServing: Double {
        (proteinPer100g * defaultServing.grams) / 100.0
    }

    /// Carbs for the default serving
    var carbsPerServing: Double {
        (carbsPer100g * defaultServing.grams) / 100.0
    }

    /// Fat for the default serving
    var fatPerServing: Double {
        (fatPer100g * defaultServing.grams) / 100.0
    }

    /// Display string for the serving (e.g., "1 item" or "per 100g")
    var servingDisplayString: String {
        if hasItemServing {
            return defaultServing.label
        }
        return "per 100g"
    }
}

/// Represents a serving option for a food item
struct ServingOption: Identifiable, Equatable {
    let id = UUID()
    let label: String  // Display label (e.g., "1 item", "100g", "1 cup")
    let grams: Double  // Equivalent weight in grams

    /// Parse serving options from JSON string (e.g., '["100g", "1.0 item (291g)"]')
    static func parse(from jsonString: String) -> [ServingOption] {
        guard let data = jsonString.data(using: .utf8),
            let options = try? JSONDecoder().decode([String].self, from: data)
        else {
            return [ServingOption(label: "100g", grams: 100)]
        }

        return options.compactMap { parseOption($0) }
    }

    /// Parse a single serving option string (e.g., "1.0 item (291g)")
    private static func parseOption(_ option: String) -> ServingOption? {
        // Handle simple gram format: "100g"
        if option.hasSuffix("g"), let grams = Double(option.dropLast()) {
            return ServingOption(label: option, grams: grams)
        }

        // Handle item format: "1.0 item (291g)"
        let pattern = #"^([\d.]+)\s*(\w+)\s*\((\d+(?:\.\d+)?)g\)$"#
        if let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(in: option, range: NSRange(option.startIndex..., in: option)),
            let quantityRange = Range(match.range(at: 1), in: option),
            let unitRange = Range(match.range(at: 2), in: option),
            let gramsRange = Range(match.range(at: 3), in: option)
        {
            let quantity = Double(option[quantityRange]) ?? 1.0
            let unit = String(option[unitRange])
            let grams = Double(option[gramsRange]) ?? 100.0

            // Format label nicely
            let label = quantity == 1.0 ? "1 \(unit)" : "\(Int(quantity)) \(unit)"
            return ServingOption(label: label, grams: grams)
        }

        return nil
    }

    static func == (lhs: ServingOption, rhs: ServingOption) -> Bool {
        lhs.label == rhs.label && lhs.grams == rhs.grams
    }
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
            // Map database source string to FoodSource enum
            let source: FoodSource =
                switch local.source {
                case "openFoodFacts": .openFoodFacts
                case "foundation", "sr_legacy": .local
                default: .local
                }

            // Parse serving options from JSON string
            let servingOptions = ServingOption.parse(from: local.servingOptions)

            return FoodSearchResult(
                fdcId: local.fdcId,
                barcode: local.barcode,
                name: local.name,
                brand: local.brand,
                source: source,
                caloriesPer100g: local.caloriesPer100g,
                proteinPer100g: local.proteinPer100g,
                carbsPer100g: local.carbsPer100g,
                fatPer100g: local.fatPer100g,
                fiberPer100g: local.fiberPer100g,
                category: local.category,
                servingSize: local.servingSize,
                servingOptions: servingOptions
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
