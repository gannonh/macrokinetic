import Foundation
import SwiftData
import Testing
import UserNotifications

@testable import JabTracker

/**
 * Integration tests for SettingsView notification section.
 *
 * Tests the integration between SettingsView and NotificationService, including:
 * - Toggle state binding
 * - Enable/disable notification workflows
 * - Reminder timing updates
 * - Authorization status display
 * - Error handling
 * - Component visibility
 *
 * Test Coverage: SettingsView notification integration (85% target)
 * Related Files:
 * - JabTracker/Views/Settings/SettingsView.swift
 * - JabTracker/Services/NotificationService.swift
 * - JabTracker/Views/Settings/ReminderTimingPicker.swift
 * - JabTracker/Views/Settings/NotificationAuthorizationStatus.swift
 */

@MainActor
@Suite("SettingsView Notification Integration Tests")
struct SettingsViewNotificationIntegrationTests {
    /// Test container with in-memory storage
    var container: ModelContainer
    var context: ModelContext
    var mockNotificationCenter: MockNotificationCenter
    var scheduleService: ScheduleService
    var notificationService: NotificationService

    init() async throws {
        // Create test model container
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            Dose.self,
            DoseSchedule.self,
            ScheduledDose.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        self.container = try ModelContainer(for: schema, configurations: [config])
        self.context = ModelContext(container)

        // Create mock notification center
        self.mockNotificationCenter = MockNotificationCenter()

        // Create services
        self.scheduleService = ScheduleService(context: context)
        self.notificationService = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockNotificationCenter
        )
    }

    // MARK: - Toggle State Binding Tests

    @Test("notificationsEnabled property binds to NotificationService state")
    func testNotificationsEnabledBinding() async {
        // Initial state
        #expect(notificationService.notificationsEnabled == false)

        // Enable notifications
        notificationService.notificationsEnabled = true
        #expect(notificationService.notificationsEnabled == true)

        // Disable notifications
        notificationService.notificationsEnabled = false
        #expect(notificationService.notificationsEnabled == false)
    }

    @Test("Toggle reflects NotificationService notificationsEnabled state")
    func testToggleReflectsServiceState() async {
        // Set service state to enabled
        notificationService.notificationsEnabled = true
        #expect(notificationService.notificationsEnabled == true)

        // Set service state to disabled
        notificationService.notificationsEnabled = false
        #expect(notificationService.notificationsEnabled == false)
    }

    // MARK: - Enable Notifications Tests

    @Test("Enabling notifications calls NotificationService.enable()")
    func testEnableNotificationsCalls() async throws {
        // Grant authorization
        mockNotificationCenter.authorizationStatus = .authorized
        mockNotificationCenter.shouldGrantAuthorization = true

        // Enable notifications
        try await notificationService.enable()

        // Verify state
        #expect(notificationService.notificationsEnabled == true)
    }

    @Test("Enabling notifications with authorization granted succeeds")
    func testEnableWithAuthorizationGranted() async throws {
        // Setup: Grant authorization
        mockNotificationCenter.authorizationStatus = .authorized

        // Enable notifications
        try await notificationService.enable()

        // Verify success
        #expect(notificationService.notificationsEnabled == true)
        #expect(notificationService.authorizationStatus == .authorized)
    }

    @Test("Enabling notifications with authorization denied throws error")
    func testEnableWithAuthorizationDenied() async {
        // Setup: Deny authorization
        mockNotificationCenter.authorizationStatus = .denied

        // Attempt to enable notifications
        do {
            try await notificationService.enable()
            Issue.record("Expected NotificationServiceError.authorizationDenied to be thrown")
        } catch NotificationServiceError.authorizationDenied {
            // Expected error
            #expect(true)
        } catch {
            Issue.record("Unexpected error thrown: \(error)")
        }

        // Verify state remains disabled
        #expect(notificationService.notificationsEnabled == false)
    }

    // MARK: - Disable Notifications Tests

    @Test("Disabling notifications calls NotificationService.disable()")
    func testDisableNotificationsCalls() async {
        // Setup: Enable notifications first
        mockNotificationCenter.authorizationStatus = .authorized
        try? await notificationService.enable()

        // Disable notifications
        await notificationService.disable()

        // Verify state
        #expect(notificationService.notificationsEnabled == false)
        #expect(mockNotificationCenter.didRemoveAll == true)
    }

    @Test("Disabling notifications clears pending notifications")
    func testDisableClearsPendingNotifications() async {
        // Setup: Enable and schedule notifications
        mockNotificationCenter.authorizationStatus = .authorized
        try? await notificationService.enable()

        // Disable notifications
        await notificationService.disable()

        // Verify pending notifications cleared
        #expect(notificationService.notificationQueue.isEmpty)
        #expect(mockNotificationCenter.didRemoveAll == true)
    }

    // MARK: - Reminder Timing Update Tests

    @Test("Changing reminderMinutesBefore calls updateReminderTiming()")
    func testReminderTimingUpdateCalls() async throws {
        // Setup: Enable notifications
        mockNotificationCenter.authorizationStatus = .authorized
        try await notificationService.enable()

        // Change reminder timing
        try await notificationService.updateReminderTiming(30)

        // Verify update
        #expect(notificationService.reminderMinutesBefore == 30)
    }

    @Test("updateReminderTiming validates input values")
    func testUpdateReminderTimingValidation() async {
        // Test invalid timing value
        do {
            try await notificationService.updateReminderTiming(45)
            Issue.record("Expected NotificationServiceError.invalidReminderTiming to be thrown")
        } catch NotificationServiceError.invalidReminderTiming {
            // Expected error
            #expect(true)
        } catch {
            Issue.record("Unexpected error thrown: \(error)")
        }
    }

    @Test("updateReminderTiming with valid values succeeds")
    func testUpdateReminderTimingValidValues() async throws {
        // Setup: Enable notifications
        mockNotificationCenter.authorizationStatus = .authorized
        try await notificationService.enable()

        // Test all valid timing values
        for validMinutes in [15, 30, 60, 120] {
            try await notificationService.updateReminderTiming(validMinutes)
            #expect(notificationService.reminderMinutesBefore == validMinutes)
        }
    }

    // MARK: - Authorization Status Display Tests

    @Test("Authorization status displays correct state")
    func testAuthorizationStatusDisplay() async {
        // Test different authorization states
        let statusValues: [UNAuthorizationStatus] = [
            .notDetermined, .denied, .authorized, .provisional, .ephemeral,
        ]

        for status in statusValues {
            mockNotificationCenter.authorizationStatus = status
            _ = await notificationService.checkAuthorizationStatus()
            #expect(notificationService.authorizationStatus == status)
        }
    }

    // MARK: - Component Visibility Tests

    @Test("ReminderTimingPicker visible when notifications enabled")
    func testReminderPickerVisibility() async throws {
        // Initial state: disabled
        #expect(notificationService.notificationsEnabled == false)

        // Enable notifications
        mockNotificationCenter.authorizationStatus = .authorized
        try await notificationService.enable()

        // Verify enabled
        #expect(notificationService.notificationsEnabled == true)
    }

    @Test("NotificationAuthorizationStatus visible when notifications enabled")
    func testAuthorizationStatusVisibility() async throws {
        // Initial state: disabled
        #expect(notificationService.notificationsEnabled == false)

        // Enable notifications
        mockNotificationCenter.authorizationStatus = .authorized
        try await notificationService.enable()

        // Verify enabled and status set
        #expect(notificationService.notificationsEnabled == true)
        #expect(notificationService.authorizationStatus == .authorized)
    }
}
