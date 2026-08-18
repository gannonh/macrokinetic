//
//  PredictiveActivityProviderTests.swift
//  JabTrackerTests
//
//  Tests for predictive activity adjustment provider.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

@Suite("PredictiveActivityProvider Tests")
@MainActor
struct PredictiveActivityProviderTests {

    // MARK: - Test Setup

    var container: ModelContainer!
    var context: ModelContext!
    var user: User!
    var mockDataSource: MockActiveEnergyDataSource!

    init() throws {
        let config = InMemoryTestStore.configuration()
        container = try ModelContainer(for: User.self, NutritionGoal.self, configurations: config)
        context = container.mainContext
        user = User()
        context.insert(user)
        mockDataSource = MockActiveEnergyDataSource()
    }

    // MARK: - Test Helpers

    /// Set up uniform energy history for the 7 days ending yesterday
    /// (Provider uses days before the target date to avoid overlap with burned calories)
    private mutating func setUpHistoryEndingYesterday(value: Double, days: Int = 7) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }

        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: yesterday) else { continue }
            mockDataSource.energyByDate[date] = value
        }
    }

    /// Set up specific energy values for days ending yesterday
    private mutating func setUpHistoryEndingYesterday(values: [Double]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }

        for (offset, value) in values.enumerated() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: yesterday) else { continue }
            mockDataSource.energyByDate[date] = value
        }
    }

    // MARK: - Feature Flag Tests

    @Test("Returns 0 when predictiveActivityEnabled is false")
    mutating func testReturnsZero_WhenDisabled() async {
        // Given
        user.predictiveActivityEnabled = false
        user.addBurnedCaloriesEnabled = false
        setUpHistoryEndingYesterday(value: 400.0)

        let provider = PredictiveActivityProvider(activeEnergyDataSource: mockDataSource)

        // When
        let result = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        #expect(result == 0.0, "Should return 0 when feature disabled")
    }

    @Test("Returns 0 when addBurnedCaloriesEnabled is true (mutual exclusivity)")
    mutating func testReturnsZero_WhenBurnedCaloriesEnabled() async {
        // Given: Both features enabled - predictive should skip to avoid double-counting
        user.predictiveActivityEnabled = true
        user.addBurnedCaloriesEnabled = true
        setUpHistoryEndingYesterday(value: 400.0)

        let provider = PredictiveActivityProvider(activeEnergyDataSource: mockDataSource)

        // When
        let result = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        #expect(result == 0.0, "Should return 0 when burned calories enabled to avoid double-counting")
    }

    // MARK: - Empty History Tests

    @Test("Returns 0 when history is empty")
    mutating func testReturnsZero_WhenHistoryEmpty() async {
        // Given
        user.predictiveActivityEnabled = true
        user.addBurnedCaloriesEnabled = false
        // Don't populate any history

        let provider = PredictiveActivityProvider(activeEnergyDataSource: mockDataSource)

        // When
        let result = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        #expect(result == 0.0, "Should return 0 when no history data available")
    }

    // MARK: - Average Calculation Tests

    @Test("Calculates 7-day average correctly")
    mutating func testCalculates7DayAverage() async {
        // Given: History with known values [100,200,300,400,500,600,700] -> avg 400
        user.predictiveActivityEnabled = true
        user.addBurnedCaloriesEnabled = false
        setUpHistoryEndingYesterday(values: [100, 200, 300, 400, 500, 600, 700])

        // No goal set - should use maintenance multiplier (1.0)
        let provider = PredictiveActivityProvider(activeEnergyDataSource: mockDataSource)

        // When
        let result = await provider.calculateAdjustment(for: user, on: Date())

        // Then: Average is 400, maintenance multiplier is 1.0, so result should be 400
        #expect(result == 400.0, "Should calculate correct 7-day average (400 * 1.0 = 400)")
    }

    // MARK: - Goal Multiplier Tests

    @Test("Applies 0.8 multiplier for weightLoss goal")
    mutating func testAppliesWeightLossMultiplier() async {
        // Given: 400 average, weightLoss goal -> 400 * 0.8 = 320
        user.predictiveActivityEnabled = true
        user.addBurnedCaloriesEnabled = false

        let goal = NutritionGoal(goalType: .weightLoss)
        goal.isActive = true
        goal.user = user
        context.insert(goal)

        setUpHistoryEndingYesterday(value: 400.0)

        let provider = PredictiveActivityProvider(activeEnergyDataSource: mockDataSource)

        // When
        let result = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        #expect(result == 320.0, "Should apply 0.8 multiplier for weightLoss (400 * 0.8 = 320)")
    }

    @Test("Applies 1.0 multiplier for maintenance goal")
    mutating func testAppliesMaintenanceMultiplier() async {
        // Given: 400 average, maintenance goal -> 400 * 1.0 = 400
        user.predictiveActivityEnabled = true
        user.addBurnedCaloriesEnabled = false

        let goal = NutritionGoal(goalType: .maintenance)
        goal.isActive = true
        goal.user = user
        context.insert(goal)

        setUpHistoryEndingYesterday(value: 400.0)

        let provider = PredictiveActivityProvider(activeEnergyDataSource: mockDataSource)

        // When
        let result = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        #expect(result == 400.0, "Should apply 1.0 multiplier for maintenance (400 * 1.0 = 400)")
    }

    @Test("Applies 1.2 multiplier for muscleGain goal")
    mutating func testAppliesMuscleGainMultiplier() async {
        // Given: 400 average, muscleGain goal -> 400 * 1.2 = 480
        user.predictiveActivityEnabled = true
        user.addBurnedCaloriesEnabled = false

        let goal = NutritionGoal(goalType: .muscleGain)
        goal.isActive = true
        goal.user = user
        context.insert(goal)

        setUpHistoryEndingYesterday(value: 400.0)

        let provider = PredictiveActivityProvider(activeEnergyDataSource: mockDataSource)

        // When
        let result = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        #expect(result == 480.0, "Should apply 1.2 multiplier for muscleGain (400 * 1.2 = 480)")
    }

    // MARK: - Partial History Tests

    @Test("Handles partial history gracefully (fewer than 7 days)")
    mutating func testHandlesPartialHistory() async {
        // Given: Only 3 days of history [300, 400, 500] -> avg 400
        user.predictiveActivityEnabled = true
        user.addBurnedCaloriesEnabled = false
        setUpHistoryEndingYesterday(values: [300, 400, 500])

        let provider = PredictiveActivityProvider(activeEnergyDataSource: mockDataSource)

        // When
        let result = await provider.calculateAdjustment(for: user, on: Date())

        // Then: Average of 3 values is 400, maintenance multiplier is 1.0
        #expect(result == 400.0, "Should calculate average from available history (400 * 1.0 = 400)")
    }

    @Test("Uses 1.0 multiplier when no active goal")
    mutating func testUsesDefaultMultiplierWithoutGoal() async {
        // Given: No active nutrition goal
        user.predictiveActivityEnabled = true
        user.addBurnedCaloriesEnabled = false
        setUpHistoryEndingYesterday(value: 500.0)

        let provider = PredictiveActivityProvider(activeEnergyDataSource: mockDataSource)

        // When
        let result = await provider.calculateAdjustment(for: user, on: Date())

        // Then: Should use maintenance multiplier (1.0) as default
        #expect(result == 500.0, "Should use 1.0 multiplier when no active goal (500 * 1.0 = 500)")
    }
}
