//
//  QuickAddViewModel.swift
//  JabTracker
//
//  ViewModel for quick add food entry form.
//

import Foundation
import OSLog

/// ViewModel managing state for QuickAddSheet
@Observable
@MainActor
final class QuickAddViewModel {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "QuickAddViewModel")

    // MARK: - Dependencies

    private let mealLogService: MealLogService

    // MARK: - Constants

    /// Fixed name for quick add entries
    static let quickAddName = "Quick Add"

    // MARK: - Form State

    var energy: Double = 0
    var protein: Double = 0
    var fat: Double = 0
    var carbs: Double = 0

    // MARK: - UI State

    var isSaving: Bool = false
    var errorMessage: String?

    /// Computed binding for showing error alert (derived from errorMessage)
    var showingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    // MARK: - Computed Properties

    /// Macro sum calculation (protein*4 + carbs*4 + fat*9)
    var macroSum: Double {
        (protein * 4) + (carbs * 4) + (fat * 9)
    }

    /// Whether the form is valid and can be saved
    var canSave: Bool {
        // Cannot save while already saving
        guard !isSaving else { return false }

        // At least one value must be entered
        return energy > 0 || protein > 0 || fat > 0 || carbs > 0
    }

    // MARK: - Initialization

    init(mealLogService: MealLogService) {
        self.mealLogService = mealLogService
    }

    // MARK: - Save

    /// Save the quick add entry
    /// - Parameters:
    ///   - mealSection: Meal section to log to
    ///   - loggedAt: Time to log at
    /// - Returns: The created FoodEntry
    /// - Throws: FoodEntryValidationError if validation fails
    func save(mealSection: MealSection, loggedAt: Date) async throws -> FoodEntry {
        Self.logger.debug("Saving quick add entry")

        isSaving = true
        errorMessage = nil

        do {
            let entry = try await mealLogService.logQuickAdd(
                name: Self.quickAddName,
                caloriesPer100g: energy,
                proteinPer100g: protein,
                carbsPer100g: carbs,
                fatPer100g: fat,
                servingGrams: 100.0,
                mealSection: mealSection,
                notes: "",
                loggedAt: loggedAt
            )

            Self.logger.info("Created quick add entry")
            isSaving = false
            return entry
        } catch {
            Self.logger.error("Failed to save quick add entry: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isSaving = false
            throw error
        }
    }

    /// Reset form to initial state
    func reset() {
        energy = 0
        protein = 0
        fat = 0
        carbs = 0
        errorMessage = nil
    }
}
