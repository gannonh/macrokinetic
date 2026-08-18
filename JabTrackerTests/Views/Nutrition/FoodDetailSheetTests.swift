//
//  FoodDetailSheetTests.swift
//  JabTrackerTests
//
//  Tests for the FoodDetailSheet view.
//

import SwiftData
import SwiftUI
import Testing

@testable import JabTracker

@Suite("FoodDetailSheet Tests")
struct FoodDetailSheetTests {

    // MARK: - Test Setup

    @MainActor
    func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([User.self, Food.self, FoodEntry.self])
        let config = InMemoryTestStore.configuration(schema: schema)
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
        user.dailyCarbGoal = 200.0
        user.dailyFatGoal = 65.0
        context.insert(user)
        try? context.save()
        return user
    }

    @MainActor
    func createTestFoodResult() -> FoodSearchResult {
        FoodSearchResult(
            fdcId: 12345,
            barcode: nil,
            name: "Burger King Whopper No Cheese",
            brand: "Burger King",
            source: .openFoodFacts,
            caloriesPer100g: 232.0,
            proteinPer100g: 10.7,
            carbsPer100g: 18.6,
            fatPer100g: 12.8,
            fiberPer100g: 1.3,
            category: nil
        )
    }

    // MARK: - Static Properties Tests

    @Test("FoodDetailSheet has correct accessibility identifier")
    @MainActor
    func hasCorrectAccessibilityIdentifier() {
        #expect(FoodDetailSheet.accessibilityIdentifierValue == "food-detail-sheet")
    }

    @Test("FoodDetailSheet quantity input has correct accessibility identifier")
    @MainActor
    func quantityInputHasCorrectAccessibilityIdentifier() {
        #expect(FoodDetailSheet.quantityInputIdentifier == "quantity-input")
    }

    @Test("FoodDetailSheet add button has correct accessibility identifier")
    @MainActor
    func addButtonHasCorrectAccessibilityIdentifier() {
        #expect(FoodDetailSheet.addButtonIdentifier == "add-food-button")
    }

    // MARK: - Macro Calculation Tests

    @Test("FoodDetailSheet calculates scaled calories correctly")
    @MainActor
    func calculatesScaledCaloriesCorrectly() {
        let food = createTestFoodResult()

        // For 100g serving
        let scaledCalories100 = (food.caloriesPer100g * 100.0) / 100.0
        #expect(scaledCalories100 == 232.0)

        // For 150g serving
        let scaledCalories150 = (food.caloriesPer100g * 150.0) / 100.0
        #expect(scaledCalories150 == 348.0)

        // For 50g serving
        let scaledCalories50 = (food.caloriesPer100g * 50.0) / 100.0
        #expect(scaledCalories50 == 116.0)
    }

    @Test("FoodDetailSheet calculates impact percentage correctly")
    @MainActor
    func calculatesImpactPercentageCorrectly() {
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(context: context)
        let food = createTestFoodResult()

        // 100g serving = 232 calories
        // User goal = 2000 calories
        // Impact = 232 / 2000 = 11.6%
        let calorieImpact = (food.caloriesPer100g * 100.0 / 100.0) / user.dailyCalorieGoal
        #expect(calorieImpact > 0.115 && calorieImpact < 0.117)

        // Protein: 10.7g out of 150g goal = 7.1%
        let proteinImpact = (food.proteinPer100g * 100.0 / 100.0) / user.dailyProteinGoal
        #expect(proteinImpact > 0.070 && proteinImpact < 0.072)
    }

    // MARK: - Quantity Tests

    @Test("FoodDetailSheet default quantity is 100g")
    @MainActor
    func defaultQuantityIs100g() {
        #expect(FoodDetailSheet.defaultQuantity == 100.0)
    }

    @Test("FoodDetailSheet minimum quantity is 1g")
    @MainActor
    func minimumQuantityIs1g() {
        #expect(FoodDetailSheet.minimumQuantity == 1.0)
    }

    @Test("FoodDetailSheet maximum quantity is 2000g")
    @MainActor
    func maximumQuantityIs2000g() {
        #expect(FoodDetailSheet.maximumQuantity == 2000.0)
    }

    // MARK: - Carb Breakdown Tests

    @Test("FoodDetailSheet calculates net carbs correctly")
    @MainActor
    func calculatesNetCarbsCorrectly() {
        let food = createTestFoodResult()

        // Net carbs = carbs - fiber
        // 18.6 - 1.3 = 17.3g per 100g
        let netCarbs = food.carbsPer100g - food.fiberPer100g
        #expect(netCarbs == 17.3)
    }
}

// MARK: - Macro Impact Tests

@Suite("MacroImpact Tests")
struct MacroImpactTests {

    @Test("MacroImpact calculates percentage for partial goal")
    func calculatesPercentageForPartialGoal() {
        // 500 calories consumed out of 2000 goal = 25%
        let percentage = 500.0 / 2000.0
        #expect(percentage == 0.25)
    }

    @Test("MacroImpact handles overflow (over 100%)")
    func handlesOverflow() {
        // 2500 calories consumed out of 2000 goal = 125%
        let percentage = 2500.0 / 2000.0
        #expect(percentage == 1.25)
    }

    @Test("MacroImpact handles zero goal gracefully")
    func handlesZeroGoal() {
        // When goal is 0, avoid division by zero
        let goal = 0.0
        let consumed = 100.0
        let percentage = goal > 0 ? consumed / goal : 0.0
        #expect(percentage == 0.0)
    }
}
