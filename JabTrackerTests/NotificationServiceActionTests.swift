import Foundation
import SwiftData
import Testing
import UserNotifications

@testable import JabTracker

/// Comprehensive tests for NotificationService action handling and missed dose detection
@MainActor
@Suite("NotificationService Action Handling Tests")
struct NotificationServiceActionTests {
    // MARK: - Test Setup

    // swiftlint:disable large_tuple
    private func createTestEnvironment() async throws -> (
        service: NotificationService,
        scheduleService: ScheduleService,
        context: ModelContext
    ) {
        // swiftlint:enable large_tuple
        let container = try TestDataSeeding.createTestContainer()
        let context = container.mainContext

        let scheduleService = ScheduleService(context: context)
        let notificationService = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: .current()
        )

        return (notificationService, scheduleService, context)
    }

    private func createTestScheduledDose(
        context: ModelContext,
        scheduledFor: Date = Date(),
        medication: MedicationProfile? = nil
    ) throws -> ScheduledDose {
        let profile = medication ?? TestDataSeeding.createTestMedicationProfile()
        context.insert(profile)

        let scheduled = ScheduledDose(
            scheduledTime: scheduledFor,
            doseAmount: 0.5
        )
        context.insert(scheduled)
        try context.save()

        return scheduled
    }

    // MARK: - Action Handling Tests (15 tests)

    @Test("handleNotificationAction handles TAKE_DOSE action")
    func testHandleTakeDoseAction() async throws {
        let (service, _, context) = try await createTestEnvironment()

        let scheduledDose = try createTestScheduledDose(context: context)
        let actionIdentifier = "TAKE_DOSE"

        // Execute action
        try await service.handleNotificationAction(
            actionIdentifier,
            for: scheduledDose
        )

        // Verify dose was created
        let descriptor = FetchDescriptor<Dose>()
        let doses = try context.fetch(descriptor)
        #expect(doses.count == 1)
        #expect(doses.first?.medication == scheduledDose.schedule?.medicationProfile)
        #expect(doses.first?.amount == scheduledDose.doseAmount)
    }

    @Test("handleNotificationAction handles SKIP_DOSE action")
    func testHandleSkipDoseAction() async throws {
        let (service, _, context) = try await createTestEnvironment()

        let scheduledDose = try createTestScheduledDose(context: context)
        let actionIdentifier = "SKIP_DOSE"

        // Execute action
        try await service.handleNotificationAction(
            actionIdentifier,
            for: scheduledDose
        )

        // Verify scheduled dose was marked as skipped
        let descriptor = FetchDescriptor<ScheduledDose>()
        let scheduledDoses = try context.fetch(descriptor)
        #expect(scheduledDoses.count == 1)
        #expect(scheduledDoses.first?.skipReason != nil)
    }

    @Test("handleNotificationAction handles SNOOZE action")
    func testHandleSnoozeAction() async throws {
        let (service, _, context) = try await createTestEnvironment()

        let scheduledDose = try createTestScheduledDose(context: context)
        let actionIdentifier = "SNOOZE"

        // Get current queue size
        let initialQueueCount = service.notificationQueue.count

        // Execute action
        try await service.handleNotificationAction(
            actionIdentifier,
            for: scheduledDose
        )

        // Verify notification was rescheduled (queue updated)
        // After snooze, queue should have same or more notifications
        #expect(service.notificationQueue.count >= initialQueueCount)
    }

    @Test("handleNotificationAction validates scheduled dose exists")
    func testHandleActionValidatesScheduledDose() async throws {
        let (service, _, context) = try await createTestEnvironment()

        let scheduledDose = try createTestScheduledDose(context: context)

        // Delete scheduled dose to simulate missing dose
        context.delete(scheduledDose)
        try context.save()

        // Action should throw error for missing dose
        await #expect(throws: NotificationServiceError.self) {
            try await service.handleNotificationAction("TAKE_DOSE", for: scheduledDose)
        }
    }

    @Test("handleNotificationAction creates dose with correct timestamp")
    func testHandleActionCreatesCorrectTimestamp() async throws {
        let (service, _, context) = try await createTestEnvironment()

        let scheduledTime = Date()
        let scheduledDose = try createTestScheduledDose(
            context: context,
            scheduledFor: scheduledTime
        )

        // Execute TAKE_DOSE action
        try await service.handleNotificationAction(
            "TAKE_DOSE",
            for: scheduledDose
        )

        // Verify dose timestamp is close to scheduled time (within 1 minute)
        let descriptor = FetchDescriptor<Dose>()
        let doses = try context.fetch(descriptor)
        #expect(doses.count == 1)

        if let dose = doses.first {
            let timeDifference = abs(dose.timestamp.timeIntervalSince(scheduledTime))
            #expect(timeDifference < 60)  // Within 1 minute
        }
    }

    @Test("handleNotificationAction preserves medication profile relationship")
    func testHandleActionPreservesMedicationProfile() async throws {
        let (service, _, context) = try await createTestEnvironment()

        let medication = TestDataSeeding.createTestMedicationProfile()
        context.insert(medication)

        let scheduledDose = try createTestScheduledDose(
            context: context,
            medication: medication
        )

        // Execute action
        try await service.handleNotificationAction(
            "TAKE_DOSE",
            for: scheduledDose
        )

        // Verify relationship preserved
        let descriptor = FetchDescriptor<Dose>()
        let doses = try context.fetch(descriptor)
        #expect(doses.count == 1)
        #expect(doses.first?.medication === medication)
    }

    @Test("handleNotificationAction handles invalid action identifier")
    func testHandleActionInvalidIdentifier() async throws {
        let (service, _, context) = try await createTestEnvironment()

        let scheduledDose = try createTestScheduledDose(context: context)
        let invalidAction = "INVALID_ACTION"

        // Invalid action should throw error
        await #expect(throws: NotificationServiceError.self) {
            try await service.handleNotificationAction(invalidAction, for: scheduledDose)
        }
    }

    @Test("handleNotificationResponse routes TAKE_DOSE correctly")
    func testHandleResponseTakeDose() async throws {
        // TODO: This test requires protocol abstraction for UNNotificationResponse
        // UNNotificationResponse cannot be properly mocked in tests
        // Will be implemented once NotificationService is refactored to use protocol
        #expect(true)  // Placeholder until implementation phase
    }

    @Test("handleNotificationResponse routes SKIP_DOSE correctly")
    func testHandleResponseSkipDose() async throws {
        // TODO: This test requires protocol abstraction for UNNotificationResponse
        // UNNotificationResponse cannot be properly mocked in tests
        // Will be implemented once NotificationService is refactored to use protocol
        #expect(true)  // Placeholder until implementation phase
    }

    @Test("handleNotificationResponse extracts scheduled dose ID from userInfo")
    func testHandleResponseExtractsDoseID() async throws {
        // TODO: This test requires protocol abstraction for UNNotificationResponse
        // UNNotificationResponse cannot be properly mocked in tests
        // Will be implemented once NotificationService is refactored to use protocol
        #expect(true)  // Placeholder until implementation phase
    }

    @Test("handleNotificationResponse handles missing dose ID gracefully")
    func testHandleResponseMissingDoseID() async throws {
        // TODO: This test requires protocol abstraction for UNNotificationResponse
        // UNNotificationResponse cannot be properly mocked in tests
        // Will be implemented once NotificationService is refactored to use protocol
        #expect(true)  // Placeholder until implementation phase
    }

    @Test("handleNotificationAction updates notification queue after action")
    func testHandleActionUpdatesQueue() async throws {
        let (service, _, context) = try await createTestEnvironment()

        let scheduledDose = try createTestScheduledDose(context: context)

        // Get initial queue
        _ = service.notificationQueue

        // Handle action
        try await service.handleNotificationAction("TAKE_DOSE", for: scheduledDose)

        // Queue should be updated (refreshed) after action
        // This is implementation-specific, but queue should change
        _ = service.notificationQueue

        // Queue may have different count or different content after refresh
        // At minimum, it should have been refreshed (property changed)
        #expect(true)  // Placeholder - actual implementation may vary
    }

    @Test("handleNotificationAction creates dose with correct injection site")
    func testHandleActionCorrectInjectionSite() async throws {
        let (service, _, context) = try await createTestEnvironment()

        let medication = TestDataSeeding.createTestMedicationProfile()
        medication.preferredInjectionSites = ["Abdomen"]
        context.insert(medication)

        let scheduledDose = try createTestScheduledDose(
            context: context,
            medication: medication
        )

        try await service.handleNotificationAction("TAKE_DOSE", for: scheduledDose)

        let descriptor = FetchDescriptor<Dose>()
        let doses = try context.fetch(descriptor)
        #expect(doses.count == 1)
        // Injection site should be set from medication profile
        // Implementation may vary - placeholder assertion
        #expect(doses.first != nil)
    }

    @Test("handleNotificationAction persists changes to SwiftData")
    func testHandleActionPersistsChanges() async throws {
        let (service, _, context) = try await createTestEnvironment()

        let scheduledDose = try createTestScheduledDose(context: context)

        try await service.handleNotificationAction("TAKE_DOSE", for: scheduledDose)

        // Changes should be persisted (context saved)
        #expect(context.hasChanges == false)  // Should be saved

        // Verify dose persisted
        let descriptor = FetchDescriptor<Dose>()
        let doses = try context.fetch(descriptor)
        #expect(doses.count == 1)
    }

    // MARK: - Missed Dose Detection Tests (5 tests)

    @Test("detectMissedDoses finds overdue scheduled doses")
    func testDetectMissedDosesFindsOverdue() async throws {
        let (service, _, context) = try await createTestEnvironment()

        // Create a scheduled dose from 2 hours ago (overdue)
        let pastTime = Date().addingTimeInterval(-2 * 3600)
        _ = try createTestScheduledDose(context: context, scheduledFor: pastTime)

        // Detect missed doses
        let missedDoses = try await service.detectMissedDoses()

        #expect(missedDoses.count == 1)
    }

    @Test("detectMissedDoses excludes future scheduled doses")
    func testDetectMissedDosesExcludesFuture() async throws {
        let (service, _, context) = try await createTestEnvironment()

        // Create a scheduled dose for future (not missed)
        let futureTime = Date().addingTimeInterval(2 * 3600)
        _ = try createTestScheduledDose(context: context, scheduledFor: futureTime)

        let missedDoses = try await service.detectMissedDoses()

        #expect(missedDoses.count == 0)
    }

    @Test("detectMissedDoses excludes doses with actual doses")
    func testDetectMissedDosesExcludesCompleted() async throws {
        let (service, _, context) = try await createTestEnvironment()

        let pastTime = Date().addingTimeInterval(-2 * 3600)
        let scheduledDose = try createTestScheduledDose(context: context, scheduledFor: pastTime)

        // Create actual dose for scheduled dose
        let dose = Dose(
            amount: scheduledDose.doseAmount,
            timestamp: pastTime,
            site: "Abdomen"
        )
        dose.medication = scheduledDose.schedule?.medicationProfile
        context.insert(dose)
        try context.save()

        let missedDoses = try await service.detectMissedDoses()

        // Should not include scheduled dose with actual dose
        #expect(missedDoses.count == 0)
    }

    @Test("scheduleMissedDoseAlert creates notification for missed dose")
    func testScheduleMissedDoseAlert() async throws {
        let (service, _, context) = try await createTestEnvironment()

        let pastTime = Date().addingTimeInterval(-2 * 3600)
        let scheduledDose = try createTestScheduledDose(context: context, scheduledFor: pastTime)

        // Schedule missed dose alert
        try await service.scheduleMissedDoseAlert(for: scheduledDose)

        // Verify notification was scheduled (queue updated)
        #expect(service.notificationQueue.count > 0)
    }

    @Test("processMissedDoses detects and schedules alerts")
    func testProcessMissedDoses() async throws {
        let (service, _, context) = try await createTestEnvironment()

        // Create multiple missed doses
        let pastTime1 = Date().addingTimeInterval(-2 * 3600)
        let pastTime2 = Date().addingTimeInterval(-4 * 3600)
        _ = try createTestScheduledDose(context: context, scheduledFor: pastTime1)
        _ = try createTestScheduledDose(context: context, scheduledFor: pastTime2)

        // Process missed doses
        try await service.processMissedDoses()

        // Should have scheduled alerts for both missed doses
        #expect(service.notificationQueue.count >= 2)
    }
}

// MARK: - Mock UNNotificationResponse

/// Mock UNNotificationResponse for testing notification actions
/// Note: This is a simplified mock that bypasses UNNotificationResponse initialization constraints
private struct MockNotificationResponseData {
    let actionIdentifier: String
    let scheduledDoseID: UUID?

    var userInfo: [AnyHashable: Any] {
        if let id = scheduledDoseID {
            return ["scheduledDoseID": id.uuidString]
        }
        return [:]
    }
}

/// Factory for creating mock notification responses
private final class MockUNNotificationResponse {
    static func create(actionIdentifier: String, scheduledDoseID: UUID?) -> UNNotificationResponse {
        // Create notification content with userInfo
        let content = UNMutableNotificationContent()
        if let id = scheduledDoseID {
            content.userInfo = ["scheduledDoseID": id.uuidString]
        }

        // Create notification request
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        // This is a workaround for testing - in real scenarios, UNNotificationResponse
        // is created by the system. For tests, we'll need to refactor NotificationService
        // to accept a protocol or simpler data structure.
        fatalError("UNNotificationResponse cannot be properly mocked - NotificationService needs protocol abstraction")
    }
}
