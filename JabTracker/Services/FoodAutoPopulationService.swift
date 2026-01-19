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
/// Creates entries for the entire current week when schedules are saved.
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

    /// UserDefaults key for tracking last populated week start
    private static let lastPopulatedWeekKey = "lastFoodAutoPopulationWeekStart"

    /// Initialize with required dependencies
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

    /// Populate food entries for the remainder of the current week for a specific schedule.
    /// Called when a schedule is created or updated.
    /// - Parameter schedule: The schedule to populate entries for
    /// - Returns: Number of entries created
    @discardableResult
    func populateWeek(for schedule: FoodSchedule) async throws -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endOfWeek = getEndOfWeek(for: today)

        var entriesCreated = 0
        var currentDate = today

        while currentDate <= endOfWeek {
            let count = try await populateDayForSchedule(schedule, date: currentDate)
            entriesCreated += count

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        if entriesCreated > 0 {
            try context.save()
            Self.logger.info(
                "Populated \(entriesCreated) entries for schedule '\(schedule.foodName)' through end of week"
            )
        }

        return entriesCreated
    }

    /// Delete all scheduled entries for a schedule after a given date.
    /// Used when a schedule is deleted or modified.
    /// - Parameters:
    ///   - scheduleId: The schedule ID to delete entries for
    ///   - afterDate: Delete entries on or after this date (default: today)
    func deleteScheduledEntries(for scheduleId: UUID, after afterDate: Date? = nil) async throws {
        let calendar = Calendar.current
        let cutoffDate = afterDate ?? calendar.startOfDay(for: Date())

        // Fetch all entries with this scheduleId on or after the cutoff date
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { entry in
                entry.scheduleId == scheduleId && entry.loggedAt >= cutoffDate
            }
        )

        let entries = try context.fetch(descriptor)

        for entry in entries {
            context.delete(entry)
        }

        if !entries.isEmpty {
            try context.save()
            Self.logger.info("Deleted \(entries.count) scheduled entries for schedule \(scheduleId)")
        }
    }

    /// Check if new week has started and populate entries for all active schedules.
    /// Should be called on app activation to handle week rollover.
    func checkAndPopulateNewWeek() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentWeekStart = getStartOfWeek(for: today)

        // Get last populated week start
        let lastWeekStart: Date
        if let stored = UserDefaults.standard.object(forKey: Self.lastPopulatedWeekKey) as? Date {
            lastWeekStart = calendar.startOfDay(for: stored)
        } else {
            // First run - set to beginning of last week so we populate this week
            lastWeekStart = calendar.date(byAdding: .day, value: -7, to: currentWeekStart) ?? currentWeekStart
        }

        // If we're in a new week, populate for all active schedules
        if currentWeekStart > lastWeekStart {
            Self.logger.info("New week detected - populating entries for all active schedules")

            do {
                let schedules = try await scheduleService.getAllActiveSchedules()
                var totalEntries = 0

                for schedule in schedules {
                    let count = try await populateWeek(for: schedule)
                    totalEntries += count
                }

                // Update last populated week
                UserDefaults.standard.set(currentWeekStart, forKey: Self.lastPopulatedWeekKey)

                Self.logger.info("New week population complete: \(totalEntries) entries created")
            } catch {
                Self.logger.error("Failed to populate new week: \(error.localizedDescription)")
            }
        }
    }

    /// Legacy method - populate entries for today only.
    /// Kept for backward compatibility but prefer populateWeek().
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

    // MARK: - Private Methods

    /// Get the start of the week (Sunday) for a given date
    private func getStartOfWeek(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    /// Get the end of the week (Saturday) for a given date
    private func getEndOfWeek(for date: Date) -> Date {
        let calendar = Calendar.current
        let startOfWeek = getStartOfWeek(for: date)
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? date
    }

    /// Populate entries for a single schedule on a specific date
    private func populateDayForSchedule(_ schedule: FoodSchedule, date: Date) async throws -> Int {
        let normalizedDate = Calendar.current.startOfDay(for: date)

        // Check if schedule applies to this date
        let meals = schedule.scheduledMeals(for: normalizedDate)
        guard !meals.isEmpty else { return 0 }

        // Check for existing entries to avoid duplicates
        let existingEntries = try await mealLogService.getEntries(for: normalizedDate)
        var existingKeys = Set<FoodMealKey>()
        for entry in existingEntries {
            existingKeys.insert(FoodMealKey(foodId: entry.foodId, meal: entry.meal))
        }

        var entriesCreated = 0

        for meal in meals {
            let key = FoodMealKey(foodId: schedule.foodId, meal: meal)

            // Skip if entry already exists
            if existingKeys.contains(key) {
                continue
            }

            let entry = createFoodEntry(from: schedule, meal: meal, date: normalizedDate)
            context.insert(entry)
            existingKeys.insert(key)
            entriesCreated += 1
        }

        return entriesCreated
    }

    /// Populate food entries for a specific date from ALL applicable schedules.
    private func populateDay(_ date: Date) async throws -> Int {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        let schedules = try await scheduleService.getSchedules(for: normalizedDate)

        guard !schedules.isEmpty else { return 0 }

        var totalCreated = 0
        for schedule in schedules {
            let count = try await populateDayForSchedule(schedule, date: normalizedDate)
            totalCreated += count
        }

        if totalCreated > 0 {
            try context.save()
        }

        return totalCreated
    }

    /// Create a FoodEntry from a FoodSchedule for a specific meal and date.
    private func createFoodEntry(
        from schedule: FoodSchedule,
        meal: MealSection,
        date: Date
    ) -> FoodEntry {
        FoodEntry(
            foodId: schedule.foodId,
            scheduleId: schedule.id,  // Link to schedule for cascade operations
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
