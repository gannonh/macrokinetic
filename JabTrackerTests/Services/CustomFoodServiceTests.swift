//
//  CustomFoodServiceTests.swift
//  JabTrackerTests
//
//  Tests for CustomFoodService - CRUD operations for user-created custom foods
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Tests for CustomFoodService
/// Verifies CRUD operations, validation, and barcode handling for user-created foods
@Suite("CustomFoodService Tests")
@MainActor
struct CustomFoodServiceTests {

    // MARK: - Create Tests

    @Test("Create custom food returns Food with source set to userCreated")
    func testCreateCustomFoodSetsSourceToUserCreated() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        let food = try await service.createCustomFood(
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

        #expect(food.foodSource == .userCreated)
        #expect(food.name == "My Protein Shake")
        #expect(food.brand == "Homemade")
        #expect(food.caloriesPer100g == 80)
        #expect(food.proteinPer100g == 15)
        #expect(food.carbsPer100g == 5)
        #expect(food.fatPer100g == 2)
        #expect(food.servingSize == 250)
        #expect(food.servingUnit == "ml")
        #expect(food.servingDescription == "1 shake")
    }

    @Test("Create custom food with empty name throws emptyName error")
    func testCreateCustomFoodWithEmptyNameThrows() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        await #expect(throws: CustomFoodError.emptyName) {
            _ = try await service.createCustomFood(makeInput(name: ""))
        }
    }

    @Test("Create custom food with whitespace-only name throws emptyName error")
    func testCreateCustomFoodWithWhitespaceNameThrows() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        await #expect(throws: CustomFoodError.emptyName) {
            _ = try await service.createCustomFood(makeInput(name: "   "))
        }
    }

    @Test("Create custom food with negative calories throws negativeNutrition error")
    func testCreateCustomFoodWithNegativeCaloriesThrows() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        await #expect(throws: CustomFoodError.negativeNutrition) {
            _ = try await service.createCustomFood(
                makeInput(
                    name: "Invalid Food",
                    caloriesPer100g: -50
                ))
        }
    }

    @Test("Create custom food with negative protein throws negativeNutrition error")
    func testCreateCustomFoodWithNegativeProteinThrows() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        await #expect(throws: CustomFoodError.negativeNutrition) {
            _ = try await service.createCustomFood(
                makeInput(
                    name: "Invalid Food",
                    proteinPer100g: -5
                ))
        }
    }

    @Test("Create custom food with zero serving size throws invalidServingSize error")
    func testCreateCustomFoodWithZeroServingSizeThrows() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        await #expect(throws: CustomFoodError.invalidServingSize) {
            _ = try await service.createCustomFood(
                makeInput(
                    name: "Invalid Food",
                    servingSize: 0
                ))
        }
    }

    @Test("Create custom food with negative serving size throws invalidServingSize error")
    func testCreateCustomFoodWithNegativeServingSizeThrows() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        await #expect(throws: CustomFoodError.invalidServingSize) {
            _ = try await service.createCustomFood(
                makeInput(
                    name: "Invalid Food",
                    servingSize: -100
                ))
        }
    }

    @Test("Create custom food with duplicate barcode throws duplicateBarcode error")
    func testCreateCustomFoodWithDuplicateBarcodeThrows() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        // Create first custom food with barcode
        _ = try await service.createCustomFood(
            makeInput(
                name: "First Food",
                barcode: "1234567890"
            ))

        // Try to create second food with same barcode
        await #expect(throws: CustomFoodError.duplicateBarcode(existingFood: "First Food")) {
            _ = try await service.createCustomFood(
                makeInput(
                    name: "Second Food",
                    caloriesPer100g: 200,
                    proteinPer100g: 20,
                    carbsPer100g: 20,
                    fatPer100g: 10,
                    barcode: "1234567890"
                ))
        }
    }

    @Test("Create custom food with empty barcode does not check for duplicates")
    func testCreateCustomFoodWithEmptyBarcodeDoesNotCheckDuplicates() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        // Create two foods without barcodes - should succeed
        let food1 = try await service.createCustomFood(makeInput(name: "First Food"))
        let food2 = try await service.createCustomFood(
            makeInput(
                name: "Second Food",
                caloriesPer100g: 200,
                proteinPer100g: 20,
                carbsPer100g: 20,
                fatPer100g: 10
            ))

        #expect(food1.name == "First Food")
        #expect(food2.name == "Second Food")
    }

    // MARK: - Read Tests

    @Test("getAllCustomFoods returns only userCreated foods")
    func testGetAllCustomFoodsReturnsOnlyUserCreated() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        // Create custom food
        _ = try await service.createCustomFood(makeInput(name: "Custom Food"))

        // Create non-custom food directly
        let localFood = Food(name: "Local Food", source: .local)
        context.insert(localFood)
        try context.save()

        let customFoods = try await service.getAllCustomFoods(limit: 100)

        #expect(customFoods.count == 1)
        #expect(customFoods.first?.name == "Custom Food")
    }

    @Test("getAllCustomFoods respects limit parameter")
    func testGetAllCustomFoodsRespectsLimit() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        // Create 5 custom foods
        for index in 0..<5 {
            _ = try await service.createCustomFood(makeInput(name: "Food \(index)"))
        }

        let customFoods = try await service.getAllCustomFoods(limit: 3)

        #expect(customFoods.count == 3)
    }

    @Test("search returns custom foods matching query")
    func testSearchReturnsMatchingCustomFoods() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        _ = try await service.createCustomFood(
            makeInput(
                name: "Protein Shake",
                brand: "Homemade",
                caloriesPer100g: 80,
                proteinPer100g: 15,
                carbsPer100g: 5,
                fatPer100g: 2,
                servingSize: 250,
                servingUnit: "ml"
            ))

        _ = try await service.createCustomFood(
            makeInput(
                name: "Morning Oatmeal",
                caloriesPer100g: 150,
                proteinPer100g: 5,
                carbsPer100g: 27,
                fatPer100g: 3,
                fiberPer100g: 4,
                servingSize: 200
            ))

        let results = try await service.search(query: "protein", limit: 10)

        #expect(results.count == 1)
        #expect(results.first?.name == "Protein Shake")
    }

    @Test("search is case insensitive")
    func testSearchIsCaseInsensitive() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        _ = try await service.createCustomFood(
            makeInput(
                name: "PROTEIN SHAKE",
                caloriesPer100g: 80,
                proteinPer100g: 15,
                carbsPer100g: 5,
                fatPer100g: 2,
                servingSize: 250,
                servingUnit: "ml"
            ))

        let results = try await service.search(query: "protein", limit: 10)

        #expect(results.count == 1)
    }

    @Test("search respects limit parameter")
    func testSearchRespectsLimit() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        // Create 5 foods with "Food" in name
        for index in 0..<5 {
            _ = try await service.createCustomFood(makeInput(name: "Food Item \(index)"))
        }

        let results = try await service.search(query: "Food", limit: 2)

        #expect(results.count == 2)
    }

    @Test("lookup returns food matching barcode")
    func testLookupReturnsFoodMatchingBarcode() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        _ = try await service.createCustomFood(
            makeInput(
                name: "Barcoded Food",
                brand: "MyBrand",
                barcode: "ABC123"
            ))

        let result = try await service.lookup(barcode: "ABC123")

        #expect(result != nil)
        #expect(result?.name == "Barcoded Food")
    }

    @Test("lookup returns nil for non-existent barcode")
    func testLookupReturnsNilForNonExistentBarcode() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        _ = try await service.createCustomFood(
            makeInput(
                name: "Some Food",
                barcode: "DIFFERENT"
            ))

        let result = try await service.lookup(barcode: "ABC123")

        #expect(result == nil)
    }

    @Test("lookup only searches custom foods")
    func testLookupOnlySearchesCustomFoods() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        // Create a local food with a barcode (not custom)
        let localFood = Food(name: "Local Food", source: .local, barcode: "ABC123")
        context.insert(localFood)
        try context.save()

        let result = try await service.lookup(barcode: "ABC123")

        #expect(result == nil)
    }

    // MARK: - Update Tests

    @Test("updateCustomFood modifies food properties")
    func testUpdateCustomFoodModifiesProperties() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        let food = try await service.createCustomFood(
            makeInput(
                name: "Original Name",
                brand: "Original Brand"
            ))

        try await service.updateCustomFood(
            food,
            with: makeInput(
                name: "Updated Name",
                brand: "Updated Brand",
                caloriesPer100g: 200,
                proteinPer100g: 20,
                carbsPer100g: 20,
                fatPer100g: 10,
                fiberPer100g: 5,
                servingSize: 150,
                servingUnit: "ml",
                servingDescription: "1 cup",
                barcode: "NEW123"
            ))

        #expect(food.name == "Updated Name")
        #expect(food.brand == "Updated Brand")
        #expect(food.caloriesPer100g == 200)
        #expect(food.proteinPer100g == 20)
        #expect(food.carbsPer100g == 20)
        #expect(food.fatPer100g == 10)
        #expect(food.fiberPer100g == 5)
        #expect(food.servingSize == 150)
        #expect(food.servingUnit == "ml")
        #expect(food.servingDescription == "1 cup")
        #expect(food.barcode == "NEW123")
    }

    @Test("updateCustomFood throws notCustomFood for local food")
    func testUpdateCustomFoodThrowsForLocalFood() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        let localFood = Food(name: "Local Food", source: .local)
        context.insert(localFood)
        try context.save()

        await #expect(throws: CustomFoodError.notCustomFood) {
            try await service.updateCustomFood(localFood, with: makeInput(name: "Updated Name"))
        }
    }

    @Test("updateCustomFood validates empty name")
    func testUpdateCustomFoodValidatesEmptyName() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        let food = try await service.createCustomFood(makeInput(name: "Original Name"))

        await #expect(throws: CustomFoodError.emptyName) {
            try await service.updateCustomFood(food, with: makeInput(name: ""))
        }
    }

    @Test("updateCustomFood checks barcode conflict")
    func testUpdateCustomFoodChecksBarcodeConflict() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        // Create first food with barcode
        _ = try await service.createCustomFood(
            makeInput(
                name: "First Food",
                barcode: "BARCODE1"
            ))

        // Create second food
        let secondFood = try await service.createCustomFood(
            makeInput(
                name: "Second Food",
                barcode: "BARCODE2"
            ))

        // Try to update second food with first food's barcode
        await #expect(throws: CustomFoodError.duplicateBarcode(existingFood: "First Food")) {
            try await service.updateCustomFood(
                secondFood,
                with: makeInput(
                    name: "Second Food",
                    barcode: "BARCODE1"
                ))
        }
    }

    @Test("updateCustomFood allows keeping same barcode")
    func testUpdateCustomFoodAllowsKeepingSameBarcode() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        let food = try await service.createCustomFood(
            makeInput(
                name: "My Food",
                barcode: "MYBARCODE"
            ))

        // Update with same barcode should succeed
        try await service.updateCustomFood(
            food,
            with: makeInput(
                name: "Updated Name",
                barcode: "MYBARCODE"
            ))

        #expect(food.name == "Updated Name")
        #expect(food.barcode == "MYBARCODE")
    }

    // MARK: - Delete Tests

    @Test("deleteCustomFood removes food from context")
    func testDeleteCustomFoodRemovesFromContext() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        let food = try await service.createCustomFood(makeInput(name: "To Delete"))

        let foodId = food.id
        try await service.deleteCustomFood(food)

        // Try to fetch the deleted food
        let descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { $0.id == foodId }
        )
        let found = try context.fetch(descriptor)

        #expect(found.isEmpty)
    }

    @Test("deleteCustomFood throws notCustomFood for local food")
    func testDeleteCustomFoodThrowsForLocalFood() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = CustomFoodService(context: context)

        let localFood = Food(name: "Local Food", source: .local)
        context.insert(localFood)
        try context.save()

        await #expect(throws: CustomFoodError.notCustomFood) {
            try await service.deleteCustomFood(localFood)
        }
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
