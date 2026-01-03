import Foundation
import OSLog

// MARK: - NotificationService+Persistence

extension NotificationService {
    // MARK: - UserDefaults Keys

    /// Keys for persisting notification settings to UserDefaults
    private enum PersistenceKeys {
        static let notificationsEnabled = "notificationsEnabled"
        static let reminderMinutesBefore = "reminderMinutesBefore"

        // Weigh-in reminder keys
        static let weighInDailyEnabled = "weighInDailyEnabled"
        static let weighInDailyTime = "weighInDailyTime"
        static let weighInWeeklyEnabled = "weighInWeeklyEnabled"
        static let weighInWeeklyDay = "weighInWeeklyDay"
        static let weighInWeeklyTime = "weighInWeeklyTime"

        // Food logging reminder keys
        static let breakfastReminderEnabled = "breakfastReminderEnabled"
        static let breakfastReminderTime = "breakfastReminderTime"
        static let lunchReminderEnabled = "lunchReminderEnabled"
        static let lunchReminderTime = "lunchReminderTime"
        static let snackReminderEnabled = "snackReminderEnabled"
        static let snackReminderTime = "snackReminderTime"
        static let dinnerReminderEnabled = "dinnerReminderEnabled"
        static let dinnerReminderTime = "dinnerReminderTime"
        static let endOfDayReminderEnabled = "endOfDayReminderEnabled"
        static let endOfDayReminderTime = "endOfDayReminderTime"
    }

    // MARK: - State Persistence

    /**
     * Save notification settings to UserDefaults.
     *
     * Persists the current state of notification preferences to device-local storage.
     * This allows settings to survive app restarts and be restored when the app launches.
     *
     * Settings saved:
     * - notificationsEnabled: Whether notifications are currently enabled
     * - reminderMinutesBefore: Minutes before dose to send reminder (15, 30, 60, or 120)
     *
     * - Note: Uses UserDefaults (not SwiftData) because these are device-specific settings
     * - Note: Should be called after enable(), disable(), or updateReminderTiming()
     */
    func saveState() {
        logger.debug("Saving notification state to UserDefaults")

        // Dose notifications
        UserDefaults.standard.set(notificationsEnabled, forKey: PersistenceKeys.notificationsEnabled)
        UserDefaults.standard.set(reminderMinutesBefore, forKey: PersistenceKeys.reminderMinutesBefore)

        // Weigh-in reminders
        UserDefaults.standard.set(weighInDailyEnabled, forKey: PersistenceKeys.weighInDailyEnabled)
        UserDefaults.standard.set(weighInDailyTime, forKey: PersistenceKeys.weighInDailyTime)
        UserDefaults.standard.set(weighInWeeklyEnabled, forKey: PersistenceKeys.weighInWeeklyEnabled)
        UserDefaults.standard.set(weighInWeeklyDay, forKey: PersistenceKeys.weighInWeeklyDay)
        UserDefaults.standard.set(weighInWeeklyTime, forKey: PersistenceKeys.weighInWeeklyTime)

        // Food logging reminders
        UserDefaults.standard.set(breakfastReminderEnabled, forKey: PersistenceKeys.breakfastReminderEnabled)
        UserDefaults.standard.set(breakfastReminderTime, forKey: PersistenceKeys.breakfastReminderTime)
        UserDefaults.standard.set(lunchReminderEnabled, forKey: PersistenceKeys.lunchReminderEnabled)
        UserDefaults.standard.set(lunchReminderTime, forKey: PersistenceKeys.lunchReminderTime)
        UserDefaults.standard.set(snackReminderEnabled, forKey: PersistenceKeys.snackReminderEnabled)
        UserDefaults.standard.set(snackReminderTime, forKey: PersistenceKeys.snackReminderTime)
        UserDefaults.standard.set(dinnerReminderEnabled, forKey: PersistenceKeys.dinnerReminderEnabled)
        UserDefaults.standard.set(dinnerReminderTime, forKey: PersistenceKeys.dinnerReminderTime)
        UserDefaults.standard.set(endOfDayReminderEnabled, forKey: PersistenceKeys.endOfDayReminderEnabled)
        UserDefaults.standard.set(endOfDayReminderTime, forKey: PersistenceKeys.endOfDayReminderTime)

        logger.info(
            """
            Notification state saved: enabled=\(self.notificationsEnabled), \
            reminderMinutes=\(self.reminderMinutesBefore)
            """
        )
    }

    /**
     * Load notification settings from UserDefaults.
     *
     * Restores previously saved notification preferences from device-local storage.
     * If no saved state exists, uses default values (disabled, 60 minutes).
     *
     * Settings loaded:
     * - notificationsEnabled: Whether notifications are currently enabled (default: false)
     * - reminderMinutesBefore: Minutes before dose to send reminder (default: 60)
     *
     * - Note: Should be called during initialization to restore user's preferences
     * - Note: Handles missing keys gracefully by using default values
     */
    func loadState() {  // swiftlint:disable:this cyclomatic_complexity
        logger.debug("Loading notification state from UserDefaults")

        // Load dose notification settings
        if UserDefaults.standard.object(forKey: PersistenceKeys.notificationsEnabled) != nil {
            notificationsEnabled = UserDefaults.standard.bool(forKey: PersistenceKeys.notificationsEnabled)
        } else {
            notificationsEnabled = false
            logger.debug("No saved notificationsEnabled state, using default: false")
        }

        if UserDefaults.standard.object(forKey: PersistenceKeys.reminderMinutesBefore) != nil {
            reminderMinutesBefore = UserDefaults.standard.integer(forKey: PersistenceKeys.reminderMinutesBefore)
        } else {
            reminderMinutesBefore = 60
            logger.debug("No saved reminderMinutesBefore state, using default: 60")
        }

        // Load weigh-in reminder settings
        if UserDefaults.standard.object(forKey: PersistenceKeys.weighInDailyEnabled) != nil {
            weighInDailyEnabled = UserDefaults.standard.bool(forKey: PersistenceKeys.weighInDailyEnabled)
        }
        if let savedTime = UserDefaults.standard.object(forKey: PersistenceKeys.weighInDailyTime) as? Date {
            weighInDailyTime = savedTime
        }
        if UserDefaults.standard.object(forKey: PersistenceKeys.weighInWeeklyEnabled) != nil {
            weighInWeeklyEnabled = UserDefaults.standard.bool(forKey: PersistenceKeys.weighInWeeklyEnabled)
        }
        if UserDefaults.standard.object(forKey: PersistenceKeys.weighInWeeklyDay) != nil {
            weighInWeeklyDay = UserDefaults.standard.integer(forKey: PersistenceKeys.weighInWeeklyDay)
        }
        if let savedTime = UserDefaults.standard.object(forKey: PersistenceKeys.weighInWeeklyTime) as? Date {
            weighInWeeklyTime = savedTime
        }

        // Load food logging reminder settings
        if UserDefaults.standard.object(forKey: PersistenceKeys.breakfastReminderEnabled) != nil {
            breakfastReminderEnabled = UserDefaults.standard.bool(forKey: PersistenceKeys.breakfastReminderEnabled)
        }
        if let savedTime = UserDefaults.standard.object(forKey: PersistenceKeys.breakfastReminderTime) as? Date {
            breakfastReminderTime = savedTime
        }
        if UserDefaults.standard.object(forKey: PersistenceKeys.lunchReminderEnabled) != nil {
            lunchReminderEnabled = UserDefaults.standard.bool(forKey: PersistenceKeys.lunchReminderEnabled)
        }
        if let savedTime = UserDefaults.standard.object(forKey: PersistenceKeys.lunchReminderTime) as? Date {
            lunchReminderTime = savedTime
        }
        if UserDefaults.standard.object(forKey: PersistenceKeys.snackReminderEnabled) != nil {
            snackReminderEnabled = UserDefaults.standard.bool(forKey: PersistenceKeys.snackReminderEnabled)
        }
        if let savedTime = UserDefaults.standard.object(forKey: PersistenceKeys.snackReminderTime) as? Date {
            snackReminderTime = savedTime
        }
        if UserDefaults.standard.object(forKey: PersistenceKeys.dinnerReminderEnabled) != nil {
            dinnerReminderEnabled = UserDefaults.standard.bool(forKey: PersistenceKeys.dinnerReminderEnabled)
        }
        if let savedTime = UserDefaults.standard.object(forKey: PersistenceKeys.dinnerReminderTime) as? Date {
            dinnerReminderTime = savedTime
        }
        if UserDefaults.standard.object(forKey: PersistenceKeys.endOfDayReminderEnabled) != nil {
            endOfDayReminderEnabled = UserDefaults.standard.bool(forKey: PersistenceKeys.endOfDayReminderEnabled)
        }
        if let savedTime = UserDefaults.standard.object(forKey: PersistenceKeys.endOfDayReminderTime) as? Date {
            endOfDayReminderTime = savedTime
        }

        logger.info(
            """
            Notification state loaded: enabled=\(self.notificationsEnabled), \
            reminderMinutes=\(self.reminderMinutesBefore)
            """
        )
    }
}
