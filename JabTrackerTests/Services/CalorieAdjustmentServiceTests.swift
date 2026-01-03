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
        let config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
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
}
