//
//  MealLogService.swift
//  JabTracker
//
//  CRUD operations and queries for FoodEntry meal logging.
//

import Foundation
import OSLog
import SwiftData

/// Daily nutrition totals
struct DailyNutritionTotals {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double

    static let zero = DailyNutritionTotals(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0)
}

/// Service for managing meal log entries
/// Provides CRUD operations, date-based queries, and daily totals
@MainActor
@Observable
final class MealLogService {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "MealLogService")

    private let context: ModelContext

    /// Tracks data mutations for reactive UI updates
    /// Views can observe this property to refresh when food entries change
    private(set) var dataVersion = UUID()

    /// Initialize with model context
    init(context: ModelContext) {
        self.context = context
    }

    /// Notify observers that data has changed
    private func notifyDataChanged() {
        dataVersion = UUID()
    }

    // MARK: - Create

    /// Log a food entry
    /// - Parameters:
    ///   - food: Food item to log
    ///   - servingGrams: Serving size in grams
    ///   - mealSection: Meal section (breakfast, lunch, dinner, snacks)
    ///   - notes: Optional notes
    ///   - loggedAt: When the entry was logged (defaults to now)
    /// - Returns: The created FoodEntry
    func logFood(
        food: Food,
        servingGrams: Double,
        mealSection: MealSection,
        notes: String = "",
        loggedAt: Date = Date()
    ) async throws -> FoodEntry {
        let entry = FoodEntry(from: food, servingGrams: servingGrams, mealSection: mealSection)
        entry.notes = notes
        entry.loggedAt = loggedAt

        context.insert(entry)
        try context.save()
        notifyDataChanged()

        Self.logger.info("Logged food entry: \(food.name) (\(servingGrams)g) for \(mealSection.displayName)")

        return entry
    }

    // MARK: - Read

    /// Get all entries for a specific date
    /// - Parameter date: The date to query
    /// - Returns: Array of FoodEntry for that date
    func getEntries(for date: Date) async throws -> [FoodEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { entry in
                entry.loggedAt >= startOfDay && entry.loggedAt < endOfDay
            },
            sortBy: [SortDescriptor(\.loggedAt, order: .forward)]
        )

        return try context.fetch(descriptor)
    }

    /// Get entries grouped by meal section for a specific date
    /// - Parameter date: The date to query
    /// - Returns: Dictionary of MealSection to array of FoodEntry
    func getEntriesGroupedByMeal(for date: Date) async throws -> [MealSection: [FoodEntry]] {
        let entries = try await getEntries(for: date)

        var grouped: [MealSection: [FoodEntry]] = [:]

        for entry in entries {
            let section = entry.meal
            if grouped[section] == nil {
                grouped[section] = []
            }
            grouped[section]?.append(entry)
        }

        return grouped
    }

    /// Get daily nutrition totals
    /// - Parameter date: The date to calculate totals for
    /// - Returns: Daily totals for calories, protein, carbs, fat, fiber
    func getDailyTotals(for date: Date) async throws -> DailyNutritionTotals {
        let entries = try await getEntries(for: date)

        guard !entries.isEmpty else {
            return .zero
        }

        let calories = entries.reduce(0.0) { $0 + $1.calories }
        let protein = entries.reduce(0.0) { $0 + $1.protein }
        let carbs = entries.reduce(0.0) { $0 + $1.carbs }
        let fat = entries.reduce(0.0) { $0 + $1.fat }
        let fiber = entries.reduce(0.0) { $0 + $1.fiber }

        return DailyNutritionTotals(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber
        )
    }

    /// Get recent entries ordered by most recent first
    /// - Parameter limit: Maximum entries to return
    /// - Returns: Array of recent FoodEntry
    func getRecentEntries(limit: Int = 10) async throws -> [FoodEntry] {
        var descriptor = FetchDescriptor<FoodEntry>(
            sortBy: [SortDescriptor(\.loggedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try context.fetch(descriptor)
    }

    // MARK: - Update

    /// Update a food entry
    /// - Parameters:
    ///   - entry: Entry to update
    ///   - servingGrams: New serving size (optional)
    ///   - mealSection: New meal section (optional)
    ///   - loggedAt: New logged date/time (optional)
    ///   - notes: New notes (optional)
    func updateEntry(
        _ entry: FoodEntry,
        servingGrams: Double? = nil,
        mealSection: MealSection? = nil,
        loggedAt: Date? = nil,
        notes: String? = nil
    ) async throws {
        if let servingGrams = servingGrams {
            entry.servingGrams = servingGrams
        }

        if let mealSection = mealSection {
            entry.meal = mealSection
        }

        if let loggedAt = loggedAt {
            entry.loggedAt = loggedAt
        }

        if let notes = notes {
            entry.notes = notes
        }

        try context.save()
        notifyDataChanged()

        Self.logger.info("Updated food entry: \(entry.foodName)")
    }

    // MARK: - Delete

    /// Delete a food entry
    /// - Parameter entry: Entry to delete
    func deleteEntry(_ entry: FoodEntry) async throws {
        let name = entry.foodName
        context.delete(entry)
        try context.save()
        notifyDataChanged()

        Self.logger.info("Deleted food entry: \(name)")
    }

    // MARK: - Quick Add

    /// Log a quick add entry with manual macro values
    /// - Parameters:
    ///   - name: Name for the food entry
    ///   - caloriesPer100g: Calories per 100g
    ///   - proteinPer100g: Protein per 100g
    ///   - carbsPer100g: Carbs per 100g
    ///   - fatPer100g: Fat per 100g
    ///   - servingGrams: Serving size in grams (default 100)
    ///   - mealSection: Meal section (breakfast, lunch, dinner, snacks)
    ///   - notes: Optional notes
    ///   - loggedAt: When the entry was logged (defaults to now)
    /// - Returns: The created FoodEntry
    /// - Throws: FoodEntryValidationError if validation fails
    func logQuickAdd(
        name: String,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        servingGrams: Double = 100.0,
        mealSection: MealSection,
        notes: String = "",
        loggedAt: Date = Date()
    ) async throws -> FoodEntry {
        // Validate name not empty
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw FoodEntryValidationError.emptyFoodName
        }

        // Validate serving size positive
        guard servingGrams > 0 else {
            throw FoodEntryValidationError.invalidServingSize
        }

        // Create FoodEntry directly (no Food model needed)
        let entry = FoodEntry(
            foodId: UUID(),
            foodName: name,
            foodBrand: nil,
            mealSection: mealSection,
            loggedAt: loggedAt,
            servingGrams: servingGrams,
            servingDescription: nil,
            caloriesPer100g: caloriesPer100g,
            proteinPer100g: proteinPer100g,
            carbsPer100g: carbsPer100g,
            fatPer100g: fatPer100g,
            fiberPer100g: 0,
            notes: notes.isEmpty ? nil : notes
        )

        context.insert(entry)
        try context.save()
        notifyDataChanged()

        Self.logger.info("Logged quick add entry: \(name) (\(servingGrams)g) for \(mealSection.displayName)")

        return entry
    }
}
