//
//  CalorieAdjustmentProviderTests.swift
//  JabTrackerTests
//
//  Tests for calorie adjustment provider (rollover calories).
//

import SwiftData
import XCTest

@testable import JabTracker

@MainActor
final class CalorieAdjustmentProviderTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var user: User!
    var mockNutritionDataSource: MockNutritionDataSource!

    override func setUp() async throws {
        let config = InMemoryTestStore.configuration()
        container = try ModelContainer(for: User.self, FoodEntry.self, configurations: config)
        context = container.mainContext
        user = User()
        context.insert(user)

        mockNutritionDataSource = MockNutritionDataSource()
    }

    override func tearDown() {
        container = nil
        context = nil
        user = nil
        mockNutritionDataSource = nil
    }

    // MARK: - Feature Flag Tests

    func testRollover_WhenDisabled_ReturnsZero() async {
        // Given
        user.rolloverCaloriesEnabled = false
        mockNutritionDataSource.dailyTotals = DailyNutritionTotals(
            calories: 1500, protein: 0, carbs: 0, fat: 0, fiber: 0
        )
        mockNutritionDataSource.baseCalorieTarget = 2000.0

        let provider = RolloverCalorieProvider(nutritionDataSource: mockNutritionDataSource)

        // When
        let rollover = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        XCTAssertEqual(rollover, 0.0, "Should return 0 when feature disabled")
    }

    // MARK: - Rollover Calculation Tests

    func testRollover_WhenNoDeficit_ReturnsZero() async {
        // Given: User consumed 2000, target was 2000 (no deficit)
        user.rolloverCaloriesEnabled = true
        mockNutritionDataSource.dailyTotals = DailyNutritionTotals(
            calories: 2000, protein: 0, carbs: 0, fat: 0, fiber: 0
        )
        mockNutritionDataSource.baseCalorieTarget = 2000.0

        let provider = RolloverCalorieProvider(nutritionDataSource: mockNutritionDataSource)

        // When
        let rollover = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        XCTAssertEqual(rollover, 0.0, "Should return 0 when no deficit")
    }

    func testRollover_WhenOverBudget_ReturnsZero() async {
        // Given: User consumed 2500, target was 2000 (over budget)
        user.rolloverCaloriesEnabled = true
        mockNutritionDataSource.dailyTotals = DailyNutritionTotals(
            calories: 2500, protein: 0, carbs: 0, fat: 0, fiber: 0
        )
        mockNutritionDataSource.baseCalorieTarget = 2000.0

        let provider = RolloverCalorieProvider(nutritionDataSource: mockNutritionDataSource)

        // When
        let rollover = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        XCTAssertEqual(rollover, 0.0, "Should return 0 when over budget")
    }

    func testRollover_WhenUnderBudget_ReturnsUnusedCalories() async {
        // Given: User consumed 1850, target was 2000 (150 unused)
        user.rolloverCaloriesEnabled = true
        mockNutritionDataSource.dailyTotals = DailyNutritionTotals(
            calories: 1850, protein: 0, carbs: 0, fat: 0, fiber: 0
        )
        mockNutritionDataSource.baseCalorieTarget = 2000.0

        let provider = RolloverCalorieProvider(nutritionDataSource: mockNutritionDataSource)

        // When
        let rollover = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        XCTAssertEqual(rollover, 150.0, "Should return unused calories")
    }

    func testRollover_CappedAt200() async {
        // Given: User consumed 1500, target was 2000 (500 unused, but capped at 200)
        user.rolloverCaloriesEnabled = true
        mockNutritionDataSource.dailyTotals = DailyNutritionTotals(
            calories: 1500, protein: 0, carbs: 0, fat: 0, fiber: 0
        )
        mockNutritionDataSource.baseCalorieTarget = 2000.0

        let provider = RolloverCalorieProvider(nutritionDataSource: mockNutritionDataSource)

        // When
        let rollover = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        XCTAssertEqual(rollover, 200.0, "Should cap rollover at 200 kcal")
    }

    // MARK: - Edge Cases

    func testRollover_WhenDataFetchFails_ReturnsZero() async {
        // Given: Data source throws an error
        user.rolloverCaloriesEnabled = true
        mockNutritionDataSource.shouldThrowError = true

        let provider = RolloverCalorieProvider(nutritionDataSource: mockNutritionDataSource)

        // When
        let rollover = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        XCTAssertEqual(rollover, 0.0, "Should return 0 when data fetch fails")
    }

    func testRollover_UsesYesterdaysData() async {
        // Given
        user.rolloverCaloriesEnabled = true
        mockNutritionDataSource.dailyTotals = DailyNutritionTotals(
            calories: 1900, protein: 0, carbs: 0, fat: 0, fiber: 0
        )
        mockNutritionDataSource.baseCalorieTarget = 2000.0

        let provider = RolloverCalorieProvider(nutritionDataSource: mockNutritionDataSource)
        let today = Date()

        // When
        _ = await provider.calculateAdjustment(for: user, on: today)

        // Then
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: today))!
        XCTAssertEqual(mockNutritionDataSource.lastRequestedDate, yesterday, "Should query yesterday's data")
    }

    func testRollover_ExactlyAt200Threshold() async {
        // Given: User consumed 1800, target was 2000 (exactly 200 unused)
        user.rolloverCaloriesEnabled = true
        mockNutritionDataSource.dailyTotals = DailyNutritionTotals(
            calories: 1800, protein: 0, carbs: 0, fat: 0, fiber: 0
        )
        mockNutritionDataSource.baseCalorieTarget = 2000.0

        let provider = RolloverCalorieProvider(nutritionDataSource: mockNutritionDataSource)

        // When
        let rollover = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        XCTAssertEqual(rollover, 200.0, "Should return exactly 200 when at cap threshold")
    }
}

// MARK: - Mock Nutrition Data Source

@MainActor
final class MockNutritionDataSource: NutritionDataSource {
    var dailyTotals: DailyNutritionTotals = .zero
    var baseCalorieTarget: Double = 2000.0
    var shouldThrowError: Bool = false
    var lastRequestedDate: Date?

    func getDailyTotals(for date: Date) async throws -> DailyNutritionTotals {
        lastRequestedDate = date
        if shouldThrowError {
            throw NSError(domain: "test", code: 1)
        }
        return dailyTotals
    }

    func getBaseCalorieTarget(for user: User, on date: Date) -> Double {
        baseCalorieTarget
    }
}
