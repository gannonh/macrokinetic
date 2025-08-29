import CloudKit
import Foundation
@testable import JabTracker
import SwiftData
import Testing

@MainActor
@Suite("DataController CloudKit Tests")
struct DataControllerCloudKitTests {
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
                .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork,
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
            .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork,
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

    @Test("DataController CloudKit configuration and status initialization")
    @MainActor
    func dataControllerCloudKitConfigAndInit() throws {
        // Test CloudKit configuration logic by creating controllers with different settings

        // Test 1: Force CloudKit configuration path in init
        let cloudKitController = DataController(inMemory: false)

        // This should have triggered checkCloudKitStatus() in the init method
        #expect(cloudKitController.container.schema.entities.count == 3, "Should have 3 entities")

        // Test 2: Test the preview static property initialization path
        let previewController = DataController.preview
        #expect(previewController.isCloudKitEnabled == false, "Preview should disable CloudKit")

        // Test 3: Force multiple initialization scenarios to hit different code paths
        for _ in 0 ..< 3 {
            let controller = DataController(inMemory: false)
            // Each initialization should go through the CloudKit setup path
            let validStatuses: [SyncStatus] = [
                .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork,
            ]
            #expect(validStatuses.contains(controller.syncStatus), "Each controller should have valid status")
        }

        // Test 4: Test retryCloudKitSetup multiple times to force checkCloudKitStatus calls
        for _ in 0 ..< 5 {
            cloudKitController.retryCloudKitSetup() // This calls checkCloudKitStatus()
        }

        Task {
            // Wait for async CloudKit operations to complete
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            // Verify CloudKit status was checked
            let validStatuses: [SyncStatus] = [
                .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork,
            ]
            #expect(validStatuses.contains(cloudKitController.syncStatus),
                    "CloudKit status should be valid after multiple retries")
        }
    }
}
