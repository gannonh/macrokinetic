//
//  FoodTests.swift
//  JabTrackerTests
//
//  Tests for the Food SwiftData model.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
struct FoodTests {

    // MARK: - Test Helpers

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([Food.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none  // Critical for tests
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - Default Initialization Tests

    @Test("Food initializes with CloudKit-compatible defaults")
    func testDefaultInitialization() throws {
        let food = Food()

        // All fields must have non-nil defaults for CloudKit
        #expect(food.id != UUID())  // Has a valid UUID (not equal to a new one)
        #expect(food.fdcId == 0)
        #expect(food.name == "")
        #expect(food.brand == nil)
        #expect(food.source == "local")
        #expect(food.barcode == nil)
        #expect(food.caloriesPer100g == 0.0)
        #expect(food.proteinPer100g == 0.0)
        #expect(food.carbsPer100g == 0.0)
        #expect(food.fatPer100g == 0.0)
        #expect(food.fiberPer100g == 0.0)
        #expect(food.sugarPer100g == 0.0)
        #expect(food.sodiumPer100g == 0.0)
        #expect(food.servingSize == 100.0)
        #expect(food.servingUnit == "g")
        #expect(food.servingDescription == nil)
        #expect(food.createdAt <= Date())
        #expect(food.lastAccessedAt <= Date())
    }

    @Test("Food initializes with custom values")
    func testCustomInitialization() throws {
        let food = Food(
            name: "Chicken Breast",
            brand: "Perdue",
            fdcId: 171077,
            source: .local,
            barcode: "123456789012",
            caloriesPer100g: 165.0,
            proteinPer100g: 31.0,
            carbsPer100g: 0.0,
            fatPer100g: 3.6,
            fiberPer100g: 0.0,
            sugarPer100g: 0.0,
            sodiumPer100g: 74.0,
            servingSize: 100.0,
            servingUnit: "g",
            servingDescription: "3 oz cooked"
        )

        #expect(food.name == "Chicken Breast")
        #expect(food.brand == "Perdue")
        #expect(food.fdcId == 171077)
        #expect(food.source == "local")
        #expect(food.barcode == "123456789012")
        #expect(food.caloriesPer100g == 165.0)
        #expect(food.proteinPer100g == 31.0)
        #expect(food.carbsPer100g == 0.0)
        #expect(food.fatPer100g == 3.6)
        #expect(food.fiberPer100g == 0.0)
        #expect(food.sugarPer100g == 0.0)
        #expect(food.sodiumPer100g == 74.0)
        #expect(food.servingSize == 100.0)
        #expect(food.servingUnit == "g")
        #expect(food.servingDescription == "3 oz cooked")
    }

    // MARK: - FoodSource Computed Property Tests

    @Test("foodSource computed property returns correct enum value")
    func testFoodSourceGetterLocal() throws {
        let food = Food()
        food.source = "local"

        #expect(food.foodSource == .local)
    }

    @Test("foodSource computed property returns openFoodFacts")
    func testFoodSourceGetterOpenFoodFacts() throws {
        let food = Food()
        food.source = "openFoodFacts"

        #expect(food.foodSource == .openFoodFacts)
    }

    @Test("foodSource computed property returns userCreated")
    func testFoodSourceGetterUserCreated() throws {
        let food = Food()
        food.source = "userCreated"

        #expect(food.foodSource == .userCreated)
    }

    @Test("foodSource computed property defaults to local for unknown value")
    func testFoodSourceGetterUnknown() throws {
        let food = Food()
        food.source = "unknownSource"

        #expect(food.foodSource == .local)
    }

    @Test("foodSource setter updates source string")
    func testFoodSourceSetter() throws {
        let food = Food()

        food.foodSource = .openFoodFacts
        #expect(food.source == "openFoodFacts")

        food.foodSource = .userCreated
        #expect(food.source == "userCreated")

        food.foodSource = .local
        #expect(food.source == "local")
    }

    // MARK: - SwiftData Persistence Tests

    @Test("Food can be inserted into SwiftData context")
    func testInsert() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let food = Food(name: "Chicken Breast", caloriesPer100g: 165.0)
        context.insert(food)
        try context.save()

        let descriptor = FetchDescriptor<Food>()
        let foods = try context.fetch(descriptor)

        #expect(foods.count == 1)
        #expect(foods.first?.name == "Chicken Breast")
        #expect(foods.first?.caloriesPer100g == 165.0)
    }

    @Test("Food can be fetched from SwiftData context")
    func testFetch() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Insert multiple foods
        let chicken = Food(name: "Chicken Breast", caloriesPer100g: 165.0)
        let salmon = Food(name: "Atlantic Salmon", caloriesPer100g: 208.0)
        let broccoli = Food(name: "Broccoli", caloriesPer100g: 34.0)

        context.insert(chicken)
        context.insert(salmon)
        context.insert(broccoli)
        try context.save()

        let descriptor = FetchDescriptor<Food>()
        let foods = try context.fetch(descriptor)

        #expect(foods.count == 3)
    }

    @Test("Food can be updated in SwiftData context")
    func testUpdate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let food = Food(name: "Chicken Breast", caloriesPer100g: 165.0)
        context.insert(food)
        try context.save()

        // Update the food
        food.name = "Grilled Chicken Breast"
        food.caloriesPer100g = 170.0
        food.brand = "Fresh Market"
        try context.save()

        // Fetch and verify
        let descriptor = FetchDescriptor<Food>()
        let foods = try context.fetch(descriptor)

        #expect(foods.count == 1)
        #expect(foods.first?.name == "Grilled Chicken Breast")
        #expect(foods.first?.caloriesPer100g == 170.0)
        #expect(foods.first?.brand == "Fresh Market")
    }

    @Test("Food can be deleted from SwiftData context")
    func testDelete() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let food = Food(name: "Chicken Breast", caloriesPer100g: 165.0)
        context.insert(food)
        try context.save()

        // Verify inserted
        var descriptor = FetchDescriptor<Food>()
        var foods = try context.fetch(descriptor)
        #expect(foods.count == 1)

        // Delete
        context.delete(food)
        try context.save()

        // Verify deleted
        descriptor = FetchDescriptor<Food>()
        foods = try context.fetch(descriptor)
        #expect(foods.count == 0)
    }

    @Test("Food with all nutrition values persists correctly")
    func testFullNutritionPersistence() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let food = Food(
            name: "Whole Milk",
            brand: "Organic Valley",
            fdcId: 746782,
            source: .local,
            barcode: "093966000016",
            caloriesPer100g: 61.0,
            proteinPer100g: 3.2,
            carbsPer100g: 4.8,
            fatPer100g: 3.3,
            fiberPer100g: 0.0,
            sugarPer100g: 5.0,
            sodiumPer100g: 43.0,
            servingSize: 244.0,
            servingUnit: "ml",
            servingDescription: "1 cup"
        )

        context.insert(food)
        try context.save()

        let descriptor = FetchDescriptor<Food>()
        let foods = try context.fetch(descriptor)

        #expect(foods.count == 1)
        guard let fetched = foods.first else {
            Issue.record("No food found after insert")
            return
        }

        #expect(fetched.name == "Whole Milk")
        #expect(fetched.brand == "Organic Valley")
        #expect(fetched.fdcId == 746782)
        #expect(fetched.source == "local")
        #expect(fetched.barcode == "093966000016")
        #expect(fetched.caloriesPer100g == 61.0)
        #expect(fetched.proteinPer100g == 3.2)
        #expect(fetched.carbsPer100g == 4.8)
        #expect(fetched.fatPer100g == 3.3)
        #expect(fetched.fiberPer100g == 0.0)
        #expect(fetched.sugarPer100g == 5.0)
        #expect(fetched.sodiumPer100g == 43.0)
        #expect(fetched.servingSize == 244.0)
        #expect(fetched.servingUnit == "ml")
        #expect(fetched.servingDescription == "1 cup")
    }

    @Test("Food with different sources persists correctly")
    func testDifferentSourcesPersistence() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let usdaFood = Food(name: "USDA Chicken", source: .local)
        let offFood = Food(name: "OFF Product", source: .openFoodFacts)
        let customFood = Food(name: "My Recipe", source: .userCreated)

        context.insert(usdaFood)
        context.insert(offFood)
        context.insert(customFood)
        try context.save()

        let descriptor = FetchDescriptor<Food>()
        let foods = try context.fetch(descriptor)

        #expect(foods.count == 3)

        let usdaResult = foods.first { $0.name == "USDA Chicken" }
        let offResult = foods.first { $0.name == "OFF Product" }
        let customResult = foods.first { $0.name == "My Recipe" }

        #expect(usdaResult?.foodSource == .local)
        #expect(offResult?.foodSource == .openFoodFacts)
        #expect(customResult?.foodSource == .userCreated)
    }
}
