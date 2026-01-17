//
//  FoodClipboardServiceTests.swift
//  JabTrackerTests
//
//  Tests for FoodClipboardService session clipboard functionality.
//

import Foundation
import Testing

@testable import JabTracker

@Suite("FoodClipboardService Tests")
@MainActor
struct FoodClipboardServiceTests {

    // MARK: - Test Helpers

    /// Creates a FoodEntry for testing without requiring SwiftData persistence
    private func createTestFoodEntry(
        name: String = "Test Food",
        meal: MealSection = .breakfast
    ) -> FoodEntry {
        FoodEntry(
            foodId: UUID(),
            foodName: name,
            foodBrand: nil,
            mealSection: meal,
            loggedAt: Date(),
            servingGrams: 100,
            servingDescription: "1 serving",
            servingOptionsJSON: "[]",
            caloriesPer100g: 200,
            proteinPer100g: 10,
            carbsPer100g: 25,
            fatPer100g: 8,
            fiberPer100g: 3
        )
    }

    // MARK: - Initial State Tests

    @Test("FoodClipboardService initializes with empty content")
    func testInitialStateIsEmpty() {
        let service = FoodClipboardService()

        #expect(service.content == nil)
        #expect(service.hasContent == false)
        #expect(service.entryCount == 0)
    }

    // MARK: - copyDay Tests

    @Test("copyDay stores entries as day content")
    func testCopyDayStoresEntries() {
        let service = FoodClipboardService()
        let date = Date()

        let entry1 = createTestFoodEntry(name: "Eggs", meal: .breakfast)
        let entry2 = createTestFoodEntry(name: "Toast", meal: .breakfast)

        service.copyDay(date: date, entries: [entry1, entry2])

        #expect(service.hasContent == true)
        #expect(service.entryCount == 2)

        guard case .day(let storedDate, let entries) = service.content else {
            Issue.record("Expected .day content type")
            return
        }

        #expect(storedDate == date)
        #expect(entries.count == 2)
        #expect(entries[0].foodName == "Eggs")
        #expect(entries[1].foodName == "Toast")
    }

    @Test("copyDay replaces existing content")
    func testCopyDayReplacesExisting() {
        let service = FoodClipboardService()

        let entry1 = createTestFoodEntry(name: "First Food")
        service.copyDay(date: Date(), entries: [entry1])

        #expect(service.entryCount == 1)

        let entry2 = createTestFoodEntry(name: "Second Food")
        let entry3 = createTestFoodEntry(name: "Third Food")
        service.copyDay(date: Date(), entries: [entry2, entry3])

        #expect(service.entryCount == 2)
        guard case .day(_, let entries) = service.content else {
            Issue.record("Expected .day content type")
            return
        }
        #expect(entries[0].foodName == "Second Food")
    }

    @Test("copyDay with empty entries stores empty array")
    func testCopyDayEmptyEntries() {
        let service = FoodClipboardService()

        service.copyDay(date: Date(), entries: [])

        #expect(service.hasContent == true)
        #expect(service.entryCount == 0)
    }

    // MARK: - copyMeal Tests

    @Test("copyMeal stores entries as meal content")
    func testCopyMealStoresEntries() {
        let service = FoodClipboardService()
        let date = Date()

        let entry = createTestFoodEntry(name: "Chicken Salad", meal: .lunch)

        service.copyMeal(date: date, meal: .lunch, entries: [entry])

        #expect(service.hasContent == true)
        #expect(service.entryCount == 1)

        guard case .meal(let storedDate, let meal, let entries) = service.content else {
            Issue.record("Expected .meal content type")
            return
        }

        #expect(storedDate == date)
        #expect(meal == .lunch)
        #expect(entries.count == 1)
        #expect(entries[0].foodName == "Chicken Salad")
    }

    @Test("copyMeal preserves meal section in entries")
    func testCopyMealPreservesMealSection() {
        let service = FoodClipboardService()

        let entry = createTestFoodEntry(name: "Steak", meal: .dinner)

        service.copyMeal(date: Date(), meal: .dinner, entries: [entry])

        guard case .meal(_, _, let entries) = service.content else {
            Issue.record("Expected .meal content type")
            return
        }

        #expect(entries[0].mealSection == .dinner)
    }

    @Test("copyMeal replaces day content")
    func testCopyMealReplacesDayContent() {
        let service = FoodClipboardService()

        let dayEntry = createTestFoodEntry(name: "Day Entry")
        service.copyDay(date: Date(), entries: [dayEntry])

        let mealEntry = createTestFoodEntry(name: "Meal Entry", meal: .lunch)
        service.copyMeal(date: Date(), meal: .lunch, entries: [mealEntry])

        guard case .meal = service.content else {
            Issue.record("Expected content to be replaced with .meal type")
            return
        }
    }

    @Test("copyMeal with multiple entries")
    func testCopyMealMultipleEntries() {
        let service = FoodClipboardService()

        let entries = [
            createTestFoodEntry(name: "Eggs", meal: .breakfast),
            createTestFoodEntry(name: "Bacon", meal: .breakfast),
            createTestFoodEntry(name: "Coffee", meal: .breakfast),
        ]

        service.copyMeal(date: Date(), meal: .breakfast, entries: entries)

        #expect(service.entryCount == 3)
    }

    // MARK: - clear Tests

    @Test("clear removes content")
    func testClearRemovesContent() {
        let service = FoodClipboardService()

        let entry = createTestFoodEntry()
        service.copyDay(date: Date(), entries: [entry])
        #expect(service.hasContent == true)

        service.clear()

        #expect(service.content == nil)
        #expect(service.hasContent == false)
        #expect(service.entryCount == 0)
    }

    @Test("clear on empty clipboard does not crash")
    func testClearEmptyClipboard() {
        let service = FoodClipboardService()

        service.clear()

        #expect(service.content == nil)
    }

    // MARK: - hasContent Tests

    @Test("hasContent returns true after copying")
    func testHasContentAfterCopy() {
        let service = FoodClipboardService()

        #expect(service.hasContent == false)

        let entry = createTestFoodEntry()
        service.copyDay(date: Date(), entries: [entry])

        #expect(service.hasContent == true)
    }

    @Test("hasContent returns false after clear")
    func testHasContentAfterClear() {
        let service = FoodClipboardService()

        let entry = createTestFoodEntry()
        service.copyDay(date: Date(), entries: [entry])
        service.clear()

        #expect(service.hasContent == false)
    }

    // MARK: - entryCount Tests

    @Test("entryCount returns correct count for day content")
    func testEntryCountDay() {
        let service = FoodClipboardService()

        let entries = [
            createTestFoodEntry(name: "Food 1"),
            createTestFoodEntry(name: "Food 2"),
            createTestFoodEntry(name: "Food 3"),
            createTestFoodEntry(name: "Food 4"),
            createTestFoodEntry(name: "Food 5"),
        ]

        service.copyDay(date: Date(), entries: entries)

        #expect(service.entryCount == 5)
    }

    @Test("entryCount returns correct count for meal content")
    func testEntryCountMeal() {
        let service = FoodClipboardService()

        let entries = [
            createTestFoodEntry(name: "Protein", meal: .dinner),
            createTestFoodEntry(name: "Carbs", meal: .dinner),
        ]

        service.copyMeal(date: Date(), meal: .dinner, entries: entries)

        #expect(service.entryCount == 2)
    }

    @Test("entryCount returns 0 for empty clipboard")
    func testEntryCountEmpty() {
        let service = FoodClipboardService()

        #expect(service.entryCount == 0)
    }

    // MARK: - ClipboardEntry ID Generation Tests

    @Test("Copied entries get new UUIDs")
    func testCopiedEntriesGetNewIds() {
        let service = FoodClipboardService()

        let entry = createTestFoodEntry(name: "Original")
        let originalId = entry.id

        service.copyDay(date: Date(), entries: [entry])

        guard case .day(_, let clipboardEntries) = service.content else {
            Issue.record("Expected .day content")
            return
        }

        // ClipboardEntry should have a new ID, not the original FoodEntry ID
        #expect(clipboardEntries[0].id != originalId)
    }

    // MARK: - Content sourceDescription Tests

    @Test("content sourceDescription for day is accessible")
    func testContentSourceDescriptionDay() {
        let service = FoodClipboardService()

        let entries = [
            createTestFoodEntry(name: "Food 1"),
            createTestFoodEntry(name: "Food 2"),
        ]

        service.copyDay(date: Date(), entries: entries)

        guard let content = service.content else {
            Issue.record("Expected content to be set")
            return
        }

        let description = content.sourceDescription
        #expect(description.contains("2 items"))
    }

    @Test("content sourceDescription for meal is accessible")
    func testContentSourceDescriptionMeal() {
        let service = FoodClipboardService()

        let entries = [
            createTestFoodEntry(name: "Lunch Food", meal: .lunch)
        ]

        service.copyMeal(date: Date(), meal: .lunch, entries: entries)

        guard let content = service.content else {
            Issue.record("Expected content to be set")
            return
        }

        let description = content.sourceDescription
        #expect(description.contains("1 item"))
        #expect(description.contains("Lunch"))
    }
}
