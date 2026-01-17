//
//  ClipboardContent.swift
//  JabTracker
//
//  Data types for clipboard copy/paste operations.
//  Uses lightweight value types to avoid SwiftData context issues.
//

import Foundation

/// Lightweight snapshot of a FoodEntry for clipboard storage.
///
/// Uses value types to avoid SwiftData ModelContext issues when
/// navigating between views. Each ClipboardEntry gets a new UUID
/// when pasted to create independent entries.
struct ClipboardEntry: Equatable, Identifiable {
    let id: UUID
    let foodId: UUID
    let foodName: String
    let foodBrand: String?
    let mealSection: MealSection
    let servingGrams: Double
    let servingDescription: String?
    let servingOptionsJSON: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double
    let notes: String?

    /// Create a ClipboardEntry from a FoodEntry
    /// - Parameter entry: The FoodEntry to copy
    init(from entry: FoodEntry) {
        self.id = UUID()  // New ID for clipboard, not copied from original
        self.foodId = entry.foodId
        self.foodName = entry.foodName
        self.foodBrand = entry.foodBrand
        self.mealSection = entry.meal
        self.servingGrams = entry.servingGrams
        self.servingDescription = entry.servingDescription
        self.servingOptionsJSON = entry.servingOptionsJSON
        self.caloriesPer100g = entry.caloriesPer100g
        self.proteinPer100g = entry.proteinPer100g
        self.carbsPer100g = entry.carbsPer100g
        self.fatPer100g = entry.fatPer100g
        self.fiberPer100g = entry.fiberPer100g
        self.notes = entry.notes
    }

    /// Memberwise initializer for testing
    init(
        id: UUID = UUID(),
        foodId: UUID,
        foodName: String,
        foodBrand: String? = nil,
        mealSection: MealSection,
        servingGrams: Double,
        servingDescription: String? = nil,
        servingOptionsJSON: String = "[]",
        caloriesPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        fiberPer100g: Double = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.foodId = foodId
        self.foodName = foodName
        self.foodBrand = foodBrand
        self.mealSection = mealSection
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
}

/// Content stored in the food clipboard.
///
/// Supports copying either an entire day's entries or a single meal's entries.
/// New copy replaces any existing clipboard content (session-only storage).
enum FoodClipboardContent: Equatable {
    /// Copied entries from an entire day
    case day(date: Date, entries: [ClipboardEntry])

    /// Copied entries from a single meal
    case meal(date: Date, meal: MealSection, entries: [ClipboardEntry])

    /// Number of entries in the clipboard for UI display
    var entryCount: Int {
        switch self {
        case .day(_, let entries), .meal(_, _, let entries):
            return entries.count
        }
    }

    /// Human-readable description of clipboard source for UI
    /// Examples: "3 items from Breakfast", "5 items from Jan 15"
    var sourceDescription: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"

        switch self {
        case .day(let date, let entries):
            let dateString = dateFormatter.string(from: date)
            let itemText = entries.count == 1 ? "item" : "items"
            return "\(entries.count) \(itemText) from \(dateString)"

        case .meal(_, let meal, let entries):
            let itemText = entries.count == 1 ? "item" : "items"
            return "\(entries.count) \(itemText) from \(meal.displayName)"
        }
    }
}
