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
        #expect(shared1.container.schema.entities.count == 16)
    }

    @Test("DataController test container creation")
    @MainActor
    func dataControllerTestContainer() throws {
        let testController = DataController.testContainer()

        // Test container should be in memory
        let context = testController.container.mainContext
        _ = context  // ModelContext is never nil, just verify we can access it

        // Test container should have correct schema
        #expect(testController.container.schema.entities.count == 16, "Should have 16 entities")

        // Test that it's isolated from shared instance
        #expect(
            testController !== DataController.shared,
            "Test container should be separate from shared instance")
    }

    @Test("DataController disk store initialization")
    @MainActor
    func dataControllerDiskStoreInit() throws {
        // Test non-memory controller (simulates production)
        let productionStyleController = DataController(inMemory: false)

        _ = productionStyleController.container.mainContext
        #expect(
            productionStyleController.container.schema.entities.count == 16, "Should have 16 entities")
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
        #expect(schema.entities.count == 16, "Should have exactly 16 entities in schema")
    }
}
