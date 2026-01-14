//
//  Food.swift
//  JabTracker
//
//  Food database item - represents a food from USDA, Open Food Facts, or user-created.
//

import Foundation
import SwiftData

/// Validation errors for Food creation
enum FoodValidationError: LocalizedError {
    case emptyName
    case negativeNutrition
    case invalidServingSize

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Food name cannot be empty"
        case .negativeNutrition:
            return "Nutrition values cannot be negative"
        case .invalidServingSize:
            return "Serving size must be positive"
        }
    }
}

/// Food database item - represents a food from USDA, Open Food Facts, or user-created
@Model
final class Food {
    // MARK: - Identity

    var id: UUID = UUID()
    var fdcId: Int = 0  // USDA Food Data Central ID (0 for non-USDA)

    // MARK: - Basic Information

    var name: String = ""  // Required - food name
    var brand: String = ""  // CloudKit requires non-optional with default
    var source: String = "local"  // FoodSource rawValue for CloudKit
    var barcode: String = ""  // CloudKit requires non-optional with default

    // MARK: - Nutrition (per 100g)

    var caloriesPer100g: Double = 0.0
    var proteinPer100g: Double = 0.0
    var carbsPer100g: Double = 0.0
    var fatPer100g: Double = 0.0
    var fiberPer100g: Double = 0.0
    var sugarPer100g: Double = 0.0
    var sodiumPer100g: Double = 0.0  // mg

    // MARK: - Serving Information

    var servingSize: Double = 100.0
    var servingUnit: String = "g"
    var servingDescription: String = ""  // CloudKit requires non-optional with default
    var servingOptionsJSON: String = "[]"  // JSON array of serving options

    // MARK: - Timestamps

    var createdAt: Date = Date()
    var lastAccessedAt: Date = Date()

    // MARK: - Computed Properties

    var foodSource: FoodSource {
        get { FoodSource(rawValue: source) ?? .local }
        set { source = newValue.rawValue }
    }

    // MARK: - Initialization

    init(
        name: String = "",
        brand: String = "",
        fdcId: Int = 0,
        source: FoodSource = .local,
        barcode: String = "",
        caloriesPer100g: Double = 0.0,
        proteinPer100g: Double = 0.0,
        carbsPer100g: Double = 0.0,
        fatPer100g: Double = 0.0,
        fiberPer100g: Double = 0.0,
        sugarPer100g: Double = 0.0,
        sodiumPer100g: Double = 0.0,
        servingSize: Double = 100.0,
        servingUnit: String = "g",
        servingDescription: String = "",
        servingOptionsJSON: String = "[]"
    ) {
        self.name = name
        self.brand = brand
        self.fdcId = fdcId
        self.source = source.rawValue
        self.barcode = barcode
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.sugarPer100g = sugarPer100g
        self.sodiumPer100g = sodiumPer100g
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.servingDescription = servingDescription
        self.servingOptionsJSON = servingOptionsJSON
        self.createdAt = Date()
        self.lastAccessedAt = Date()
    }

    // MARK: - Validation

    /// Check if the food has valid data for display/use
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && servingSize > 0
    }

    /// Create a validated Food instance
    /// - Throws: FoodValidationError if validation fails
    static func create(
        name: String,
        brand: String = "",
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        fiberPer100g: Double = 0,
        servingSize: Double = 100.0
    ) throws -> Food {
        // Validate name
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw FoodValidationError.emptyName
        }

        // Validate nutrition values are non-negative
        guard caloriesPer100g >= 0,
            proteinPer100g >= 0,
            carbsPer100g >= 0,
            fatPer100g >= 0,
            fiberPer100g >= 0
        else {
            throw FoodValidationError.negativeNutrition
        }

        // Validate serving size
        guard servingSize > 0 else {
            throw FoodValidationError.invalidServingSize
        }

        return Food(
            name: name,
            brand: brand,
            caloriesPer100g: caloriesPer100g,
            proteinPer100g: proteinPer100g,
            carbsPer100g: carbsPer100g,
            fatPer100g: fatPer100g,
            fiberPer100g: fiberPer100g,
            servingSize: servingSize
        )
    }

    // MARK: - Custom Food Support

    /// Creates a custom food with source set to .userCreated
    static func createCustom(
        name: String,
        brand: String = "",
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        fiberPer100g: Double = 0,
        servingSize: Double = 100.0,
        servingUnit: String = "g",
        servingDescription: String = "",
        servingOptionsJSON: String = "[]",
        barcode: String = ""
    ) throws -> Food {
        let food = try create(
            name: name,
            brand: brand,
            caloriesPer100g: caloriesPer100g,
            proteinPer100g: proteinPer100g,
            carbsPer100g: carbsPer100g,
            fatPer100g: fatPer100g,
            fiberPer100g: fiberPer100g,
            servingSize: servingSize
        )
        food.foodSource = .userCreated
        food.servingUnit = servingUnit
        food.servingDescription = servingDescription
        food.servingOptionsJSON = servingOptionsJSON
        food.barcode = barcode
        return food
    }

    /// Whether this food is a user-created custom food
    var isCustomFood: Bool {
        foodSource == .userCreated
    }
}
