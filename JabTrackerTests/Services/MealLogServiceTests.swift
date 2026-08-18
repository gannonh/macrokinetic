//
//  MealLogServiceTests.swift
//  JabTrackerTests
//
//  Tests for MealLogService - CRUD operations and queries for FoodEntry
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Tests for MealLogService
/// Verifies CRUD operations, date-based queries, and daily totals
@Suite("MealLogService Tests")
@MainActor
struct MealLogServiceTests {

    // MARK: - Log Entry Tests

    @Test("Log food entry creates FoodEntry in context")
    func testLogFoodEntryCreatesEntry() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let food = createTestFood(name: "Chicken Breast", calories: 165, protein: 31)

        let entry = try await service.logFood(
            food: food,
            servingGrams: 200,
            mealSection: .lunch
        )

        #expect(entry.foodName == "Chicken Breast")
        #expect(entry.servingGrams == 200)
        #expect(entry.meal == .lunch)
    }

    @Test("Log food entry calculates correct calories")
    func testLogFoodEntryCalculatesCalories() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let food = createTestFood(name: "Rice", calories: 130, protein: 2.7, carbs: 28)

        let entry = try await service.logFood(
            food: food,
            servingGrams: 150,
            mealSection: .dinner
        )

        // 130 calories per 100g * 1.5 = 195 calories
        #expect(entry.calories == 195)
    }

    @Test("Log food entry uses current time by default")
    func testLogFoodEntryUsesCurrentTime() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let food = createTestFood(name: "Apple", calories: 52)

        let before = Date()
        let entry = try await service.logFood(
            food: food,
            servingGrams: 100,
            mealSection: .snacks
        )
        let after = Date()

        #expect(entry.loggedAt >= before)
        #expect(entry.loggedAt <= after)
    }

    @Test("Log food entry with notes stores notes")
    func testLogFoodEntryWithNotes() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let food = createTestFood(name: "Salad", calories: 20)

        let entry = try await service.logFood(
            food: food,
            servingGrams: 200,
            mealSection: .lunch,
            notes: "Added dressing"
        )

        #expect(entry.notes == "Added dressing")
    }

    // MARK: - Get Entries Tests

    @Test("Get entries for date returns entries on that date")
    func testGetEntriesForDate() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        // Create entry for today
        let todayEntry = FoodEntry(
            foodName: "Today Food",
            mealSection: .breakfast,
            loggedAt: today
        )
        context.insert(todayEntry)

        // Create entry for yesterday
        let yesterdayEntry = FoodEntry(
            foodName: "Yesterday Food",
            mealSection: .breakfast,
            loggedAt: yesterday
        )
        context.insert(yesterdayEntry)

        try context.save()

        let entries = try await service.getEntries(for: today)

        #expect(entries.count == 1)
        #expect(entries.first?.foodName == "Today Food")
    }

    @Test("Get entries grouped by meal section")
    func testGetEntriesGroupedByMealSection() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let today = Date()

        // Create entries for different meal sections
        let breakfastEntry = FoodEntry(
            foodName: "Eggs",
            mealSection: .breakfast,
            loggedAt: today
        )
        context.insert(breakfastEntry)

        let lunchEntry = FoodEntry(
            foodName: "Sandwich",
            mealSection: .lunch,
            loggedAt: today
        )
        context.insert(lunchEntry)

        let dinnerEntry = FoodEntry(
            foodName: "Steak",
            mealSection: .dinner,
            loggedAt: today
        )
        context.insert(dinnerEntry)

        try context.save()

        let grouped = try await service.getEntriesGroupedByMeal(for: today)

        #expect(grouped[.breakfast]?.count == 1)
        #expect(grouped[.lunch]?.count == 1)
        #expect(grouped[.dinner]?.count == 1)
        #expect(grouped[.snacks]?.count == 0 || grouped[.snacks] == nil)
    }

    // MARK: - Daily Totals Tests

    @Test("Get daily totals calculates sum of all entries")
    func testGetDailyTotals() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let today = Date()

        // Entry 1: 200 cals, 20g protein, 30g carbs, 5g fat
        let entry1 = FoodEntry(
            foodName: "Food 1",
            mealSection: .breakfast,
            loggedAt: today,
            servingGrams: 100,
            caloriesPer100g: 200,
            proteinPer100g: 20,
            carbsPer100g: 30,
            fatPer100g: 5
        )
        context.insert(entry1)

        // Entry 2: 150 cals, 10g protein, 20g carbs, 3g fat (per 100g) at 200g serving
        // Actual: 300 cals, 20g protein, 40g carbs, 6g fat
        let entry2 = FoodEntry(
            foodName: "Food 2",
            mealSection: .lunch,
            loggedAt: today,
            servingGrams: 200,
            caloriesPer100g: 150,
            proteinPer100g: 10,
            carbsPer100g: 20,
            fatPer100g: 3
        )
        context.insert(entry2)

        try context.save()

        let totals = try await service.getDailyTotals(for: today)

        #expect(totals.calories == 500)  // 200 + 300
        #expect(totals.protein == 40)  // 20 + 20
        #expect(totals.carbs == 70)  // 30 + 40
        #expect(totals.fat == 11)  // 5 + 6
    }

    @Test("Daily totals returns zero for day with no entries")
    func testDailyTotalsReturnsZeroForEmptyDay() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let today = Date()

        let totals = try await service.getDailyTotals(for: today)

        #expect(totals.calories == 0)
        #expect(totals.protein == 0)
        #expect(totals.carbs == 0)
        #expect(totals.fat == 0)
    }

    // MARK: - Update Entry Tests

    @Test("Update entry modifies serving size")
    func testUpdateEntryModifiesServingSize() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let entry = FoodEntry(
            foodName: "Rice",
            mealSection: .dinner,
            loggedAt: Date(),
            servingGrams: 100,
            caloriesPer100g: 130
        )
        context.insert(entry)
        try context.save()

        try await service.updateEntry(entry, servingGrams: 200)

        #expect(entry.servingGrams == 200)
        #expect(entry.calories == 260)  // 130 * 2
    }

    @Test("Update entry modifies meal section")
    func testUpdateEntryModifiesMealSection() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let entry = FoodEntry(
            foodName: "Snack",
            mealSection: .snacks,
            loggedAt: Date()
        )
        context.insert(entry)
        try context.save()

        try await service.updateEntry(entry, mealSection: .lunch)

        #expect(entry.meal == .lunch)
    }

    @Test("Update entry modifies notes")
    func testUpdateEntryModifiesNotes() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let entry = FoodEntry(
            foodName: "Food",
            mealSection: .breakfast,
            loggedAt: Date()
        )
        context.insert(entry)
        try context.save()

        try await service.updateEntry(entry, notes: "Updated note")

        #expect(entry.notes == "Updated note")
    }

    @Test("Update entry modifies logged time")
    func testUpdateEntryModifiesLoggedAt() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let originalTime = Date()
        let entry = FoodEntry(
            foodName: "Food",
            mealSection: .breakfast,
            loggedAt: originalTime
        )
        context.insert(entry)
        try context.save()

        let newTime = Calendar.current.date(byAdding: .hour, value: -2, to: originalTime)!
        try await service.updateEntry(entry, loggedAt: newTime)

        #expect(entry.loggedAt == newTime)
    }

    // MARK: - Delete Entry Tests

    @Test("Delete entry removes from context")
    func testDeleteEntryRemovesFromContext() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let entry = FoodEntry(
            foodName: "To Delete",
            mealSection: .breakfast,
            loggedAt: Date()
        )
        context.insert(entry)
        try context.save()

        let entryId = entry.id
        try await service.deleteEntry(entry)

        // Try to fetch the deleted entry
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { $0.id == entryId }
        )
        let found = try context.fetch(descriptor)

        #expect(found.isEmpty)
    }

    // MARK: - Recent Entries Tests

    @Test("Get recent entries returns most recent first")
    func testGetRecentEntriesReturnsMostRecentFirst() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let now = Date()

        // Create entries at different times
        let olderEntry = FoodEntry(
            foodName: "Older",
            mealSection: .breakfast,
            loggedAt: now.addingTimeInterval(-3600)
        )
        context.insert(olderEntry)

        let newerEntry = FoodEntry(
            foodName: "Newer",
            mealSection: .lunch,
            loggedAt: now
        )
        context.insert(newerEntry)

        try context.save()

        let recent = try await service.getRecentEntries(limit: 10)

        #expect(recent.count == 2)
        #expect(recent[0].foodName == "Newer")
        #expect(recent[1].foodName == "Older")
    }

    @Test("Get recent entries respects limit")
    func testGetRecentEntriesRespectsLimit() async throws {
        let context = createTestContext()
        let service = MealLogService(context: context)

        let now = Date()

        // Create 5 entries
        for index in 0..<5 {
            let entry = FoodEntry(
                foodName: "Entry \(index)",
                mealSection: .breakfast,
                loggedAt: now.addingTimeInterval(Double(-index * 60))
            )
            context.insert(entry)
        }
        try context.save()

        let recent = try await service.getRecentEntries(limit: 3)

        #expect(recent.count == 3)
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
        let configuration = InMemoryTestStore.configuration(schema: schema)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func createTestFood(
        name: String,
        calories: Double,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0
    ) -> Food {
        Food(
            name: name,
            caloriesPer100g: calories,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat
        )
    }
}
