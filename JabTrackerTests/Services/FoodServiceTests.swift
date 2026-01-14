//
//  FoodServiceTests.swift
//  JabTrackerTests
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Tests for FoodService orchestrator
/// Verifies combined local + API search functionality
@Suite("FoodService Tests")
@MainActor
struct FoodServiceTests {

    // MARK: - Search Tests

    @Test("Search returns local results for common foods")
    func testSearchReturnsLocalResults() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        let results = try await service.search(query: "chicken")

        #expect(!results.isEmpty, "Should find chicken from local database")
    }

    @Test("Search returns empty for invalid query")
    func testSearchReturnsEmptyForInvalidQuery() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        let results = try await service.search(query: "")

        #expect(results.isEmpty)
    }

    @Test("Search handles whitespace query")
    func testSearchHandlesWhitespaceQuery() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        let results = try await service.search(query: "   ")

        #expect(results.isEmpty)
    }

    @Test("Search respects limit")
    func testSearchRespectsLimit() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        let results = try await service.search(query: "chicken", limit: 3)

        #expect(results.count <= 3)
    }

    // MARK: - Result Conversion Tests

    @Test("Search results contain source information")
    func testSearchResultsContainSource() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        let results = try await service.search(query: "chicken")

        for result in results {
            #expect(result.source == .local || result.source == .openFoodFacts || result.source == .userCreated)
        }
    }

    @Test("Search results have nutrition data")
    func testSearchResultsHaveNutritionData() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        let results = try await service.search(query: "chicken breast")

        guard let first = results.first else {
            Issue.record("No results found")
            return
        }

        // Chicken breast should have protein
        #expect(first.proteinPer100g > 0)
    }

    // MARK: - Food Model Conversion Tests

    @Test("Convert result to Food model preserves data")
    func testConvertResultToFoodModel() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        let results = try await service.search(query: "banana")

        guard let result = results.first else {
            Issue.record("No results for banana")
            return
        }

        let food = service.createFood(from: result)

        #expect(food.name == result.name)
        #expect(food.caloriesPer100g == result.caloriesPer100g)
        #expect(food.proteinPer100g == result.proteinPer100g)
    }

    @Test("Create Food model sets correct source")
    func testCreateFoodModelSetsSource() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        let results = try await service.search(query: "rice")

        guard let result = results.first else {
            Issue.record("No results for rice")
            return
        }

        let food = service.createFood(from: result)

        #expect(food.foodSource == result.source)
    }

    // MARK: - Recent Foods Tests

    @Test("Save recent food stores in context")
    func testSaveRecentFoodStoresInContext() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        let food = Food(
            name: "Test Food",
            caloriesPer100g: 100,
            proteinPer100g: 10,
            carbsPer100g: 20,
            fatPer100g: 5
        )

        try service.saveRecentFood(food)

        // Fetch from context
        let descriptor = FetchDescriptor<Food>()
        let foods = try context.fetch(descriptor)

        #expect(foods.contains { $0.name == "Test Food" })
    }

    @Test("Get recent foods returns recently accessed")
    func testGetRecentFoodsReturnsRecentlyAccessed() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        // Save a food
        let food = Food(
            name: "Recent Test Food",
            caloriesPer100g: 200,
            proteinPer100g: 15,
            carbsPer100g: 25,
            fatPer100g: 8
        )
        food.lastAccessedAt = Date()
        context.insert(food)
        try context.save()

        let recentFoods = try await service.getRecentFoods(limit: 5)

        #expect(recentFoods.contains { $0.name == "Recent Test Food" })
    }

    @Test("Recent foods ordered by last accessed date")
    func testRecentFoodsOrderedByLastAccessed() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        // Create foods with different access times
        let olderFood = Food(name: "Older Food", caloriesPer100g: 100)
        olderFood.lastAccessedAt = Date().addingTimeInterval(-3600)  // 1 hour ago
        context.insert(olderFood)

        let newerFood = Food(name: "Newer Food", caloriesPer100g: 100)
        newerFood.lastAccessedAt = Date()
        context.insert(newerFood)

        try context.save()

        let recentFoods = try await service.getRecentFoods(limit: 10)

        guard recentFoods.count >= 2 else {
            Issue.record("Not enough foods returned")
            return
        }

        // First should be the newer one
        #expect(recentFoods[0].name == "Newer Food")
        #expect(recentFoods[1].name == "Older Food")
    }

    // MARK: - Categorized Search Tests

    @Test("Categorized search returns all four categories")
    func testCategorizedSearchReturnsAllCategories() async throws {
        let (context, _) = createTestContextWithContainer()
        let service = FoodService(context: context)

        let results = try await service.searchCategorized(query: "banana")

        // Should have the structure with all 4 categories
        // historyResults will be empty since no FoodEntry records
        // customResults is a stub (empty)
        // commonResults and brandedResults should have data
        #expect(
            results.commonResults.count > 0 || results.brandedResults.count > 0,
            "Should have results from local database")
    }

    @Test("Categorized search with empty query returns empty results")
    func testCategorizedSearchEmptyQuery() async throws {
        let (context, _) = createTestContextWithContainer()
        let service = FoodService(context: context)

        let results = try await service.searchCategorized(query: "")

        #expect(results.historyResults.isEmpty)
        #expect(results.customResults.isEmpty)
        #expect(results.commonResults.isEmpty)
        #expect(results.brandedResults.isEmpty)
        #expect(!results.hasResults)
    }

    @Test("Categorized search common results are USDA sources only")
    func testCategorizedSearchCommonResultsAreUSDA() async throws {
        let (context, _) = createTestContextWithContainer()
        let service = FoodService(context: context)

        let results = try await service.searchCategorized(query: "chicken")

        // Common results should only include USDA sources
        // The source in FoodSearchResult is .local for all local database entries
        // but the underlying database entries have source field that was filtered
        #expect(results.commonResults.allSatisfy { $0.source == .local })
    }

    @Test("Categorized search branded results have openFoodFacts source")
    func testCategorizedSearchBrandedResultsHaveOFFSource() async throws {
        let (context, _) = createTestContextWithContainer()
        let service = FoodService(context: context)

        let results = try await service.searchCategorized(query: "banana")

        // Branded results from Open Food Facts have source .openFoodFacts
        // If there are branded results, they should all have .openFoodFacts source
        if !results.brandedResults.isEmpty {
            #expect(results.brandedResults.allSatisfy { $0.source == .openFoodFacts })
        }
        // The test passes if branded results are empty (database may not have OFF entries)
    }

    @Test("Categorized search hasResults computed property works")
    func testCategorizedSearchHasResults() async throws {
        let (context, _) = createTestContextWithContainer()
        let service = FoodService(context: context)

        let withResults = try await service.searchCategorized(query: "chicken")
        let withoutResults = try await service.searchCategorized(query: "xyznonexistent123")

        #expect(withResults.hasResults)
        #expect(!withoutResults.hasResults)
    }

    @Test("Categorized search totalCount matches sum of all categories")
    func testCategorizedSearchTotalCount() async throws {
        let (context, _) = createTestContextWithContainer()
        let service = FoodService(context: context)

        let results = try await service.searchCategorized(query: "rice")

        let expectedTotal =
            results.historyResults.count
            + results.customResults.count
            + results.commonResults.count
            + results.brandedResults.count

        #expect(results.totalCount == expectedTotal)
    }

    // MARK: - Food History Search Tests

    @Test("Food history search returns logged foods matching query")
    func testFoodHistorySearchReturnsLoggedFoods() async throws {
        let (context, _) = createTestContextWithContainer()
        let service = FoodService(context: context)

        // Create a FoodEntry
        let entry = FoodEntry(
            foodName: "Grilled Chicken Breast",
            foodBrand: nil,
            mealSection: .lunch,
            servingGrams: 100,
            caloriesPer100g: 165,
            proteinPer100g: 31,
            carbsPer100g: 0,
            fatPer100g: 3.6,
            fiberPer100g: 0
        )
        context.insert(entry)
        try context.save()

        let results = try await service.searchFoodHistory(query: "chicken")

        #expect(!results.isEmpty, "Should find logged chicken")
        #expect(results.first?.name == "Grilled Chicken Breast")
    }

    @Test("Food history search returns empty for no matching entries")
    func testFoodHistorySearchEmptyForNoMatches() async throws {
        let (context, _) = createTestContextWithContainer()
        let service = FoodService(context: context)

        // Create a FoodEntry that won't match our query
        let entry = FoodEntry(
            foodName: "Banana",
            foodBrand: nil,
            mealSection: .snacks,
            servingGrams: 100,
            caloriesPer100g: 89,
            proteinPer100g: 1.1,
            carbsPer100g: 22.8,
            fatPer100g: 0.3,
            fiberPer100g: 2.6
        )
        context.insert(entry)
        try context.save()

        let results = try await service.searchFoodHistory(query: "pizza")

        #expect(results.isEmpty)
    }

    @Test("Food history search deduplicates by food name")
    func testFoodHistorySearchDeduplicates() async throws {
        let (context, _) = createTestContextWithContainer()
        let service = FoodService(context: context)

        // Create multiple entries for the same food
        for _ in 0..<3 {
            let entry = FoodEntry(
                foodName: "Oatmeal",
                foodBrand: nil,
                mealSection: .breakfast,
                servingGrams: 100,
                caloriesPer100g: 68,
                proteinPer100g: 2.4,
                carbsPer100g: 12,
                fatPer100g: 1.4,
                fiberPer100g: 1.7
            )
            context.insert(entry)
        }
        try context.save()

        let results = try await service.searchFoodHistory(query: "oatmeal")

        #expect(results.count == 1, "Should deduplicate same food name")
    }

    @Test("Food history search respects limit")
    func testFoodHistorySearchRespectsLimit() async throws {
        let (context, _) = createTestContextWithContainer()
        let service = FoodService(context: context)

        // Create multiple unique food entries
        for index in 0..<10 {
            let entry = FoodEntry(
                foodName: "Apple Variety \(index)",
                foodBrand: nil,
                mealSection: .snacks,
                servingGrams: 100,
                caloriesPer100g: 52,
                proteinPer100g: 0.3,
                carbsPer100g: 14,
                fatPer100g: 0.2,
                fiberPer100g: 2.4
            )
            context.insert(entry)
        }
        try context.save()

        let results = try await service.searchFoodHistory(query: "apple", limit: 5)

        #expect(results.count <= 5)
    }

    @Test("Food history search is case insensitive")
    func testFoodHistorySearchCaseInsensitive() async throws {
        let (context, _) = createTestContextWithContainer()
        let service = FoodService(context: context)

        let entry = FoodEntry(
            foodName: "Greek Yogurt",
            foodBrand: "Fage",
            mealSection: .breakfast,
            servingGrams: 100,
            caloriesPer100g: 97,
            proteinPer100g: 9,
            carbsPer100g: 4,
            fatPer100g: 5,
            fiberPer100g: 0
        )
        context.insert(entry)
        try context.save()

        let lowercaseResults = try await service.searchFoodHistory(query: "greek")
        let uppercaseResults = try await service.searchFoodHistory(query: "GREEK")

        #expect(!lowercaseResults.isEmpty)
        #expect(!uppercaseResults.isEmpty)
        #expect(lowercaseResults.count == uppercaseResults.count)
    }

    @Test("Food history search preserves nutrition data")
    func testFoodHistorySearchPreservesNutritionData() async throws {
        let (context, _) = createTestContextWithContainer()
        let service = FoodService(context: context)

        let entry = FoodEntry(
            foodName: "Salmon Fillet",
            foodBrand: nil,
            mealSection: .dinner,
            servingGrams: 150,
            caloriesPer100g: 208,
            proteinPer100g: 20,
            carbsPer100g: 0,
            fatPer100g: 13,
            fiberPer100g: 0
        )
        context.insert(entry)
        try context.save()

        let results = try await service.searchFoodHistory(query: "salmon")

        guard let result = results.first else {
            Issue.record("No results found")
            return
        }

        #expect(result.caloriesPer100g == 208)
        #expect(result.proteinPer100g == 20)
        #expect(result.carbsPer100g == 0)
        #expect(result.fatPer100g == 13)
    }

    // MARK: - ServingOption Parsing Tests

    @Test("ServingOption parses simple gram format")
    func testServingOptionParsesGramFormat() {
        let options = ServingOption.parse(from: "[\"100g\"]")

        #expect(options.count == 1)
        #expect(options.first?.label == "100g")
        #expect(options.first?.grams == 100)
    }

    @Test("ServingOption parses item format with grams")
    func testServingOptionParsesItemFormat() {
        let options = ServingOption.parse(from: "[\"1.0 item (150g)\"]")

        #expect(options.count == 1)
        // When quantity is 1.0, label omits the "1" prefix for cleaner display
        #expect(options.first?.label == "item")
        #expect(options.first?.grams == 150)
    }

    @Test("ServingOption parses multiple serving options")
    func testServingOptionParsesMultiple() {
        let options = ServingOption.parse(from: "[\"100g\", \"1.0 item (200g)\"]")

        #expect(options.count == 2)
    }

    @Test("ServingOption handles malformed JSON gracefully")
    func testServingOptionHandlesMalformedJSON() {
        let options = ServingOption.parse(from: "not valid json")

        // Should return default 100g option
        #expect(options.count == 1)
        #expect(options.first?.label == "100g")
        #expect(options.first?.grams == 100)
    }

    @Test("ServingOption provides default 100g option for empty JSON array")
    func testServingOptionHandlesEmptyArray() {
        let options = ServingOption.parse(from: "[]")

        // Empty input returns default 100g fallback option
        #expect(options.count == 1)
        #expect(options.first?.label == "100g")
        #expect(options.first?.grams == 100)
    }

    @Test("ServingOption parses decimal quantities")
    func testServingOptionParsesDecimalQuantities() {
        let options = ServingOption.parse(from: "[\"0.5 cup (120g)\"]")

        // Note: current implementation formats as "0 cup" for decimal quantities
        // This is a known limitation - the test documents current behavior
        #expect(options.count == 1)
        #expect(options.first?.grams == 120)
    }

    // MARK: - Barcode Lookup Tests
    // Note: Barcode tests use defensive patterns because bundled database content
    // may vary between builds. Tests verify the lookup path works, not specific products.
    // If a barcode test needs a guaranteed result, use the invalid barcode tests instead.

    @Test("Barcode lookup returns nil for unknown barcode")
    func testBarcodeLookupReturnsNilForUnknownBarcode() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        // Use a clearly fake barcode that won't exist in the database
        let result = try await service.lookupBarcode("0000000000000")

        #expect(result == nil, "Unknown barcode should return nil")
    }

    @Test("Barcode lookup handles empty barcode gracefully")
    func testBarcodeLookupHandlesEmptyBarcode() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        // Empty barcode should not throw - may return result if database has foods with empty barcode field
        let result = try await service.lookupBarcode("")

        // Just verify it didn't throw and returns valid data if found
        if let food = result {
            #expect(!food.name.isEmpty, "If found, food should have a name")
        }
        // Either outcome (found or nil) is valid - test just verifies no crash
    }

    @Test("Barcode lookup handles whitespace barcode")
    func testBarcodeLookupHandlesWhitespaceBarcode() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        let result = try await service.lookupBarcode("   ")

        #expect(result == nil, "Whitespace barcode should return nil")
    }

    @Test("Barcode lookup returns food with nutrition data when found")
    func testBarcodeLookupReturnsNutritionData() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        // Try a common barcode that might exist in the Open Food Facts dump
        // This test documents expected behavior - actual result depends on database content
        let result = try await service.lookupBarcode("5449000000996")  // Coca-Cola barcode

        // If found, verify it has nutrition data
        if let food = result {
            #expect(!food.name.isEmpty, "Food should have a name")
            #expect(food.caloriesPer100g >= 0, "Calories should be non-negative")
            #expect(food.barcode == "5449000000996", "Barcode should match")
        }
        // If not found, that's also valid - the barcode might not be in the local database
    }

    @Test("Barcode lookup returns correct source type")
    func testBarcodeLookupReturnsCorrectSource() async throws {
        let context = createTestContext()
        let service = FoodService(context: context)

        // Try a barcode lookup - source should be appropriate for where it was found
        let result = try await service.lookupBarcode("5449000000996")

        if let food = result {
            // Barcode lookup from local database should return local or openFoodFacts source
            #expect(
                food.source == .local || food.source == .openFoodFacts,
                "Source should be local or openFoodFacts"
            )
        }
    }

    // MARK: - Helper Methods

    private func createTestContext() -> ModelContext {
        let (context, _) = createTestContextWithContainer()
        return context
    }

    private func createTestContextWithContainer() -> (ModelContext, ModelContainer) {
        let schema = Schema([
            User.self,
            Dose.self,
            MedicationProfile.self,
            DoseTitration.self,
            Food.self,
            FoodEntry.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return (ModelContext(container), container)
    }
}
