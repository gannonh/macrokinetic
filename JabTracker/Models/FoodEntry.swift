//
//  FoodEntry.swift
//  JabTracker
//
//  Logged meal item - denormalized snapshot at log time.
//

import Foundation
import SwiftData

/// Validation errors for FoodEntry creation
enum FoodEntryValidationError: LocalizedError {
    case emptyFoodName
    case invalidServingSize

    var errorDescription: String? {
        switch self {
        case .emptyFoodName:
            return "Food name cannot be empty"
        case .invalidServingSize:
            return "Serving size must be positive"
        }
    }
}

/// Logged meal item - denormalized snapshot at log time
/// Note: No User relationship - entries are queried by date in a single-user app context
@Model
final class FoodEntry {
    // MARK: - Identity

    var id: UUID = UUID()

    // MARK: - Food Reference (Denormalized)

    var foodId: UUID = UUID()  // Reference to original Food if exists
    var scheduleId: UUID?  // Reference to FoodSchedule if auto-populated, nil for manual entries
    var foodName: String = ""  // Snapshot at log time
    var foodBrand: String?  // Snapshot at log time

    // MARK: - Meal Context

    var mealSection: String = "breakfast"  // MealSection rawValue for CloudKit
    var loggedAt: Date = Date()

    // MARK: - Serving

    var servingGrams: Double = 100.0
    var servingDescription: String?  // e.g., "1 cup"
    var servingOptionsJSON: String = "[]"  // JSON array of available serving options

    // MARK: - Nutrition Snapshot (per 100g at log time)

    var caloriesPer100g: Double = 0.0
    var proteinPer100g: Double = 0.0
    var carbsPer100g: Double = 0.0
    var fatPer100g: Double = 0.0
    var fiberPer100g: Double = 0.0

    // MARK: - Notes

    var notes: String?

    // MARK: - Computed Properties

    var meal: MealSection {
        get { MealSection(rawValue: mealSection) ?? .breakfast }
        set { mealSection = newValue.rawValue }
    }

    /// Actual calories for this serving
    var calories: Double { (caloriesPer100g / 100.0) * servingGrams }

    /// Actual protein for this serving
    var protein: Double { (proteinPer100g / 100.0) * servingGrams }

    /// Actual carbs for this serving
    var carbs: Double { (carbsPer100g / 100.0) * servingGrams }

    /// Actual fat for this serving
    var fat: Double { (fatPer100g / 100.0) * servingGrams }

    /// Actual fiber for this serving
    var fiber: Double { (fiberPer100g / 100.0) * servingGrams }

    // MARK: - Initialization

    init(
        foodId: UUID = UUID(),
        scheduleId: UUID? = nil,
        foodName: String = "",
        foodBrand: String? = nil,
        mealSection: MealSection = .breakfast,
        loggedAt: Date = Date(),
        servingGrams: Double = 100.0,
        servingDescription: String? = nil,
        servingOptionsJSON: String = "[]",
        caloriesPer100g: Double = 0.0,
        proteinPer100g: Double = 0.0,
        carbsPer100g: Double = 0.0,
        fatPer100g: Double = 0.0,
        fiberPer100g: Double = 0.0,
        notes: String? = nil
    ) {
        self.foodId = foodId
        self.scheduleId = scheduleId
        self.foodName = foodName
        self.foodBrand = foodBrand
        self.mealSection = mealSection.rawValue
        self.loggedAt = loggedAt
        self.servingGrams = servingGrams
        self.servingDescription = servingDescription
        self.servingOptionsJSON = servingOptionsJSON
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.notes = notes
    }

    /// Create from Food with serving size
    convenience init(from food: Food, servingGrams: Double, mealSection: MealSection) {
        self.init(
            foodId: food.id,
            foodName: food.name,
            foodBrand: food.brand,
            mealSection: mealSection,
            loggedAt: Date(),
            servingGrams: servingGrams,
            servingDescription: food.servingDescription,
            servingOptionsJSON: food.servingOptionsJSON,
            caloriesPer100g: food.caloriesPer100g,
            proteinPer100g: food.proteinPer100g,
            carbsPer100g: food.carbsPer100g,
            fatPer100g: food.fatPer100g,
            fiberPer100g: food.fiberPer100g,
            notes: nil
        )
    }

    // MARK: - Validation

    /// Check if the entry has valid data
    var isValid: Bool {
        !foodName.trimmingCharacters(in: .whitespaces).isEmpty && servingGrams > 0
    }

    /// Create a validated FoodEntry from a Food
    /// - Throws: FoodEntryValidationError if validation fails
    static func create(
        from food: Food,
        servingGrams: Double,
        mealSection: MealSection,
        notes: String? = nil
    ) throws -> FoodEntry {
        // Validate food name
        guard !food.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw FoodEntryValidationError.emptyFoodName
        }

        // Validate serving size
        guard servingGrams > 0 else {
            throw FoodEntryValidationError.invalidServingSize
        }

        let entry = FoodEntry(from: food, servingGrams: servingGrams, mealSection: mealSection)
        entry.notes = notes
        return entry
    }
}
