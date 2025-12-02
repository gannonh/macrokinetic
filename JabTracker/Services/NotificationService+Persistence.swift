import Foundation
import OSLog

// MARK: - NotificationService+Persistence

extension NotificationService {
    // MARK: - UserDefaults Keys

    /// Keys for persisting notification settings to UserDefaults
    private enum PersistenceKeys {
        static let notificationsEnabled = "notificationsEnabled"
        static let reminderMinutesBefore = "reminderMinutesBefore"
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

        UserDefaults.standard.set(notificationsEnabled, forKey: PersistenceKeys.notificationsEnabled)
        UserDefaults.standard.set(reminderMinutesBefore, forKey: PersistenceKeys.reminderMinutesBefore)

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
    func loadState() {
        logger.debug("Loading notification state from UserDefaults")

        // Load notificationsEnabled (default: false if not found)
        if UserDefaults.standard.object(forKey: PersistenceKeys.notificationsEnabled) != nil {
            notificationsEnabled = UserDefaults.standard.bool(forKey: PersistenceKeys.notificationsEnabled)
        } else {
            notificationsEnabled = false
            logger.debug("No saved notificationsEnabled state, using default: false")
        }

        // Load reminderMinutesBefore (default: 60 if not found)
        if UserDefaults.standard.object(forKey: PersistenceKeys.reminderMinutesBefore) != nil {
            reminderMinutesBefore = UserDefaults.standard.integer(forKey: PersistenceKeys.reminderMinutesBefore)
        } else {
            reminderMinutesBefore = 60
            logger.debug("No saved reminderMinutesBefore state, using default: 60")
        }

        logger.info(
            """
            Notification state loaded: enabled=\(self.notificationsEnabled), \
            reminderMinutes=\(self.reminderMinutesBefore)
            """
        )
    }
}
