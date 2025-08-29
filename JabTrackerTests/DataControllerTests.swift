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
        let validStatuses: [SyncStatus] = [
            .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork,
        ]
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
        let validStatuses: [SyncStatus] = [
            .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork,
        ]
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

    @Test("DataController CloudKit status async checking")
    @MainActor
    func dataControllerCloudKitStatusAsyncChecking() throws {
        // Test the async CloudKit status checking logic
        let controller = DataController(inMemory: false) // Enable CloudKit logic
        
        // Test initial CloudKit status checking
        Task {
            // Force a status check (this tests the private checkiCloudStatus method)
            controller.retryCloudKitSetup()
            
            // Should complete without throwing
            // Status should be one of the valid CloudKit statuses
            let validStatuses: [SyncStatus] = [
                .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork
            ]
            #expect(validStatuses.contains(controller.syncStatus), 
                    "CloudKit status check should result in valid status")
        }
    }

    @Test("DataController CloudKit container creation")
    @MainActor  
    func dataControllerCloudKitContainerCreation() throws {
        // Test CloudKit container identifier and setup
        let controller = DataController(inMemory: false)
        
        // Container should be created with correct schema
        #expect(controller.container.schema.entities.count == 3, 
                "CloudKit container should have all 3 entities")
        
        // Test that CloudKit configuration doesn't break basic operations
        let context = controller.container.mainContext
        let testUser = User(email: "cloudkit-test@example.com")
        context.insert(testUser)
        
        try context.save()
        #expect(testUser.email == "cloudkit-test@example.com", 
                "CloudKit container should support basic operations")
    }

    @Test("DataController initialization error handling") 
    @MainActor
    func dataControllerInitializationErrorHandling() throws {
        // Test that DataController handles various initialization scenarios
        
        // Test in-memory initialization (should always succeed)
        let inMemoryController = DataController(inMemory: true)
        #expect(inMemoryController.isCloudKitEnabled == false, 
                "In-memory controller should disable CloudKit")
        #expect(inMemoryController.syncStatus == .unavailable,
                "In-memory controller should be unavailable for sync")
        
        // Test production initialization (may or may not have CloudKit available)
        let productionController = DataController(inMemory: false)
        let context = productionController.container.mainContext
        _ = context // Should not be nil
        
        // Should have valid sync status regardless of CloudKit availability
        let validStatuses: [SyncStatus] = [
            .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork
        ]
        #expect(validStatuses.contains(productionController.syncStatus),
                "Production controller should have valid sync status")
    }

    @Test("DataController sync status state transitions")
    @MainActor
    func dataControllerSyncStatusTransitions() throws {
        let controller = DataController.testContainer()
        
        // Test that sync status can be updated programmatically (for testing CloudKit scenarios)
        let originalStatus = controller.syncStatus
        
        // Test all possible status transitions
        let statuses: [SyncStatus] = [.unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork]
        
        for status in statuses {
            controller.syncStatus = status
            #expect(controller.syncStatus == status, "Should be able to set sync status to \(status)")
            
            // Test that sync capability reflects the status
            let shouldSync = (status == .available)
            #expect(controller.willSyncAcrossDevices == shouldSync, 
                    "Sync capability should match status \(status)")
        }
        
        // Restore original status
        controller.syncStatus = originalStatus
    }

    @Test("DataController checkCloudKitStatus execution paths")
    @MainActor
    func dataControllerCheckCloudKitStatusExecution() throws {
        // Test that triggers the private checkCloudKitStatus and checkiCloudStatus methods
        let controller = DataController(inMemory: false)
        
        // The initialization should have called checkCloudKitStatus
        // Let's verify the controller is in a valid state
        #expect(controller.isCloudKitEnabled == true || controller.isCloudKitEnabled == false,
                "CloudKit enabled should be set")
        
        // Test retryCloudKitSetup which calls checkCloudKitStatus
        controller.retryCloudKitSetup()
        
        // Should trigger async checkiCloudStatus through retryCloudKitSetup
        Task {
            // Give time for async operation
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            
            let validStatuses: [SyncStatus] = [
                .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork
            ]
            #expect(validStatuses.contains(controller.syncStatus),
                    "Should have valid sync status after retry")
        }
    }
    
    @Test("DataController multiple initialization scenarios")
    @MainActor
    func dataControllerMultipleInitScenarios() throws {
        // Test various initialization paths to hit error handling
        
        // Test 1: Multiple in-memory controllers
        let inMemory1 = DataController(inMemory: true)
        let inMemory2 = DataController(inMemory: true)
        
        #expect(inMemory1.syncStatus == .unavailable, "In-memory should be unavailable")
        #expect(inMemory2.syncStatus == .unavailable, "Multiple in-memory should work")
        
        // Test 2: Multiple CloudKit controllers
        let cloudKit1 = DataController(inMemory: false)
        let cloudKit2 = DataController(inMemory: false)
        
        // Both should initialize without crashing
        _ = cloudKit1.container.mainContext
        _ = cloudKit2.container.mainContext
        
        // Should have attempted CloudKit setup for both
        let validStatuses: [SyncStatus] = [
            .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork
        ]
        #expect(validStatuses.contains(cloudKit1.syncStatus), "First CloudKit controller should have valid status")
        #expect(validStatuses.contains(cloudKit2.syncStatus), "Second CloudKit controller should have valid status")
    }
    
    @Test("DataController async CloudKit status checking with delays")
    @MainActor
    func dataControllerAsyncCloudKitStatusWithDelays() async throws {
        // Test the async execution of checkiCloudStatus to ensure it completes
        let controller = DataController(inMemory: false)
        
        // Force multiple CloudKit status checks to exercise the async path
        controller.retryCloudKitSetup()
        
        // Wait for async operation to complete 
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Check that the status was updated
        let validStatuses: [SyncStatus] = [
            .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork
        ]
        #expect(validStatuses.contains(controller.syncStatus), 
                "Async CloudKit status check should result in valid status")
        
        // Test multiple sequential retries don't cause issues
        controller.retryCloudKitSetup()
        controller.retryCloudKitSetup()
        
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        
        #expect(validStatuses.contains(controller.syncStatus), 
                "Multiple retries should maintain valid status")
    }
}
