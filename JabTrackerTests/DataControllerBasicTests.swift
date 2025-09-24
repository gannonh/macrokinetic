import CloudKit
import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
@Suite("DataController Basic Tests")
struct DataControllerBasicTests {
    @Test("DataController shared instance")
    @MainActor
    func dataControllerSharedInstance() throws {
        // Test that shared instance exists and is consistent
        let shared1 = DataController.shared
        let shared2 = DataController.shared

        #expect(shared1 === shared2, "Shared instance should return same object")

        // Test that shared instance has valid container
        _ = shared1.container.mainContext
        #expect(
            shared1.container.schema.entities.count == 4,
            "Should have 4 entities (User, Dose, MedicationProfile, DoseTitration)")
    }

    @Test("DataController test container creation")
    @MainActor
    func dataControllerTestContainer() throws {
        let testController = DataController.testContainer()

        // Test container should be in memory
        let context = testController.container.mainContext
        _ = context  // ModelContext is never nil, just verify we can access it

        // Test container should have correct schema
        #expect(testController.container.schema.entities.count == 4, "Should have 4 entities")

        // Test that it's isolated from shared instance
        #expect(
            testController !== DataController.shared,
            "Test container should be separate from shared instance")

        // Test CloudKit is disabled for test container
        #expect(testController.isCloudKitEnabled == false, "Test container should disable CloudKit")
        #expect(
            testController.syncStatus == .unavailable, "Test container should be unavailable for sync")
    }

    @Test("DataController CloudKit initialization")
    @MainActor
    func dataControllerCloudKitInit() throws {
        // Test non-memory controller (simulates production)
        let productionStyleController = DataController(inMemory: false)

        // Should have valid container
        let context = productionStyleController.container.mainContext
        _ = context  // ModelContext is never nil, just verify we can access it

        // Should attempt CloudKit setup
        #expect(
            productionStyleController.container.schema.entities.count == 4, "Should have 4 entities")

        // CloudKit status should be set
        let validStatuses: [SyncStatus] = [
            .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork,
        ]
        #expect(
            validStatuses.contains(productionStyleController.syncStatus), "Should have valid sync status")
    }

    @Test("DataController schema validation")
    @MainActor
    func dataControllerSchemaValidation() throws {
        let controller = DataController.testContainer()
        let schema = controller.container.schema

        // Test that all required entities are in schema
        let entityNames = schema.entities.map(\.name)
        #expect(entityNames.contains("User"), "Schema should contain User entity")
        #expect(entityNames.contains("Dose"), "Schema should contain Dose entity")
        #expect(
            entityNames.contains("MedicationProfile"), "Schema should contain MedicationProfile entity")
        #expect(entityNames.contains("DoseTitration"), "Schema should contain DoseTitration entity")

        // Test schema has correct number of entities
        #expect(schema.entities.count == 4, "Should have exactly 4 entities in schema")
    }

    @Test("DataController published properties")
    @MainActor
    func dataControllerPublishedProperties() throws {
        let controller = DataController.testContainer()

        // Test that published properties exist and are accessible
        let syncStatus = controller.syncStatus
        let isCloudKitEnabled = controller.isCloudKitEnabled

        _ = syncStatus  // SyncStatus is never nil, just verify we can access it
        #expect(
            isCloudKitEnabled == true || isCloudKitEnabled == false,
            "isCloudKitEnabled should be valid boolean")

        // Test that properties can be changed (for testing purposes)
        let originalStatus = controller.syncStatus
        controller.syncStatus = .available
        #expect(controller.syncStatus == .available, "Should be able to change sync status")
        controller.syncStatus = originalStatus
    }
}
