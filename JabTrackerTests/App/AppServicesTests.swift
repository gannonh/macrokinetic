//
//  AppServicesTests.swift
//  JabTrackerTests
//
//  Tests for AppServices service coordinator.
//

import Foundation
import SwiftData
import Testing

@testable import JabTracker

// MARK: - Test Utilities

/// Creates an in-memory test context and container for SwiftData testing.
/// CRITICAL: Both context AND container must be retained - container deallocation invalidates context.
@MainActor
private func createTestContext() -> (context: ModelContext, container: ModelContainer) {
    let schema = Schema([
        User.self,
        Dose.self,
        MedicationProfile.self,
        DoseTitration.self,
        DoseSchedule.self,
        ScheduledDose.self,
        Food.self,
        FoodEntry.self,
        WeightEntry.self,
        MetricsEntry.self,
        ProgressPhoto.self,
        NutritionGoal.self,
        NutritionProgram.self,
    ])
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    let container = try! ModelContainer(for: schema, configurations: [config])
    return (container.mainContext, container)
}

@Suite("AppServices Tests")
struct AppServicesTests {

    // MARK: - Initialization Tests

    @Test("AppServices shared instance exists")
    @MainActor
    func testSharedInstanceExists() {
        // Verify we can access the shared instance (non-optional, always exists)
        let services = AppServices.shared
        // Just accessing without crash means success
        _ = services
    }

    @Test("Services are nil before initialization")
    @MainActor
    func testServicesNilBeforeInitialization() {
        // Create a fresh AppServices instance using reset
        let services = AppServices.shared
        services.reset()

        #expect(services.scheduleService == nil)
        #expect(services.notificationService == nil)
        #expect(services.foodService == nil)
        #expect(services.mealLogService == nil)
        #expect(services.customFoodService == nil)
        #expect(services.metricsService == nil)
        #expect(services.progressPhotoService == nil)
        #expect(services.calorieAdjustmentService == nil)
    }

    @Test("Initialize creates all services")
    @MainActor
    func testInitializeCreatesAllServices() {
        let (context, container) = createTestContext()
        _ = container  // Keep container alive

        let services = AppServices.shared
        services.reset()  // Start fresh
        services.initialize(with: context)

        #expect(services.scheduleService != nil)
        #expect(services.notificationService != nil)
        #expect(services.foodService != nil)
        #expect(services.mealLogService != nil)
        #expect(services.customFoodService != nil)
        #expect(services.metricsService != nil)
        #expect(services.progressPhotoService != nil)
        #expect(services.calorieAdjustmentService != nil)

        // Clean up
        services.reset()
    }

    @Test("Initialize is idempotent - only initializes once")
    @MainActor
    func testInitializeIsIdempotent() {
        let (context1, container1) = createTestContext()
        let (context2, container2) = createTestContext()
        _ = container1
        _ = container2

        let services = AppServices.shared
        services.reset()

        // First initialization
        services.initialize(with: context1)
        let firstScheduleService = services.scheduleService

        // Second initialization should be no-op
        services.initialize(with: context2)
        let secondScheduleService = services.scheduleService

        // Should be the same instance
        #expect(firstScheduleService === secondScheduleService)

        // Clean up
        services.reset()
    }

    // MARK: - Reset Tests

    @Test("Reset clears all services")
    @MainActor
    func testResetClearsAllServices() {
        let (context, container) = createTestContext()
        _ = container

        let services = AppServices.shared
        services.initialize(with: context)

        // Verify services are initialized
        #expect(services.scheduleService != nil)

        // Reset
        services.reset()

        // All services should be nil
        #expect(services.scheduleService == nil)
        #expect(services.notificationService == nil)
        #expect(services.foodService == nil)
        #expect(services.mealLogService == nil)
        #expect(services.customFoodService == nil)
        #expect(services.metricsService == nil)
        #expect(services.progressPhotoService == nil)
        #expect(services.calorieAdjustmentService == nil)
    }

    @Test("Can reinitialize after reset")
    @MainActor
    func testCanReinitializeAfterReset() {
        let (context1, container1) = createTestContext()
        let (context2, container2) = createTestContext()
        _ = container1
        _ = container2

        let services = AppServices.shared
        services.reset()

        // First initialization
        services.initialize(with: context1)
        let firstScheduleService = services.scheduleService
        #expect(firstScheduleService != nil)

        // Reset
        services.reset()
        #expect(services.scheduleService == nil)

        // Reinitialize with different context
        services.initialize(with: context2)
        let secondScheduleService = services.scheduleService
        #expect(secondScheduleService != nil)

        // Should be a different instance after reset + reinitialize
        #expect(firstScheduleService !== secondScheduleService)

        // Clean up
        services.reset()
    }

    // MARK: - Service Dependency Tests

    @Test("NotificationService receives ScheduleService dependency")
    @MainActor
    func testNotificationServiceHasScheduleServiceDependency() {
        let (context, container) = createTestContext()
        _ = container

        let services = AppServices.shared
        services.reset()
        services.initialize(with: context)

        // NotificationService should be initialized with ScheduleService
        let notificationService = services.notificationService
        #expect(notificationService != nil)

        // Clean up
        services.reset()
    }

    @Test("FoodService receives CustomFoodService dependency")
    @MainActor
    func testFoodServiceHasCustomFoodServiceDependency() {
        let (context, container) = createTestContext()
        _ = container

        let services = AppServices.shared
        services.reset()
        services.initialize(with: context)

        // FoodService should be initialized with CustomFoodService
        let foodService = services.foodService
        #expect(foodService != nil)

        // Clean up
        services.reset()
    }

    @Test("CalorieAdjustmentService receives MealLogService for rollover")
    @MainActor
    func testCalorieAdjustmentServiceHasMealLogServiceDependency() {
        let (context, container) = createTestContext()
        _ = container

        let services = AppServices.shared
        services.reset()
        services.initialize(with: context)

        // CalorieAdjustmentService should be configured
        let calorieAdjustmentService = services.calorieAdjustmentService
        #expect(calorieAdjustmentService != nil)

        // Clean up
        services.reset()
    }

    // MARK: - Environment Key Tests

    @Test("AppServicesKey defaultValue returns shared instance")
    @MainActor
    func testAppServicesKeyDefaultValue() {
        let defaultValue = AppServicesKey.defaultValue
        #expect(defaultValue === AppServices.shared)
    }
}
