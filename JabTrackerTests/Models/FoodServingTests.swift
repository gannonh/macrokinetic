//
//  FoodServingTests.swift
//  JabTrackerTests
//
//  Tests for Food+Serving extension - per-serving macro calculations.
//

import Testing

@testable import JabTracker

@Suite("Food+Serving Tests")
struct FoodServingTests {

    // MARK: - Calories Per Serving Tests

    @Test("caloriesPerServing calculates correctly for 100g serving")
    func testCaloriesPerServingStandardServing() {
        let food = Food(
            name: "Chicken Breast",
            caloriesPer100g: 165.0,
            servingSize: 100.0
        )

        #expect(food.caloriesPerServing == 165.0)
    }

    @Test("caloriesPerServing calculates correctly for 50g serving")
    func testCaloriesPerServingHalfServing() {
        let food = Food(
            name: "Chicken Breast",
            caloriesPer100g: 200.0,
            servingSize: 50.0
        )

        #expect(food.caloriesPerServing == 100.0)
    }

    @Test("caloriesPerServing calculates correctly for 250g serving")
    func testCaloriesPerServingLargeServing() {
        let food = Food(
            name: "Rice",
            caloriesPer100g: 130.0,
            servingSize: 250.0
        )

        #expect(food.caloriesPerServing == 325.0)
    }

    // MARK: - Protein Per Serving Tests

    @Test("proteinPerServing calculates correctly for 100g serving")
    func testProteinPerServingStandardServing() {
        let food = Food(
            name: "Chicken Breast",
            proteinPer100g: 31.0,
            servingSize: 100.0
        )

        #expect(food.proteinPerServing == 31.0)
    }

    @Test("proteinPerServing calculates correctly for 150g serving")
    func testProteinPerServingLargeServing() {
        let food = Food(
            name: "Salmon",
            proteinPer100g: 20.0,
            servingSize: 150.0
        )

        #expect(food.proteinPerServing == 30.0)
    }

    // MARK: - Carbs Per Serving Tests

    @Test("carbsPerServing calculates correctly for 100g serving")
    func testCarbsPerServingStandardServing() {
        let food = Food(
            name: "Rice",
            carbsPer100g: 28.0,
            servingSize: 100.0
        )

        #expect(abs(food.carbsPerServing - 28.0) < 0.01)
    }

    @Test("carbsPerServing calculates correctly for 200g serving")
    func testCarbsPerServingDoubleServing() {
        let food = Food(
            name: "Pasta",
            carbsPer100g: 25.0,
            servingSize: 200.0
        )

        #expect(food.carbsPerServing == 50.0)
    }

    // MARK: - Fat Per Serving Tests

    @Test("fatPerServing calculates correctly for 100g serving")
    func testFatPerServingStandardServing() {
        let food = Food(
            name: "Avocado",
            fatPer100g: 15.0,
            servingSize: 100.0
        )

        #expect(food.fatPerServing == 15.0)
    }

    @Test("fatPerServing calculates correctly for 30g serving")
    func testFatPerServingSmallServing() {
        let food = Food(
            name: "Olive Oil",
            fatPer100g: 100.0,
            servingSize: 30.0
        )

        #expect(food.fatPerServing == 30.0)
    }

    // MARK: - Edge Cases

    @Test("All macros calculate correctly for typical food")
    func testAllMacrosForTypicalFood() {
        let food = Food(
            name: "Whole Milk",
            caloriesPer100g: 61.0,
            proteinPer100g: 3.2,
            carbsPer100g: 4.8,
            fatPer100g: 3.3,
            servingSize: 244.0  // 1 cup
        )

        // Expected: (value / 100) * 244
        #expect(abs(food.caloriesPerServing - 148.84) < 0.01)
        #expect(abs(food.proteinPerServing - 7.808) < 0.01)
        #expect(abs(food.carbsPerServing - 11.712) < 0.01)
        #expect(abs(food.fatPerServing - 8.052) < 0.01)
    }

    @Test("Zero calories returns zero per serving")
    func testZeroCalories() {
        let food = Food(
            name: "Water",
            caloriesPer100g: 0.0,
            servingSize: 250.0
        )

        #expect(food.caloriesPerServing == 0.0)
    }

    @Test("Very small serving calculates correctly")
    func testVerySmallServing() {
        let food = Food(
            name: "Salt",
            caloriesPer100g: 0.0,
            proteinPer100g: 0.0,
            carbsPer100g: 0.0,
            fatPer100g: 0.0,
            servingSize: 1.0  // 1 gram
        )

        #expect(food.caloriesPerServing == 0.0)
        #expect(food.proteinPerServing == 0.0)
        #expect(food.carbsPerServing == 0.0)
        #expect(food.fatPerServing == 0.0)
    }
}
