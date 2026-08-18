//
//  CreateFoodViewModelTests.swift
//  JabTrackerTests
//
//  Tests for CreateFoodViewModel validation and behavior.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite
@MainActor
struct CreateFoodViewModelTests {
    // MARK: - Test Helpers

    private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
        let schema = Schema([Food.self, FoodEntry.self, User.self])
        let config = InMemoryTestStore.configuration(schema: schema)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return (container.mainContext, container)
    }

    private func createService(context: ModelContext) -> CustomFoodService {
        CustomFoodService(context: context)
    }

    private func createViewModel(context: ModelContext, mode: CreateFoodViewModel.Mode = .create) -> CreateFoodViewModel
    {
        let service = createService(context: context)
        return CreateFoodViewModel(customFoodService: service, mode: mode)
    }

    private func createViewModelWithFood(
        context: ModelContext,
        editingFood: Food
    ) -> CreateFoodViewModel {
        let service = createService(context: context)
        return CreateFoodViewModel(customFoodService: service, mode: .edit, editingFood: editingFood)
    }

    /// Populate ViewModel with valid default values for testing
    private func populateValidDefaults(_ viewModel: CreateFoodViewModel) {
        viewModel.name = "Test Food"
        viewModel.caloriesPer100g = 100
        viewModel.proteinPer100g = 10
        viewModel.carbsPer100g = 20
        viewModel.fatPer100g = 5
        viewModel.servingSize = 100
    }

    // MARK: - canSave Validation Tests

    @Test("canSave returns false when name is empty")
    func testCanSaveReturnsFalseWhenNameIsEmpty() {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive

        let viewModel = createViewModel(context: context)

        // Empty name
        viewModel.name = ""
        viewModel.caloriesPer100g = 100
        viewModel.proteinPer100g = 10
        viewModel.carbsPer100g = 20
        viewModel.fatPer100g = 5
        viewModel.servingSize = 100

        #expect(viewModel.canSave == false)
    }

    @Test("canSave returns false when name is only whitespace")
    func testCanSaveReturnsFalseWhenNameIsWhitespace() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "   "
        viewModel.caloriesPer100g = 100
        viewModel.proteinPer100g = 10
        viewModel.carbsPer100g = 20
        viewModel.fatPer100g = 5
        viewModel.servingSize = 100

        #expect(viewModel.canSave == false)
    }

    @Test("canSave returns false when calories is negative")
    func testCanSaveReturnsFalseWhenCaloriesNegative() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "Test Food"
        viewModel.caloriesPer100g = -10
        viewModel.proteinPer100g = 10
        viewModel.carbsPer100g = 20
        viewModel.fatPer100g = 5
        viewModel.servingSize = 100

        #expect(viewModel.canSave == false)
    }

    @Test("canSave returns false when protein is negative")
    func testCanSaveReturnsFalseWhenProteinNegative() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "Test Food"
        viewModel.caloriesPer100g = 100
        viewModel.proteinPer100g = -5
        viewModel.carbsPer100g = 20
        viewModel.fatPer100g = 5
        viewModel.servingSize = 100

        #expect(viewModel.canSave == false)
    }

    @Test("canSave returns false when carbs is negative")
    func testCanSaveReturnsFalseWhenCarbsNegative() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "Test Food"
        viewModel.caloriesPer100g = 100
        viewModel.proteinPer100g = 10
        viewModel.carbsPer100g = -20
        viewModel.fatPer100g = 5
        viewModel.servingSize = 100

        #expect(viewModel.canSave == false)
    }

    @Test("canSave returns false when fat is negative")
    func testCanSaveReturnsFalseWhenFatNegative() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "Test Food"
        viewModel.caloriesPer100g = 100
        viewModel.proteinPer100g = 10
        viewModel.carbsPer100g = 20
        viewModel.fatPer100g = -5
        viewModel.servingSize = 100

        #expect(viewModel.canSave == false)
    }

    @Test("canSave returns false when fiber is negative")
    func testCanSaveReturnsFalseWhenFiberNegative() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "Test Food"
        viewModel.caloriesPer100g = 100
        viewModel.proteinPer100g = 10
        viewModel.carbsPer100g = 20
        viewModel.fatPer100g = 5
        viewModel.fiberPer100g = -2
        viewModel.servingSize = 100

        #expect(viewModel.canSave == false)
    }

    @Test("canSave returns false when servingSize is zero")
    func testCanSaveReturnsFalseWhenServingSizeZero() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "Test Food"
        viewModel.caloriesPer100g = 100
        viewModel.proteinPer100g = 10
        viewModel.carbsPer100g = 20
        viewModel.fatPer100g = 5
        viewModel.servingSize = 0

        #expect(viewModel.canSave == false)
    }

    @Test("canSave returns false when servingSize is negative")
    func testCanSaveReturnsFalseWhenServingSizeNegative() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "Test Food"
        viewModel.caloriesPer100g = 100
        viewModel.proteinPer100g = 10
        viewModel.carbsPer100g = 20
        viewModel.fatPer100g = 5
        viewModel.servingSize = -100

        #expect(viewModel.canSave == false)
    }

    @Test("canSave returns true with valid input")
    func testCanSaveReturnsTrueWithValidInput() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "Test Food"
        viewModel.caloriesPer100g = 100
        viewModel.proteinPer100g = 10
        viewModel.carbsPer100g = 20
        viewModel.fatPer100g = 5
        viewModel.fiberPer100g = 2
        viewModel.servingSize = 100

        #expect(viewModel.canSave == true)
    }

    @Test("canSave returns true with zero macros")
    func testCanSaveReturnsTrueWithZeroMacros() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "Water"
        viewModel.caloriesPer100g = 0
        viewModel.proteinPer100g = 0
        viewModel.carbsPer100g = 0
        viewModel.fatPer100g = 0
        viewModel.servingSize = 100

        #expect(viewModel.canSave == true)
    }

    // MARK: - prefill Tests

    @Test("prefill populates all fields from FoodSearchResult")
    func testPrefillPopulatesAllFields() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        let searchResult = FoodSearchResult(
            id: UUID(),
            fdcId: 12345,
            barcode: "1234567890123",
            name: "Chicken Breast",
            brand: "Organic Farm",
            source: .local,
            caloriesPer100g: 165,
            proteinPer100g: 31,
            carbsPer100g: 0,
            fatPer100g: 3.6,
            fiberPer100g: 0,
            category: "Poultry",
            servingSize: 140,
            servingOptions: []
        )

        viewModel.prefill(from: searchResult)

        #expect(viewModel.name == "Chicken Breast")
        #expect(viewModel.brand == "Organic Farm")
        #expect(viewModel.caloriesPer100g == 165)
        #expect(viewModel.proteinPer100g == 31)
        #expect(viewModel.carbsPer100g == 0)
        #expect(viewModel.fatPer100g == 3.6)
        #expect(viewModel.fiberPer100g == 0)
        #expect(viewModel.servingSize == 140)
        #expect(viewModel.barcode == "1234567890123")
    }

    @Test("prefill handles nil brand and barcode")
    func testPrefillHandlesNilOptionalFields() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        let searchResult = FoodSearchResult(
            id: UUID(),
            fdcId: nil,
            barcode: nil,
            name: "Apple",
            brand: nil,
            source: .local,
            caloriesPer100g: 52,
            proteinPer100g: 0.3,
            carbsPer100g: 14,
            fatPer100g: 0.2,
            fiberPer100g: 2.4,
            category: nil,
            servingSize: 182,
            servingOptions: []
        )

        viewModel.prefill(from: searchResult)

        #expect(viewModel.name == "Apple")
        #expect(viewModel.brand == "")
        #expect(viewModel.barcode == "")
        #expect(viewModel.servingSize == 182)
    }

    // MARK: - buildInput Tests

    @Test("buildInput creates correct CustomFoodInput")
    func testBuildInputCreatesCorrectInput() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "My Custom Food"
        viewModel.brand = "Homemade"
        viewModel.caloriesPer100g = 250
        viewModel.proteinPer100g = 20
        viewModel.carbsPer100g = 30
        viewModel.fatPer100g = 10
        viewModel.fiberPer100g = 5
        viewModel.servingSize = 150
        viewModel.servingUnit = "g"
        viewModel.servingDescription = "1 serving"
        viewModel.barcode = "9876543210123"

        let input = viewModel.buildInput()

        #expect(input.name == "My Custom Food")
        #expect(input.brand == "Homemade")
        #expect(input.caloriesPer100g == 250)
        #expect(input.proteinPer100g == 20)
        #expect(input.carbsPer100g == 30)
        #expect(input.fatPer100g == 10)
        #expect(input.fiberPer100g == 5)
        #expect(input.servingSize == 150)
        #expect(input.servingUnit == "g")
        #expect(input.servingDescription == "1 serving")
        #expect(input.barcode == "9876543210123")
    }

    // MARK: - save Tests

    @Test("save calls customFoodService.createCustomFood")
    func testSaveCallsCreateCustomFood() async throws {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "Test Food"
        viewModel.caloriesPer100g = 100
        viewModel.proteinPer100g = 10
        viewModel.carbsPer100g = 20
        viewModel.fatPer100g = 5
        viewModel.servingSize = 100

        // Should not throw
        let food = try await viewModel.save()

        // Verify the food was created
        #expect(food.name == "Test Food")
        #expect(food.caloriesPer100g == 100)
        #expect(food.proteinPer100g == 10)
        #expect(food.foodSource == .userCreated)
    }

    @Test("save sets errorMessage on failure")
    func testSaveSetsErrorMessageOnFailure() async {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        // Invalid input - empty name will cause service to throw
        viewModel.name = ""
        viewModel.servingSize = 100

        do {
            _ = try await viewModel.save()
            Issue.record("Expected save to throw an error")
        } catch {
            // Error should be set
            #expect(viewModel.errorMessage != nil)
            #expect(viewModel.showingError == true)
        }
    }

    @Test("save sets isSaving during operation")
    func testSaveSetsIsSavingDuringOperation() async throws {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.name = "Test Food"
        viewModel.caloriesPer100g = 100
        viewModel.servingSize = 100

        // isSaving should be false before
        #expect(viewModel.isSaving == false)

        _ = try await viewModel.save()

        // isSaving should be false after
        #expect(viewModel.isSaving == false)
    }

    // MARK: - Navigation Title Tests

    @Test("navigationTitle returns correct value for create mode")
    func testNavigationTitleForCreateMode() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context, mode: .create)

        #expect(viewModel.navigationTitle == "Create Custom Food")
    }

    @Test("navigationTitle returns correct value for edit mode")
    func testNavigationTitleForEditMode() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context, mode: .edit)

        #expect(viewModel.navigationTitle == "Edit Custom Food")
    }

    // MARK: - canSave while saving Tests

    @Test("canSave returns false while isSaving is true")
    func testCanSaveReturnsFalseWhileSaving() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)
        populateValidDefaults(viewModel)

        // Manually set isSaving to true (simulating in-progress save)
        viewModel.isSaving = true

        #expect(viewModel.canSave == false)
    }

    // MARK: - Edit Mode Tests

    @Test("edit mode prefills from editingFood on init")
    func testEditModePrefillsFromEditingFood() {
        let (context, container) = createTestContext()
        _ = container

        // Create an existing food
        let existingFood = Food(
            name: "Existing Food",
            brand: "Test Brand",
            source: .userCreated,
            barcode: "1111111111",
            caloriesPer100g: 200,
            proteinPer100g: 25,
            carbsPer100g: 15,
            fatPer100g: 8,
            fiberPer100g: 3,
            servingSize: 150,
            servingUnit: "oz",
            servingDescription: "1 serving"
        )
        context.insert(existingFood)

        let viewModel = createViewModelWithFood(context: context, editingFood: existingFood)

        #expect(viewModel.name == "Existing Food")
        #expect(viewModel.brand == "Test Brand")
        #expect(viewModel.caloriesPer100g == 200)
        #expect(viewModel.proteinPer100g == 25)
        #expect(viewModel.carbsPer100g == 15)
        #expect(viewModel.fatPer100g == 8)
        #expect(viewModel.fiberPer100g == 3)
        #expect(viewModel.servingSize == 150)
        #expect(viewModel.servingUnit == "oz")
        #expect(viewModel.servingDescription == "1 serving")
        #expect(viewModel.barcode == "1111111111")
        #expect(viewModel.mode == .edit)
    }

    @Test("save in edit mode calls updateCustomFood")
    func testSaveInEditModeCallsUpdate() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Create an existing food
        let existingFood = Food(
            name: "Original Name",
            brand: "",
            source: .userCreated,
            barcode: "",
            caloriesPer100g: 100,
            proteinPer100g: 10,
            carbsPer100g: 20,
            fatPer100g: 5,
            fiberPer100g: 2,
            servingSize: 100,
            servingUnit: "g",
            servingDescription: ""
        )
        context.insert(existingFood)
        try context.save()

        let viewModel = createViewModelWithFood(context: context, editingFood: existingFood)

        // Modify the food
        viewModel.name = "Updated Name"
        viewModel.caloriesPer100g = 150

        // Save should update the existing food
        let food = try await viewModel.save()

        // Should return the same food object (updated in place)
        #expect(food.id == existingFood.id)
        #expect(food.name == "Updated Name")
        #expect(food.caloriesPer100g == 150)
    }

    @Test("save in edit mode returns the editingFood")
    func testSaveInEditModeReturnsEditingFood() async throws {
        let (context, container) = createTestContext()
        _ = container

        // Create an existing food
        let existingFood = Food(
            name: "Test Food",
            brand: "",
            source: .userCreated,
            barcode: "",
            caloriesPer100g: 100,
            proteinPer100g: 10,
            carbsPer100g: 20,
            fatPer100g: 5,
            fiberPer100g: 0,
            servingSize: 100,
            servingUnit: "g",
            servingDescription: ""
        )
        context.insert(existingFood)
        try context.save()

        let viewModel = createViewModelWithFood(context: context, editingFood: existingFood)

        let returnedFood = try await viewModel.save()

        // The returned food should be the same instance as editingFood
        #expect(returnedFood === existingFood)
    }

    // MARK: - showingError Computed Property Tests

    @Test("showingError returns true when errorMessage is set")
    func testShowingErrorReturnsTrue() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.errorMessage = "Some error"

        #expect(viewModel.showingError == true)
    }

    @Test("showingError returns false when errorMessage is nil")
    func testShowingErrorReturnsFalseWhenNil() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.errorMessage = nil

        #expect(viewModel.showingError == false)
    }

    @Test("setting showingError to false clears errorMessage")
    func testSettingShowingErrorFalseClearsMessage() {
        let (context, container) = createTestContext()
        _ = container

        let viewModel = createViewModel(context: context)

        viewModel.errorMessage = "Some error"
        #expect(viewModel.showingError == true)

        viewModel.showingError = false

        #expect(viewModel.errorMessage == nil)
    }
}
