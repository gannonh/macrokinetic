import CloudKit
import Foundation
import SwiftData
import Testing

@testable import JabTracker

@MainActor
@Suite("DataController Sync Tests")
struct DataControllerSyncTests {
    @Test("SyncStatus enum all cases")
    func syncStatusEnumCases() throws {
        // Test all SyncStatus cases exist
        let allCases: [SyncStatus] = [
            .unknown, .available, .unavailable, .accountNotSignedIn, .restricted, .noNetwork,
        ]

        #expect(allCases.count == 6, "Should have exactly 6 sync status cases")

        // Test that each case can be used
        for status in allCases {
            switch status {
            case .unknown, .available, .unavailable, .accountNotSignedIn, .restricted, .noNetwork:
                break  // All valid cases
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
            #expect(
                message.lowercased().contains(expectedContent.lowercased()),
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

    @Test("DataController sync status state transitions")
    @MainActor
    func dataControllerSyncStatusTransitions() throws {
        let controller = DataController.testContainer()

        // Test that sync status can be updated programmatically (for testing CloudKit scenarios)
        let originalStatus = controller.syncStatus

        // Test all possible status transitions
        let statuses: [SyncStatus] = [
            .unknown, .available, .unavailable, .restricted, .accountNotSignedIn, .noNetwork,
        ]

        for status in statuses {
            controller.syncStatus = status
            #expect(controller.syncStatus == status, "Should be able to set sync status to \(status)")

            // Test that sync capability reflects the status
            let shouldSync = (status == .available)
            #expect(
                controller.willSyncAcrossDevices == shouldSync,
                "Sync capability should match status \(status)")
        }

        // Restore original status
        controller.syncStatus = originalStatus
    }
}
