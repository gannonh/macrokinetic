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
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        container = try ModelContainer(for: User.self, NutritionGoal.self, configurations: config)
        context = container.mainContext
        user = User()
        context.insert(user)
        mockDataSource = MockActiveEnergyDataSource()
    }

    // MARK: - Feature Flag Tests

    @Test("Returns 0 when predictiveActivityEnabled is false")
    mutating func testReturnsZero_WhenDisabled() async {
        // Given
        user.predictiveActivityEnabled = false
        mockDataSource.populateHistory(days: 7, baseValue: 400.0, variance: 0)

        let provider = PredictiveActivityProvider(activeEnergyDataSource: mockDataSource)

        // When
        let result = await provider.calculateAdjustment(for: user, on: Date())

        // Then
        #expect(result == 0.0, "Should return 0 when feature disabled")
    }

    // MARK: - Empty History Tests

    @Test("Returns 0 when history is empty")
    mutating func testReturnsZero_WhenHistoryEmpty() async {
        // Given
        user.predictiveActivityEnabled = true
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

        // Set up exact values for each of the 7 days
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let values: [Double] = [100, 200, 300, 400, 500, 600, 700]

        for (offset, value) in values.enumerated() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            mockDataSource.energyByDate[date] = value
        }
        mockDataSource.todayEnergy = values[0]

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

        let goal = NutritionGoal(goalType: .weightLoss)
        goal.isActive = true
        goal.user = user
        context.insert(goal)

        // Set up history with 400 average
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            mockDataSource.energyByDate[date] = 400.0
        }
        mockDataSource.todayEnergy = 400.0

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

        let goal = NutritionGoal(goalType: .maintenance)
        goal.isActive = true
        goal.user = user
        context.insert(goal)

        // Set up history with 400 average
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            mockDataSource.energyByDate[date] = 400.0
        }
        mockDataSource.todayEnergy = 400.0

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

        let goal = NutritionGoal(goalType: .muscleGain)
        goal.isActive = true
        goal.user = user
        context.insert(goal)

        // Set up history with 400 average
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            mockDataSource.energyByDate[date] = 400.0
        }
        mockDataSource.todayEnergy = 400.0

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

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let values: [Double] = [300, 400, 500]

        for (offset, value) in values.enumerated() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            mockDataSource.energyByDate[date] = value
        }
        mockDataSource.todayEnergy = values[0]

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

        // Set up history with 500 average
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            mockDataSource.energyByDate[date] = 500.0
        }
        mockDataSource.todayEnergy = 500.0

        let provider = PredictiveActivityProvider(activeEnergyDataSource: mockDataSource)

        // When
        let result = await provider.calculateAdjustment(for: user, on: Date())

        // Then: Should use maintenance multiplier (1.0) as default
        #expect(result == 500.0, "Should use 1.0 multiplier when no active goal (500 * 1.0 = 500)")
    }
}
