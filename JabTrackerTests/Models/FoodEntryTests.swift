//
//  FoodEntryTests.swift
//  JabTrackerTests
//
//  Tests for the FoodEntry SwiftData model.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
struct FoodEntryTests {

    // MARK: - Test Helpers

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([User.self, Food.self, FoodEntry.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none  // Critical for tests
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - Default Initialization Tests

    @Test("FoodEntry initializes with CloudKit-compatible defaults")
    func testDefaultInitialization() throws {
        let entry = FoodEntry()

        // All fields must have non-nil defaults for CloudKit
        #expect(entry.id != UUID())  // Has a valid UUID (not equal to a new one)
        #expect(entry.foodId != UUID())  // Has a valid UUID
        #expect(entry.foodName == "")
        #expect(entry.foodBrand == nil)
        #expect(entry.mealSection == "breakfast")
        #expect(entry.loggedAt <= Date())
        #expect(entry.servingGrams == 100.0)
        #expect(entry.servingDescription == nil)
        #expect(entry.caloriesPer100g == 0.0)
        #expect(entry.proteinPer100g == 0.0)
        #expect(entry.carbsPer100g == 0.0)
        #expect(entry.fatPer100g == 0.0)
        #expect(entry.fiberPer100g == 0.0)
        #expect(entry.notes == nil)
        #expect(entry.user == nil)
    }

    @Test("FoodEntry initializes with custom values")
    func testCustomInitialization() throws {
        let testDate = Date()
        let testFoodId = UUID()

        let entry = FoodEntry(
            foodId: testFoodId,
            foodName: "Chicken Breast",
            foodBrand: "Perdue",
            mealSection: .lunch,
            loggedAt: testDate,
            servingGrams: 150.0,
            servingDescription: "1 breast",
            caloriesPer100g: 165.0,
            proteinPer100g: 31.0,
            carbsPer100g: 0.0,
            fatPer100g: 3.6,
            fiberPer100g: 0.0,
            notes: "Grilled"
        )

        #expect(entry.foodId == testFoodId)
        #expect(entry.foodName == "Chicken Breast")
        #expect(entry.foodBrand == "Perdue")
        #expect(entry.mealSection == "lunch")
        #expect(entry.loggedAt == testDate)
        #expect(entry.servingGrams == 150.0)
        #expect(entry.servingDescription == "1 breast")
        #expect(entry.caloriesPer100g == 165.0)
        #expect(entry.proteinPer100g == 31.0)
        #expect(entry.carbsPer100g == 0.0)
        #expect(entry.fatPer100g == 3.6)
        #expect(entry.fiberPer100g == 0.0)
        #expect(entry.notes == "Grilled")
    }

    // MARK: - Meal Computed Property Tests

    @Test("meal computed property returns correct enum value for breakfast")
    func testMealGetterBreakfast() throws {
        let entry = FoodEntry()
        entry.mealSection = "breakfast"

        #expect(entry.meal == .breakfast)
    }

    @Test("meal computed property returns correct enum value for lunch")
    func testMealGetterLunch() throws {
        let entry = FoodEntry()
        entry.mealSection = "lunch"

        #expect(entry.meal == .lunch)
    }

    @Test("meal computed property returns correct enum value for dinner")
    func testMealGetterDinner() throws {
        let entry = FoodEntry()
        entry.mealSection = "dinner"

        #expect(entry.meal == .dinner)
    }

    @Test("meal computed property returns correct enum value for snacks")
    func testMealGetterSnacks() throws {
        let entry = FoodEntry()
        entry.mealSection = "snacks"

        #expect(entry.meal == .snacks)
    }

    @Test("meal computed property defaults to breakfast for unknown value")
    func testMealGetterUnknown() throws {
        let entry = FoodEntry()
        entry.mealSection = "unknownMeal"

        #expect(entry.meal == .breakfast)
    }

    @Test("meal setter updates mealSection string")
    func testMealSetter() throws {
        let entry = FoodEntry()

        entry.meal = .lunch
        #expect(entry.mealSection == "lunch")

        entry.meal = .dinner
        #expect(entry.mealSection == "dinner")

        entry.meal = .snacks
        #expect(entry.mealSection == "snacks")

        entry.meal = .breakfast
        #expect(entry.mealSection == "breakfast")
    }

    // MARK: - Computed Macro Tests

    @Test("calories computed property calculates correctly for 100g serving")
    func testCaloriesComputation100g() throws {
        let entry = FoodEntry(
            foodName: "Chicken",
            servingGrams: 100,
            caloriesPer100g: 165
        )

        // 165 * (100/100) = 165
        #expect(entry.calories == 165.0)
    }

    @Test("calories computed property calculates correctly for 150g serving")
    func testCaloriesComputation150g() throws {
        let entry = FoodEntry(
            foodName: "Chicken",
            servingGrams: 150,
            caloriesPer100g: 165
        )

        // 165 * (150/100) = 247.5
        #expect(entry.calories == 247.5)
    }

    @Test("calories computed property calculates correctly for 50g serving")
    func testCaloriesComputation50g() throws {
        let entry = FoodEntry(
            foodName: "Chicken",
            servingGrams: 50,
            caloriesPer100g: 165
        )

        // 165 * (50/100) = 82.5
        #expect(entry.calories == 82.5)
    }

    @Test("protein computed property calculates correctly for serving size")
    func testProteinComputation() throws {
        let entry = FoodEntry(
            foodName: "Chicken",
            servingGrams: 200,
            proteinPer100g: 31.0
        )

        // 31 * (200/100) = 62.0
        #expect(entry.protein == 62.0)
    }

    @Test("carbs computed property calculates correctly for serving size")
    func testCarbsComputation() throws {
        let entry = FoodEntry(
            foodName: "Rice",
            servingGrams: 150,
            carbsPer100g: 28.0
        )

        // 28 * (150/100) = 42.0
        #expect(abs(entry.carbs - 42.0) < 0.001)
    }

    @Test("fat computed property calculates correctly for serving size")
    func testFatComputation() throws {
        let entry = FoodEntry(
            foodName: "Salmon",
            servingGrams: 120,
            fatPer100g: 13.0
        )

        // 13 * (120/100) = 15.6
        #expect(abs(entry.fat - 15.6) < 0.001)
    }

    @Test("fiber computed property calculates correctly for serving size")
    func testFiberComputation() throws {
        let entry = FoodEntry(
            foodName: "Broccoli",
            servingGrams: 85,
            fiberPer100g: 2.6
        )

        // 2.6 * (85/100) = 2.21
        #expect(abs(entry.fiber - 2.21) < 0.001)
    }

    @Test("all macros calculate correctly together")
    func testAllMacrosComputation() throws {
        let entry = FoodEntry(
            foodName: "Balanced Meal",
            servingGrams: 200,
            caloriesPer100g: 150,
            proteinPer100g: 10,
            carbsPer100g: 20,
            fatPer100g: 5,
            fiberPer100g: 3
        )

        // All values * (200/100) = * 2
        #expect(entry.calories == 300.0)
        #expect(entry.protein == 20.0)
        #expect(entry.carbs == 40.0)
        #expect(entry.fat == 10.0)
        #expect(entry.fiber == 6.0)
    }

    @Test("macros return zero when serving is zero")
    func testMacrosWithZeroServing() throws {
        let entry = FoodEntry(
            foodName: "Test",
            servingGrams: 0,
            caloriesPer100g: 100,
            proteinPer100g: 10,
            carbsPer100g: 20,
            fatPer100g: 5,
            fiberPer100g: 2
        )

        #expect(entry.calories == 0.0)
        #expect(entry.protein == 0.0)
        #expect(entry.carbs == 0.0)
        #expect(entry.fat == 0.0)
        #expect(entry.fiber == 0.0)
    }

    // MARK: - Convenience Initializer Tests

    @Test("convenience init from Food copies all nutrition data")
    func testConvenienceInitFromFood() throws {
        let food = Food(
            name: "Chicken Breast",
            brand: "Generic",
            caloriesPer100g: 165,
            proteinPer100g: 31,
            carbsPer100g: 0,
            fatPer100g: 3.6,
            fiberPer100g: 0,
            servingDescription: "3 oz cooked"
        )

        let entry = FoodEntry(from: food, servingGrams: 200, mealSection: .lunch, user: nil)

        #expect(entry.foodId == food.id)
        #expect(entry.foodName == "Chicken Breast")
        #expect(entry.foodBrand == "Generic")
        #expect(entry.caloriesPer100g == 165)
        #expect(entry.proteinPer100g == 31)
        #expect(entry.carbsPer100g == 0)
        #expect(entry.fatPer100g == 3.6)
        #expect(entry.fiberPer100g == 0)
        #expect(entry.servingGrams == 200)
        #expect(entry.servingDescription == "3 oz cooked")
        #expect(entry.meal == .lunch)
        #expect(entry.loggedAt <= Date())
    }

    @Test("convenience init from Food with user sets relationship")
    func testConvenienceInitFromFoodWithUser() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = User(name: "Test User")
        context.insert(user)

        let food = Food(name: "Salmon", caloriesPer100g: 208)

        let entry = FoodEntry(from: food, servingGrams: 150, mealSection: .dinner, user: user)

        #expect(entry.user === user)
        #expect(entry.foodName == "Salmon")
        #expect(entry.meal == .dinner)
    }

    @Test("convenience init from Food with nil brand handles nil correctly")
    func testConvenienceInitFromFoodWithNilBrand() throws {
        let food = Food(
            name: "Homemade Soup",
            brand: nil,
            caloriesPer100g: 45
        )

        let entry = FoodEntry(from: food, servingGrams: 250, mealSection: .snacks, user: nil)

        #expect(entry.foodBrand == nil)
        #expect(entry.foodName == "Homemade Soup")
    }

    // MARK: - SwiftData Persistence Tests

    @Test("FoodEntry can be inserted into SwiftData context")
    func testInsert() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let entry = FoodEntry(
            foodName: "Chicken Breast",
            mealSection: .lunch,
            servingGrams: 150,
            caloriesPer100g: 165.0
        )
        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<FoodEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        #expect(entries.first?.foodName == "Chicken Breast")
        #expect(entries.first?.mealSection == "lunch")
        #expect(entries.first?.servingGrams == 150.0)
        #expect(entries.first?.caloriesPer100g == 165.0)
    }

    @Test("FoodEntry can be fetched from SwiftData context")
    func testFetch() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        // Insert multiple entries
        let breakfast = FoodEntry(foodName: "Oatmeal", mealSection: .breakfast, caloriesPer100g: 68)
        let lunch = FoodEntry(foodName: "Salad", mealSection: .lunch, caloriesPer100g: 20)
        let dinner = FoodEntry(foodName: "Steak", mealSection: .dinner, caloriesPer100g: 271)

        context.insert(breakfast)
        context.insert(lunch)
        context.insert(dinner)
        try context.save()

        let descriptor = FetchDescriptor<FoodEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 3)
    }

    @Test("FoodEntry can be updated in SwiftData context")
    func testUpdate() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let entry = FoodEntry(foodName: "Chicken Breast", caloriesPer100g: 165.0)
        context.insert(entry)
        try context.save()

        // Update the entry
        entry.foodName = "Grilled Chicken Breast"
        entry.caloriesPer100g = 170.0
        entry.notes = "Added seasonings"
        try context.save()

        // Fetch and verify
        let descriptor = FetchDescriptor<FoodEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        #expect(entries.first?.foodName == "Grilled Chicken Breast")
        #expect(entries.first?.caloriesPer100g == 170.0)
        #expect(entries.first?.notes == "Added seasonings")
    }

    @Test("FoodEntry can be deleted from SwiftData context")
    func testDelete() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let entry = FoodEntry(foodName: "Chicken Breast", caloriesPer100g: 165.0)
        context.insert(entry)
        try context.save()

        // Verify inserted
        var descriptor = FetchDescriptor<FoodEntry>()
        var entries = try context.fetch(descriptor)
        #expect(entries.count == 1)

        // Delete
        context.delete(entry)
        try context.save()

        // Verify deleted
        descriptor = FetchDescriptor<FoodEntry>()
        entries = try context.fetch(descriptor)
        #expect(entries.count == 0)
    }

    @Test("FoodEntry with all nutrition values persists correctly")
    func testFullNutritionPersistence() throws {
        let container = try createTestContainer()
        let context = container.mainContext
        let testDate = Date()
        let testFoodId = UUID()

        let entry = FoodEntry(
            foodId: testFoodId,
            foodName: "Whole Milk",
            foodBrand: "Organic Valley",
            mealSection: .breakfast,
            loggedAt: testDate,
            servingGrams: 244.0,
            servingDescription: "1 cup",
            caloriesPer100g: 61.0,
            proteinPer100g: 3.2,
            carbsPer100g: 4.8,
            fatPer100g: 3.3,
            fiberPer100g: 0.0,
            notes: "Morning coffee"
        )

        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<FoodEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        guard let fetched = entries.first else {
            Issue.record("No FoodEntry found after insert")
            return
        }

        #expect(fetched.foodId == testFoodId)
        #expect(fetched.foodName == "Whole Milk")
        #expect(fetched.foodBrand == "Organic Valley")
        #expect(fetched.mealSection == "breakfast")
        #expect(fetched.loggedAt == testDate)
        #expect(fetched.servingGrams == 244.0)
        #expect(fetched.servingDescription == "1 cup")
        #expect(fetched.caloriesPer100g == 61.0)
        #expect(fetched.proteinPer100g == 3.2)
        #expect(fetched.carbsPer100g == 4.8)
        #expect(fetched.fatPer100g == 3.3)
        #expect(fetched.fiberPer100g == 0.0)
        #expect(fetched.notes == "Morning coffee")
    }

    @Test("FoodEntry with different meal sections persists correctly")
    func testDifferentMealSectionsPersistence() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let breakfast = FoodEntry(foodName: "Eggs", mealSection: .breakfast)
        let lunch = FoodEntry(foodName: "Sandwich", mealSection: .lunch)
        let dinner = FoodEntry(foodName: "Pasta", mealSection: .dinner)
        let snack = FoodEntry(foodName: "Apple", mealSection: .snacks)

        context.insert(breakfast)
        context.insert(lunch)
        context.insert(dinner)
        context.insert(snack)
        try context.save()

        let descriptor = FetchDescriptor<FoodEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 4)

        let breakfastResult = entries.first { $0.foodName == "Eggs" }
        let lunchResult = entries.first { $0.foodName == "Sandwich" }
        let dinnerResult = entries.first { $0.foodName == "Pasta" }
        let snackResult = entries.first { $0.foodName == "Apple" }

        #expect(breakfastResult?.meal == .breakfast)
        #expect(lunchResult?.meal == .lunch)
        #expect(dinnerResult?.meal == .dinner)
        #expect(snackResult?.meal == .snacks)
    }

    // MARK: - User Relationship Tests

    @Test("FoodEntry can be associated with User")
    func testUserRelationship() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = User(name: "Test User")
        context.insert(user)

        let entry = FoodEntry(foodName: "Chicken Breast", user: user)
        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<FoodEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        #expect(entries.first?.user === user)
        #expect(entries.first?.user?.name == "Test User")
    }

    @Test("FoodEntry can exist without User")
    func testFoodEntryWithoutUser() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let entry = FoodEntry(foodName: "Standalone Entry", user: nil)
        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<FoodEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 1)
        #expect(entries.first?.user == nil)
    }

    @Test("Multiple FoodEntries can be associated with same User")
    func testMultipleEntriesForUser() throws {
        let container = try createTestContainer()
        let context = container.mainContext

        let user = User(name: "Test User")
        context.insert(user)

        let entry1 = FoodEntry(foodName: "Breakfast", mealSection: .breakfast, user: user)
        let entry2 = FoodEntry(foodName: "Lunch", mealSection: .lunch, user: user)
        let entry3 = FoodEntry(foodName: "Dinner", mealSection: .dinner, user: user)

        context.insert(entry1)
        context.insert(entry2)
        context.insert(entry3)
        try context.save()

        let descriptor = FetchDescriptor<FoodEntry>()
        let entries = try context.fetch(descriptor)

        #expect(entries.count == 3)
        #expect(entries.allSatisfy { $0.user === user })
    }
}
