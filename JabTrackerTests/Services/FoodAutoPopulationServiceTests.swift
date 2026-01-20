//
//  FoodAutoPopulationServiceTests.swift
//  JabTrackerTests
//
//  Tests for FoodAutoPopulationService - auto-population of FoodEntry from FoodSchedule.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Tests for FoodAutoPopulationService
/// Verifies population logic, duplicate prevention, and schedule date range handling
@Suite("FoodAutoPopulationService Tests")
@MainActor
struct FoodAutoPopulationServiceTests {

    // MARK: - UserDefaults Keys

    /// UserDefaults key used by the service for date tracking (must match service's key)
    private static let lastPopulatedDateKey = "lastFoodAutoPopulationDate"

    /// UserDefaults key used by the service for week tracking (must match service's key)
    private static let lastPopulatedWeekKey = "lastFoodAutoPopulationWeekStart"

    // MARK: - Test Setup/Teardown

    /// Reset UserDefaults before each test
    private func resetUserDefaults() {
        UserDefaults.standard.removeObject(forKey: Self.lastPopulatedDateKey)
        UserDefaults.standard.removeObject(forKey: Self.lastPopulatedWeekKey)
    }

    // MARK: - Create Tests

    @Test("Populate day creates entries from schedule")
    func testPopulateDay_CreatesEntriesFromSchedule() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(
            name: "Test Food",
            brand: "Test Brand",
            source: .userCreated,
            caloriesPer100g: 100,
            proteinPer100g: 10,
            carbsPer100g: 20,
            fatPer100g: 5,
            fiberPer100g: 2
        )
        services.context.insert(food)
        try services.context.save()

        // Find today's day of week
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        guard let scheduleDay = ScheduleDay(rawValue: weekday) else {
            Issue.record("Could not determine schedule day for weekday \(weekday)")
            return
        }

        // Create schedule for today's day
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: scheduleDay, meal: .breakfast)
        ])

        _ = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 150,
            servingDescription: "1 serving"
        )

        // Set last populated date to yesterday so it runs for today
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        UserDefaults.standard.set(yesterday, forKey: Self.lastPopulatedDateKey)

        // Run population (populateToday handles single day population)
        await services.autoPopulationService.populateToday()

        // Verify entry was created
        let entries = try await services.mealLogService.getEntries(for: today)
        #expect(entries.count == 1)

        let entry = entries[0]
        #expect(entry.foodName == "Test Food")
        #expect(entry.foodBrand == "Test Brand")
        #expect(entry.meal == .breakfast)
        #expect(entry.servingGrams == 150)
        #expect(entry.caloriesPer100g == 100)
        #expect(entry.proteinPer100g == 10)
        #expect(entry.carbsPer100g == 20)
        #expect(entry.fatPer100g == 5)
        #expect(entry.fiberPer100g == 2)
    }

    @Test("Populate day skips duplicates")
    func testPopulateDay_SkipsDuplicates() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(
            name: "Duplicate Test",
            source: .userCreated,
            caloriesPer100g: 200
        )
        services.context.insert(food)
        try services.context.save()

        // Find today's day of week
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        guard let scheduleDay = ScheduleDay(rawValue: weekday) else {
            Issue.record("Could not determine schedule day")
            return
        }

        // Create schedule for today
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: scheduleDay, meal: .lunch)
        ])

        _ = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        // Set last populated date to yesterday so it runs for today
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        UserDefaults.standard.set(yesterday, forKey: Self.lastPopulatedDateKey)

        // Run population twice
        await services.autoPopulationService.populateToday()

        // Reset last populated to yesterday again so second run would try to populate
        UserDefaults.standard.set(yesterday, forKey: Self.lastPopulatedDateKey)
        await services.autoPopulationService.populateToday()

        // Verify only one entry exists (not duplicated)
        let entries = try await services.mealLogService.getEntries(for: today)
        #expect(entries.count == 1)
    }

    @Test("Populate day respects date range - future start date")
    func testPopulateDay_RespectsDateRange() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(
            name: "Future Food",
            source: .userCreated,
            caloriesPer100g: 100
        )
        services.context.insert(food)
        try services.context.save()

        // Find today's day of week
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        guard let scheduleDay = ScheduleDay(rawValue: weekday) else {
            Issue.record("Could not determine schedule day")
            return
        }

        // Create schedule with startDate in future
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: scheduleDay, meal: .dinner)
        ])

        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: today)!

        _ = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: "",
            startDate: futureDate,
            endDate: nil
        )

        // Set last populated date to yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        UserDefaults.standard.set(yesterday, forKey: Self.lastPopulatedDateKey)

        // Run population (populateToday handles single day population)
        await services.autoPopulationService.populateToday()

        // Verify no entries created (schedule hasn't started yet)
        let entries = try await services.mealLogService.getEntries(for: today)
        #expect(entries.count == 0)
    }

    @Test("Populate day creates multiple meals from schedule")
    func testPopulateDay_CreatesMultipleMealsFromSchedule() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(
            name: "Multi-Meal Food",
            source: .userCreated,
            caloriesPer100g: 150
        )
        services.context.insert(food)
        try services.context.save()

        // Find today's day of week
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        guard let scheduleDay = ScheduleDay(rawValue: weekday) else {
            Issue.record("Could not determine schedule day")
            return
        }

        // Create schedule with breakfast AND lunch on same day
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: scheduleDay, meal: .breakfast),
            ScheduleDayMealConfig(day: scheduleDay, meal: .lunch),
        ])

        _ = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        // Set last populated date to yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        UserDefaults.standard.set(yesterday, forKey: Self.lastPopulatedDateKey)

        // Run population (populateToday handles single day population)
        await services.autoPopulationService.populateToday()

        // Verify two entries created (one per meal)
        let entries = try await services.mealLogService.getEntries(for: today)
        #expect(entries.count == 2)

        let meals = Set(entries.map { $0.meal })
        #expect(meals.contains(.breakfast))
        #expect(meals.contains(.lunch))
    }

    @Test("Populate today does NOT backfill missed days")
    func testPopulateToday_DoesNotBackfillMissedDays() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(
            name: "Backfill Food",
            source: .userCreated,
            caloriesPer100g: 100
        )
        services.context.insert(food)
        try services.context.save()

        // Create schedule that applies to all days of the week
        var dayMealConfigs: [ScheduleDayMealConfig] = []
        for day in ScheduleDay.allCases {
            dayMealConfigs.append(ScheduleDayMealConfig(day: day, meal: .breakfast))
        }
        let config = ScheduleConfig(dayMealConfigs: dayMealConfigs)

        _ = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        // Set last populated date to 2 days ago (simulating app wasn't opened)
        let today = Calendar.current.startOfDay(for: Date())
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        UserDefaults.standard.set(twoDaysAgo, forKey: Self.lastPopulatedDateKey)

        // Run population (populateToday only populates today - no backfill)
        await services.autoPopulationService.populateToday()

        // Verify NO entries for yesterday (no backfill per UAT requirement)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let yesterdayEntries = try await services.mealLogService.getEntries(for: yesterday)
        #expect(yesterdayEntries.count == 0, "Should NOT backfill missed days")

        // Verify today's entry was created
        let todayEntries = try await services.mealLogService.getEntries(for: today)
        #expect(todayEntries.count == 1, "Should populate today")
    }

    @Test("Populate today creates entry regardless of last populated date")
    func testPopulateToday_CreatesEntryRegardlessOfLastPopulatedDate() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(
            name: "Skip Test Food",
            source: .userCreated,
            caloriesPer100g: 100
        )
        services.context.insert(food)
        try services.context.save()

        // Find today's day of week
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        guard let scheduleDay = ScheduleDay(rawValue: weekday) else {
            Issue.record("Could not determine schedule day")
            return
        }

        // Create schedule for today
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: scheduleDay, meal: .snacks)
        ])

        _ = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        // Set last populated date to today (simulating already ran)
        // Note: populateToday() uses duplicate prevention via existing entries,
        // not date tracking, so this flag doesn't prevent population
        UserDefaults.standard.set(today, forKey: Self.lastPopulatedDateKey)

        // Run population - should still create entry (duplicate prevention checks existing entries)
        await services.autoPopulationService.populateToday()

        // Verify entry was created (1 entry)
        let entries = try await services.mealLogService.getEntries(for: today)
        #expect(entries.count == 1, "Should create entry - duplicate prevention checks existing entries, not dates")
    }

    // MARK: - Delete Scheduled Entries Tests

    @Test("Delete scheduled entries removes entries after cutoff")
    func testDeleteScheduledEntries_RemovesEntriesAfterCutoff() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(
            name: "Delete Test Food",
            source: .userCreated,
            caloriesPer100g: 100
        )
        services.context.insert(food)
        try services.context.save()

        // Find today's day of week
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        guard let scheduleDay = ScheduleDay(rawValue: weekday) else {
            Issue.record("Could not determine schedule day")
            return
        }

        // Create schedule for today
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: scheduleDay, meal: .breakfast)
        ])

        let schedule = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        // Populate entries (creates future entries)
        _ = try await services.autoPopulationService.populateWeek(for: schedule)

        // Verify entries exist
        let entriesBefore = try await services.mealLogService.getEntries(for: today)
        #expect(entriesBefore.count >= 1, "Should have at least one entry before deletion")

        // Delete scheduled entries
        try await services.autoPopulationService.deleteScheduledEntries(for: schedule.id)

        // Verify entries are deleted
        let entriesAfter = try await services.mealLogService.getEntries(for: today)
        #expect(entriesAfter.count == 0, "Entries should be deleted after cutoff")
    }

    @Test("Delete scheduled entries preserves entries before cutoff")
    func testDeleteScheduledEntries_PreservesEntriesBeforeCutoff() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(
            name: "Preserve Test Food",
            source: .userCreated,
            caloriesPer100g: 100
        )
        services.context.insert(food)
        try services.context.save()

        // Create a manual entry for yesterday (not from schedule)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayNormalized = Calendar.current.startOfDay(for: yesterday)

        let manualEntry = FoodEntry(
            foodId: food.id,
            scheduleId: UUID(),  // Use a different schedule ID to distinguish
            foodName: food.name,
            foodBrand: nil,
            mealSection: .breakfast,
            loggedAt: yesterdayNormalized,
            servingGrams: 100,
            servingDescription: nil,
            servingOptionsJSON: "[]",
            caloriesPer100g: 100,
            proteinPer100g: 0.0,
            carbsPer100g: 0.0,
            fatPer100g: 0.0,
            fiberPer100g: 0.0,
            notes: nil
        )
        services.context.insert(manualEntry)
        try services.context.save()

        // Find today's day of week
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        guard let scheduleDay = ScheduleDay(rawValue: weekday) else {
            Issue.record("Could not determine schedule day")
            return
        }

        // Create schedule for today
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: scheduleDay, meal: .breakfast)
        ])

        let schedule = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        // Populate entries for this schedule
        _ = try await services.autoPopulationService.populateWeek(for: schedule)

        // Delete scheduled entries for THIS schedule only
        try await services.autoPopulationService.deleteScheduledEntries(for: schedule.id)

        // Verify yesterday's entry still exists (different scheduleId, and before cutoff)
        let yesterdayEntries = try await services.mealLogService.getEntries(for: yesterdayNormalized)
        #expect(yesterdayEntries.count == 1, "Yesterday's entry should be preserved")
    }

    // MARK: - Populate Week Tests

    @Test("Populate week creates entries through end of week")
    func testPopulateWeek_CreatesEntriesThroughEndOfWeek() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(
            name: "Week Test Food",
            source: .userCreated,
            caloriesPer100g: 100
        )
        services.context.insert(food)
        try services.context.save()

        // Create schedule for ALL days of the week
        var dayMealConfigs: [ScheduleDayMealConfig] = []
        for day in ScheduleDay.allCases {
            dayMealConfigs.append(ScheduleDayMealConfig(day: day, meal: .breakfast))
        }
        let config = ScheduleConfig(dayMealConfigs: dayMealConfigs)

        let schedule = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        // Populate week
        let entriesCreated = try await services.autoPopulationService.populateWeek(for: schedule)

        // Should create entries from today through end of week
        // The number depends on what day of the week it is
        #expect(entriesCreated >= 1, "Should create at least one entry (today)")
        #expect(entriesCreated <= 7, "Should create at most 7 entries (full week)")
    }

    @Test("Populate week respects future start date")
    func testPopulateWeek_RespectsDateRange() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(
            name: "Future Start Food",
            source: .userCreated,
            caloriesPer100g: 100
        )
        services.context.insert(food)
        try services.context.save()

        let today = Calendar.current.startOfDay(for: Date())

        // Create schedule for ALL days but with startDate in future (next week)
        var dayMealConfigs: [ScheduleDayMealConfig] = []
        for day in ScheduleDay.allCases {
            dayMealConfigs.append(ScheduleDayMealConfig(day: day, meal: .breakfast))
        }
        let config = ScheduleConfig(dayMealConfigs: dayMealConfigs)

        let futureDate = Calendar.current.date(byAdding: .day, value: 14, to: today)!

        let schedule = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: "",
            startDate: futureDate,
            endDate: nil
        )

        // Populate week - should create nothing since start date is in future
        let entriesCreated = try await services.autoPopulationService.populateWeek(for: schedule)

        #expect(entriesCreated == 0, "Should create no entries when start date is in future")
    }

    // MARK: - Check and Populate New Week Tests

    @Test("Check and populate new week populates on week change")
    func testCheckAndPopulateNewWeek_PopulatesOnWeekChange() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(
            name: "Week Change Food",
            source: .userCreated,
            caloriesPer100g: 100
        )
        services.context.insert(food)
        try services.context.save()

        // Find today's day of week
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        guard let scheduleDay = ScheduleDay(rawValue: weekday) else {
            Issue.record("Could not determine schedule day")
            return
        }

        // Create schedule for today
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: scheduleDay, meal: .breakfast)
        ])

        _ = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        // Set last populated week to LAST week (simulating week change)
        let lastWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        UserDefaults.standard.set(lastWeekStart, forKey: Self.lastPopulatedWeekKey)

        // Run check and populate
        let result = await services.autoPopulationService.checkAndPopulateNewWeek()

        // Should detect new week and populate
        #expect(result.isSuccess, "Should succeed")
        #expect(result.schedulesProcessed >= 1, "Should process at least one schedule")
    }

    @Test("Check and populate new week skips when same week")
    func testCheckAndPopulateNewWeek_SkipsWhenSameWeek() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(
            name: "Same Week Food",
            source: .userCreated,
            caloriesPer100g: 100
        )
        services.context.insert(food)
        try services.context.save()

        // Find today's day of week
        let today = Calendar.current.startOfDay(for: Date())
        let weekday = Calendar.current.component(.weekday, from: today)
        guard let scheduleDay = ScheduleDay(rawValue: weekday) else {
            Issue.record("Could not determine schedule day")
            return
        }

        // Create schedule for today
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: scheduleDay, meal: .lunch)
        ])

        _ = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        // Set last populated week to current week start
        // Calculate current week start
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        let currentWeekStart = calendar.date(from: components)!

        UserDefaults.standard.set(currentWeekStart, forKey: Self.lastPopulatedWeekKey)

        // Run check and populate
        let result = await services.autoPopulationService.checkAndPopulateNewWeek()

        // Should skip because we're in the same week
        #expect(result.isSuccess, "Should succeed (but skip population)")
        #expect(result.schedulesProcessed == 0, "Should process no schedules when same week")
        #expect(result.entriesCreated == 0, "Should create no entries when same week")
    }

    @Test("Check and populate new week succeeds with no schedules")
    func testCheckAndPopulateNewWeek_SucceedsWithNoSchedules() async throws {
        resetUserDefaults()
        let services = createTestServices()
        _ = services.container

        // Set last populated week to last week to trigger population
        let today = Calendar.current.startOfDay(for: Date())
        let lastWeekStart = Calendar.current.date(byAdding: .day, value: -7, to: today)!
        UserDefaults.standard.set(lastWeekStart, forKey: Self.lastPopulatedWeekKey)

        // Without any schedules, population should succeed but create no entries
        let result = await services.autoPopulationService.checkAndPopulateNewWeek()

        // With no schedules, it should succeed with 0 entries (no error)
        #expect(result.isSuccess, "Should succeed even with no schedules")
        #expect(result.error == nil, "Should have no error")
        #expect(result.entriesCreated == 0, "Should create no entries when no schedules exist")
    }

    // MARK: - Helper Types

    /// Container for test services
    private struct TestServices {
        let context: ModelContext
        let container: ModelContainer
        let customFoodService: CustomFoodService
        let scheduleService: FoodScheduleService
        let mealLogService: MealLogService
        let autoPopulationService: FoodAutoPopulationService
    }

    // MARK: - Helper Methods

    private func createTestServices() -> TestServices {
        let (context, container) = CustomFoodTestHelpers.createTestContext()
        let customFoodService = CustomFoodService(context: context)
        let scheduleService = FoodScheduleService(context: context, customFoodService: customFoodService)
        let mealLogService = MealLogService(context: context)
        let autoPopulationService = FoodAutoPopulationService(
            context: context,
            scheduleService: scheduleService,
            mealLogService: mealLogService
        )
        return TestServices(
            context: context,
            container: container,
            customFoodService: customFoodService,
            scheduleService: scheduleService,
            mealLogService: mealLogService,
            autoPopulationService: autoPopulationService
        )
    }
}
