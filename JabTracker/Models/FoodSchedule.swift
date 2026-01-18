//
//  FoodSchedule.swift
//  JabTracker
//
//  SwiftData model for scheduled food entries.
//

import Foundation
import OSLog
import SwiftData

/// Represents a recurring food schedule that defines when a food should appear in the meal plan.
/// The one-schedule-per-food constraint is enforced by FoodScheduleService (SCHED-07).
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
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "FoodSchedule")

    /// Decoded schedule configuration. Setting this property automatically updates `updatedAt`.
    var scheduleConfig: ScheduleConfig? {
        get {
            guard !scheduleConfigData.isEmpty else { return nil }
            do {
                return try JSONDecoder().decode(ScheduleConfig.self, from: scheduleConfigData)
            } catch {
                let scheduleId = self.id
                Self.logger.error("Failed to decode scheduleConfig for schedule \(scheduleId): \(error)")
                return nil
            }
        }
        set {
            if let config = newValue {
                do {
                    scheduleConfigData = try JSONEncoder().encode(config)
                    updatedAt = Date()
                } catch {
                    Self.logger.error("Failed to encode scheduleConfig - preserving existing data: \(error)")
                    // Preserve existing data on encoding failure to prevent data loss
                }
            } else {
                scheduleConfigData = Data()
                updatedAt = Date()
            }
        }
    }

    /// Whether schedule applies to a given date (considering active status and date range)
    func appliesTo(date: Date) -> Bool {
        guard isActive else { return false }

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

    /// Returns meals scheduled for a specific date, considering day of week, date range, and active status.
    /// Returns an empty array if the schedule does not apply to the given date.
    func scheduledMeals(for date: Date) -> [MealSection] {
        guard appliesTo(date: date),
            let config = scheduleConfig
        else { return [] }

        let weekday = Calendar.current.component(.weekday, from: date)
        guard let scheduleDay = ScheduleDay(rawValue: weekday) else {
            Self.logger.error("Unexpected weekday value \(weekday) for date \(date) - cannot determine schedule day")
            return []
        }

        return config.meals(for: scheduleDay)
    }
}
