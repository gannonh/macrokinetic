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

        service.saveRecentFood(food)

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

    // MARK: - Helper Methods

    private func createTestContext() -> ModelContext {
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
        return ModelContext(container)
    }
}
