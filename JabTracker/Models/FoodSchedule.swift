//
//  FoodSchedule.swift
//  JabTracker
//
//  SwiftData model for scheduled food entries.
//

import Foundation
import SwiftData

/// Scheduled food for automatic population
/// One schedule per food enforced at service layer
@Model
final class FoodSchedule {
    // MARK: - Identity

    var id: UUID = UUID()

    // MARK: - Food Reference (UUID, not relationship)
    // Matches FoodEntry pattern - stores ID reference, food details denormalized

    var foodId: UUID = UUID()
    var foodName: String = ""
    var foodBrand: String = ""

    // MARK: - Schedule Configuration (JSON-encoded)

    /// JSON-encoded ScheduleConfig
    var scheduleConfigData: Data = Data()

    // MARK: - Serving Configuration

    var servingGrams: Double = 100.0
    var servingDescription: String = ""
    var servingOptionsJSON: String = "[]"

    // MARK: - Nutrition (denormalized from Food at schedule time)

    var caloriesPer100g: Double = 0.0
    var proteinPer100g: Double = 0.0
    var carbsPer100g: Double = 0.0
    var fatPer100g: Double = 0.0
    var fiberPer100g: Double = 0.0

    // MARK: - Date Range (optional)

    var startDate: Date?
    var endDate: Date?

    // MARK: - State

    var isActive: Bool = true

    // MARK: - Timestamps

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        foodId: UUID = UUID(),
        foodName: String = "",
        foodBrand: String = "",
        scheduleConfigData: Data = Data(),
        servingGrams: Double = 100.0,
        servingDescription: String = "",
        servingOptionsJSON: String = "[]",
        caloriesPer100g: Double = 0.0,
        proteinPer100g: Double = 0.0,
        carbsPer100g: Double = 0.0,
        fatPer100g: Double = 0.0,
        fiberPer100g: Double = 0.0,
        startDate: Date? = nil,
        endDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.foodId = foodId
        self.foodName = foodName
        self.foodBrand = foodBrand
        self.scheduleConfigData = scheduleConfigData
        self.servingGrams = servingGrams
        self.servingDescription = servingDescription
        self.servingOptionsJSON = servingOptionsJSON
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Schedule Config Accessor

extension FoodSchedule {
    /// Decoded schedule configuration
    var scheduleConfig: ScheduleConfig? {
        get {
            guard !scheduleConfigData.isEmpty else { return nil }
            return try? JSONDecoder().decode(ScheduleConfig.self, from: scheduleConfigData)
        }
        set {
            if let config = newValue {
                scheduleConfigData = (try? JSONEncoder().encode(config)) ?? Data()
            } else {
                scheduleConfigData = Data()
            }
            updatedAt = Date()
        }
    }

    /// Whether schedule applies to a given date
    func appliesTo(date: Date) -> Bool {
        // Check active state
        guard isActive else { return false }

        // Check date range if specified
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)

        if let start = startDate, startOfDate < calendar.startOfDay(for: start) {
            return false
        }
        if let end = endDate, startOfDate > calendar.startOfDay(for: end) {
            return false
        }

        return true
    }

    /// Meals scheduled for a specific date (considering day of week and date range)
    func scheduledMeals(for date: Date) -> [MealSection] {
        guard appliesTo(date: date),
            let config = scheduleConfig
        else { return [] }

        let weekday = Calendar.current.component(.weekday, from: date)
        guard let scheduleDay = ScheduleDay(rawValue: weekday) else { return [] }

        return config.meals(for: scheduleDay)
    }
}
