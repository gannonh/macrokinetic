import Foundation
import OSLog
import UserNotifications

extension NotificationService {
    private static let reminderLogger = Logger(
        subsystem: "com.gannonhall.JabTracker",
        category: "NotificationReminders"
    )

    // MARK: - Weigh-in Reminders

    /**
     * Schedule daily weigh-in reminder.
     *
     * If enabled, schedules a repeating notification to remind the user to log their weight daily
     * at the configured time. If disabled, cancels the reminder.
     */
    func scheduleWeighInDailyReminder() async throws {
        guard weighInDailyEnabled else {
            cancelWeighInDailyReminder()
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Time to weigh in"
        content.body = "Track your progress by logging today's weight"
        content.categoryIdentifier = "WEIGH_IN_REMINDER"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: weighInDailyTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "weigh-in-daily",
            content: content,
            trigger: trigger
        )
        try await notificationCenter.add(request)
        Self.reminderLogger.info(
            "Scheduled daily weigh-in reminder at \(components.hour ?? 0):\(components.minute ?? 0)"
        )
    }

    /**
     * Cancel daily weigh-in reminder.
     */
    func cancelWeighInDailyReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["weigh-in-daily"])
    }

    /**
     * Schedule weekly weigh-in reminder.
     *
     * If enabled, schedules a repeating notification to remind the user to log their weight weekly
     * on the configured day and time. If disabled, cancels the reminder.
     */
    func scheduleWeighInWeeklyReminder() async throws {
        guard weighInWeeklyEnabled else {
            cancelWeighInWeeklyReminder()
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Weekly weigh-in"
        content.body = "Time for your weekly weight check"
        content.categoryIdentifier = "WEIGH_IN_REMINDER"
        content.sound = .default

        var components = Calendar.current.dateComponents([.hour, .minute], from: weighInWeeklyTime)
        components.weekday = weighInWeeklyDay
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "weigh-in-weekly",
            content: content,
            trigger: trigger
        )
        try await notificationCenter.add(request)
        Self.reminderLogger.info("Scheduled weekly weigh-in reminder")
    }

    /**
     * Cancel weekly weigh-in reminder.
     */
    func cancelWeighInWeeklyReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["weigh-in-weekly"])
    }

    // MARK: - Food Logging Reminders

    /**
     * Schedule a meal reminder.
     *
     * Generic helper to schedule or cancel a meal reminder based on enabled state.
     *
     * - Parameters:
     *   - meal: Meal name (e.g., "Breakfast", "Lunch")
     *   - identifier: Unique identifier for this reminder
     *   - time: Time of day for the reminder
     *   - enabled: Whether the reminder is enabled
     */
    func scheduleMealReminder(meal: String, identifier: String, time: Date, enabled: Bool) async throws {
        guard enabled else {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Log your \(meal.lowercased())"
        content.body = "Don't forget to track what you ate"
        content.categoryIdentifier = "FOOD_LOG_REMINDER"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        try await notificationCenter.add(request)
        Self.reminderLogger.info("Scheduled \(meal) reminder at \(components.hour ?? 0):\(components.minute ?? 0)")
    }

    /**
     * Schedule all food logging reminders based on current settings.
     *
     * Refreshes all meal reminders (breakfast, lunch, snack, dinner, end of day)
     * according to their enabled state and configured times.
     */
    func refreshFoodLoggingReminders() async throws {
        try await scheduleMealReminder(
            meal: "Breakfast",
            identifier: "food-log-breakfast",
            time: breakfastReminderTime,
            enabled: breakfastReminderEnabled
        )
        try await scheduleMealReminder(
            meal: "Lunch",
            identifier: "food-log-lunch",
            time: lunchReminderTime,
            enabled: lunchReminderEnabled
        )
        try await scheduleMealReminder(
            meal: "Snack",
            identifier: "food-log-snack",
            time: snackReminderTime,
            enabled: snackReminderEnabled
        )
        try await scheduleMealReminder(
            meal: "Dinner",
            identifier: "food-log-dinner",
            time: dinnerReminderTime,
            enabled: dinnerReminderEnabled
        )

        // End of day reminder has different copy
        if endOfDayReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Log your meals"
            content.body = "Take a moment to log everything you ate today"
            content.categoryIdentifier = "FOOD_LOG_REMINDER"
            content.sound = .default

            let components = Calendar.current.dateComponents([.hour, .minute], from: endOfDayReminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let request = UNNotificationRequest(
                identifier: "food-log-end-of-day",
                content: content,
                trigger: trigger
            )
            try await notificationCenter.add(request)
        } else {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: ["food-log-end-of-day"])
        }
    }

    /**
     * Cancel all food logging reminders.
     */
    func cancelAllFoodLoggingReminders() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "food-log-breakfast",
            "food-log-lunch",
            "food-log-snack",
            "food-log-dinner",
            "food-log-end-of-day",
        ])
    }
}
