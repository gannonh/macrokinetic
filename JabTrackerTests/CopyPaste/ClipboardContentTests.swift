//
//  ClipboardContentTests.swift
//  JabTrackerTests
//
//  Tests for ClipboardContent and ClipboardEntry value types.
//

import Foundation
import Testing

@testable import JabTracker

@Suite("ClipboardEntry Tests")
@MainActor
struct ClipboardEntryTests {

    // MARK: - Test Helpers

    /// Creates a FoodEntry for testing without requiring SwiftData persistence
    private func createTestFoodEntry(
        name: String = "Test Food",
        brand: String? = nil,
        meal: MealSection = .breakfast,
        servingGrams: Double = 100,
        caloriesPer100g: Double = 200,
        proteinPer100g: Double = 10,
        carbsPer100g: Double = 25,
        fatPer100g: Double = 8,
        fiberPer100g: Double = 3
    ) -> FoodEntry {
        FoodEntry(
            foodId: UUID(),
            foodName: name,
            foodBrand: brand,
            mealSection: meal,
            loggedAt: Date(),
            servingGrams: servingGrams,
            servingDescription: "1 cup",
            servingOptionsJSON: "[{\"description\": \"1 cup\", \"grams\": 100}]",
            caloriesPer100g: caloriesPer100g,
            proteinPer100g: proteinPer100g,
            carbsPer100g: carbsPer100g,
            fatPer100g: fatPer100g,
            fiberPer100g: fiberPer100g
        )
    }

    // MARK: - ClipboardEntry Init from FoodEntry Tests

    @Test("ClipboardEntry creates new ID distinct from original FoodEntry")
    func testClipboardEntryCreatesNewId() throws {
        let foodEntry = createTestFoodEntry()
        let originalId = foodEntry.id

        let clipboardEntry = ClipboardEntry(from: foodEntry)

        #expect(clipboardEntry.id != originalId)
    }

    @Test("ClipboardEntry copies all properties from FoodEntry")
    func testClipboardEntryCopiesProperties() throws {
        let foodEntry = createTestFoodEntry(
            name: "Chicken Breast",
            brand: "Organic Farms",
            meal: .lunch,
            servingGrams: 150,
            caloriesPer100g: 165,
            proteinPer100g: 31,
            carbsPer100g: 0,
            fatPer100g: 3.6,
            fiberPer100g: 0
        )

        let clipboardEntry = ClipboardEntry(from: foodEntry)

        #expect(clipboardEntry.foodId == foodEntry.foodId)
        #expect(clipboardEntry.foodName == "Chicken Breast")
        #expect(clipboardEntry.foodBrand == "Organic Farms")
        #expect(clipboardEntry.mealSection == .lunch)
        #expect(clipboardEntry.servingGrams == 150)
        #expect(clipboardEntry.caloriesPer100g == 165)
        #expect(clipboardEntry.proteinPer100g == 31)
        #expect(clipboardEntry.carbsPer100g == 0)
        #expect(clipboardEntry.fatPer100g == 3.6)
        #expect(clipboardEntry.fiberPer100g == 0)
    }

    @Test("ClipboardEntry copies serving description from FoodEntry")
    func testClipboardEntryCopiesServingDescription() throws {
        let foodEntry = createTestFoodEntry()

        let clipboardEntry = ClipboardEntry(from: foodEntry)

        #expect(clipboardEntry.servingDescription == "1 cup")
    }

    @Test("ClipboardEntry copies serving options JSON from FoodEntry")
    func testClipboardEntryCopiesServingOptionsJSON() throws {
        let foodEntry = createTestFoodEntry()

        let clipboardEntry = ClipboardEntry(from: foodEntry)

        #expect(clipboardEntry.servingOptionsJSON.contains("1 cup"))
    }

    @Test("ClipboardEntry copies notes from FoodEntry")
    func testClipboardEntryCopiesNotes() throws {
        let foodEntry = createTestFoodEntry()
        foodEntry.notes = "Grilled with olive oil"

        let clipboardEntry = ClipboardEntry(from: foodEntry)

        #expect(clipboardEntry.notes == "Grilled with olive oil")
    }

    // MARK: - ClipboardEntry Memberwise Initializer Tests

    @Test("ClipboardEntry memberwise initializer creates with all values")
    func testMemberwiseInitializer() {
        let id = UUID()
        let foodId = UUID()

        let entry = ClipboardEntry(
            id: id,
            foodId: foodId,
            foodName: "Oatmeal",
            foodBrand: "Quaker",
            mealSection: .breakfast,
            servingGrams: 40,
            servingDescription: "1/2 cup dry",
            servingOptionsJSON: "[]",
            caloriesPer100g: 389,
            proteinPer100g: 16.9,
            carbsPer100g: 66.3,
            fatPer100g: 6.9,
            fiberPer100g: 10.6,
            notes: "Add berries"
        )

        #expect(entry.id == id)
        #expect(entry.foodId == foodId)
        #expect(entry.foodName == "Oatmeal")
        #expect(entry.foodBrand == "Quaker")
        #expect(entry.mealSection == .breakfast)
        #expect(entry.servingGrams == 40)
        #expect(entry.servingDescription == "1/2 cup dry")
        #expect(entry.caloriesPer100g == 389)
        #expect(entry.proteinPer100g == 16.9)
        #expect(entry.carbsPer100g == 66.3)
        #expect(entry.fatPer100g == 6.9)
        #expect(entry.fiberPer100g == 10.6)
        #expect(entry.notes == "Add berries")
    }

    @Test("ClipboardEntry memberwise initializer uses default values")
    func testMemberwiseInitializerDefaults() {
        let foodId = UUID()

        let entry = ClipboardEntry(
            foodId: foodId,
            foodName: "Apple",
            mealSection: .snacks,
            servingGrams: 182,
            caloriesPer100g: 52,
            proteinPer100g: 0.3,
            carbsPer100g: 14,
            fatPer100g: 0.2
        )

        #expect(entry.foodBrand == nil)
        #expect(entry.servingDescription == nil)
        #expect(entry.servingOptionsJSON == "[]")
        #expect(entry.fiberPer100g == 0)
        #expect(entry.notes == nil)
    }

    // MARK: - ClipboardEntry Equatable Tests

    @Test("ClipboardEntry Equatable compares all fields")
    func testEquatable() {
        let id = UUID()
        let foodId = UUID()

        let entry1 = ClipboardEntry(
            id: id,
            foodId: foodId,
            foodName: "Banana",
            mealSection: .snacks,
            servingGrams: 118,
            caloriesPer100g: 89,
            proteinPer100g: 1.1,
            carbsPer100g: 23,
            fatPer100g: 0.3
        )

        let entry2 = ClipboardEntry(
            id: id,
            foodId: foodId,
            foodName: "Banana",
            mealSection: .snacks,
            servingGrams: 118,
            caloriesPer100g: 89,
            proteinPer100g: 1.1,
            carbsPer100g: 23,
            fatPer100g: 0.3
        )

        #expect(entry1 == entry2)
    }

    @Test("ClipboardEntry not equal when values differ")
    func testNotEqual() {
        let foodId = UUID()

        let entry1 = ClipboardEntry(
            foodId: foodId,
            foodName: "Banana",
            mealSection: .snacks,
            servingGrams: 118,
            caloriesPer100g: 89,
            proteinPer100g: 1.1,
            carbsPer100g: 23,
            fatPer100g: 0.3
        )

        let entry2 = ClipboardEntry(
            foodId: foodId,
            foodName: "Apple",  // Different name
            mealSection: .snacks,
            servingGrams: 118,
            caloriesPer100g: 89,
            proteinPer100g: 1.1,
            carbsPer100g: 23,
            fatPer100g: 0.3
        )

        #expect(entry1 != entry2)
    }
}

@Suite("FoodClipboardContent Tests")
struct FoodClipboardContentTests {

    // MARK: - entryCount Tests

    @Test("FoodClipboardContent entryCount returns count for day content")
    func testEntryCountDay() {
        let entries = [
            ClipboardEntry(
                foodId: UUID(),
                foodName: "Eggs",
                mealSection: .breakfast,
                servingGrams: 100,
                caloriesPer100g: 155,
                proteinPer100g: 13,
                carbsPer100g: 1.1,
                fatPer100g: 11
            ),
            ClipboardEntry(
                foodId: UUID(),
                foodName: "Toast",
                mealSection: .breakfast,
                servingGrams: 50,
                caloriesPer100g: 264,
                proteinPer100g: 9,
                carbsPer100g: 49,
                fatPer100g: 3.2
            ),
        ]

        let content = FoodClipboardContent.day(date: Date(), entries: entries)

        #expect(content.entryCount == 2)
    }

    @Test("FoodClipboardContent entryCount returns count for meal content")
    func testEntryCountMeal() {
        let entries = [
            ClipboardEntry(
                foodId: UUID(),
                foodName: "Salad",
                mealSection: .lunch,
                servingGrams: 200,
                caloriesPer100g: 20,
                proteinPer100g: 1.5,
                carbsPer100g: 3,
                fatPer100g: 0.2
            )
        ]

        let content = FoodClipboardContent.meal(date: Date(), meal: .lunch, entries: entries)

        #expect(content.entryCount == 1)
    }

    // MARK: - sourceDescription Tests

    @Test("FoodClipboardContent sourceDescription for day with single item")
    func testSourceDescriptionDaySingle() {
        let entries = [
            ClipboardEntry(
                foodId: UUID(),
                foodName: "Coffee",
                mealSection: .breakfast,
                servingGrams: 240,
                caloriesPer100g: 1,
                proteinPer100g: 0.3,
                carbsPer100g: 0,
                fatPer100g: 0
            )
        ]

        let content = FoodClipboardContent.day(date: Date(), entries: entries)
        let description = content.sourceDescription

        #expect(description.contains("1 item from"))
    }

    @Test("FoodClipboardContent sourceDescription for day with multiple items")
    func testSourceDescriptionDayMultiple() {
        let entries = [
            ClipboardEntry(
                foodId: UUID(),
                foodName: "Eggs",
                mealSection: .breakfast,
                servingGrams: 100,
                caloriesPer100g: 155,
                proteinPer100g: 13,
                carbsPer100g: 1.1,
                fatPer100g: 11
            ),
            ClipboardEntry(
                foodId: UUID(),
                foodName: "Toast",
                mealSection: .breakfast,
                servingGrams: 50,
                caloriesPer100g: 264,
                proteinPer100g: 9,
                carbsPer100g: 49,
                fatPer100g: 3.2
            ),
            ClipboardEntry(
                foodId: UUID(),
                foodName: "Orange Juice",
                mealSection: .breakfast,
                servingGrams: 200,
                caloriesPer100g: 45,
                proteinPer100g: 0.7,
                carbsPer100g: 10,
                fatPer100g: 0.2
            ),
        ]

        let content = FoodClipboardContent.day(date: Date(), entries: entries)
        let description = content.sourceDescription

        #expect(description.contains("3 items from"))
    }

    @Test("FoodClipboardContent sourceDescription for meal shows meal name")
    func testSourceDescriptionMealShowsMealName() {
        let entries = [
            ClipboardEntry(
                foodId: UUID(),
                foodName: "Chicken",
                mealSection: .lunch,
                servingGrams: 150,
                caloriesPer100g: 165,
                proteinPer100g: 31,
                carbsPer100g: 0,
                fatPer100g: 3.6
            )
        ]

        let content = FoodClipboardContent.meal(date: Date(), meal: .lunch, entries: entries)
        let description = content.sourceDescription

        #expect(description.contains("Lunch"))
    }

    @Test("FoodClipboardContent sourceDescription for breakfast")
    func testSourceDescriptionBreakfast() {
        let entries = [
            ClipboardEntry(
                foodId: UUID(),
                foodName: "Oatmeal",
                mealSection: .breakfast,
                servingGrams: 100,
                caloriesPer100g: 68,
                proteinPer100g: 2.4,
                carbsPer100g: 12,
                fatPer100g: 1.4
            )
        ]

        let content = FoodClipboardContent.meal(date: Date(), meal: .breakfast, entries: entries)

        #expect(content.sourceDescription.contains("Breakfast"))
    }

    @Test("FoodClipboardContent sourceDescription for dinner")
    func testSourceDescriptionDinner() {
        let entries = [
            ClipboardEntry(
                foodId: UUID(),
                foodName: "Steak",
                mealSection: .dinner,
                servingGrams: 200,
                caloriesPer100g: 271,
                proteinPer100g: 26,
                carbsPer100g: 0,
                fatPer100g: 18
            )
        ]

        let content = FoodClipboardContent.meal(date: Date(), meal: .dinner, entries: entries)

        #expect(content.sourceDescription.contains("Dinner"))
    }

    @Test("FoodClipboardContent sourceDescription for snacks")
    func testSourceDescriptionSnacks() {
        let entries = [
            ClipboardEntry(
                foodId: UUID(),
                foodName: "Almonds",
                mealSection: .snacks,
                servingGrams: 28,
                caloriesPer100g: 579,
                proteinPer100g: 21,
                carbsPer100g: 22,
                fatPer100g: 50
            )
        ]

        let content = FoodClipboardContent.meal(date: Date(), meal: .snacks, entries: entries)

        #expect(content.sourceDescription.contains("Snacks"))
    }

    // MARK: - Equatable Tests

    @Test("FoodClipboardContent Equatable for day content")
    func testEquatableDay() {
        let date = Date()
        let entries = [
            ClipboardEntry(
                id: UUID(),
                foodId: UUID(),
                foodName: "Test",
                mealSection: .breakfast,
                servingGrams: 100,
                caloriesPer100g: 100,
                proteinPer100g: 10,
                carbsPer100g: 10,
                fatPer100g: 5
            )
        ]

        let content1 = FoodClipboardContent.day(date: date, entries: entries)
        let content2 = FoodClipboardContent.day(date: date, entries: entries)

        #expect(content1 == content2)
    }

    @Test("FoodClipboardContent Equatable for meal content")
    func testEquatableMeal() {
        let date = Date()
        let entries = [
            ClipboardEntry(
                id: UUID(),
                foodId: UUID(),
                foodName: "Test",
                mealSection: .lunch,
                servingGrams: 100,
                caloriesPer100g: 100,
                proteinPer100g: 10,
                carbsPer100g: 10,
                fatPer100g: 5
            )
        ]

        let content1 = FoodClipboardContent.meal(date: date, meal: .lunch, entries: entries)
        let content2 = FoodClipboardContent.meal(date: date, meal: .lunch, entries: entries)

        #expect(content1 == content2)
    }

    @Test("FoodClipboardContent not equal for different types")
    func testNotEqualDifferentTypes() {
        let date = Date()
        let entries = [
            ClipboardEntry(
                id: UUID(),
                foodId: UUID(),
                foodName: "Test",
                mealSection: .lunch,
                servingGrams: 100,
                caloriesPer100g: 100,
                proteinPer100g: 10,
                carbsPer100g: 10,
                fatPer100g: 5
            )
        ]

        let dayContent = FoodClipboardContent.day(date: date, entries: entries)
        let mealContent = FoodClipboardContent.meal(date: date, meal: .lunch, entries: entries)

        #expect(dayContent != mealContent)
    }
}
