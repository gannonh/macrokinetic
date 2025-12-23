//
//  CustomFoodService.swift
//  JabTracker
//
//  CRUD operations for user-created custom foods.
//

import Foundation
import OSLog
import SwiftData

/// Input data for creating or updating a custom food
struct CustomFoodInput {
    let name: String
    let brand: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double
    let servingSize: Double
    let servingUnit: String
    let servingDescription: String
    let barcode: String
}

/// Errors that can occur during custom food operations
enum CustomFoodError: LocalizedError, Equatable {
    case emptyName
    case negativeNutrition
    case invalidServingSize
    case duplicateBarcode(existingFood: String)
    case notCustomFood
    case foodNotFound

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Food name cannot be empty"
        case .negativeNutrition:
            return "Nutrition values cannot be negative"
        case .invalidServingSize:
            return "Serving size must be positive"
        case .duplicateBarcode(let existingFood):
            return "Barcode already assigned to '\(existingFood)'"
        case .notCustomFood:
            return "Cannot modify a food that is not user-created"
        case .foodNotFound:
            return "Food not found"
        }
    }
}

/// Service for managing user-created custom foods
/// Provides CRUD operations with validation and barcode uniqueness checking
@MainActor
final class CustomFoodService {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "CustomFoodService")

    private let context: ModelContext

    /// Initialize with model context
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create

    /// Create a new custom food
    /// - Parameter input: Custom food input data containing all required fields
    /// - Returns: The created Food with source = .userCreated
    /// - Throws: CustomFoodError if validation fails
    func createCustomFood(_ input: CustomFoodInput) async throws -> Food {
        // Validate input
        try validate(input)

        // Check barcode uniqueness (only if barcode is provided)
        if !input.barcode.isEmpty {
            try await checkBarcodeConflict(barcode: input.barcode, excluding: nil)
        }

        // Create the food
        let food = Food(
            name: input.name.trimmingCharacters(in: .whitespaces),
            brand: input.brand,
            source: .userCreated,
            barcode: input.barcode,
            caloriesPer100g: input.caloriesPer100g,
            proteinPer100g: input.proteinPer100g,
            carbsPer100g: input.carbsPer100g,
            fatPer100g: input.fatPer100g,
            fiberPer100g: input.fiberPer100g,
            servingSize: input.servingSize,
            servingUnit: input.servingUnit,
            servingDescription: input.servingDescription
        )

        context.insert(food)
        try context.save()

        Self.logger.info("Created custom food: \(input.name)")

        return food
    }

    // MARK: - Read

    /// Get all custom foods
    /// - Parameter limit: Maximum number of foods to return
    /// - Returns: Array of custom foods ordered by creation date (newest first)
    func getAllCustomFoods(limit: Int) async throws -> [Food] {
        var descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { food in
                food.source == "userCreated"
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try context.fetch(descriptor)
    }

    /// Search custom foods by name
    /// - Parameters:
    ///   - query: Search query (case insensitive)
    ///   - limit: Maximum number of results
    /// - Returns: Array of custom foods matching the query
    func search(query: String, limit: Int) async throws -> [Food] {
        let lowercaseQuery = query.lowercased()

        var descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { food in
                food.source == "userCreated"
            },
            sortBy: [SortDescriptor(\.name)]
        )
        // Fetch more to filter locally (SwiftData predicates don't support case-insensitive contains)
        descriptor.fetchLimit = 100

        let allCustomFoods = try context.fetch(descriptor)

        // Filter by query (case insensitive)
        let filtered =
            allCustomFoods
            .filter { $0.name.lowercased().contains(lowercaseQuery) }
            .prefix(limit)

        return Array(filtered)
    }

    /// Look up a custom food by barcode
    /// - Parameter barcode: Barcode to search for
    /// - Returns: Custom food with matching barcode, or nil if not found
    func lookup(barcode: String) async throws -> Food? {
        guard !barcode.isEmpty else {
            return nil
        }

        let descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { food in
                food.source == "userCreated" && food.barcode == barcode
            }
        )

        let results = try context.fetch(descriptor)
        return results.first
    }

    /// Look up a custom food by exact name
    /// - Parameter name: Name to search for (case sensitive)
    /// - Returns: Custom food with matching name, or nil if not found
    func getCustomFood(named name: String) throws -> Food? {
        let descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { food in
                food.source == "userCreated" && food.name == name
            }
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - Update

    /// Update an existing custom food
    /// - Parameters:
    ///   - food: The food to update (must be a custom food)
    ///   - input: New custom food input data
    /// - Throws: CustomFoodError if validation fails or food is not a custom food
    func updateCustomFood(_ food: Food, with input: CustomFoodInput) async throws {
        // Verify this is a custom food
        guard food.foodSource == .userCreated else {
            throw CustomFoodError.notCustomFood
        }

        // Validate input
        try validate(input)

        // Check barcode uniqueness (only if barcode changed and is not empty)
        if !input.barcode.isEmpty {
            try await checkBarcodeConflict(barcode: input.barcode, excluding: food.id)
        }

        // Update the food
        food.name = input.name.trimmingCharacters(in: .whitespaces)
        food.brand = input.brand
        food.caloriesPer100g = input.caloriesPer100g
        food.proteinPer100g = input.proteinPer100g
        food.carbsPer100g = input.carbsPer100g
        food.fatPer100g = input.fatPer100g
        food.fiberPer100g = input.fiberPer100g
        food.servingSize = input.servingSize
        food.servingUnit = input.servingUnit
        food.servingDescription = input.servingDescription
        food.barcode = input.barcode

        try context.save()

        Self.logger.info("Updated custom food: \(input.name)")
    }

    // MARK: - Delete

    /// Delete a custom food
    /// - Parameter food: The food to delete (must be a custom food)
    /// - Throws: CustomFoodError.notCustomFood if the food is not user-created
    func deleteCustomFood(_ food: Food) async throws {
        // Verify this is a custom food
        guard food.foodSource == .userCreated else {
            throw CustomFoodError.notCustomFood
        }

        let name = food.name
        context.delete(food)
        try context.save()

        Self.logger.info("Deleted custom food: \(name)")
    }

    // MARK: - Private Validation

    private func validate(_ input: CustomFoodInput) throws {
        // Validate name
        guard !input.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CustomFoodError.emptyName
        }

        // Validate nutrition values are non-negative
        guard input.caloriesPer100g >= 0,
            input.proteinPer100g >= 0,
            input.carbsPer100g >= 0,
            input.fatPer100g >= 0,
            input.fiberPer100g >= 0
        else {
            throw CustomFoodError.negativeNutrition
        }

        // Validate serving size
        guard input.servingSize > 0 else {
            throw CustomFoodError.invalidServingSize
        }
    }

    private func checkBarcodeConflict(barcode: String, excluding foodId: UUID?) async throws {
        let descriptor = FetchDescriptor<Food>(
            predicate: #Predicate { food in
                food.source == "userCreated" && food.barcode == barcode
            }
        )

        let existingFoods = try context.fetch(descriptor)

        // Check if any existing food has this barcode (excluding the food being updated)
        for existing in existingFoods {
            if let excludeId = foodId, existing.id == excludeId {
                continue
            }
            throw CustomFoodError.duplicateBarcode(existingFood: existing.name)
        }
    }
}
