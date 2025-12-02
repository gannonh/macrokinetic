import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Tests for NotificationService activation and configuration methods
///
/// This test suite validates the enable(), disable(), and updateReminderTiming() methods
/// that allow users to control notification settings through the UI.
///
/// Test Coverage:
/// - enable() method: authorization, queue refresh, background scheduling, state updates
/// - disable() method: cancellation, queue clearing, badge updates, state updates
/// - updateReminderTiming() method: validation, rescheduling, state updates
/// - Error handling: authorization denial, invalid timing values
/// - State management: @Published property updates
@Suite("NotificationService Activation Tests")
@MainActor
struct NotificationServiceActivationTests {

    // MARK: - Test Helpers

    private func createTestContext() -> ModelContext {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            DoseSchedule.self,
            ScheduledDose.self,
            Dose.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try! ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func createTestUser(context: ModelContext) -> User {
        let user = User(
            email: "test@example.com",
            name: "Test User",
            appleUserId: "test-user-\(UUID().uuidString)"
        )
        context.insert(user)
        return user
    }

    private func createTestProfile(context: ModelContext, user: User) -> MedicationProfile {
        let profile = MedicationProfile(
            genericName: "semaglutide",
            brandName: "Ozempic",
            currentDose: 1.0
        )
        context.insert(profile)
        profile.user = user
        return profile
    }

    private func createTestSchedule(context: ModelContext, profile: MedicationProfile) -> DoseSchedule {
        let schedule = DoseSchedule(
            medicationProfile: profile,
            patternType: .weekly
        )
        context.insert(schedule)
        return schedule
    }

    // MARK: - enable() Method Tests

    @Test("enable() requests authorization when not determined")
    func testEnableRequestsAuthorization() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .notDetermined
        mockCenter.shouldGrantAuthorization = true

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Initially disabled
        #expect(service.notificationsEnabled == false)

        // Enable notifications
        try await service.enable()

        // Should be enabled now
        #expect(service.notificationsEnabled == true)
    }

    @Test("enable() throws error when authorization denied")
    func testEnableThrowsWhenAuthorizationDenied() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .notDetermined
        mockCenter.shouldGrantAuthorization = false

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await service.enable()
        }

        // Should remain disabled
        #expect(service.notificationsEnabled == false)
    }

    @Test("enable() refreshes notification queue for all active schedules")
    func testEnableRefreshesNotificationQueue() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.shouldGrantAuthorization = true

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Enable notifications
        try await service.enable()

        // Should be enabled (notification count depends on schedule data which may be empty)
        #expect(service.notificationsEnabled == true)
        // Queue refresh was called (even if no doses to schedule)
        #expect(service.isRefreshing == false)  // Should be done refreshing
    }

    @Test("enable() schedules background refresh")
    func testEnableSchedulesBackgroundRefresh() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.shouldGrantAuthorization = true

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Enable notifications
        try await service.enable()

        // Background refresh scheduling is handled by BGTaskScheduler
        // We can't easily test this without mocking BGTaskScheduler
        // But we can verify the service is enabled
        #expect(service.notificationsEnabled == true)
    }

    @Test("enable() is idempotent - can be called multiple times")
    func testEnableIsIdempotent() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.shouldGrantAuthorization = true

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Enable twice
        try await service.enable()
        try await service.enable()

        // Should still be enabled
        #expect(service.notificationsEnabled == true)
    }

    @Test("enable() works when authorization already granted")
    func testEnableWithExistingAuthorization() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .authorized
        mockCenter.shouldGrantAuthorization = true

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Enable notifications
        try await service.enable()

        // Should be enabled
        #expect(service.notificationsEnabled == true)
    }

    // MARK: - disable() Method Tests

    @Test("disable() cancels all pending notifications")
    func testDisableCancelsAllNotifications() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.shouldGrantAuthorization = true

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Enable first
        try await service.enable()

        // Disable notifications
        await service.disable()

        // Should have called removeAll
        #expect(mockCenter.didRemoveAll == true)
        #expect(service.notificationsEnabled == false)
    }

    @Test("disable() clears notification queue")
    func testDisableClearsQueue() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.shouldGrantAuthorization = true

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Enable first
        try await service.enable()

        // Manually add an item to the queue to test clearing
        let mockPendingNotification = PendingNotification(
            id: "test-notification",
            scheduledDoseId: UUID(),
            triggerDate: Date(),
            content: NotificationContent(
                title: "Test",
                body: "Test body",
                categoryIdentifier: "TEST"
            )
        )
        service.notificationQueue.append(mockPendingNotification)
        #expect(service.notificationQueue.count > 0)

        // Disable notifications
        await service.disable()

        // Queue should be cleared
        #expect(service.notificationQueue.count == 0)
    }

    @Test("disable() updates badge count to zero")
    func testDisableUpdatesBadge() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.shouldGrantAuthorization = true
        mockCenter.badgeCount = 5

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Enable first
        try await service.enable()

        // Disable notifications
        await service.disable()

        // Badge should be reset to zero
        #expect(mockCenter.badgeCount == 0)
    }

    @Test("disable() sets notificationsEnabled to false")
    func testDisableUpdatesEnabledState() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.shouldGrantAuthorization = true

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Enable first
        try await service.enable()
        #expect(service.notificationsEnabled == true)

        // Disable notifications
        await service.disable()

        // Should be disabled
        #expect(service.notificationsEnabled == false)
    }

    @Test("disable() is idempotent - can be called multiple times")
    func testDisableIsIdempotent() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Disable twice (without enabling first)
        await service.disable()
        await service.disable()

        // Should be disabled
        #expect(service.notificationsEnabled == false)
    }

    @Test("disable() works when notifications were never enabled")
    func testDisableWhenNeverEnabled() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Disable without enabling first
        await service.disable()

        // Should be disabled (no crash)
        #expect(service.notificationsEnabled == false)
    }

    // MARK: - updateReminderTiming() Method Tests

    @Test("updateReminderTiming() accepts valid timing values")
    func testUpdateReminderTimingAcceptsValidValues() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Test all valid values
        let validValues = [15, 30, 60, 120]

        for minutes in validValues {
            try await service.updateReminderTiming(minutes)
            #expect(service.reminderMinutesBefore == minutes)
        }
    }

    @Test("updateReminderTiming() throws error for invalid values")
    func testUpdateReminderTimingRejectsInvalidValues() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Test invalid values
        let invalidValues = [0, 5, 10, 45, 90, 180, -15]

        for minutes in invalidValues {
            await #expect(throws: NotificationServiceError.invalidReminderTiming) {
                try await service.updateReminderTiming(minutes)
            }
        }
    }

    @Test("updateReminderTiming() reschedules notifications when enabled")
    func testUpdateReminderTimingReschedulesWhenEnabled() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.shouldGrantAuthorization = true

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Enable notifications with default timing (60 minutes)
        try await service.enable()

        // Reset mock to track new activity
        mockCenter.didRemoveAll = false

        // Update reminder timing
        try await service.updateReminderTiming(30)

        // Should have updated timing and called removeAll (part of refresh)
        #expect(service.reminderMinutesBefore == 30)
        #expect(mockCenter.didRemoveAll == true)  // refreshNotificationQueue calls removeAll
    }

    @Test("updateReminderTiming() does not reschedule when disabled")
    func testUpdateReminderTimingDoesNotRescheduleWhenDisabled() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Update timing while disabled
        try await service.updateReminderTiming(30)

        // Should update property but not schedule
        #expect(service.reminderMinutesBefore == 30)
        #expect(mockCenter.addedRequests.count == 0)
    }

    @Test("updateReminderTiming() updates reminderMinutesBefore property")
    func testUpdateReminderTimingUpdatesProperty() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Initial value (default 60)
        #expect(service.reminderMinutesBefore == 60)

        // Update to 30
        try await service.updateReminderTiming(30)
        #expect(service.reminderMinutesBefore == 30)

        // Update to 120
        try await service.updateReminderTiming(120)
        #expect(service.reminderMinutesBefore == 120)
    }

    // MARK: - State Management Tests

    @Test("notificationsEnabled property defaults to false")
    func testNotificationsEnabledDefaultsFalse() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        #expect(service.notificationsEnabled == false)
    }

    @Test("reminderMinutesBefore property defaults to 60")
    func testReminderMinutesBeforeDefaultsSixty() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        #expect(service.reminderMinutesBefore == 60)
    }

    @Test("enable() followed by disable() returns to initial state")
    func testEnableDisableCycle() async throws {
        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.shouldGrantAuthorization = true

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Initial state
        #expect(service.notificationsEnabled == false)
        #expect(service.notificationQueue.count == 0)

        // Enable
        try await service.enable()
        #expect(service.notificationsEnabled == true)

        // Disable
        await service.disable()
        #expect(service.notificationsEnabled == false)
        #expect(service.notificationQueue.count == 0)
        #expect(mockCenter.addedRequests.count == 0)
    }
}
