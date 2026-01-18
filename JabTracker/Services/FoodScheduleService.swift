//
//  FoodScheduleService.swift
//  JabTracker
//
//  CRUD operations for food schedules with constraint enforcement.
//

import Foundation
import OSLog
import SwiftData

/// Errors that can occur during food schedule operations
enum FoodScheduleError: LocalizedError, Equatable {
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Schedule configuration is invalid"
        }
    }
}

/// Service for managing food schedules.
/// Provides CRUD operations with:
/// - One-schedule-per-food constraint enforcement (SCHED-07)
/// - Auto-conversion of non-custom foods to custom foods before scheduling (SCHED-04)
@MainActor
final class FoodScheduleService {
    private static let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "FoodScheduleService")

    private let context: ModelContext
    private let customFoodService: CustomFoodService

    /// Initialize with model context and custom food service for auto-conversion
    init(context: ModelContext, customFoodService: CustomFoodService) {
        self.context = context
        self.customFoodService = customFoodService
    }

    // MARK: - Create/Update

    /// Create or update a schedule for a food
    /// If the food is not a custom food, it will be auto-converted to custom (SCHED-04)
    /// If a schedule already exists for the food, it will be updated (SCHED-07 one-per-food constraint)
    /// - Parameters:
    ///   - food: The food to schedule
    ///   - config: Schedule configuration with day/meal combinations
    ///   - servingGrams: Serving size in grams
    ///   - servingDescription: Human-readable serving description
    ///   - startDate: Optional schedule start date
    ///   - endDate: Optional schedule end date
    /// - Returns: The created or updated FoodSchedule
    /// - Throws: FoodScheduleError if configuration is invalid
    /// - Note: When auto-conversion occurs, the returned schedule references the newly created custom food,
    ///   not the original food parameter. The original food remains unchanged.
    func createOrUpdateSchedule(
        for food: Food,
        config: ScheduleConfig,
        servingGrams: Double,
        servingDescription: String,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> FoodSchedule {
        guard config.isValid else {
            Self.logger.error("Invalid schedule configuration attempted for food: \(food.name)")
            throw FoodScheduleError.invalidConfiguration
        }

        let targetFood: Food
        if food.isCustomFood {
            targetFood = food
        } else {
            targetFood = try await convertToCustomFood(food)
        }

        // Check for existing schedule (one-per-food constraint, SCHED-07)
        if let existingSchedule = try await getSchedule(for: targetFood.id) {
            // Update existing schedule
            return try await updateSchedule(
                existingSchedule,
                config: config,
                servingGrams: servingGrams,
                servingDescription: servingDescription,
                startDate: startDate,
                endDate: endDate
            )
        }

        // Create new schedule
        let schedule = FoodSchedule(
            foodId: targetFood.id,
            foodName: targetFood.name,
            foodBrand: targetFood.brand,
            servingGrams: servingGrams,
            servingDescription: servingDescription,
            caloriesPer100g: targetFood.caloriesPer100g,
            proteinPer100g: targetFood.proteinPer100g,
            carbsPer100g: targetFood.carbsPer100g,
            fatPer100g: targetFood.fatPer100g,
            fiberPer100g: targetFood.fiberPer100g,
            startDate: startDate,
            endDate: endDate
        )
        schedule.scheduleConfig = config

        context.insert(schedule)
        try context.save()

        Self.logger.info("Created schedule for food: \(targetFood.name)")

        return schedule
    }

    // MARK: - Read

    /// Get schedule for a specific food by ID
    /// - Parameter foodId: The food ID to look up
    /// - Returns: The schedule if found, nil otherwise
    func getSchedule(for foodId: UUID) async throws -> FoodSchedule? {
        let descriptor = FetchDescriptor<FoodSchedule>(
            predicate: #Predicate { schedule in
                schedule.foodId == foodId
            }
        )
        return try context.fetch(descriptor).first
    }

    /// Get all active schedules
    /// - Returns: Array of active schedules sorted by food name
    func getAllActiveSchedules() async throws -> [FoodSchedule] {
        let descriptor = FetchDescriptor<FoodSchedule>(
            predicate: #Predicate { schedule in
                schedule.isActive == true
            },
            sortBy: [SortDescriptor(\.foodName)]
        )
        return try context.fetch(descriptor)
    }

    /// Get schedules that apply to a specific date (checks date range and day of week)
    /// - Parameter date: The date to check
    /// - Returns: Array of schedules that have meals scheduled for the given date
    func getSchedules(for date: Date) async throws -> [FoodSchedule] {
        let activeSchedules = try await getAllActiveSchedules()
        return activeSchedules.filter { !$0.scheduledMeals(for: date).isEmpty }
    }

    // MARK: - Update

    /// Update an existing schedule
    /// - Parameters:
    ///   - schedule: The schedule to update
    ///   - config: New schedule configuration
    ///   - servingGrams: New serving size in grams
    ///   - servingDescription: New serving description
    ///   - startDate: New start date
    ///   - endDate: New end date
    /// - Returns: The updated schedule
    /// - Throws: FoodScheduleError if configuration is invalid
    @discardableResult
    func updateSchedule(
        _ schedule: FoodSchedule,
        config: ScheduleConfig,
        servingGrams: Double,
        servingDescription: String,
        startDate: Date?,
        endDate: Date?
    ) async throws -> FoodSchedule {
        guard config.isValid else {
            Self.logger.error("Invalid schedule configuration in update for food: \(schedule.foodName)")
            throw FoodScheduleError.invalidConfiguration
        }

        schedule.scheduleConfig = config
        schedule.servingGrams = servingGrams
        schedule.servingDescription = servingDescription
        schedule.startDate = startDate
        schedule.endDate = endDate
        schedule.updatedAt = Date()

        try context.save()

        Self.logger.info("Updated schedule for food: \(schedule.foodName)")

        return schedule
    }

    // MARK: - Delete

    /// Delete a schedule
    /// - Parameter schedule: The schedule to delete
    func deleteSchedule(_ schedule: FoodSchedule) async throws {
        let foodName = schedule.foodName
        context.delete(schedule)
        try context.save()

        Self.logger.info("Deleted schedule for food: \(foodName)")
    }

    // MARK: - Private Helpers

    /// Convert a non-custom food to a custom food
    /// - Parameter food: The food to convert
    /// - Returns: The newly created custom food
    private func convertToCustomFood(_ food: Food) async throws -> Food {
        let input = CustomFoodInput(
            name: food.name,
            brand: food.brand,
            caloriesPer100g: food.caloriesPer100g,
            proteinPer100g: food.proteinPer100g,
            carbsPer100g: food.carbsPer100g,
            fatPer100g: food.fatPer100g,
            fiberPer100g: food.fiberPer100g,
            servingSize: food.servingSize,
            servingUnit: food.servingUnit,
            servingDescription: food.servingDescription,
            barcode: ""  // Empty barcode to avoid conflicts
        )

        let customFood = try await customFoodService.createCustomFood(input)

        Self.logger.info("Converted food '\(food.name)' to custom food for scheduling")

        return customFood
    }
}
