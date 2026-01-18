//
//  ScheduleConfigurationTests.swift
//  JabTrackerTests
//
//  Unit tests for schedule configuration value types.
//

import Foundation
import Testing

@testable import JabTracker

@Suite("ScheduleDay Tests")
struct ScheduleDayTests {
    @Test("rawValues match Calendar weekday convention")
    func testRawValuesMatchCalendarWeekday() {
        // Calendar.component(.weekday) returns 1=Sunday through 7=Saturday
        #expect(ScheduleDay.sunday.rawValue == 1)
        #expect(ScheduleDay.monday.rawValue == 2)
        #expect(ScheduleDay.tuesday.rawValue == 3)
        #expect(ScheduleDay.wednesday.rawValue == 4)
        #expect(ScheduleDay.thursday.rawValue == 5)
        #expect(ScheduleDay.friday.rawValue == 6)
        #expect(ScheduleDay.saturday.rawValue == 7)
    }

    @Test("displayName returns full day names")
    func testDisplayName() {
        #expect(ScheduleDay.sunday.displayName == "Sunday")
        #expect(ScheduleDay.monday.displayName == "Monday")
        #expect(ScheduleDay.tuesday.displayName == "Tuesday")
        #expect(ScheduleDay.wednesday.displayName == "Wednesday")
        #expect(ScheduleDay.thursday.displayName == "Thursday")
        #expect(ScheduleDay.friday.displayName == "Friday")
        #expect(ScheduleDay.saturday.displayName == "Saturday")
    }

    @Test("shortName returns three-letter abbreviations")
    func testShortName() {
        #expect(ScheduleDay.sunday.shortName == "Sun")
        #expect(ScheduleDay.monday.shortName == "Mon")
        #expect(ScheduleDay.tuesday.shortName == "Tue")
        #expect(ScheduleDay.wednesday.shortName == "Wed")
        #expect(ScheduleDay.thursday.shortName == "Thu")
        #expect(ScheduleDay.friday.shortName == "Fri")
        #expect(ScheduleDay.saturday.shortName == "Sat")
    }

    @Test("all cases are iterable")
    func testCaseIterable() {
        #expect(ScheduleDay.allCases.count == 7)
    }

    @Test("id returns rawValue for Identifiable conformance")
    func testIdentifiable() {
        #expect(ScheduleDay.monday.id == 2)
        #expect(ScheduleDay.friday.id == 6)
    }
}

@Suite("ScheduleDayMealConfig Tests")
struct ScheduleDayMealConfigTests {
    @Test("initializes with day and meal")
    func testInit() {
        let config = ScheduleDayMealConfig(day: .monday, meal: .breakfast)

        #expect(config.day == .monday)
        #expect(config.meal == .breakfast)
        #expect(config.id != UUID())  // Has a UUID
    }

    @Test("encodes and decodes correctly via JSON round-trip")
    func testJSONRoundTrip() throws {
        let original = ScheduleDayMealConfig(day: .wednesday, meal: .lunch)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ScheduleDayMealConfig.self, from: data)

        #expect(decoded.day == original.day)
        #expect(decoded.meal == original.meal)
        #expect(decoded.id == original.id)
    }

    @Test("equatable compares all properties")
    func testEquatable() {
        let id = UUID()
        let config1 = ScheduleDayMealConfig(id: id, day: .monday, meal: .dinner)
        let config2 = ScheduleDayMealConfig(id: id, day: .monday, meal: .dinner)
        let config3 = ScheduleDayMealConfig(id: id, day: .tuesday, meal: .dinner)

        #expect(config1 == config2)
        #expect(config1 != config3)
    }
}

@Suite("ScheduleConfig Tests")
struct ScheduleConfigTests {
    @Test("meals(for:) returns correct meals for each day")
    func testMealsForDay() {
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast),
            ScheduleDayMealConfig(day: .monday, meal: .lunch),
            ScheduleDayMealConfig(day: .wednesday, meal: .dinner),
            ScheduleDayMealConfig(day: .friday, meal: .breakfast),
        ])

        let mondayMeals = config.meals(for: .monday)
        #expect(mondayMeals.count == 2)
        #expect(mondayMeals.contains(.breakfast))
        #expect(mondayMeals.contains(.lunch))

        let wednesdayMeals = config.meals(for: .wednesday)
        #expect(wednesdayMeals.count == 1)
        #expect(wednesdayMeals.contains(.dinner))

        let fridayMeals = config.meals(for: .friday)
        #expect(fridayMeals.count == 1)
        #expect(fridayMeals.contains(.breakfast))

        let tuesdayMeals = config.meals(for: .tuesday)
        #expect(tuesdayMeals.isEmpty)
    }

    @Test("isScheduled correctly identifies configured day/meal pairs")
    func testIsScheduled() {
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast),
            ScheduleDayMealConfig(day: .wednesday, meal: .dinner),
        ])

        #expect(config.isScheduled(day: .monday, meal: .breakfast) == true)
        #expect(config.isScheduled(day: .wednesday, meal: .dinner) == true)
        #expect(config.isScheduled(day: .monday, meal: .lunch) == false)
        #expect(config.isScheduled(day: .tuesday, meal: .breakfast) == false)
    }

    @Test("isValid returns false for empty configs, true otherwise")
    func testIsValid() {
        let emptyConfig = ScheduleConfig(dayMealConfigs: [])
        #expect(emptyConfig.isValid == false)

        let validConfig = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast)
        ])
        #expect(validConfig.isValid == true)
    }

    @Test("scheduledDays returns unique days")
    func testScheduledDays() {
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast),
            ScheduleDayMealConfig(day: .monday, meal: .lunch),
            ScheduleDayMealConfig(day: .friday, meal: .dinner),
        ])

        let days = config.scheduledDays
        #expect(days.count == 2)
        #expect(days.contains(.monday))
        #expect(days.contains(.friday))
    }

    @Test("scheduledMeals returns unique meals")
    func testScheduledMeals() {
        let config = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast),
            ScheduleDayMealConfig(day: .wednesday, meal: .breakfast),
            ScheduleDayMealConfig(day: .friday, meal: .dinner),
        ])

        let meals = config.scheduledMeals
        #expect(meals.count == 2)
        #expect(meals.contains(.breakfast))
        #expect(meals.contains(.dinner))
    }

    @Test("JSON round-trip preserves all data")
    func testJSONRoundTrip() throws {
        let original = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(day: .monday, meal: .breakfast),
            ScheduleDayMealConfig(day: .wednesday, meal: .lunch),
            ScheduleDayMealConfig(day: .friday, meal: .dinner),
        ])

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ScheduleConfig.self, from: data)

        #expect(decoded == original)
        #expect(decoded.dayMealConfigs.count == 3)
    }

    @Test("equatable works correctly")
    func testEquatable() {
        let config1 = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(id: UUID(), day: .monday, meal: .breakfast)
        ])
        let config2 = ScheduleConfig(dayMealConfigs: [
            ScheduleDayMealConfig(id: UUID(), day: .monday, meal: .breakfast)
        ])
        let config3 = ScheduleConfig(dayMealConfigs: [])

        // Different UUIDs so not equal
        #expect(config1 != config2)
        #expect(config1 != config3)
    }
}
