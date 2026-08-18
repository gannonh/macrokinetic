import Foundation
import SwiftData
import Testing

@testable import JabTracker

/// Tests for NotificationService state persistence
///
/// This test suite validates that notification settings persist across app restarts
/// using UserDefaults for device-specific preferences.
///
/// Test Coverage:
/// - notificationsEnabled persistence
/// - reminderMinutesBefore persistence
/// - Default values when no saved state exists
/// - State restoration after enable/disable cycles
@Suite("NotificationService Persistence Tests")
@MainActor
struct NotificationServicePersistenceTests {

    // MARK: - Test Helpers

    private func createTestContext() -> ModelContext {
        let schema = Schema([
            User.self,
            MedicationProfile.self,
            DoseSchedule.self,
            ScheduledDose.self,
            Dose.self,
        ])
        let config = InMemoryTestStore.configuration(schema: schema)
        let container = try! ModelContainer(for: schema, configurations: [config])
        return ModelContext(container)
    }

    private func clearPersistedState() {
        // Clear UserDefaults keys used by NotificationService
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "reminderMinutesBefore")
    }

    // MARK: - Persistence Tests

    @Test("notificationsEnabled persists to UserDefaults when enabled")
    func testNotificationsEnabledPersistsWhenEnabled() async throws {
        clearPersistedState()

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

        // Manually persist state (in real app, this would be automatic)
        service.saveState()

        // Verify state was saved to UserDefaults
        let saved = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        #expect(saved == true)
    }

    @Test("notificationsEnabled persists to UserDefaults when disabled")
    func testNotificationsEnabledPersistsWhenDisabled() async throws {
        clearPersistedState()

        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.shouldGrantAuthorization = true

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Enable then disable
        try await service.enable()
        service.saveState()

        await service.disable()
        service.saveState()

        // Verify state was saved to UserDefaults
        let saved = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        #expect(saved == false)
    }

    @Test("reminderMinutesBefore persists to UserDefaults")
    func testReminderMinutesBeforePersists() async throws {
        clearPersistedState()

        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Update reminder timing
        try await service.updateReminderTiming(30)
        service.saveState()

        // Verify state was saved to UserDefaults
        let saved = UserDefaults.standard.integer(forKey: "reminderMinutesBefore")
        #expect(saved == 30)
    }

    @Test("State is restored from UserDefaults on initialization")
    func testStateRestoredOnInitialization() async throws {
        clearPersistedState()

        // Manually set UserDefaults to simulate previous app session
        UserDefaults.standard.set(true, forKey: "notificationsEnabled")
        UserDefaults.standard.set(120, forKey: "reminderMinutesBefore")

        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Load state from UserDefaults
        service.loadState()

        // Verify state was restored
        #expect(service.notificationsEnabled == true)
        #expect(service.reminderMinutesBefore == 120)
    }

    @Test("Default values used when no saved state exists")
    func testDefaultValuesWhenNoSavedState() async throws {
        clearPersistedState()

        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Load state (should use defaults since nothing is saved)
        service.loadState()

        // Verify defaults
        #expect(service.notificationsEnabled == false)
        #expect(service.reminderMinutesBefore == 60)
    }

    @Test("State persists across enable/disable cycles")
    func testStatePersistsAcrossCycles() async throws {
        clearPersistedState()

        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()
        mockCenter.shouldGrantAuthorization = true

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Enable
        try await service.enable()
        service.saveState()
        #expect(UserDefaults.standard.bool(forKey: "notificationsEnabled") == true)

        // Disable
        await service.disable()
        service.saveState()
        #expect(UserDefaults.standard.bool(forKey: "notificationsEnabled") == false)

        // Enable again
        try await service.enable()
        service.saveState()
        #expect(UserDefaults.standard.bool(forKey: "notificationsEnabled") == true)
    }

    @Test("Reminder timing preference persists independently")
    func testReminderTimingPersistsIndependently() async throws {
        clearPersistedState()

        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        // Update timing multiple times
        try await service.updateReminderTiming(15)
        service.saveState()
        #expect(UserDefaults.standard.integer(forKey: "reminderMinutesBefore") == 15)

        try await service.updateReminderTiming(120)
        service.saveState()
        #expect(UserDefaults.standard.integer(forKey: "reminderMinutesBefore") == 120)

        // Verify current value
        #expect(service.reminderMinutesBefore == 120)
    }

    @Test("State restoration handles missing keys gracefully")
    func testStateRestorationHandlesMissingKeys() async throws {
        clearPersistedState()

        // Only set one key, leave the other missing
        UserDefaults.standard.set(true, forKey: "notificationsEnabled")
        // reminderMinutesBefore intentionally not set

        let context = createTestContext()
        let scheduleService = ScheduleService(context: context)
        let mockCenter = MockNotificationCenter()

        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )

        service.loadState()

        // Should restore the available key and use default for missing key
        #expect(service.notificationsEnabled == true)
        #expect(service.reminderMinutesBefore == 60)  // Default value
    }
}
