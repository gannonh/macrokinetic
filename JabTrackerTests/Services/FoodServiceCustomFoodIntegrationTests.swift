//
//  FoodServiceCustomFoodIntegrationTests.swift
//  JabTrackerTests
//
//  Integration tests for custom food search flow through FoodService.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Integration tests for custom foods in FoodService
/// Verifies end-to-end custom food search and logging flow
@Suite("FoodService Custom Food Integration")
@MainActor
struct FoodServiceCustomFoodIntegrationTests {

    @Test("Custom foods appear in searchCategorized results")
    func testCustomFoodsInCategorizedSearch() async throws {
        // Setup
        let (context, container) = createTestContext()
        _ = container

        let customFoodService = CustomFoodService(context: context)
        let foodService = FoodService(context: context, customFoodService: customFoodService)

        // Create a custom food
        let customFood = try await customFoodService.createCustomFood(
            makeInput(
                name: "My Protein Shake",
                brand: "Homemade",
                caloriesPer100g: 80,
                proteinPer100g: 15,
                carbsPer100g: 5,
                fatPer100g: 2,
                servingSize: 250,
                servingUnit: "ml",
                servingDescription: "1 shake"
            ))

        // Search
        let results = try await foodService.searchCategorized(query: "protein", limit: 10)

        // Verify custom food in results
        #expect(results.customResults.contains { $0.id == customFood.id })
        #expect(results.customResults.first { $0.id == customFood.id }?.source == .userCreated)
    }

    @Test("Custom food can be logged via MealLogService")
    func testCustomFoodCanBeLogged() async throws {
        let (context, container) = createTestContext()
        _ = container

        let customFoodService = CustomFoodService(context: context)
        let mealLogService = MealLogService(context: context)

        // Create custom food
        let customFood = try await customFoodService.createCustomFood(
            makeInput(
                name: "Morning Oatmeal",
                caloriesPer100g: 150,
                proteinPer100g: 5,
                carbsPer100g: 27,
                fatPer100g: 3,
                fiberPer100g: 4,
                servingSize: 200,
                servingDescription: "1 bowl"
            ))

        // Log it
        let entry = try await mealLogService.logFood(
            food: customFood,
            servingGrams: 200,
            mealSection: .breakfast
        )

        // Verify
        #expect(entry.foodName == "Morning Oatmeal")
        #expect(entry.calories == 300)  // 150 cal/100g * 200g
    }

    @Test("Custom food search excludes non-custom foods")
    func testSearchExcludesNonCustomFoods() async throws {
        let (context, container) = createTestContext()
        _ = container

        let customFoodService = CustomFoodService(context: context)
        let foodService = FoodService(context: context, customFoodService: customFoodService)

        // Create a custom food
        _ = try await customFoodService.createCustomFood(
            makeInput(
                name: "Custom Chicken",
                brand: "Homemade",
                caloriesPer100g: 165,
                proteinPer100g: 31,
                carbsPer100g: 0,
                fatPer100g: 3.6
            ))

        // Create a local food (not custom)
        let localFood = Food(name: "Local Chicken", source: .local)
        context.insert(localFood)
        try context.save()

        // Search via FoodService
        let results = try await foodService.searchCategorized(query: "chicken", limit: 10)

        // Custom results should only have the custom food
        #expect(results.customResults.count == 1)
        #expect(results.customResults.first?.name == "Custom Chicken")
    }

    @Test("Multiple custom foods returned in search results")
    func testMultipleCustomFoodsInSearch() async throws {
        let (context, container) = createTestContext()
        _ = container

        let customFoodService = CustomFoodService(context: context)
        let foodService = FoodService(context: context, customFoodService: customFoodService)

        // Create multiple custom foods with "meal" in name
        _ = try await customFoodService.createCustomFood(
            makeInput(
                name: "Post-Workout Meal",
                caloriesPer100g: 200,
                proteinPer100g: 25,
                carbsPer100g: 15,
                fatPer100g: 5,
                fiberPer100g: 2,
                servingSize: 300
            ))

        _ = try await customFoodService.createCustomFood(
            makeInput(
                name: "Pre-Workout Meal",
                caloriesPer100g: 180,
                proteinPer100g: 15,
                carbsPer100g: 25,
                fatPer100g: 4,
                fiberPer100g: 3,
                servingSize: 250
            ))

        _ = try await customFoodService.createCustomFood(
            makeInput(
                name: "Snack Time",
                caloriesPer100g: 100,
                proteinPer100g: 5,
                carbsPer100g: 10,
                fatPer100g: 5,
                fiberPer100g: 1,
                servingSize: 50
            ))

        // Search for "meal"
        let results = try await foodService.searchCategorized(query: "meal", limit: 10)

        // Should find 2 custom foods with "meal" in name
        #expect(results.customResults.count == 2)
    }

    @Test("Custom food with barcode appears in search")
    func testCustomFoodWithBarcodeInSearch() async throws {
        let (context, container) = createTestContext()
        _ = container

        let customFoodService = CustomFoodService(context: context)
        let foodService = FoodService(context: context, customFoodService: customFoodService)

        // Create custom food with barcode
        let customFood = try await customFoodService.createCustomFood(
            makeInput(
                name: "Custom Granola Bar",
                brand: "My Brand",
                caloriesPer100g: 400,
                proteinPer100g: 10,
                carbsPer100g: 60,
                fatPer100g: 15,
                fiberPer100g: 5,
                servingSize: 40,
                servingDescription: "1 bar",
                barcode: "1234567890123"
            ))

        // Search
        let results = try await foodService.searchCategorized(query: "granola", limit: 10)

        // Verify food found and has barcode preserved
        let foundFood = results.customResults.first { $0.id == customFood.id }
        #expect(foundFood != nil)
        #expect(foundFood?.barcode == "1234567890123")
    }

    @Test("FoodService without CustomFoodService returns empty custom results")
    func testFoodServiceWithoutCustomFoodServiceReturnsEmptyCustom() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Create FoodService without CustomFoodService
        let foodService = FoodService(context: context)

        // Create a custom food directly in context
        let customFood = Food(name: "Direct Custom Food", source: .userCreated)
        context.insert(customFood)
        try context.save()

        // Search - custom results should be empty since no CustomFoodService
        let results = try await foodService.searchCategorized(query: "direct", limit: 10)

        #expect(results.customResults.isEmpty)
    }

    @Test("Custom food preserves all nutrition data through search")
    func testCustomFoodPreservesNutritionData() async throws {
        let (context, container) = createTestContext()
        _ = container

        let customFoodService = CustomFoodService(context: context)
        let foodService = FoodService(context: context, customFoodService: customFoodService)

        // Create custom food with specific nutrition values
        let customFood = try await customFoodService.createCustomFood(
            makeInput(
                name: "Test Nutrition Food",
                brand: "Test Brand",
                caloriesPer100g: 123.45,
                proteinPer100g: 12.34,
                carbsPer100g: 23.45,
                fatPer100g: 5.67,
                fiberPer100g: 3.21,
                servingSize: 150,
                servingDescription: "1 portion"
            ))

        // Search
        let results = try await foodService.searchCategorized(query: "nutrition", limit: 10)
        let foundFood = results.customResults.first { $0.id == customFood.id }

        // Verify all nutrition values preserved
        #expect(foundFood != nil)
        #expect(foundFood?.caloriesPer100g == 123.45)
        #expect(foundFood?.proteinPer100g == 12.34)
        #expect(foundFood?.carbsPer100g == 23.45)
        #expect(foundFood?.fatPer100g == 5.67)
        #expect(foundFood?.fiberPer100g == 3.21)
        #expect(foundFood?.servingSize == 150)
    }

    // MARK: - Helper Methods

    private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        CustomFoodTestHelpers.createTestContext()
    }

    private func makeInput(
        name: String = "Test Food",
        brand: String = "",
        caloriesPer100g: Double = 100,
        proteinPer100g: Double = 10,
        carbsPer100g: Double = 10,
        fatPer100g: Double = 5,
        fiberPer100g: Double = 0,
        servingSize: Double = 100,
        servingUnit: String = "g",
        servingDescription: String = "",
        barcode: String = ""
    ) -> CustomFoodInput {
        CustomFoodTestHelpers.makeInput(
            name: name,
            brand: brand,
            caloriesPer100g: caloriesPer100g,
            proteinPer100g: proteinPer100g,
            carbsPer100g: carbsPer100g,
            fatPer100g: fatPer100g,
            fiberPer100g: fiberPer100g,
            servingSize: servingSize,
            servingUnit: servingUnit,
            servingDescription: servingDescription,
            barcode: barcode
        )
    }
}
