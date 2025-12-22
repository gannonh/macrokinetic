//
//  MealSectionTests.swift
//  JabTrackerTests
//
//  Tests for MealSection enum - meal categorization for food entries.
//

import Foundation
import Testing

@testable import JabTracker

struct MealSectionTests {

    // MARK: - Case Existence Tests

    @Test("All meal section cases exist")
    func testAllCases() {
        #expect(MealSection.allCases.count == 4)
        #expect(MealSection.allCases.contains(.breakfast))
        #expect(MealSection.allCases.contains(.lunch))
        #expect(MealSection.allCases.contains(.dinner))
        #expect(MealSection.allCases.contains(.snacks))
    }

    // MARK: - Display Name Tests

    @Test("Breakfast displayName returns correct value")
    func testBreakfastDisplayName() {
        #expect(MealSection.breakfast.displayName == "Breakfast")
    }

    @Test("Lunch displayName returns correct value")
    func testLunchDisplayName() {
        #expect(MealSection.lunch.displayName == "Lunch")
    }

    @Test("Dinner displayName returns correct value")
    func testDinnerDisplayName() {
        #expect(MealSection.dinner.displayName == "Dinner")
    }

    @Test("Snacks displayName returns correct value")
    func testSnacksDisplayName() {
        #expect(MealSection.snacks.displayName == "Snacks")
    }

    // MARK: - Icon Tests

    @Test("Breakfast icon returns sunrise SF Symbol")
    func testBreakfastIcon() {
        #expect(MealSection.breakfast.icon == "sunrise.fill")
    }

    @Test("Lunch icon returns sun SF Symbol")
    func testLunchIcon() {
        #expect(MealSection.lunch.icon == "sun.max.fill")
    }

    @Test("Dinner icon returns moon SF Symbol")
    func testDinnerIcon() {
        #expect(MealSection.dinner.icon == "moon.stars.fill")
    }

    @Test("Snacks icon returns leaf SF Symbol")
    func testSnacksIcon() {
        #expect(MealSection.snacks.icon == "leaf.fill")
    }

    // MARK: - Default Time Range Tests

    @Test("Breakfast default time range is 5-10")
    func testBreakfastTimeRange() {
        #expect(MealSection.breakfast.defaultTimeRange == 5...10)
    }

    @Test("Lunch default time range is 11-14")
    func testLunchTimeRange() {
        #expect(MealSection.lunch.defaultTimeRange == 11...14)
    }

    @Test("Dinner default time range is 17-21")
    func testDinnerTimeRange() {
        #expect(MealSection.dinner.defaultTimeRange == 17...21)
    }

    @Test("Snacks default time range is 0-23 (any time)")
    func testSnacksTimeRange() {
        #expect(MealSection.snacks.defaultTimeRange == 0...23)
    }

    // MARK: - From Date Tests

    @Test("from(date:) returns breakfast for 5 AM")
    func testFromDateBreakfastStart() {
        let date = createDate(hour: 5)
        #expect(MealSection.from(date: date) == .breakfast)
    }

    @Test("from(date:) returns breakfast for 10 AM")
    func testFromDateBreakfastEnd() {
        let date = createDate(hour: 10)
        #expect(MealSection.from(date: date) == .breakfast)
    }

    @Test("from(date:) returns lunch for 11 AM")
    func testFromDateLunchStart() {
        let date = createDate(hour: 11)
        #expect(MealSection.from(date: date) == .lunch)
    }

    @Test("from(date:) returns lunch for 2 PM")
    func testFromDateLunchEnd() {
        let date = createDate(hour: 14)
        #expect(MealSection.from(date: date) == .lunch)
    }

    @Test("from(date:) returns dinner for 5 PM")
    func testFromDateDinnerStart() {
        let date = createDate(hour: 17)
        #expect(MealSection.from(date: date) == .dinner)
    }

    @Test("from(date:) returns dinner for 9 PM")
    func testFromDateDinnerEnd() {
        let date = createDate(hour: 21)
        #expect(MealSection.from(date: date) == .dinner)
    }

    @Test("from(date:) returns snacks for midnight")
    func testFromDateSnacksMidnight() {
        let date = createDate(hour: 0)
        #expect(MealSection.from(date: date) == .snacks)
    }

    @Test("from(date:) returns snacks for 3 AM")
    func testFromDateSnacksEarlyMorning() {
        let date = createDate(hour: 3)
        #expect(MealSection.from(date: date) == .snacks)
    }

    @Test("from(date:) returns snacks for 3 PM (gap between lunch and dinner)")
    func testFromDateSnacksAfternoonGap() {
        let date = createDate(hour: 15)
        #expect(MealSection.from(date: date) == .snacks)
    }

    @Test("from(date:) returns snacks for 10 PM")
    func testFromDateSnacksLateNight() {
        let date = createDate(hour: 22)
        #expect(MealSection.from(date: date) == .snacks)
    }

    // MARK: - Identifiable Tests

    @Test("id returns rawValue for each case")
    func testIdentifiable() {
        #expect(MealSection.breakfast.id == "breakfast")
        #expect(MealSection.lunch.id == "lunch")
        #expect(MealSection.dinner.id == "dinner")
        #expect(MealSection.snacks.id == "snacks")
    }

    // MARK: - Codable Tests

    @Test("MealSection encodes and decodes correctly")
    func testCodableRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for section in MealSection.allCases {
            let data = try encoder.encode(section)
            let decoded = try decoder.decode(MealSection.self, from: data)
            #expect(decoded == section)
        }
    }

    @Test("MealSection decodes from raw string value")
    func testDecodeFromRawString() throws {
        let decoder = JSONDecoder()

        let breakfastData = Data("\"breakfast\"".utf8)
        let decoded = try decoder.decode(MealSection.self, from: breakfastData)
        #expect(decoded == .breakfast)
    }

    // MARK: - Helpers

    private func createDate(hour: Int) -> Date {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 1
        components.hour = hour
        components.minute = 0
        return Calendar.current.date(from: components)!
    }
}
