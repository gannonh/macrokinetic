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
    // MARK: - Test Context

    /// Test context containing service, mock center, and container
    private struct TestContext {
        let service: NotificationService
        let mockCenter: MockNotificationCenter
        let container: ModelContainer
    }

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
    private func createTestNotificationService() throws -> TestContext {
        let (scheduleService, container) = try createTestScheduleService()
        let mockCenter = createMockNotificationCenter()
        let service = NotificationService(
            scheduleService: scheduleService,
            notificationCenter: mockCenter
        )
        return TestContext(service: service, mockCenter: mockCenter, container: container)
    }

    // MARK: - Daily Weigh-in Reminder Tests

    @Test("Schedule daily weigh-in reminder when enabled and authorized")
    func testScheduleWeighInDailyReminderSuccess() async throws {
        // GIVEN: NotificationService with daily weigh-in enabled and authorized
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        // Set up authorized state - MUST set both mockCenter AND service authorizationStatus
        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized  // Service checks its own property
        ctx.service.weighInDailyEnabled = true
        ctx.service.weighInDailyTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 30)) ?? Date()

        // WHEN: Schedule daily weigh-in reminder
        try await ctx.service.scheduleWeighInDailyReminder()

        // THEN: Notification should be scheduled with correct content
        let requests = ctx.mockCenter.addedRequests
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
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.service.weighInDailyEnabled = false

        // WHEN: Schedule daily weigh-in reminder (should cancel instead)
        try await ctx.service.scheduleWeighInDailyReminder()

        // THEN: No notification should be scheduled
        #expect(ctx.mockCenter.addedRequests.isEmpty, "Should not schedule when disabled")

        // AND: Cancel request should be made
        #expect(ctx.mockCenter.wasRemoved(identifier: "weigh-in-daily"), "Should cancel existing reminder")
    }

    @Test("Schedule daily weigh-in reminder throws when not authorized")
    func testScheduleWeighInDailyReminderThrowsWhenNotAuthorized() async throws {
        // GIVEN: NotificationService with daily weigh-in enabled but not authorized
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .denied
        ctx.service.weighInDailyEnabled = true

        // WHEN/THEN: Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await ctx.service.scheduleWeighInDailyReminder()
        }
    }

    @Test("Cancel daily weigh-in reminder removes pending notification")
    func testCancelWeighInDailyReminder() async throws {
        // GIVEN: NotificationService with an existing daily weigh-in reminder
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        // First schedule a notification
        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized
        ctx.service.weighInDailyEnabled = true
        try await ctx.service.scheduleWeighInDailyReminder()
        #expect(ctx.mockCenter.addedRequests.count == 1, "Should have one scheduled notification")

        // WHEN: Cancel daily weigh-in reminder
        ctx.service.cancelWeighInDailyReminder()

        // THEN: Notification should be removed
        #expect(ctx.mockCenter.wasRemoved(identifier: "weigh-in-daily"), "Should remove daily weigh-in notification")
        #expect(ctx.mockCenter.addedRequests.isEmpty, "Should have no remaining notifications")
    }

    // MARK: - Weekly Weigh-in Reminder Tests

    @Test("Schedule weekly weigh-in reminder when enabled and authorized")
    func testScheduleWeighInWeeklyReminderSuccess() async throws {
        // GIVEN: NotificationService with weekly weigh-in enabled and authorized
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized
        ctx.service.weighInWeeklyEnabled = true
        ctx.service.weighInWeeklyDay = 2  // Monday
        ctx.service.weighInWeeklyTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

        // WHEN: Schedule weekly weigh-in reminder
        try await ctx.service.scheduleWeighInWeeklyReminder()

        // THEN: Notification should be scheduled with correct content
        let requests = ctx.mockCenter.addedRequests
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
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.service.weighInWeeklyEnabled = false

        // WHEN: Schedule weekly weigh-in reminder (should cancel instead)
        try await ctx.service.scheduleWeighInWeeklyReminder()

        // THEN: No notification should be scheduled
        #expect(ctx.mockCenter.addedRequests.isEmpty, "Should not schedule when disabled")

        // AND: Cancel request should be made
        #expect(ctx.mockCenter.wasRemoved(identifier: "weigh-in-weekly"), "Should cancel existing reminder")
    }

    @Test("Schedule weekly weigh-in reminder throws when not authorized")
    func testScheduleWeighInWeeklyReminderThrowsWhenNotAuthorized() async throws {
        // GIVEN: NotificationService with weekly weigh-in enabled but not authorized
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .denied
        ctx.service.weighInWeeklyEnabled = true

        // WHEN/THEN: Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await ctx.service.scheduleWeighInWeeklyReminder()
        }
    }

    @Test("Cancel weekly weigh-in reminder removes pending notification")
    func testCancelWeighInWeeklyReminder() async throws {
        // GIVEN: NotificationService with an existing weekly weigh-in reminder
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        // First schedule a notification
        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized
        ctx.service.weighInWeeklyEnabled = true
        try await ctx.service.scheduleWeighInWeeklyReminder()
        #expect(ctx.mockCenter.addedRequests.count == 1, "Should have one scheduled notification")

        // WHEN: Cancel weekly weigh-in reminder
        ctx.service.cancelWeighInWeeklyReminder()

        // THEN: Notification should be removed
        #expect(ctx.mockCenter.wasRemoved(identifier: "weigh-in-weekly"), "Should remove weekly weigh-in notification")
        #expect(ctx.mockCenter.addedRequests.isEmpty, "Should have no remaining notifications")
    }

    // MARK: - Meal Reminder Tests

    @Test("Schedule meal reminder when enabled and authorized")
    func testScheduleMealReminderSuccess() async throws {
        // GIVEN: NotificationService with authorized state
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized
        let reminderTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()

        // WHEN: Schedule meal reminder for lunch
        try await ctx.service.scheduleMealReminder(
            meal: "Lunch",
            identifier: "food-log-lunch",
            time: reminderTime,
            enabled: true
        )

        // THEN: Notification should be scheduled with correct content
        let requests = ctx.mockCenter.addedRequests
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
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        let reminderTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

        // WHEN: Schedule meal reminder with enabled = false
        try await ctx.service.scheduleMealReminder(
            meal: "Breakfast",
            identifier: "food-log-breakfast",
            time: reminderTime,
            enabled: false
        )

        // THEN: No notification should be scheduled
        #expect(ctx.mockCenter.addedRequests.isEmpty, "Should not schedule when disabled")

        // AND: Cancel request should be made for this identifier
        #expect(ctx.mockCenter.wasRemoved(identifier: "food-log-breakfast"), "Should cancel existing reminder")
    }

    @Test("Schedule meal reminder throws when not authorized")
    func testScheduleMealReminderThrowsWhenNotAuthorized() async throws {
        // GIVEN: NotificationService with denied authorization
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .denied
        let reminderTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()

        // WHEN/THEN: Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await ctx.service.scheduleMealReminder(
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
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized
        let reminderTime = Calendar.current.date(from: DateComponents(hour: 15, minute: 0)) ?? Date()

        // WHEN: Schedule meal reminder with uppercase meal name
        try await ctx.service.scheduleMealReminder(
            meal: "SNACK",
            identifier: "food-log-snack",
            time: reminderTime,
            enabled: true
        )

        // THEN: Title should use lowercased meal name
        let request = ctx.mockCenter.addedRequests.first
        #expect(request?.content.title == "Log your snack", "Should lowercase meal name in title")
    }

    // MARK: - Refresh Food Logging Reminders Tests

    @Test("Refresh food logging reminders schedules all enabled meals")
    func testRefreshFoodLoggingRemindersAllEnabled() async throws {
        // GIVEN: NotificationService with all meal reminders enabled
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized
        ctx.service.breakfastReminderEnabled = true
        ctx.service.lunchReminderEnabled = true
        ctx.service.snackReminderEnabled = true
        ctx.service.dinnerReminderEnabled = true
        ctx.service.endOfDayReminderEnabled = true

        // WHEN: Refresh food logging reminders
        try await ctx.service.refreshFoodLoggingReminders()

        // THEN: All 5 meal reminders should be scheduled
        #expect(ctx.mockCenter.addedRequests.count == 5, "Should schedule all 5 meal reminders")

        // Verify each meal reminder exists
        let identifiers = Set(ctx.mockCenter.addedRequests.map { $0.identifier })
        #expect(identifiers.contains("food-log-breakfast"), "Should include breakfast reminder")
        #expect(identifiers.contains("food-log-lunch"), "Should include lunch reminder")
        #expect(identifiers.contains("food-log-snack"), "Should include snack reminder")
        #expect(identifiers.contains("food-log-dinner"), "Should include dinner reminder")
        #expect(identifiers.contains("food-log-end-of-day"), "Should include end of day reminder")
    }

    @Test("Refresh food logging reminders with only some enabled")
    func testRefreshFoodLoggingRemindersSomeEnabled() async throws {
        // GIVEN: NotificationService with only breakfast and dinner enabled
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized
        ctx.service.breakfastReminderEnabled = true
        ctx.service.lunchReminderEnabled = false
        ctx.service.snackReminderEnabled = false
        ctx.service.dinnerReminderEnabled = true
        ctx.service.endOfDayReminderEnabled = false

        // WHEN: Refresh food logging reminders
        try await ctx.service.refreshFoodLoggingReminders()

        // THEN: Only 2 meal reminders should be scheduled
        #expect(ctx.mockCenter.addedRequests.count == 2, "Should schedule only 2 meal reminders")

        let identifiers = Set(ctx.mockCenter.addedRequests.map { $0.identifier })
        #expect(identifiers.contains("food-log-breakfast"), "Should include breakfast reminder")
        #expect(identifiers.contains("food-log-dinner"), "Should include dinner reminder")
        #expect(!identifiers.contains("food-log-lunch"), "Should not include lunch reminder")
        #expect(!identifiers.contains("food-log-snack"), "Should not include snack reminder")
        #expect(!identifiers.contains("food-log-end-of-day"), "Should not include end of day reminder")
    }

    @Test("Refresh food logging reminders with none enabled")
    func testRefreshFoodLoggingRemindersNoneEnabled() async throws {
        // GIVEN: NotificationService with all meal reminders disabled
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.service.breakfastReminderEnabled = false
        ctx.service.lunchReminderEnabled = false
        ctx.service.snackReminderEnabled = false
        ctx.service.dinnerReminderEnabled = false
        ctx.service.endOfDayReminderEnabled = false

        // WHEN: Refresh food logging reminders
        try await ctx.service.refreshFoodLoggingReminders()

        // THEN: No meal reminders should be scheduled
        #expect(ctx.mockCenter.addedRequests.isEmpty, "Should not schedule any meal reminders")

        // AND: All meal reminder identifiers should be removed
        #expect(ctx.mockCenter.wasRemoved(identifier: "food-log-breakfast"), "Should cancel breakfast reminder")
        #expect(ctx.mockCenter.wasRemoved(identifier: "food-log-lunch"), "Should cancel lunch reminder")
        #expect(ctx.mockCenter.wasRemoved(identifier: "food-log-snack"), "Should cancel snack reminder")
        #expect(ctx.mockCenter.wasRemoved(identifier: "food-log-dinner"), "Should cancel dinner reminder")
        #expect(ctx.mockCenter.wasRemoved(identifier: "food-log-end-of-day"), "Should cancel end of day reminder")
    }

    @Test("Refresh food logging reminders throws when not authorized")
    func testRefreshFoodLoggingRemindersThrowsWhenNotAuthorized() async throws {
        // GIVEN: NotificationService with denied authorization but reminders enabled
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .denied
        ctx.service.breakfastReminderEnabled = true

        // WHEN/THEN: Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await ctx.service.refreshFoodLoggingReminders()
        }
    }

    @Test("Refresh food logging reminders end of day has custom content")
    func testRefreshFoodLoggingRemindersEndOfDayContent() async throws {
        // GIVEN: NotificationService with only end of day enabled
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized
        ctx.service.breakfastReminderEnabled = false
        ctx.service.lunchReminderEnabled = false
        ctx.service.snackReminderEnabled = false
        ctx.service.dinnerReminderEnabled = false
        ctx.service.endOfDayReminderEnabled = true
        ctx.service.endOfDayReminderTime = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()

        // WHEN: Refresh food logging reminders
        try await ctx.service.refreshFoodLoggingReminders()

        // THEN: End of day reminder should have custom content
        #expect(ctx.mockCenter.addedRequests.count == 1, "Should schedule end of day reminder")

        let request = ctx.mockCenter.addedRequests.first
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
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized
        ctx.service.breakfastReminderEnabled = true
        ctx.service.lunchReminderEnabled = true
        ctx.service.snackReminderEnabled = true
        ctx.service.dinnerReminderEnabled = true
        ctx.service.endOfDayReminderEnabled = true

        // Schedule all reminders first
        try await ctx.service.refreshFoodLoggingReminders()
        #expect(ctx.mockCenter.addedRequests.count == 5, "Should have 5 scheduled notifications")

        // WHEN: Cancel all food logging reminders
        ctx.service.cancelAllFoodLoggingReminders()

        // THEN: All meal notifications should be removed
        #expect(ctx.mockCenter.wasRemoved(identifier: "food-log-breakfast"), "Should remove breakfast reminder")
        #expect(ctx.mockCenter.wasRemoved(identifier: "food-log-lunch"), "Should remove lunch reminder")
        #expect(ctx.mockCenter.wasRemoved(identifier: "food-log-snack"), "Should remove snack reminder")
        #expect(ctx.mockCenter.wasRemoved(identifier: "food-log-dinner"), "Should remove dinner reminder")
        #expect(ctx.mockCenter.wasRemoved(identifier: "food-log-end-of-day"), "Should remove end of day reminder")
        #expect(ctx.mockCenter.addedRequests.isEmpty, "Should have no remaining notifications")
    }

    @Test("Cancel all food logging reminders works when none scheduled")
    func testCancelAllFoodLoggingRemindersWhenNoneScheduled() async throws {
        // GIVEN: NotificationService with no meal reminders scheduled
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        #expect(ctx.mockCenter.addedRequests.isEmpty, "Should start with no notifications")

        // WHEN: Cancel all food logging reminders
        ctx.service.cancelAllFoodLoggingReminders()

        // THEN: Should complete without error and identifiers should be in removed list
        #expect(ctx.mockCenter.removedIdentifiers.count == 1, "Should have one removal batch")
        let removedBatch = ctx.mockCenter.removedIdentifiers.first ?? []
        #expect(removedBatch.count == 5, "Should attempt to remove all 5 meal reminder identifiers")
    }

    // MARK: - Authorization Check Tests

    @Test("Authorization check passes when authorized")
    func testAuthorizationCheckPassesWhenAuthorized() async throws {
        // GIVEN: NotificationService with authorized state
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized
        ctx.service.weighInDailyEnabled = true

        // WHEN: Attempt to schedule (which internally calls checkAuthorizationBeforeScheduling)
        // THEN: Should not throw
        try await ctx.service.scheduleWeighInDailyReminder()
        #expect(ctx.mockCenter.addedRequests.count == 1, "Should successfully schedule notification")
    }

    @Test("Authorization check fails when notDetermined")
    func testAuthorizationCheckFailsWhenNotDetermined() async throws {
        // GIVEN: NotificationService with notDetermined state
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .notDetermined
        ctx.service.weighInDailyEnabled = true

        // WHEN/THEN: Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await ctx.service.scheduleWeighInDailyReminder()
        }
    }

    @Test("Authorization check fails when provisional")
    func testAuthorizationCheckFailsWhenProvisional() async throws {
        // GIVEN: NotificationService with provisional state
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .provisional
        ctx.service.weighInWeeklyEnabled = true

        // WHEN/THEN: Should throw authorization denied error
        await #expect(throws: NotificationServiceError.authorizationDenied) {
            try await ctx.service.scheduleWeighInWeeklyReminder()
        }
    }

    // MARK: - Edge Case Tests

    @Test("Schedule meal reminder with various time components")
    func testScheduleMealReminderTimeComponents() async throws {
        // GIVEN: NotificationService with authorized state
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized

        // Test with unusual time (23:59)
        let lateTime = Calendar.current.date(from: DateComponents(hour: 23, minute: 59)) ?? Date()

        // WHEN: Schedule meal reminder at edge-case time
        try await ctx.service.scheduleMealReminder(
            meal: "Late Night Snack",
            identifier: "food-log-late",
            time: lateTime,
            enabled: true
        )

        // THEN: Should handle edge-case time correctly
        let request = ctx.mockCenter.addedRequests.first
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
        let ctx = try createTestNotificationService()
        _ = ctx.container  // Keep container alive

        ctx.mockCenter.authorizationStatus = .authorized
        ctx.service.authorizationStatus = .authorized
        ctx.service.weighInWeeklyEnabled = true

        // Test Sunday (1)
        ctx.service.weighInWeeklyDay = 1
        try await ctx.service.scheduleWeighInWeeklyReminder()

        var request = ctx.mockCenter.addedRequests.first
        if let trigger = request?.trigger as? UNCalendarNotificationTrigger {
            #expect(trigger.dateComponents.weekday == 1, "Should trigger on Sunday")
        }

        // Reset and test Saturday (7)
        ctx.mockCenter.reset()
        ctx.service.weighInWeeklyDay = 7
        try await ctx.service.scheduleWeighInWeeklyReminder()

        request = ctx.mockCenter.addedRequests.first
        if let trigger = request?.trigger as? UNCalendarNotificationTrigger {
            #expect(trigger.dateComponents.weekday == 7, "Should trigger on Saturday")
        }
    }
}
