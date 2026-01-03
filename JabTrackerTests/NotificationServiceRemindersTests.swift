import Foundation
import SwiftData
import Testing
import UserNotifications

@testable import JabTracker

/// NotificationService Reminders Extension test suite
///
/// Tests cover:
/// - Daily weigh-in reminders (schedule/cancel)
/// - Weekly weigh-in reminders (schedule/cancel)
/// - Meal reminders (breakfast, lunch, snack, dinner, end of day)
/// - Food logging reminder management
/// - Authorization check before scheduling
///
/// Total: 20+ test methods for 62%+ coverage target
@MainActor
struct NotificationServiceRemindersTests {
    // MARK: - Test Helpers

    /// Create test ScheduleService with in-memory container
    /// Returns both service and container - container MUST be kept alive for the duration of the test
    private func createTestScheduleService() throws -> (service: ScheduleService, container: ModelContainer) {
        let container = try TestDataSeeding.createTestContainer()
        let context = container.mainContext
        return (ScheduleService(context: context), container)
    }

    /// Create mock notification center for testing
    private func createMockNotificationCenter() -> MockNotificationCenter {
        MockNotificationCenter()
    }

    /// Create a NotificationService with mock notification center for testing
    private func createTestNotificationService() throws
        -> (service: NotificationService, mockCenter: MockNotificationCenter, container: ModelContainer)
    {
        let (scheduleService, container) = try createTestScheduleService()
        let mockCenter = createMockNotificationCenter()
        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )
        return (service, mockCenter, container)
    }

    // MARK: - Daily Weigh-in Reminder Tests

    @Test("Schedule daily weigh-in reminder when enabled and authorized")
    func testScheduleWeighInDailyReminderSuccess() async throws {
        // GIVEN: NotificationService with daily weigh-in enabled and authorized
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        // Set up authorized state - MUST set both mockCenter AND service authorizationStatus
        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized  // Service checks its own property
        service.weighInDailyEnabled = true
        service.weighInDailyTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 30)) ?? Date()

        // WHEN: Schedule daily weigh-in reminder
        try await service.scheduleWeighInDailyReminder()

        // THEN: Notification should be scheduled with correct content
        let requests = mockCenter.addedRequests
        #expect(requests.count == 1, "Should have one scheduled notification")

        let request = requests.first
        #expect(request?.identifier == "weigh-in-daily", "Should have correct identifier")
        #expect(request?.content.title == "Time to weigh in", "Should have correct title")
        #expect(request?.content.body == "Track your progress by logging today's weight", "Should have correct body")
        #expect(request?.content.categoryIdentifier == "WEIGH_IN_REMINDER", "Should have correct category")
        #expect(request?.content.sound != nil, "Should have sound enabled")

        // Verify trigger is calendar-based and repeats
        if let trigger = request?.trigger as? UNCalendarNotificationTrigger {
            #expect(trigger.repeats == true, "Should repeat daily")
            #expect(trigger.dateComponents.hour == 7, "Should trigger at configured hour")
            #expect(trigger.dateComponents.minute == 30, "Should trigger at configured minute")
        } else {
            #expect(Bool(false), "Should have calendar trigger")
        }
    }

    @Test("Schedule daily weigh-in reminder cancels when disabled")
    func testScheduleWeighInDailyReminderCancelsWhenDisabled() async throws {
        // GIVEN: NotificationService with daily weigh-in disabled
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        service.weighInDailyEnabled = false

        // WHEN: Schedule daily weigh-in reminder (should cancel instead)
        try await service.scheduleWeighInDailyReminder()

        // THEN: No notification should be scheduled
        #expect(mockCenter.addedRequests.isEmpty, "Should not schedule when disabled")

        // AND: Cancel request should be made
        #expect(mockCenter.wasRemoved(identifier: "weigh-in-daily"), "Should cancel existing reminder")
    }

    @Test("Schedule daily weigh-in reminder throws when not authorized")
    func testScheduleWeighInDailyReminderThrowsWhenNotAuthorized() async throws {
        // GIVEN: NotificationService with daily weigh-in enabled but not authorized
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .denied
        service.weighInDailyEnabled = true

        // WHEN/THEN: Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await service.scheduleWeighInDailyReminder()
        }
    }

    @Test("Cancel daily weigh-in reminder removes pending notification")
    func testCancelWeighInDailyReminder() async throws {
        // GIVEN: NotificationService with an existing daily weigh-in reminder
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        // First schedule a notification
        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized
        service.weighInDailyEnabled = true
        try await service.scheduleWeighInDailyReminder()
        #expect(mockCenter.addedRequests.count == 1, "Should have one scheduled notification")

        // WHEN: Cancel daily weigh-in reminder
        service.cancelWeighInDailyReminder()

        // THEN: Notification should be removed
        #expect(mockCenter.wasRemoved(identifier: "weigh-in-daily"), "Should remove daily weigh-in notification")
        #expect(mockCenter.addedRequests.isEmpty, "Should have no remaining notifications")
    }

    // MARK: - Weekly Weigh-in Reminder Tests

    @Test("Schedule weekly weigh-in reminder when enabled and authorized")
    func testScheduleWeighInWeeklyReminderSuccess() async throws {
        // GIVEN: NotificationService with weekly weigh-in enabled and authorized
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized
        service.weighInWeeklyEnabled = true
        service.weighInWeeklyDay = 2  // Monday
        service.weighInWeeklyTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

        // WHEN: Schedule weekly weigh-in reminder
        try await service.scheduleWeighInWeeklyReminder()

        // THEN: Notification should be scheduled with correct content
        let requests = mockCenter.addedRequests
        #expect(requests.count == 1, "Should have one scheduled notification")

        let request = requests.first
        #expect(request?.identifier == "weigh-in-weekly", "Should have correct identifier")
        #expect(request?.content.title == "Weekly weigh-in", "Should have correct title")
        #expect(request?.content.body == "Time for your weekly weight check", "Should have correct body")
        #expect(request?.content.categoryIdentifier == "WEIGH_IN_REMINDER", "Should have correct category")

        // Verify trigger includes weekday
        if let trigger = request?.trigger as? UNCalendarNotificationTrigger {
            #expect(trigger.repeats == true, "Should repeat weekly")
            #expect(trigger.dateComponents.weekday == 2, "Should trigger on Monday")
            #expect(trigger.dateComponents.hour == 8, "Should trigger at configured hour")
            #expect(trigger.dateComponents.minute == 0, "Should trigger at configured minute")
        } else {
            #expect(Bool(false), "Should have calendar trigger")
        }
    }

    @Test("Schedule weekly weigh-in reminder cancels when disabled")
    func testScheduleWeighInWeeklyReminderCancelsWhenDisabled() async throws {
        // GIVEN: NotificationService with weekly weigh-in disabled
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        service.weighInWeeklyEnabled = false

        // WHEN: Schedule weekly weigh-in reminder (should cancel instead)
        try await service.scheduleWeighInWeeklyReminder()

        // THEN: No notification should be scheduled
        #expect(mockCenter.addedRequests.isEmpty, "Should not schedule when disabled")

        // AND: Cancel request should be made
        #expect(mockCenter.wasRemoved(identifier: "weigh-in-weekly"), "Should cancel existing reminder")
    }

    @Test("Schedule weekly weigh-in reminder throws when not authorized")
    func testScheduleWeighInWeeklyReminderThrowsWhenNotAuthorized() async throws {
        // GIVEN: NotificationService with weekly weigh-in enabled but not authorized
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .denied
        service.weighInWeeklyEnabled = true

        // WHEN/THEN: Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await service.scheduleWeighInWeeklyReminder()
        }
    }

    @Test("Cancel weekly weigh-in reminder removes pending notification")
    func testCancelWeighInWeeklyReminder() async throws {
        // GIVEN: NotificationService with an existing weekly weigh-in reminder
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        // First schedule a notification
        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized
        service.weighInWeeklyEnabled = true
        try await service.scheduleWeighInWeeklyReminder()
        #expect(mockCenter.addedRequests.count == 1, "Should have one scheduled notification")

        // WHEN: Cancel weekly weigh-in reminder
        service.cancelWeighInWeeklyReminder()

        // THEN: Notification should be removed
        #expect(mockCenter.wasRemoved(identifier: "weigh-in-weekly"), "Should remove weekly weigh-in notification")
        #expect(mockCenter.addedRequests.isEmpty, "Should have no remaining notifications")
    }

    // MARK: - Meal Reminder Tests

    @Test("Schedule meal reminder when enabled and authorized")
    func testScheduleMealReminderSuccess() async throws {
        // GIVEN: NotificationService with authorized state
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized
        let reminderTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()

        // WHEN: Schedule meal reminder for lunch
        try await service.scheduleMealReminder(
            meal: "Lunch",
            identifier: "food-log-lunch",
            time: reminderTime,
            enabled: true
        )

        // THEN: Notification should be scheduled with correct content
        let requests = mockCenter.addedRequests
        #expect(requests.count == 1, "Should have one scheduled notification")

        let request = requests.first
        #expect(request?.identifier == "food-log-lunch", "Should have correct identifier")
        #expect(request?.content.title == "Log your lunch", "Should have correct title")
        #expect(request?.content.body == "Don't forget to track what you ate", "Should have correct body")
        #expect(request?.content.categoryIdentifier == "FOOD_LOG_REMINDER", "Should have correct category")

        // Verify trigger
        if let trigger = request?.trigger as? UNCalendarNotificationTrigger {
            #expect(trigger.repeats == true, "Should repeat daily")
            #expect(trigger.dateComponents.hour == 12, "Should trigger at configured hour")
            #expect(trigger.dateComponents.minute == 0, "Should trigger at configured minute")
        } else {
            #expect(Bool(false), "Should have calendar trigger")
        }
    }

    @Test("Schedule meal reminder cancels when disabled")
    func testScheduleMealReminderCancelsWhenDisabled() async throws {
        // GIVEN: NotificationService
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        let reminderTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

        // WHEN: Schedule meal reminder with enabled = false
        try await service.scheduleMealReminder(
            meal: "Breakfast",
            identifier: "food-log-breakfast",
            time: reminderTime,
            enabled: false
        )

        // THEN: No notification should be scheduled
        #expect(mockCenter.addedRequests.isEmpty, "Should not schedule when disabled")

        // AND: Cancel request should be made for this identifier
        #expect(mockCenter.wasRemoved(identifier: "food-log-breakfast"), "Should cancel existing reminder")
    }

    @Test("Schedule meal reminder throws when not authorized")
    func testScheduleMealReminderThrowsWhenNotAuthorized() async throws {
        // GIVEN: NotificationService with denied authorization
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .denied
        let reminderTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()

        // WHEN/THEN: Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await service.scheduleMealReminder(
                meal: "Dinner",
                identifier: "food-log-dinner",
                time: reminderTime,
                enabled: true
            )
        }
    }

    @Test("Schedule meal reminder formats meal name correctly")
    func testScheduleMealReminderFormatsName() async throws {
        // GIVEN: NotificationService with authorized state
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized
        let reminderTime = Calendar.current.date(from: DateComponents(hour: 15, minute: 0)) ?? Date()

        // WHEN: Schedule meal reminder with uppercase meal name
        try await service.scheduleMealReminder(
            meal: "SNACK",
            identifier: "food-log-snack",
            time: reminderTime,
            enabled: true
        )

        // THEN: Title should use lowercased meal name
        let request = mockCenter.addedRequests.first
        #expect(request?.content.title == "Log your snack", "Should lowercase meal name in title")
    }

    // MARK: - Refresh Food Logging Reminders Tests

    @Test("Refresh food logging reminders schedules all enabled meals")
    func testRefreshFoodLoggingRemindersAllEnabled() async throws {
        // GIVEN: NotificationService with all meal reminders enabled
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized
        service.breakfastReminderEnabled = true
        service.lunchReminderEnabled = true
        service.snackReminderEnabled = true
        service.dinnerReminderEnabled = true
        service.endOfDayReminderEnabled = true

        // WHEN: Refresh food logging reminders
        try await service.refreshFoodLoggingReminders()

        // THEN: All 5 meal reminders should be scheduled
        #expect(mockCenter.addedRequests.count == 5, "Should schedule all 5 meal reminders")

        // Verify each meal reminder exists
        let identifiers = Set(mockCenter.addedRequests.map { $0.identifier })
        #expect(identifiers.contains("food-log-breakfast"), "Should include breakfast reminder")
        #expect(identifiers.contains("food-log-lunch"), "Should include lunch reminder")
        #expect(identifiers.contains("food-log-snack"), "Should include snack reminder")
        #expect(identifiers.contains("food-log-dinner"), "Should include dinner reminder")
        #expect(identifiers.contains("food-log-end-of-day"), "Should include end of day reminder")
    }

    @Test("Refresh food logging reminders with only some enabled")
    func testRefreshFoodLoggingRemindersSomeEnabled() async throws {
        // GIVEN: NotificationService with only breakfast and dinner enabled
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized
        service.breakfastReminderEnabled = true
        service.lunchReminderEnabled = false
        service.snackReminderEnabled = false
        service.dinnerReminderEnabled = true
        service.endOfDayReminderEnabled = false

        // WHEN: Refresh food logging reminders
        try await service.refreshFoodLoggingReminders()

        // THEN: Only 2 meal reminders should be scheduled
        #expect(mockCenter.addedRequests.count == 2, "Should schedule only 2 meal reminders")

        let identifiers = Set(mockCenter.addedRequests.map { $0.identifier })
        #expect(identifiers.contains("food-log-breakfast"), "Should include breakfast reminder")
        #expect(identifiers.contains("food-log-dinner"), "Should include dinner reminder")
        #expect(!identifiers.contains("food-log-lunch"), "Should not include lunch reminder")
        #expect(!identifiers.contains("food-log-snack"), "Should not include snack reminder")
        #expect(!identifiers.contains("food-log-end-of-day"), "Should not include end of day reminder")
    }

    @Test("Refresh food logging reminders with none enabled")
    func testRefreshFoodLoggingRemindersNoneEnabled() async throws {
        // GIVEN: NotificationService with all meal reminders disabled
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        service.breakfastReminderEnabled = false
        service.lunchReminderEnabled = false
        service.snackReminderEnabled = false
        service.dinnerReminderEnabled = false
        service.endOfDayReminderEnabled = false

        // WHEN: Refresh food logging reminders
        try await service.refreshFoodLoggingReminders()

        // THEN: No meal reminders should be scheduled
        #expect(mockCenter.addedRequests.isEmpty, "Should not schedule any meal reminders")

        // AND: All meal reminder identifiers should be removed
        #expect(mockCenter.wasRemoved(identifier: "food-log-breakfast"), "Should cancel breakfast reminder")
        #expect(mockCenter.wasRemoved(identifier: "food-log-lunch"), "Should cancel lunch reminder")
        #expect(mockCenter.wasRemoved(identifier: "food-log-snack"), "Should cancel snack reminder")
        #expect(mockCenter.wasRemoved(identifier: "food-log-dinner"), "Should cancel dinner reminder")
        #expect(mockCenter.wasRemoved(identifier: "food-log-end-of-day"), "Should cancel end of day reminder")
    }

    @Test("Refresh food logging reminders throws when not authorized")
    func testRefreshFoodLoggingRemindersThrowsWhenNotAuthorized() async throws {
        // GIVEN: NotificationService with denied authorization but reminders enabled
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .denied
        service.breakfastReminderEnabled = true

        // WHEN/THEN: Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await service.refreshFoodLoggingReminders()
        }
    }

    @Test("Refresh food logging reminders end of day has custom content")
    func testRefreshFoodLoggingRemindersEndOfDayContent() async throws {
        // GIVEN: NotificationService with only end of day enabled
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized
        service.breakfastReminderEnabled = false
        service.lunchReminderEnabled = false
        service.snackReminderEnabled = false
        service.dinnerReminderEnabled = false
        service.endOfDayReminderEnabled = true
        service.endOfDayReminderTime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()

        // WHEN: Refresh food logging reminders
        try await service.refreshFoodLoggingReminders()

        // THEN: End of day reminder should have custom content
        #expect(mockCenter.addedRequests.count == 1, "Should schedule end of day reminder")

        let request = mockCenter.addedRequests.first
        #expect(request?.identifier == "food-log-end-of-day", "Should have correct identifier")
        #expect(request?.content.title == "Log your meals", "Should have custom title")
        #expect(
            request?.content.body == "Take a moment to log everything you ate today",
            "Should have custom body"
        )
        #expect(request?.content.categoryIdentifier == "FOOD_LOG_REMINDER", "Should have correct category")
    }

    // MARK: - Cancel All Food Logging Reminders Tests

    @Test("Cancel all food logging reminders removes all meal notifications")
    func testCancelAllFoodLoggingReminders() async throws {
        // GIVEN: NotificationService with all meal reminders scheduled
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized
        service.breakfastReminderEnabled = true
        service.lunchReminderEnabled = true
        service.snackReminderEnabled = true
        service.dinnerReminderEnabled = true
        service.endOfDayReminderEnabled = true

        // Schedule all reminders first
        try await service.refreshFoodLoggingReminders()
        #expect(mockCenter.addedRequests.count == 5, "Should have 5 scheduled notifications")

        // WHEN: Cancel all food logging reminders
        service.cancelAllFoodLoggingReminders()

        // THEN: All meal notifications should be removed
        #expect(mockCenter.wasRemoved(identifier: "food-log-breakfast"), "Should remove breakfast reminder")
        #expect(mockCenter.wasRemoved(identifier: "food-log-lunch"), "Should remove lunch reminder")
        #expect(mockCenter.wasRemoved(identifier: "food-log-snack"), "Should remove snack reminder")
        #expect(mockCenter.wasRemoved(identifier: "food-log-dinner"), "Should remove dinner reminder")
        #expect(mockCenter.wasRemoved(identifier: "food-log-end-of-day"), "Should remove end of day reminder")
        #expect(mockCenter.addedRequests.isEmpty, "Should have no remaining notifications")
    }

    @Test("Cancel all food logging reminders works when none scheduled")
    func testCancelAllFoodLoggingRemindersWhenNoneScheduled() async throws {
        // GIVEN: NotificationService with no meal reminders scheduled
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        #expect(mockCenter.addedRequests.isEmpty, "Should start with no notifications")

        // WHEN: Cancel all food logging reminders
        service.cancelAllFoodLoggingReminders()

        // THEN: Should complete without error and identifiers should be in removed list
        #expect(mockCenter.removedIdentifiers.count == 1, "Should have one removal batch")
        let removedBatch = mockCenter.removedIdentifiers.first ?? []
        #expect(removedBatch.count == 5, "Should attempt to remove all 5 meal reminder identifiers")
    }

    // MARK: - Authorization Check Tests

    @Test("Authorization check passes when authorized")
    func testAuthorizationCheckPassesWhenAuthorized() async throws {
        // GIVEN: NotificationService with authorized state
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized
        service.weighInDailyEnabled = true

        // WHEN: Attempt to schedule (which internally calls checkAuthorizationBeforeScheduling)
        // THEN: Should not throw
        try await service.scheduleWeighInDailyReminder()
        #expect(mockCenter.addedRequests.count == 1, "Should successfully schedule notification")
    }

    @Test("Authorization check fails when notDetermined")
    func testAuthorizationCheckFailsWhenNotDetermined() async throws {
        // GIVEN: NotificationService with notDetermined state
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .notDetermined
        service.weighInDailyEnabled = true

        // WHEN/THEN: Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await service.scheduleWeighInDailyReminder()
        }
    }

    @Test("Authorization check fails when provisional")
    func testAuthorizationCheckFailsWhenProvisional() async throws {
        // GIVEN: NotificationService with provisional state
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .provisional
        service.weighInWeeklyEnabled = true

        // WHEN/THEN: Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await service.scheduleWeighInWeeklyReminder()
        }
    }

    // MARK: - Edge Case Tests

    @Test("Schedule meal reminder with various time components")
    func testScheduleMealReminderTimeComponents() async throws {
        // GIVEN: NotificationService with authorized state
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized

        // Test with unusual time (23:59)
        let lateTime = Calendar.current.date(from: DateComponents(hour: 23, minute: 59)) ?? Date()

        // WHEN: Schedule meal reminder at edge-case time
        try await service.scheduleMealReminder(
            meal: "Late Night Snack",
            identifier: "food-log-late",
            time: lateTime,
            enabled: true
        )

        // THEN: Should handle edge-case time correctly
        let request = mockCenter.addedRequests.first
        if let trigger = request?.trigger as? UNCalendarNotificationTrigger {
            #expect(trigger.dateComponents.hour == 23, "Should handle late hour")
            #expect(trigger.dateComponents.minute == 59, "Should handle late minute")
        } else {
            #expect(Bool(false), "Should have calendar trigger")
        }
    }

    @Test("Weekly weigh-in reminder respects weekday configuration")
    func testWeeklyWeighInReminderWeekdayConfiguration() async throws {
        // GIVEN: NotificationService with various weekday configurations
        let (service, mockCenter, container) = try createTestNotificationService()
        _ = container  // Keep container alive

        mockCenter.authorizationStatus = .authorized
        service.authorizationStatus = .authorized
        service.weighInWeeklyEnabled = true

        // Test Sunday (1)
        service.weighInWeeklyDay = 1
        try await service.scheduleWeighInWeeklyReminder()

        var request = mockCenter.addedRequests.first
        if let trigger = request?.trigger as? UNCalendarNotificationTrigger {
            #expect(trigger.dateComponents.weekday == 1, "Should trigger on Sunday")
        }

        // Reset and test Saturday (7)
        mockCenter.reset()
        service.weighInWeeklyDay = 7
        try await service.scheduleWeighInWeeklyReminder()

        request = mockCenter.addedRequests.first
        if let trigger = request?.trigger as? UNCalendarNotificationTrigger {
            #expect(trigger.dateComponents.weekday == 7, "Should trigger on Saturday")
        }
    }
}
