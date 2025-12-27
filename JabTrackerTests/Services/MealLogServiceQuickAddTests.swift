//
//  MealLogServiceQuickAddTests.swift
//  JabTrackerTests
//
//  Tests for MealLogService.logQuickAdd() method.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("MealLogService Quick Add Tests")
struct MealLogServiceQuickAddTests {

    // MARK: - Test Helpers

    @MainActor
    func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([User.self, MedicationProfile.self, Dose.self, Food.self, FoodEntry.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        return (container.mainContext, container)
    }

    // MARK: - Happy Path Tests

    @Test("logQuickAdd creates FoodEntry with correct macro values")
    @MainActor
    func testLogQuickAddCreatesEntryWithCorrectMacros() async throws {
        let (context, container) = createTestContext()
        _ = container  // Keep alive
        let service = MealLogService(context: context)

        let entry = try await service.logQuickAdd(
            name: "Test Snack",
            caloriesPer100g: 200,
            proteinPer100g: 20,
            carbsPer100g: 10,
            fatPer100g: 5,
            servingGrams: 100,
            mealSection: .snacks,
            notes: "Test note",
            loggedAt: Date()
        )

        #expect(entry.foodName == "Test Snack")
        #expect(entry.caloriesPer100g == 200)
        #expect(entry.proteinPer100g == 20)
        #expect(entry.carbsPer100g == 10)
        #expect(entry.fatPer100g == 5)
        #expect(entry.servingGrams == 100)
        #expect(entry.meal == .snacks)
        #expect(entry.notes == "Test note")
    }

    @Test("logQuickAdd sets correct meal section and loggedAt")
    @MainActor
    func testLogQuickAddSetsMealAndTime() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)

        let testDate = Date(timeIntervalSince1970: 1_700_000_000)

        let entry = try await service.logQuickAdd(
            name: "Breakfast Item",
            caloriesPer100g: 150,
            proteinPer100g: 10,
            carbsPer100g: 15,
            fatPer100g: 3,
            servingGrams: 50,
            mealSection: .breakfast,
            loggedAt: testDate
        )

        #expect(entry.meal == .breakfast)
        #expect(entry.loggedAt == testDate)
    }

    // MARK: - Validation Tests

    @Test("logQuickAdd with empty name throws emptyFoodName error")
    @MainActor
    func testLogQuickAddWithEmptyNameThrows() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)

        await #expect(throws: FoodEntryValidationError.emptyFoodName) {
            _ = try await service.logQuickAdd(
                name: "",
                caloriesPer100g: 100,
                proteinPer100g: 10,
                carbsPer100g: 10,
                fatPer100g: 5,
                servingGrams: 100,
                mealSection: .lunch
            )
        }
    }

    @Test("logQuickAdd with whitespace-only name throws emptyFoodName error")
    @MainActor
    func testLogQuickAddWithWhitespaceNameThrows() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)

        await #expect(throws: FoodEntryValidationError.emptyFoodName) {
            _ = try await service.logQuickAdd(
                name: "   ",
                caloriesPer100g: 100,
                proteinPer100g: 10,
                carbsPer100g: 10,
                fatPer100g: 5,
                servingGrams: 100,
                mealSection: .lunch
            )
        }
    }

    @Test("logQuickAdd with negative serving throws invalidServingSize error")
    @MainActor
    func testLogQuickAddWithNegativeServingThrows() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)

        await #expect(throws: FoodEntryValidationError.invalidServingSize) {
            _ = try await service.logQuickAdd(
                name: "Test Food",
                caloriesPer100g: 100,
                proteinPer100g: 10,
                carbsPer100g: 10,
                fatPer100g: 5,
                servingGrams: -50,
                mealSection: .lunch
            )
        }
    }

    @Test("logQuickAdd with zero serving throws invalidServingSize error")
    @MainActor
    func testLogQuickAddWithZeroServingThrows() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)

        await #expect(throws: FoodEntryValidationError.invalidServingSize) {
            _ = try await service.logQuickAdd(
                name: "Test Food",
                caloriesPer100g: 100,
                proteinPer100g: 10,
                carbsPer100g: 10,
                fatPer100g: 5,
                servingGrams: 0,
                mealSection: .lunch
            )
        }
    }
}
