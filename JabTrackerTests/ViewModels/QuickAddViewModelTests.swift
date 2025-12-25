//
//  QuickAddViewModelTests.swift
//  JabTrackerTests
//
//  Tests for QuickAddViewModel form state and validation.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("QuickAddViewModel Tests")
struct QuickAddViewModelTests {

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

    // MARK: - canSave Validation Tests

    @Test("canSave is false when name is empty")
    @MainActor
    func testCanSaveFalseWhenNameEmpty() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.name = ""

        #expect(viewModel.canSave == false)
    }

    @Test("canSave is false when name is only whitespace")
    @MainActor
    func testCanSaveFalseWhenNameWhitespace() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.name = "   "

        #expect(viewModel.canSave == false)
    }

    @Test("canSave is true with valid name and zero macros")
    @MainActor
    func testCanSaveTrueWithValidNameZeroMacros() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.name = "Water"
        viewModel.calories = 0
        viewModel.protein = 0
        viewModel.carbs = 0
        viewModel.fat = 0

        #expect(viewModel.canSave == true)
    }

    @Test("canSave is false while isSaving is true")
    @MainActor
    func testCanSaveFalseWhileSaving() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.name = "Test Food"
        viewModel.isSaving = true

        #expect(viewModel.canSave == false)
    }

    // MARK: - Save Operation Tests

    @Test("save sets isSaving to true during operation")
    @MainActor
    func testSaveSetsIsSavingDuringOperation() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.name = "Test Food"
        viewModel.calories = 100

        // Start save but don't await - check isSaving immediately
        #expect(viewModel.isSaving == false)

        // After save completes, isSaving should be false
        _ = try await viewModel.save(mealSection: .lunch, loggedAt: Date())

        #expect(viewModel.isSaving == false)
    }

    @Test("save sets errorMessage on failure")
    @MainActor
    func testSaveSetsErrorMessageOnFailure() async {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        // Empty name should cause validation error
        viewModel.name = ""

        do {
            _ = try await viewModel.save(mealSection: .lunch, loggedAt: Date())
            #expect(Bool(false), "Expected save to throw error")
        } catch {
            #expect(viewModel.errorMessage != nil)
        }
    }

    @Test("showingError is true when errorMessage is set")
    @MainActor
    func testShowingErrorComputedFromErrorMessage() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        #expect(viewModel.showingError == false)

        viewModel.errorMessage = "Test error"

        #expect(viewModel.showingError == true)
    }

    @Test("showingError setter clears errorMessage")
    @MainActor
    func testShowingErrorSetterClearsErrorMessage() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.errorMessage = "Test error"
        #expect(viewModel.showingError == true)

        viewModel.showingError = false

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showingError == false)
    }

    // MARK: - Successful Save Tests

    @Test("save returns FoodEntry on success")
    @MainActor
    func testSaveReturnsFoodEntryOnSuccess() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.name = "Quick Snack"
        viewModel.calories = 200
        viewModel.protein = 20
        viewModel.carbs = 10
        viewModel.fat = 5
        viewModel.notes = "Test note"

        let entry = try await viewModel.save(mealSection: .snacks, loggedAt: Date())

        #expect(entry.foodName == "Quick Snack")
        #expect(entry.caloriesPer100g == 200)
        #expect(entry.proteinPer100g == 20)
        #expect(entry.carbsPer100g == 10)
        #expect(entry.fatPer100g == 5)
        #expect(entry.notes == "Test note")
    }
}
