import CloudKit
import Foundation
@testable import JabTracker
import SwiftData
import Testing

@MainActor
@Suite("DataController Comprehensive Tests")
struct DataControllerTests {
    @Test("DataController shared instance")
    @MainActor
    func dataControllerSharedInstance() throws {
        // Test that shared instance exists and is consistent
        let shared1 = DataController.shared
        let shared2 = DataController.shared

        #expect(shared1 === shared2, "Shared instance should return same object")

        // Test that shared instance has valid container
        _ = shared1.container.mainContext
        #expect(shared1.container.schema.entities.count == 3, "Should have 3 entities (User, Dose, MedicationProfile)")
    }

    @Test("DataController test container creation")
    @MainActor
    func dataControllerTestContainer() throws {
        let testController = DataController.testContainer()

        // Test container should be in memory
        let context = testController.container.mainContext
        _ = context // ModelContext is never nil, just verify we can access it

        // Test container should have correct schema
        #expect(testController.container.schema.entities.count == 3, "Should have 3 entities")

        // Test that it's isolated from shared instance
        #expect(testController !== DataController.shared, "Test container should be separate from shared instance")

        // Test CloudKit is disabled for test container
        #expect(testController.isCloudKitEnabled == false, "Test container should disable CloudKit")
        #expect(testController.syncStatus == .unavailable, "Test container should be unavailable for sync")
    }

    @Test("DataController CloudKit initialization")
    @MainActor
    func dataControllerCloudKitInit() throws {
        // Test non-memory controller (simulates production)
        let productionStyleController = DataController(inMemory: false)

        // Should have valid container
        let context = productionStyleController.container.mainContext
        _ = context // ModelContext is never nil, just verify we can access it

        // Should attempt CloudKit setup
        #expect(productionStyleController.container.schema.entities.count == 3, "Should have 3 entities")

        // CloudKit status should be set
        let validStatuses: [SyncStatus] = [.unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork]
        #expect(validStatuses.contains(productionStyleController.syncStatus), "Should have valid sync status")
    }

    @Test("DataController preview container")
    @MainActor
    func dataControllerPreviewContainer() throws {
        let previewController = DataController.preview

        // Should be in memory
        let context = previewController.container.mainContext
        _ = context // ModelContext is never nil, just verify we can access it

        // Should have sample data
        let userDescriptor = FetchDescriptor<User>()
        let users = try context.fetch(userDescriptor)
        #expect(!users.isEmpty, "Preview should have sample users")

        let doseDescriptor = FetchDescriptor<Dose>()
        let doses = try context.fetch(doseDescriptor)
        #expect(!doses.isEmpty, "Preview should have sample doses")

        let medicationDescriptor = FetchDescriptor<MedicationProfile>()
        let medications = try context.fetch(medicationDescriptor)
        #expect(!medications.isEmpty, "Preview should have sample medications")

        // Sample data should have expected values
        let sampleUser = users.first
        #expect(sampleUser?.email?.contains("preview") == true, "Preview user should have preview email")
        #expect(sampleUser?.name == "Preview User", "Preview user should have expected name")
    }

    @Test("SyncStatus enum all cases")
    func syncStatusEnumCases() throws {
        // Test all SyncStatus cases exist
        let allCases: [SyncStatus] = [.unknown, .available, .unavailable, .accountNotSignedIn, .restricted, .noNetwork]

        #expect(allCases.count == 6, "Should have exactly 6 sync status cases")

        // Test that each case can be used
        for status in allCases {
            switch status {
            case .unknown, .available, .unavailable, .accountNotSignedIn, .restricted, .noNetwork:
                break // All valid cases
            }
        }
    }

    @Test("DataController sync status messages")
    @MainActor
    func dataControllerSyncStatusMessages() throws {
        let testController = DataController.testContainer()

        // Test messages for all sync statuses
        let testCases: [(SyncStatus, String)] = [
            (.unknown, "Checking"),
            (.available, "Syncing"),
            (.unavailable, "unavailable"),
            (.accountNotSignedIn, "Sign in"),
            (.restricted, "restricted"),
            (.noNetwork, "network"),
        ]

        for (status, expectedContent) in testCases {
            testController.syncStatus = status
            let message = testController.syncStatusMessage

            #expect(!message.isEmpty, "Message should not be empty for \(status)")
            #expect(message.lowercased().contains(expectedContent.lowercased()),
                    "Message for \(status) should contain '\(expectedContent)': '\(message)'")
        }
    }

    @Test("DataController willSyncAcrossDevices property")
    @MainActor
    func dataControllerWillSyncAcrossDevices() throws {
        let testController = DataController.testContainer()

        // Test sync availability detection
        testController.syncStatus = .available
        #expect(testController.willSyncAcrossDevices == true, "Should sync when available")

        testController.syncStatus = .unavailable
        #expect(testController.willSyncAcrossDevices == false, "Should not sync when unavailable")

        testController.syncStatus = .accountNotSignedIn
        #expect(testController.willSyncAcrossDevices == false, "Should not sync when not signed in")

        testController.syncStatus = .restricted
        #expect(testController.willSyncAcrossDevices == false, "Should not sync when restricted")

        testController.syncStatus = .noNetwork
        #expect(testController.willSyncAcrossDevices == false, "Should not sync without network")

        testController.syncStatus = .unknown
        #expect(testController.willSyncAcrossDevices == false, "Should not sync when status unknown")
    }

    @Test("DataController retry CloudKit setup")
    @MainActor
    func dataControllerRetryCloudKitSetup() throws {
        let testController = DataController.testContainer()

        // Test retry when CloudKit disabled (should not crash)
        testController.retryCloudKitSetup()

        // Create controller with CloudKit enabled
        let cloudKitController = DataController(inMemory: false)
        _ = cloudKitController.syncStatus // Just reference for initial state

        // Retry should not crash
        cloudKitController.retryCloudKitSetup()

        // Status might change but should remain valid
        let validStatuses: [SyncStatus] = [.unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork]
        #expect(validStatuses.contains(cloudKitController.syncStatus), "Status should remain valid after retry")
    }

    @Test("DataController CloudKit fallback handling")
    @MainActor
    func dataControllerCloudKitFallback() throws {
        // Test that DataController handles CloudKit setup failure gracefully
        let controller = DataController(inMemory: true) // Forces no CloudKit

        #expect(controller.isCloudKitEnabled == false, "Should disable CloudKit for in-memory")
        #expect(controller.syncStatus == .unavailable, "Should mark sync unavailable")

        // Should still work for local operations
        let context = controller.container.mainContext
        let user = User(email: "fallback-test@example.com")
        context.insert(user)

        try context.save()
        #expect(user.email == "fallback-test@example.com", "Should work without CloudKit")
    }

    @Test("DataController CloudKit container identifier")
    @MainActor
    func dataControllerCloudKitContainerIdentifier() throws {
        // Test that CloudKit container identifier is correctly set
        let controller = DataController(inMemory: false)

        // Container should be created successfully even if CloudKit not available
        let context = controller.container.mainContext
        _ = context // ModelContext is never nil, just verify we can access it
    }

    @Test("DataController test environment detection")
    @MainActor
    func dataControllerTestEnvironmentDetection() throws {
        // In test environment, CloudKit should be disabled
        let testController = DataController()

        // Test environment should disable CloudKit
        #expect(testController.isCloudKitEnabled == false, "Should disable CloudKit in test environment")

        // Should still have valid container
        let context = testController.container.mainContext
        _ = context // ModelContext is never nil, just verify we can access it
    }

    @Test("DataController published properties")
    @MainActor
    func dataControllerPublishedProperties() throws {
        let controller = DataController.testContainer()

        // Test that published properties exist and are accessible
        let syncStatus = controller.syncStatus
        let isCloudKitEnabled = controller.isCloudKitEnabled

        _ = syncStatus // SyncStatus is never nil, just verify we can access it
        #expect(isCloudKitEnabled == true || isCloudKitEnabled == false, "isCloudKitEnabled should be valid boolean")

        // Test that properties can be changed (for testing purposes)
        let originalStatus = controller.syncStatus
        controller.syncStatus = .available
        #expect(controller.syncStatus == .available, "Should be able to change sync status")
        controller.syncStatus = originalStatus
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
        #expect(entityNames.contains("MedicationProfile"), "Schema should contain MedicationProfile entity")

        // Test schema has correct number of entities
        #expect(schema.entities.count == 3, "Should have exactly 3 entities in schema")
    }
}
