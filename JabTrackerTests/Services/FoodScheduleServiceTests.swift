//
//  FoodScheduleServiceTests.swift
//  JabTrackerTests
//
//  Tests for FoodScheduleService - CRUD operations for food schedules with constraint enforcement.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Tests for FoodScheduleService
/// Verifies CRUD operations, one-per-food constraint, and auto-conversion to custom foods
@Suite("FoodScheduleService Tests")
@MainActor
struct FoodScheduleServiceTests {

    // MARK: - Create Tests

    @Test("Create schedule for custom food creates schedule with correct properties")
    func testCreateScheduleForCustomFood() async throws {
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
            fatPer100g: 5
        )
        services.context.insert(food)
        try services.context.save()

        // Create valid schedule config
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])

        let schedule = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 150,
            servingDescription: "1 serving"
        )

        #expect(schedule.foodId == food.id)
        #expect(schedule.foodName == "Test Food")
        #expect(schedule.foodBrand == "Test Brand")
        #expect(schedule.servingGrams == 150)
        #expect(schedule.servingDescription == "1 serving")
        #expect(schedule.scheduleConfig != nil)
        #expect(schedule.scheduleConfig?.dayMealConfigs.count == 1)
    }

    @Test("Create schedule auto-converts non-custom food to custom (SCHED-04)")
    func testCreateScheduleAutoConvertsNonCustomFood() async throws {
        let services = createTestServices()
        _ = services.container

        // Create USDA food (not custom)
        let food = Food(
            name: "Apple",
            brand: "",
            fdcId: 12345,
            source: .local,
            caloriesPer100g: 52,
            proteinPer100g: 0.3,
            carbsPer100g: 14,
            fatPer100g: 0.2
        )
        services.context.insert(food)
        try services.context.save()

        let originalFoodId = food.id

        // Create schedule - should auto-convert to custom
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .lunch)
        ])

        let schedule = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: "1 medium apple"
        )

        // Schedule should reference new custom food, not original
        #expect(schedule.foodId != originalFoodId)
        #expect(schedule.foodName == "Apple")
    }

    @Test("Create schedule updates existing schedule (SCHED-07 one-per-food)")
    func testCreateScheduleUpdatesExistingSchedule() async throws {
        let services = createTestServices()
        _ = services.container

        // Create custom food
        let food = Food(name: "Test Food", source: .userCreated)
        services.context.insert(food)
        try services.context.save()

        // Create first schedule
        let config1 = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])

        let schedule1 = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config1,
            servingGrams: 100,
            servingDescription: "Original"
        )

        // Create second schedule for same food - should update existing
        let config2 = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .tuesday, meal: .lunch),
            ScheduleDayMealConfig(day: .wednesday, meal: .dinner),
        ])

        let schedule2 = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config2,
            servingGrams: 200,
            servingDescription: "Updated"
        )

        // Should be same schedule, updated
        #expect(schedule1.id == schedule2.id)
        #expect(schedule2.servingGrams == 200)
        #expect(schedule2.servingDescription == "Updated")
        #expect(schedule2.scheduleConfig?.dayMealConfigs.count == 2)

        // Verify only one schedule exists
        let allSchedules = try await services.scheduleService.getAllActiveSchedules()
        #expect(allSchedules.count == 1)
    }

    @Test("Create schedule with invalid config throws invalidConfiguration")
    func testCreateScheduleWithInvalidConfigThrows() async throws {
        let services = createTestServices()
        _ = services.container

        let food = Food(name: "Test Food", source: .userCreated)
        services.context.insert(food)
        try services.context.save()

        // Empty config is invalid
        let emptyConfig = ScheduleConfig(dayMealConfigs: [])

        await #expect(throws: FoodScheduleError.invalidConfiguration) {
            _ = try await services.scheduleService.createOrUpdateSchedule(
                for: food,
                config: emptyConfig,
                servingGrams: 100,
                servingDescription: ""
            )
        }
    }

    // MARK: - Read Tests

    @Test("getSchedule returns nil for unscheduled food")
    func testGetScheduleReturnsNilForUnscheduledFood() async throws {
        let services = createTestServices()
        _ = services.container

        let food = Food(name: "Test Food", source: .userCreated)
        services.context.insert(food)
        try services.context.save()

        let schedule = try await services.scheduleService.getSchedule(for: food.id)

        #expect(schedule == nil)
    }

    @Test("getSchedule returns existing schedule")
    func testGetScheduleReturnsExistingSchedule() async throws {
        let services = createTestServices()
        _ = services.container

        // Create food and schedule
        let food = Food(name: "Test Food", source: .userCreated)
        services.context.insert(food)
        try services.context.save()

        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .friday, meal: .snacks)
        ])

        _ = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 50,
            servingDescription: "snack size"
        )

        // Fetch the schedule
        let fetchedSchedule = try await services.scheduleService.getSchedule(for: food.id)

        #expect(fetchedSchedule != nil)
        #expect(fetchedSchedule?.foodName == "Test Food")
        #expect(fetchedSchedule?.servingGrams == 50)
    }

    @Test("getAllActiveSchedules returns only active schedules sorted by name")
    func testGetAllActiveSchedules() async throws {
        let services = createTestServices()
        _ = services.container

        // Create foods with schedules
        let foodA = Food(name: "Apple", source: .userCreated)
        let foodB = Food(name: "Banana", source: .userCreated)
        let foodC = Food(name: "Cherry", source: .userCreated)
        services.context.insert(foodA)
        services.context.insert(foodB)
        services.context.insert(foodC)
        try services.context.save()

        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])

        // Create active schedules for A and C
        let scheduleA = try await services.scheduleService.createOrUpdateSchedule(
            for: foodA,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        let scheduleC = try await services.scheduleService.createOrUpdateSchedule(
            for: foodC,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        // Create inactive schedule for B
        let scheduleB = try await services.scheduleService.createOrUpdateSchedule(
            for: foodB,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )
        scheduleB.isActive = false
        try services.context.save()

        let activeSchedules = try await services.scheduleService.getAllActiveSchedules()

        #expect(activeSchedules.count == 2)
        // Should be sorted by name: Apple, Cherry
        #expect(activeSchedules[0].foodName == "Apple")
        #expect(activeSchedules[1].foodName == "Cherry")

        // Keep variables alive to silence warnings
        _ = scheduleA
        _ = scheduleC
    }

    @Test("getSchedules for date returns schedules that apply")
    func testGetSchedulesForDate() async throws {
        let services = createTestServices()
        _ = services.container

        // Create food with Monday breakfast schedule
        let food = Food(name: "Test Food", source: .userCreated)
        services.context.insert(food)
        try services.context.save()

        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])

        _ = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        // Find a Monday
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 19  // A Monday
        let monday = calendar.date(from: components)!

        // Find a Tuesday
        components.day = 20  // A Tuesday
        let tuesday = calendar.date(from: components)!

        // Schedule should apply to Monday
        let mondaySchedules = try await services.scheduleService.getSchedules(for: monday)
        #expect(mondaySchedules.count == 1)

        // Schedule should NOT apply to Tuesday
        let tuesdaySchedules = try await services.scheduleService.getSchedules(for: tuesday)
        #expect(tuesdaySchedules.isEmpty)
    }

    // MARK: - Update Tests

    @Test("updateSchedule modifies schedule properties")
    func testUpdateSchedule() async throws {
        let services = createTestServices()
        _ = services.container

        // Create food and schedule
        let food = Food(name: "Test Food", source: .userCreated)
        services.context.insert(food)
        try services.context.save()

        let originalConfig = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])

        let schedule = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: originalConfig,
            servingGrams: 100,
            servingDescription: "original"
        )

        let originalUpdatedAt = schedule.updatedAt

        // Wait a moment to ensure updatedAt changes
        try await Task.sleep(for: .milliseconds(10))

        // Update the schedule
        let newConfig = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .tuesday, meal: .lunch)
        ])

        let updatedSchedule = try await services.scheduleService.updateSchedule(
            schedule,
            config: newConfig,
            servingGrams: 200,
            servingDescription: "updated",
            startDate: nil,
            endDate: nil
        )

        #expect(updatedSchedule.servingGrams == 200)
        #expect(updatedSchedule.servingDescription == "updated")
        #expect(updatedSchedule.scheduleConfig?.dayMealConfigs.first?.day == .tuesday)
        #expect(updatedSchedule.updatedAt > originalUpdatedAt)
    }

    @Test("updateSchedule with invalid config throws")
    func testUpdateScheduleWithInvalidConfigThrows() async throws {
        let services = createTestServices()
        _ = services.container

        let food = Food(name: "Test Food", source: .userCreated)
        services.context.insert(food)
        try services.context.save()

        let validConfig = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])

        let schedule = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: validConfig,
            servingGrams: 100,
            servingDescription: ""
        )

        // Try to update with invalid config
        let invalidConfig = ScheduleConfig(dayMealConfigs: [])

        await #expect(throws: FoodScheduleError.invalidConfiguration) {
            _ = try await services.scheduleService.updateSchedule(
                schedule,
                config: invalidConfig,
                servingGrams: 100,
                servingDescription: "",
                startDate: nil,
                endDate: nil
            )
        }
    }

    // MARK: - Delete Tests

    @Test("deleteSchedule removes schedule")
    func testDeleteSchedule() async throws {
        let services = createTestServices()
        _ = services.container

        // Create food and schedule
        let food = Food(name: "Test Food", source: .userCreated)
        services.context.insert(food)
        try services.context.save()

        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])

        let schedule = try await services.scheduleService.createOrUpdateSchedule(
            for: food,
            config: config,
            servingGrams: 100,
            servingDescription: ""
        )

        // Delete the schedule
        try await services.scheduleService.deleteSchedule(schedule)

        // Verify it's gone
        let fetchedSchedule = try await services.scheduleService.getSchedule(for: food.id)
        #expect(fetchedSchedule == nil)
    }

    // MARK: - Helper Types

    /// Container for test services to avoid large tuple violation
    private struct TestServices {
        let context: ModelContext
        let container: ModelContainer
        let customFoodService: CustomFoodService
        let scheduleService: FoodScheduleService
    }

    // MARK: - Helper Methods

    private func createTestServices() -> TestServices {
        let (context, container) = CustomFoodTestHelpers.createTestContext()
        let customFoodService = CustomFoodService(context: context)
        let scheduleService = FoodScheduleService(context: context, customFoodService: customFoodService)
        return TestServices(
            context: context,
            container: container,
            customFoodService: customFoodService,
            scheduleService: scheduleService
        )
    }
}
