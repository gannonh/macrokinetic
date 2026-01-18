//
//  FoodScheduleTests.swift
//  JabTrackerTests
//
//  Unit tests for FoodSchedule model.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("FoodSchedule Tests")
struct FoodScheduleTests {

    // MARK: - Test Helpers

    func createTestSchedule(
        startDate: Date? = nil,
        endDate: Date? = nil,
        isActive: Bool = true,
        config: ScheduleConfig? = nil
    ) -> FoodSchedule {
        let schedule = FoodSchedule(
            foodId: UUID(),
            foodName: "Test Food",
            foodBrand: "Test Brand",
            servingGrams: 150.0,
            servingDescription: "1 cup",
            caloriesPer100g: 200.0,
            proteinPer100g: 10.0,
            carbsPer100g: 25.0,
            fatPer100g: 8.0,
            fiberPer100g: 3.0,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive
        )
        if let config = config {
            schedule.scheduleConfig = config
        }
        return schedule
    }

    // MARK: - Initialization Tests

    @Test("model initializes with default values")
    func testDefaultInit() {
        let schedule = FoodSchedule()

        #expect(schedule.id.uuidString.isEmpty == false)  // Has a valid UUID
        #expect(schedule.foodName == "")
        #expect(schedule.foodBrand == "")
        #expect(schedule.servingGrams == 100.0)
        #expect(schedule.isActive == true)
        #expect(schedule.scheduleConfigData.isEmpty)
        #expect(schedule.startDate == nil)
        #expect(schedule.endDate == nil)
    }

    @Test("model initializes with provided values")
    func testCustomInit() {
        let id = UUID()
        let foodId = UUID()
        let startDate = Date()
        let endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)

        let schedule = FoodSchedule(
            id: id,
            foodId: foodId,
            foodName: "Oatmeal",
            foodBrand: "Quaker",
            servingGrams: 50.0,
            servingDescription: "1/2 cup dry",
            caloriesPer100g: 379.0,
            proteinPer100g: 13.0,
            carbsPer100g: 68.0,
            fatPer100g: 6.5,
            fiberPer100g: 10.0,
            startDate: startDate,
            endDate: endDate,
            isActive: true
        )

        #expect(schedule.id == id)
        #expect(schedule.foodId == foodId)
        #expect(schedule.foodName == "Oatmeal")
        #expect(schedule.foodBrand == "Quaker")
        #expect(schedule.servingGrams == 50.0)
        #expect(schedule.caloriesPer100g == 379.0)
        #expect(schedule.startDate == startDate)
        #expect(schedule.endDate == endDate)
    }

    // MARK: - Schedule Config Tests

    @Test("scheduleConfig computed property encodes and decodes correctly")
    func testScheduleConfigRoundTrip() {
        let schedule = FoodSchedule()

        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast),
            ScheduleDayMealConfig(day: .wednesday, meal: .lunch),
            ScheduleDayMealConfig(day: .friday, meal: .dinner),
        ])

        schedule.scheduleConfig = config

        // Verify it was encoded
        #expect(!schedule.scheduleConfigData.isEmpty)

        // Verify it can be decoded
        let decoded = schedule.scheduleConfig
        #expect(decoded != nil)
        #expect(decoded?.dayMealConfigs.count == 3)
        #expect(decoded?.isScheduled(day: .monday, meal: .breakfast) == true)
        #expect(decoded?.isScheduled(day: .wednesday, meal: .lunch) == true)
        #expect(decoded?.isScheduled(day: .friday, meal: .dinner) == true)
    }

    @Test("scheduleConfig returns nil for empty data")
    func testScheduleConfigEmptyData() {
        let schedule = FoodSchedule()

        // Default is empty data
        #expect(schedule.scheduleConfig == nil)
    }

    @Test("setting scheduleConfig to nil clears data")
    func testScheduleConfigSetNil() {
        let schedule = FoodSchedule()

        // Set a config
        schedule.scheduleConfig = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])
        #expect(!schedule.scheduleConfigData.isEmpty)

        // Set to nil
        schedule.scheduleConfig = nil
        #expect(schedule.scheduleConfigData.isEmpty)
    }

    @Test("scheduleConfig getter handles corrupted JSON data gracefully")
    func testScheduleConfigCorruptedData() {
        let schedule = FoodSchedule()

        // Set corrupted JSON data that will fail to decode
        let invalidJSON = Data("{invalid json".utf8)
        schedule.scheduleConfigData = invalidJSON

        // Should return nil and log error instead of crashing
        let config = schedule.scheduleConfig
        #expect(config == nil)
    }

    // MARK: - appliesTo Tests

    @Test("appliesTo returns false when isActive is false")
    func testAppliesToInactive() {
        let schedule = createTestSchedule(isActive: false)
        let today = Date()

        #expect(schedule.appliesTo(date: today) == false)
    }

    @Test("appliesTo respects startDate - returns false if date before start")
    func testAppliesToBeforeStartDate() {
        let tomorrow = Date().addingTimeInterval(24 * 60 * 60)
        let schedule = createTestSchedule(startDate: tomorrow)
        let today = Date()

        #expect(schedule.appliesTo(date: today) == false)
    }

    @Test("appliesTo respects endDate - returns false if date after end")
    func testAppliesToAfterEndDate() {
        let yesterday = Date().addingTimeInterval(-24 * 60 * 60)
        let schedule = createTestSchedule(endDate: yesterday)
        let today = Date()

        #expect(schedule.appliesTo(date: today) == false)
    }

    @Test("appliesTo returns true when date is within range")
    func testAppliesToWithinRange() {
        let yesterday = Date().addingTimeInterval(-24 * 60 * 60)
        let tomorrow = Date().addingTimeInterval(24 * 60 * 60)
        let schedule = createTestSchedule(startDate: yesterday, endDate: tomorrow)
        let today = Date()

        #expect(schedule.appliesTo(date: today) == true)
    }

    @Test("appliesTo returns true when no date constraints")
    func testAppliesToNoConstraints() {
        let schedule = createTestSchedule()
        let today = Date()

        #expect(schedule.appliesTo(date: today) == true)
    }

    @Test("appliesTo handles same-day startDate correctly")
    func testAppliesToSameDayStart() {
        let today = Date()
        let schedule = createTestSchedule(startDate: today)

        #expect(schedule.appliesTo(date: today) == true)
    }

    @Test("appliesTo handles same-day endDate correctly")
    func testAppliesToSameDayEnd() {
        let today = Date()
        let schedule = createTestSchedule(endDate: today)

        #expect(schedule.appliesTo(date: today) == true)
    }

    // MARK: - scheduledMeals Tests

    @Test("scheduledMeals returns correct meals for matching day of week")
    func testScheduledMealsMatchingDay() {
        // Create a schedule for Monday breakfast and lunch
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast),
            ScheduleDayMealConfig(day: .monday, meal: .lunch),
        ])
        let schedule = createTestSchedule(config: config)

        // Find a Monday
        let monday = findDate(dayOfWeek: .monday)
        let meals = schedule.scheduledMeals(for: monday)

        #expect(meals.count == 2)
        #expect(meals.contains(.breakfast))
        #expect(meals.contains(.lunch))
    }

    @Test("scheduledMeals returns empty array when date doesn't match any scheduled day")
    func testScheduledMealsNoMatch() {
        // Create a schedule for Monday only
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])
        let schedule = createTestSchedule(config: config)

        // Find a Tuesday
        let tuesday = findDate(dayOfWeek: .tuesday)
        let meals = schedule.scheduledMeals(for: tuesday)

        #expect(meals.isEmpty)
    }

    @Test("scheduledMeals returns empty when schedule is inactive")
    func testScheduledMealsInactive() {
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])
        let schedule = createTestSchedule(isActive: false, config: config)

        let monday = findDate(dayOfWeek: .monday)
        let meals = schedule.scheduledMeals(for: monday)

        #expect(meals.isEmpty)
    }

    @Test("scheduledMeals returns empty when date is outside range")
    func testScheduledMealsOutsideRange() {
        let yesterday = Date().addingTimeInterval(-24 * 60 * 60)
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])
        let schedule = createTestSchedule(endDate: yesterday, config: config)

        let monday = findDate(dayOfWeek: .monday)
        let meals = schedule.scheduledMeals(for: monday)

        #expect(meals.isEmpty)
    }

    @Test("scheduledMeals returns empty when no config set")
    func testScheduledMealsNoConfig() {
        let schedule = createTestSchedule()
        let monday = findDate(dayOfWeek: .monday)
        let meals = schedule.scheduledMeals(for: monday)

        #expect(meals.isEmpty)
    }

    // MARK: - updatedAt Tests

    @Test("updatedAt is set when scheduleConfig changes")
    func testUpdatedAtChanges() {
        let schedule = FoodSchedule()
        let originalUpdatedAt = schedule.updatedAt

        // Wait a small amount to ensure time difference
        Thread.sleep(forTimeInterval: 0.01)

        schedule.scheduleConfig = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])

        #expect(schedule.updatedAt > originalUpdatedAt)
    }

    // MARK: - Helper Methods

    /// Find the next occurrence of a specific day of week
    func findDate(dayOfWeek: ScheduleDay) -> Date {
        let calendar = Calendar.current
        var date = Date()

        // Find the next occurrence of the specified day
        while calendar.component(.weekday, from: date) != dayOfWeek.rawValue {
            date = date.addingTimeInterval(24 * 60 * 60)
        }

        return date
    }
}
