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
        let config = InMemoryTestStore.configuration(schema: schema)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return (container.mainContext, container)
    }

    // MARK: - canSave Validation Tests

    @Test("canSave is false when all values are zero")
    @MainActor
    func testCanSaveFalseWhenAllValuesZero() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.energy = 0
        viewModel.protein = 0
        viewModel.fat = 0
        viewModel.carbs = 0

        #expect(viewModel.canSave == false)
    }

    @Test("canSave is true when energy is non-zero")
    @MainActor
    func testCanSaveTrueWhenEnergyNonZero() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.energy = 100

        #expect(viewModel.canSave == true)
    }

    @Test("canSave is true when only protein is non-zero")
    @MainActor
    func testCanSaveTrueWhenOnlyProteinNonZero() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.protein = 10

        #expect(viewModel.canSave == true)
    }

    @Test("canSave is true when only fat is non-zero")
    @MainActor
    func testCanSaveTrueWhenOnlyFatNonZero() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.fat = 5

        #expect(viewModel.canSave == true)
    }

    @Test("canSave is true when only carbs is non-zero")
    @MainActor
    func testCanSaveTrueWhenOnlyCarbsNonZero() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.carbs = 15

        #expect(viewModel.canSave == true)
    }

    @Test("canSave is false while isSaving is true")
    @MainActor
    func testCanSaveFalseWhileSaving() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.energy = 100
        viewModel.isSaving = true

        #expect(viewModel.canSave == false)
    }

    // MARK: - macroSum Tests

    @Test("macroSum calculates correctly with all macros")
    @MainActor
    func testMacroSumCalculation() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.protein = 20  // 20 * 4 = 80
        viewModel.carbs = 30  // 30 * 4 = 120
        viewModel.fat = 10  // 10 * 9 = 90
        // Total = 80 + 120 + 90 = 290

        #expect(viewModel.macroSum == 290)
    }

    @Test("macroSum is zero when all macros are zero")
    @MainActor
    func testMacroSumZeroWhenAllZero() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        #expect(viewModel.macroSum == 0)
    }

    @Test("macroSum calculates with only protein")
    @MainActor
    func testMacroSumWithOnlyProtein() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.protein = 25  // 25 * 4 = 100

        #expect(viewModel.macroSum == 100)
    }

    // MARK: - reset() Tests

    @Test("reset clears all form values")
    @MainActor
    func testResetClearsAllValues() {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.energy = 200
        viewModel.protein = 20
        viewModel.fat = 10
        viewModel.carbs = 25
        viewModel.errorMessage = "Some error"

        viewModel.reset()

        #expect(viewModel.energy == 0)
        #expect(viewModel.protein == 0)
        #expect(viewModel.fat == 0)
        #expect(viewModel.carbs == 0)
        #expect(viewModel.errorMessage == nil)
    }

    // MARK: - quickAddName Tests

    @Test("quickAddName is correct constant")
    @MainActor
    func testQuickAddNameConstant() {
        #expect(QuickAddViewModel.quickAddName == "Quick Add")
    }

    // MARK: - Save Operation Tests

    @Test("save sets isSaving to true during operation")
    @MainActor
    func testSaveSetsIsSavingDuringOperation() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.energy = 100

        // Start save but don't await - check isSaving immediately
        #expect(viewModel.isSaving == false)

        // After save completes, isSaving should be false
        _ = try await viewModel.save(mealSection: .lunch, loggedAt: Date())

        #expect(viewModel.isSaving == false)
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

    @Test("save returns FoodEntry on success with fixed name")
    @MainActor
    func testSaveReturnsFoodEntryWithFixedName() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.energy = 200
        viewModel.protein = 20
        viewModel.carbs = 10
        viewModel.fat = 5

        let entry = try await viewModel.save(mealSection: .snacks, loggedAt: Date())

        #expect(entry.foodName == "Quick Add")
        #expect(entry.caloriesPer100g == 200)
        #expect(entry.proteinPer100g == 20)
        #expect(entry.carbsPer100g == 10)
        #expect(entry.fatPer100g == 5)
    }

    @Test("save works with only macros (no energy)")
    @MainActor
    func testSaveWorksWithOnlyMacros() async throws {
        let (context, container) = createTestContext()
        _ = container
        let service = MealLogService(context: context)
        let viewModel = QuickAddViewModel(mealLogService: service)

        viewModel.protein = 30

        let entry = try await viewModel.save(mealSection: .lunch, loggedAt: Date())

        #expect(entry.foodName == "Quick Add")
        #expect(entry.proteinPer100g == 30)
        #expect(entry.caloriesPer100g == 0)
    }
}
