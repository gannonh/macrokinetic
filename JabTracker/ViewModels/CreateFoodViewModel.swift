//
//  CreateFoodViewModel.swift
//  JabTracker
//
//  ViewModel for creating and editing custom foods.
//

import Foundation
import OSLog

/// ViewModel managing state for the CreateFoodSheet
@Observable
@MainActor
final class CreateFoodViewModel {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "CreateFoodViewModel")

    // MARK: - Mode

    enum Mode {
        case create
        case edit
    }

    // MARK: - Dependencies

    private let customFoodService: CustomFoodService

    // MARK: - Form State

    var name: String = ""
    var brand: String = ""
    var caloriesPer100g: Double = 0
    var proteinPer100g: Double = 0
    var carbsPer100g: Double = 0
    var fatPer100g: Double = 0
    var fiberPer100g: Double = 0
    var servingSize: Double = 100
    var servingUnit: String = "g"
    var servingDescription: String = ""
    var barcode: String = ""

    // MARK: - UI State

    var isSaving: Bool = false
    var errorMessage: String?
    var showingError: Bool = false

    // MARK: - Mode and Editing

    let mode: Mode
    let editingFood: Food?

    // MARK: - Computed Properties

    /// Whether the form is valid and can be saved
    var canSave: Bool {
        // Cannot save while already saving
        guard !isSaving else { return false }

        // Name must not be empty
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }

        // All nutrition values must be non-negative
        guard caloriesPer100g >= 0,
            proteinPer100g >= 0,
            carbsPer100g >= 0,
            fatPer100g >= 0,
            fiberPer100g >= 0
        else { return false }

        // Serving size must be positive
        guard servingSize > 0 else { return false }

        return true
    }

    /// Title for the navigation bar
    var navigationTitle: String {
        mode == .create ? "Create Custom Food" : "Edit Custom Food"
    }

    // MARK: - Initialization

    init(
        customFoodService: CustomFoodService,
        mode: Mode = .create,
        editingFood: Food? = nil
    ) {
        self.customFoodService = customFoodService
        self.mode = mode
        self.editingFood = editingFood

        // If editing, prefill from the food
        if let food = editingFood {
            prefill(from: food)
        }
    }

    // MARK: - Prefill

    /// Prefill form fields from a FoodSearchResult
    /// - Parameter food: The food search result to prefill from
    func prefill(from food: FoodSearchResult) {
        name = food.name
        brand = food.brand ?? ""
        caloriesPer100g = food.caloriesPer100g
        proteinPer100g = food.proteinPer100g
        carbsPer100g = food.carbsPer100g
        fatPer100g = food.fatPer100g
        fiberPer100g = food.fiberPer100g
        servingSize = food.servingSize
        barcode = food.barcode ?? ""

        Self.logger.debug("Prefilled form from FoodSearchResult: \(food.name)")
    }

    /// Prefill form fields from a Food model
    /// - Parameter food: The food to prefill from
    func prefill(from food: Food) {
        name = food.name
        brand = food.brand
        caloriesPer100g = food.caloriesPer100g
        proteinPer100g = food.proteinPer100g
        carbsPer100g = food.carbsPer100g
        fatPer100g = food.fatPer100g
        fiberPer100g = food.fiberPer100g
        servingSize = food.servingSize
        servingUnit = food.servingUnit
        servingDescription = food.servingDescription
        barcode = food.barcode

        Self.logger.debug("Prefilled form from Food: \(food.name)")
    }

    // MARK: - Build Input

    /// Build a CustomFoodInput from the current form state
    /// - Returns: CustomFoodInput ready for saving
    func buildInput() -> CustomFoodInput {
        CustomFoodInput(
            name: name,
            brand: brand,
            caloriesPer100g: caloriesPer100g,
            proteinPer100g: proteinPer100g,
            carbsPer100g: carbsPer100g,
            fatPer100g: fatPer100g,
            fiberPer100g: fiberPer100g,
            servingSize: servingSize,
            servingUnit: servingUnit,
            servingDescription: servingDescription,
            barcode: barcode
        )
    }

    // MARK: - Save

    /// Save the custom food
    /// - Returns: The created or updated Food
    /// - Throws: CustomFoodError if validation or save fails
    func save() async throws -> Food {
        Self.logger.debug("Saving custom food: \(self.name)")

        isSaving = true
        errorMessage = nil
        showingError = false

        do {
            let input = buildInput()
            let food: Food

            if mode == .edit, let existingFood = editingFood {
                // Update existing food
                try await customFoodService.updateCustomFood(existingFood, with: input)
                food = existingFood
                Self.logger.info("Updated custom food: \(self.name)")
            } else {
                // Create new food
                food = try await customFoodService.createCustomFood(input)
                Self.logger.info("Created custom food: \(self.name)")
            }

            isSaving = false
            return food
        } catch {
            Self.logger.error("Failed to save custom food: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showingError = true
            isSaving = false
            throw error
        }
    }
}
