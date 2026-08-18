//
//  CalorieAdjustmentServiceTests.swift
//  JabTrackerTests
//
//  Tests for CalorieAdjustmentService.
//

import SwiftData
import XCTest

@testable import JabTracker

@MainActor
final class CalorieAdjustmentServiceTests: XCTestCase {

    var service: CalorieAdjustmentService!
    var mockDataSource: MockActiveEnergyDataSource!
    var container: ModelContainer!
    var user: User!

    override func setUp() async throws {
        // Setup SwiftData container
        let config = InMemoryTestStore.configuration()
        container = try ModelContainer(for: User.self, configurations: config)
        user = User()
        container.mainContext.insert(user)

        // Setup Mock Data Source
        mockDataSource = MockActiveEnergyDataSource()

        // Setup Service
        service = CalorieAdjustmentService(activeEnergyDataSource: mockDataSource)
    }

    override func tearDown() {
        service = nil
        mockDataSource = nil
        container = nil
        user = nil
    }

    func testGetAdjustedCalorieTarget_WhenDisabled_ReturnsBaseTarget() async {
        // Given
        user.addBurnedCaloriesEnabled = false
        mockDataSource.todayEnergy = 500.0
        let baseTarget = 2000.0

        // When
        let result = await service.getAdjustedCalorieTarget(for: user, on: Date(), baseTarget: baseTarget)

        // Then
        XCTAssertEqual(result, baseTarget, "Should return base target when feature is disabled")
    }

    func testGetAdjustedCalorieTarget_WhenEnabled_AddsBurnedCalories() async {
        // Given
        user.addBurnedCaloriesEnabled = true
        mockDataSource.todayEnergy = 500.0
        let baseTarget = 2000.0

        // When
        let result = await service.getAdjustedCalorieTarget(for: user, on: Date(), baseTarget: baseTarget)

        // Then
        XCTAssertEqual(result, 2500.0, "Should add burned calories to base target")
    }

    func testGetAdjustedCalorieTarget_WhenEnabled_AndBurnedIsNil_ReturnsBaseTarget() async {
        // Given
        user.addBurnedCaloriesEnabled = true
        mockDataSource.todayEnergy = nil
        let baseTarget = 2000.0

        // When
        let result = await service.getAdjustedCalorieTarget(for: user, on: Date(), baseTarget: baseTarget)

        // Then
        XCTAssertEqual(result, baseTarget, "Should return base target when active energy data is missing")
    }

    func testGetAdjustedCalorieTarget_WhenEnabled_UsesCorrectDate() async {
        // Given
        user.addBurnedCaloriesEnabled = true
        let date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let normalizedDate = Calendar.current.startOfDay(for: date)

        mockDataSource.energyByDate[normalizedDate] = 300.0
        let baseTarget = 2000.0

        // When
        let result = await service.getAdjustedCalorieTarget(for: user, on: date, baseTarget: baseTarget)

        // Then
        XCTAssertEqual(result, 2300.0, "Should use data for the specific date provided")
        guard let callDate = mockDataSource.getActiveEnergyForDateCalls.first else {
            XCTFail("Should have called getActiveEnergyForDate")
            return
        }
        XCTAssertEqual(callDate, normalizedDate, "Should request energy for the correct date")
    }

    // MARK: - Adjustment Breakdown Tests

    func testGetAdjustmentBreakdown_WhenBurnedDisabled_ReturnsZeroBurned() async {
        // Given
        user.addBurnedCaloriesEnabled = false
        mockDataSource.todayEnergy = 500.0

        // When
        let breakdown = await service.getAdjustmentBreakdown(for: user, on: Date())

        // Then
        XCTAssertEqual(breakdown.burnedCalories, 0.0, "Burned should be 0 when disabled")
        XCTAssertEqual(breakdown.rolloverCalories, 0.0, "Rollover should be 0 without provider")
        XCTAssertEqual(breakdown.totalAdjustment, 0.0, "Total should be 0")
    }

    func testGetAdjustmentBreakdown_WhenBurnedEnabled_ReturnsBurned() async {
        // Given
        user.addBurnedCaloriesEnabled = true
        mockDataSource.todayEnergy = 350.0

        // When
        let breakdown = await service.getAdjustmentBreakdown(for: user, on: Date())

        // Then
        XCTAssertEqual(breakdown.burnedCalories, 350.0, "Should return burned calories")
        XCTAssertEqual(breakdown.rolloverCalories, 0.0, "Rollover should be 0 without provider")
        XCTAssertEqual(breakdown.totalAdjustment, 350.0, "Total should equal burned")
    }

    func testGetAdjustmentBreakdown_WhenBurnedNil_ReturnsZeroBurned() async {
        // Given
        user.addBurnedCaloriesEnabled = true
        mockDataSource.todayEnergy = nil

        // When
        let breakdown = await service.getAdjustmentBreakdown(for: user, on: Date())

        // Then
        XCTAssertEqual(breakdown.burnedCalories, 0.0, "Should return 0 when energy is nil")
        XCTAssertEqual(breakdown.totalAdjustment, 0.0, "Total should be 0")
    }

    // MARK: - CalorieAdjustmentBreakdown Tests

    func testCalorieAdjustmentBreakdown_TotalAdjustment() {
        // Given
        let breakdown = CalorieAdjustmentBreakdown(burnedCalories: 200, rolloverCalories: 150)

        // Then
        XCTAssertEqual(breakdown.totalAdjustment, 350.0, "Total should be sum of burned and rollover")
    }

    func testCalorieAdjustmentBreakdown_ZeroValues() {
        // Given
        let breakdown = CalorieAdjustmentBreakdown(burnedCalories: 0, rolloverCalories: 0)

        // Then
        XCTAssertEqual(breakdown.totalAdjustment, 0.0, "Total should be 0 when components are 0")
    }
}
