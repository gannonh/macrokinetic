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

    // MARK: - UserDefaults Key

    /// UserDefaults key used by the service (must match service's key)
    private static let lastPopulatedDateKey = "lastFoodAutoPopulationDate"

    // MARK: - Test Setup/Teardown

    /// Reset UserDefaults before each test
    private func resetUserDefaults() {
        UserDefaults.standard.removeObject(forKey: Self.lastPopulatedDateKey)
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

        // Run population
        await services.autoPopulationService.populateMissedDays()

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
        await services.autoPopulationService.populateMissedDays()

        // Reset last populated to yesterday again so second run would try to populate
        UserDefaults.standard.set(yesterday, forKey: Self.lastPopulatedDateKey)
        await services.autoPopulationService.populateMissedDays()

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

        // Run population
        await services.autoPopulationService.populateMissedDays()

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

        // Run population
        await services.autoPopulationService.populateMissedDays()

        // Verify two entries created (one per meal)
        let entries = try await services.mealLogService.getEntries(for: today)
        #expect(entries.count == 2)

        let meals = Set(entries.map { $0.meal })
        #expect(meals.contains(.breakfast))
        #expect(meals.contains(.lunch))
    }

    @Test("Populate missed days backfills multiple days")
    func testPopulateMissedDays_BackfillsMultipleDays() async throws {
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

        // Set last populated date to 2 days ago
        let today = Calendar.current.startOfDay(for: Date())
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        UserDefaults.standard.set(twoDaysAgo, forKey: Self.lastPopulatedDateKey)

        // Run population
        await services.autoPopulationService.populateMissedDays()

        // Verify entries exist for yesterday and today
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        let yesterdayEntries = try await services.mealLogService.getEntries(for: yesterday)
        let todayEntries = try await services.mealLogService.getEntries(for: today)

        #expect(yesterdayEntries.count == 1)
        #expect(todayEntries.count == 1)
    }

    @Test("Populate missed days skips if already ran today")
    func testPopulateMissedDays_SkipsIfAlreadyRanToday() async throws {
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

        // Set last populated date to today (already ran)
        UserDefaults.standard.set(today, forKey: Self.lastPopulatedDateKey)

        // Run population
        await services.autoPopulationService.populateMissedDays()

        // Verify no entries created (should have skipped)
        let entries = try await services.mealLogService.getEntries(for: today)
        #expect(entries.count == 0)
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
