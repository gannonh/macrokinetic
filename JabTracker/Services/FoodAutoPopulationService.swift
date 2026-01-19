//
//  FoodAutoPopulationService.swift
//  JabTracker
//
//  Populates FoodEntry records from active FoodSchedule configurations.
//

import Foundation
import OSLog
import SwiftData

/// Service for auto-populating food entries from schedules.
/// Runs on app launch to create FoodEntry records for any missed days.
@MainActor
@Observable
final class FoodAutoPopulationService {
    private static let logger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "FoodAutoPopulationService"
    )

    private let context: ModelContext
    private let scheduleService: FoodScheduleService
    private let mealLogService: MealLogService

    /// UserDefaults key for tracking last populated date
    private static let lastPopulatedDateKey = "lastFoodAutoPopulationDate"

    /// Initialize with required dependencies
    /// - Parameters:
    ///   - context: ModelContext for inserting FoodEntry records
    ///   - scheduleService: Service for fetching applicable schedules
    ///   - mealLogService: Service for checking existing entries (duplicate prevention)
    init(
        context: ModelContext,
        scheduleService: FoodScheduleService,
        mealLogService: MealLogService
    ) {
        self.context = context
        self.scheduleService = scheduleService
        self.mealLogService = mealLogService
    }

    // MARK: - Public Methods

    /// Populate food entries for today only (skips lastPopulatedDate check).
    /// Use when a schedule is created mid-session and needs immediate population.
    func populateToday() async {
        let today = Calendar.current.startOfDay(for: Date())
        do {
            let count = try await populateDay(today)
            if count > 0 {
                Self.logger.info("Populated \(count) entries for today")
            }
        } catch {
            Self.logger.error("Failed to populate today: \(error.localizedDescription)")
        }
    }

    /// Populate food entries for any missed days since last population.
    /// Skips if already ran today. Backfills from (lastPopulated + 1) through today.
    func populateMissedDays() async {
        let today = Calendar.current.startOfDay(for: Date())

        // Get last populated date (default to yesterday if first run)
        let lastPopulated: Date
        if let stored = UserDefaults.standard.object(forKey: Self.lastPopulatedDateKey) as? Date {
            lastPopulated = Calendar.current.startOfDay(for: stored)
        } else {
            // First run: default to yesterday so we populate today
            lastPopulated = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        }

        // Skip if already populated today
        if lastPopulated >= today {
            Self.logger.debug("Auto-population already ran today, skipping")
            return
        }

        // Backfill from (lastPopulated + 1) through today
        var currentDate = Calendar.current.date(byAdding: .day, value: 1, to: lastPopulated) ?? today

        var daysPopulated = 0
        var entriesCreated = 0

        while currentDate <= today {
            do {
                let count = try await populateDay(currentDate)
                entriesCreated += count
                daysPopulated += 1
            } catch {
                Self.logger.error(
                    "Failed to populate day \(currentDate): \(error.localizedDescription)"
                )
            }

            guard let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)
            else {
                break
            }
            currentDate = nextDate
        }

        // Update last populated date on success
        UserDefaults.standard.set(today, forKey: Self.lastPopulatedDateKey)

        Self.logger.info(
            "Auto-population complete: \(entriesCreated) entries created across \(daysPopulated) days"
        )
    }

    // MARK: - Private Methods

    /// Populate food entries for a specific date from applicable schedules.
    /// - Parameter date: The date to populate
    /// - Returns: Number of entries created
    private func populateDay(_ date: Date) async throws -> Int {
        let normalizedDate = Calendar.current.startOfDay(for: date)

        // Get schedules that apply to this date
        let schedules = try await scheduleService.getSchedules(for: normalizedDate)

        guard !schedules.isEmpty else {
            Self.logger.debug("No schedules apply to \(normalizedDate)")
            return 0
        }

        // Get existing entries for this date
        let existingEntries = try await mealLogService.getEntries(for: normalizedDate)

        // Build Set of FoodMealKey for O(1) duplicate lookup
        var existingKeys = Set<FoodMealKey>()
        for entry in existingEntries {
            existingKeys.insert(FoodMealKey(foodId: entry.foodId, meal: entry.meal))
        }

        var entriesCreated = 0

        // For each schedule, create entries for each scheduled meal
        for schedule in schedules {
            let meals = schedule.scheduledMeals(for: normalizedDate)

            for meal in meals {
                let key = FoodMealKey(foodId: schedule.foodId, meal: meal)

                // Skip if entry already exists (duplicate prevention)
                if existingKeys.contains(key) {
                    Self.logger.debug(
                        "Skipping duplicate: \(schedule.foodName) for \(meal.displayName)"
                    )
                    continue
                }

                // Create FoodEntry from schedule
                let entry = createFoodEntry(from: schedule, meal: meal, date: normalizedDate)
                context.insert(entry)
                existingKeys.insert(key)  // Track newly created entries
                entriesCreated += 1

                Self.logger.debug(
                    "Created entry: \(schedule.foodName) for \(meal.displayName) on \(normalizedDate)"
                )
            }
        }

        // Save all entries for this day
        if entriesCreated > 0 {
            try context.save()
        }

        return entriesCreated
    }

    /// Create a FoodEntry from a FoodSchedule for a specific meal and date.
    /// - Parameters:
    ///   - schedule: The FoodSchedule to create entry from
    ///   - meal: The meal section for the entry
    ///   - date: The date for the entry (start of day)
    /// - Returns: A new FoodEntry with all properties mapped from the schedule
    private func createFoodEntry(
        from schedule: FoodSchedule,
        meal: MealSection,
        date: Date
    ) -> FoodEntry {
        FoodEntry(
            foodId: schedule.foodId,
            foodName: schedule.foodName,
            foodBrand: schedule.foodBrand.isEmpty ? nil : schedule.foodBrand,
            mealSection: meal,
            loggedAt: date,
            servingGrams: schedule.servingGrams,
            servingDescription: schedule.servingDescription.isEmpty
                ? nil : schedule.servingDescription,
            servingOptionsJSON: schedule.servingOptionsJSON,
            caloriesPer100g: schedule.caloriesPer100g,
            proteinPer100g: schedule.proteinPer100g,
            carbsPer100g: schedule.carbsPer100g,
            fatPer100g: schedule.fatPer100g,
            fiberPer100g: schedule.fiberPer100g,
            notes: nil
        )
    }
}

// MARK: - Helper Types

/// Key for identifying unique food+meal combinations for duplicate detection
private struct FoodMealKey: Hashable {
    let foodId: UUID
    let meal: MealSection
}
