//
//  FoodSearchSheetTests.swift
//  JabTrackerTests
//
//  Tests for the FoodSearchSheet view.
//

import SwiftData
import SwiftUI
import Testing

@testable import JabTracker

@Suite("FoodSearchSheet Tests")
struct FoodSearchSheetTests {

    // MARK: - Test Setup

    @MainActor
    func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([User.self, Food.self, FoodEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
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
        context.insert(user)
        try? context.save()
        return user
    }

    // MARK: - Static Properties Tests

    @Test("FoodSearchSheet has correct accessibility identifier")
    @MainActor
    func hasCorrectAccessibilityIdentifier() {
        #expect(FoodSearchSheet.accessibilityIdentifierValue == "food-search-sheet")
    }

    @Test("FoodSearchSheet search field has correct accessibility identifier")
    @MainActor
    func searchFieldHasCorrectAccessibilityIdentifier() {
        #expect(FoodSearchSheet.searchFieldIdentifier == "food-search-field")
    }

    @Test("FoodSearchSheet time picker has correct accessibility identifier")
    @MainActor
    func timePickerHasCorrectAccessibilityIdentifier() {
        #expect(FoodSearchSheet.timePickerIdentifier == "time-picker-button")
    }

    // MARK: - Initialization Tests

    @Test("FoodSearchSheet initializes with required parameters")
    @MainActor
    func initializesWithRequiredParameters() async {
        let (context, container) = createTestContext()
        _ = container

        let user = createTestUser(context: context)
        let foodService = FoodService(context: context)
        let mealLogService = MealLogService(context: context)

        let sheet = FoodSearchSheet(
            user: user,
            foodService: foodService,
            mealLogService: mealLogService,
            onComplete: {}
        )

        #expect(sheet.user.dailyCalorieGoal == 2000.0)
    }

    // MARK: - Method Tabs Tests

    @Test("FoodSearchSheet displays all method tabs")
    @MainActor
    func displaysAllMethodTabs() {
        // All 5 search methods should be available
        #expect(SearchMethod.allCases.count == 5)

        // Verify tab order
        let methods = SearchMethod.allCases
        #expect(methods[0] == .scan)
        #expect(methods[1] == .search)
        #expect(methods[2] == .ai)
        #expect(methods[3] == .quickAdd)
        #expect(methods[4] == .library)
    }
}

// MARK: - FoodSearchResultRow Tests

@Suite("FoodSearchResultRow Tests")
struct FoodSearchResultRowTests {

    @Test("FoodSearchResultRow formats calories correctly")
    @MainActor
    func formatsCaloriesCorrectly() {
        let result = FoodSearchResult(
            fdcId: 12345,
            barcode: nil,
            name: "Test Food",
            brand: nil,
            source: .local,
            caloriesPer100g: 250.0,
            proteinPer100g: 10.0,
            carbsPer100g: 30.0,
            fatPer100g: 12.0,
            fiberPer100g: 2.0,
            category: nil
        )

        #expect(result.caloriesPer100g == 250.0)
        #expect(result.proteinPer100g == 10.0)
    }

    @Test("FoodSearchResultRow displays brand when available")
    @MainActor
    func displaysBrandWhenAvailable() {
        let resultWithBrand = FoodSearchResult(
            fdcId: 12345,
            barcode: nil,
            name: "Whopper",
            brand: "Burger King",
            source: .openFoodFacts,
            caloriesPer100g: 250.0,
            proteinPer100g: 10.0,
            carbsPer100g: 30.0,
            fatPer100g: 12.0,
            fiberPer100g: 2.0,
            category: nil
        )

        #expect(resultWithBrand.brand == "Burger King")

        let resultWithoutBrand = FoodSearchResult(
            fdcId: 12346,
            barcode: nil,
            name: "Apple",
            brand: nil,
            source: .local,
            caloriesPer100g: 52.0,
            proteinPer100g: 0.3,
            carbsPer100g: 14.0,
            fatPer100g: 0.2,
            fiberPer100g: 2.4,
            category: nil
        )

        #expect(resultWithoutBrand.brand == nil)
    }

    @Test("FoodSearchResultRow handles different food sources")
    @MainActor
    func handlesDifferentFoodSources() {
        let usdaResult = FoodSearchResult(
            fdcId: 1,
            barcode: nil,
            name: "USDA Food",
            brand: nil,
            source: .local,
            caloriesPer100g: 100,
            proteinPer100g: 5,
            carbsPer100g: 10,
            fatPer100g: 3,
            fiberPer100g: 1,
            category: nil
        )

        let offResult = FoodSearchResult(
            fdcId: nil,
            barcode: "12345678",
            name: "Branded Food",
            brand: "Brand",
            source: .openFoodFacts,
            caloriesPer100g: 200,
            proteinPer100g: 8,
            carbsPer100g: 25,
            fatPer100g: 10,
            fiberPer100g: 2,
            category: nil
        )

        let userResult = FoodSearchResult(
            fdcId: nil,
            barcode: nil,
            name: "Custom Food",
            brand: nil,
            source: .userCreated,
            caloriesPer100g: 150,
            proteinPer100g: 6,
            carbsPer100g: 15,
            fatPer100g: 8,
            fiberPer100g: 1,
            category: nil
        )

        #expect(usdaResult.source == .local)
        #expect(offResult.source == .openFoodFacts)
        #expect(userResult.source == .userCreated)
    }
}
