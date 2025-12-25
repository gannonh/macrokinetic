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

    // MARK: - Form State

    var name: String = ""
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var notes: String = ""

    // MARK: - UI State

    var isSaving: Bool = false
    var errorMessage: String?

    /// Computed binding for showing error alert (derived from errorMessage)
    var showingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    // MARK: - Computed Properties

    /// Whether the form is valid and can be saved
    var canSave: Bool {
        // Cannot save while already saving
        guard !isSaving else { return false }

        // Name must not be empty or whitespace-only
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }

        return true
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
        Self.logger.debug("Saving quick add entry: \(self.name)")

        isSaving = true
        errorMessage = nil

        do {
            let entry = try await mealLogService.logQuickAdd(
                name: name,
                caloriesPer100g: calories,
                proteinPer100g: protein,
                carbsPer100g: carbs,
                fatPer100g: fat,
                servingGrams: 100.0,
                mealSection: mealSection,
                notes: notes,
                loggedAt: loggedAt
            )

            Self.logger.info("Created quick add entry: \(self.name)")
            isSaving = false
            return entry
        } catch {
            Self.logger.error("Failed to save quick add entry: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            isSaving = false
            throw error
        }
    }
}
