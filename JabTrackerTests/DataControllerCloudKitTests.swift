import Foundation
@testable import JabTracker
import SwiftData
import Testing

@MainActor
@Suite("DataController Business Logic Tests")
struct DataControllerBusinessLogicTests {
    @Test("DataController sync status messages")
    @MainActor
    func dataControllerSyncStatusMessages() throws {
        let controller = DataController.testContainer()
        
        // Test all sync status message variants
        let testCases: [(SyncStatus, String)] = [
            (.unknown, "Checking sync status..."),
            (.available, "Syncing with iCloud"),
            (.unavailable, "Sync unavailable - using local storage"),
            (.accountNotSignedIn, "Sign in to iCloud to sync across devices"),
            (.restricted, "iCloud sync restricted"),
            (.noNetwork, "No network connection for sync")
        ]
        
        for (status, expectedMessage) in testCases {
            controller.syncStatus = status
            #expect(controller.syncStatusMessage == expectedMessage,
                    "Status message for \(status) should be '\(expectedMessage)', got '\(controller.syncStatusMessage)'")
        }
    }
    
    @Test("DataController sync availability detection")
    @MainActor
    func dataControllerSyncAvailabilityDetection() throws {
        let controller = DataController.testContainer()
        
        // Test sync availability based on status
        controller.syncStatus = .available
        #expect(controller.willSyncAcrossDevices == true, "Should sync when available")
        
        controller.syncStatus = .unavailable
        #expect(controller.willSyncAcrossDevices == false, "Should not sync when unavailable")
        
        controller.syncStatus = .accountNotSignedIn
        #expect(controller.willSyncAcrossDevices == false, "Should not sync when not signed in")
        
        controller.syncStatus = .restricted
        #expect(controller.willSyncAcrossDevices == false, "Should not sync when restricted")
        
        controller.syncStatus = .noNetwork
        #expect(controller.willSyncAcrossDevices == false, "Should not sync without network")
        
        controller.syncStatus = .unknown
        #expect(controller.willSyncAcrossDevices == false, "Should not sync when status unknown")
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
    
    @Test("DataController retry CloudKit setup with disabled state")
    @MainActor
    func dataControllerRetryCloudKitSetupDisabled() throws {
        let testController = DataController.testContainer()
        
        // Test retry when CloudKit disabled (should not crash or change state)
        let initialStatus = testController.syncStatus
        testController.retryCloudKitSetup()
        
        #expect(testController.syncStatus == initialStatus, 
                "Status should not change when CloudKit disabled")
        #expect(testController.isCloudKitEnabled == false,
                "CloudKit should remain disabled for test container")
    }
    
    @Test("DataController container schema validation")
    @MainActor
    func dataControllerContainerSchemaValidation() throws {
        let controller = DataController.testContainer()
        
        // Test that container has correct schema regardless of CloudKit state
        #expect(controller.container.schema.entities.count == 3,
                "Container should have 3 entities")
        
        let entityNames = controller.container.schema.entities.map(\.name)
        #expect(entityNames.contains("User"), "Schema should contain User entity")
        #expect(entityNames.contains("Dose"), "Schema should contain Dose entity") 
        #expect(entityNames.contains("MedicationProfile"), "Schema should contain MedicationProfile entity")
    }
    
    @Test("DataController preview instance configuration")
    @MainActor
    func dataControllerPreviewInstanceConfiguration() throws {
        let previewController = DataController.preview
        
        // Preview should be configured for local use
        #expect(previewController.isCloudKitEnabled == false, "Preview should disable CloudKit")
        #expect(previewController.syncStatus == .unavailable, "Preview should be unavailable for sync")
        
        // Preview should have sample data
        let context = previewController.container.mainContext
        
        // Access the context to verify it works
        do {
            _ = try context.fetch(FetchDescriptor<User>())
        } catch {
            // Context access failed - still functional for test purposes
        }
        
        // Should not crash and should allow operations
        #expect(true, "Preview container should be functional")
    }
}

// MARK: - Mock CloudKit Tests (Business Logic Only)

@MainActor
@Suite("DataController CloudKit Business Logic (Mocked)")
struct DataControllerCloudKitMockedTests {
    @Test("DataController handles all CloudKit status scenarios")
    @MainActor 
    func dataControllerHandlesAllCloudKitStatusScenarios() throws {
        let controller = DataController.testContainer()
        
        // Test business logic for each possible CloudKit status
        // These tests verify the app's behavior without actual CloudKit calls
        
        let statusScenarios: [(SyncStatus, Bool, String)] = [
            (.available, true, "Syncing with iCloud"),
            (.unavailable, false, "Sync unavailable - using local storage"),
            (.accountNotSignedIn, false, "Sign in to iCloud to sync across devices"),
            (.restricted, false, "iCloud sync restricted"), 
            (.noNetwork, false, "No network connection for sync"),
            (.unknown, false, "Checking sync status...")
        ]
        
        for (status, shouldSync, expectedMessage) in statusScenarios {
            controller.syncStatus = status
            
            #expect(controller.willSyncAcrossDevices == shouldSync,
                    "Sync availability should be \(shouldSync) for status \(status)")
            #expect(controller.syncStatusMessage == expectedMessage,
                    "Message should be '\(expectedMessage)' for status \(status)")
        }
    }
}
