import Foundation
import OSLog
import UserNotifications

// MARK: - NotificationService+Background

extension NotificationService {
    // MARK: - Background Task Scheduling

    /**
     * Schedule a background refresh task to keep notification queue current.
     *
     * Registers a background task with iOS to periodically refresh the notification queue.
     * This ensures notifications stay up-to-date even when the app is not actively running.
     *
     * - Note: Actual BGTaskScheduler registration should be done in AppDelegate/App lifecycle
     * - Note: This is a placeholder for the full background task scheduling implementation
     */
    func scheduleBackgroundRefresh() {
        logger.info("Background refresh scheduling requested")
        // TODO: Implement BGTaskScheduler registration
        // This will be done when full background refresh is implemented
        // For now, this is a no-op but prevents crashes in enable()
    }

    // MARK: - Background Refresh

    /**
     * Perform a complete background refresh of the notification system.
     *
     * This method orchestrates:
     * 1. Refreshing the notification queue with upcoming doses
     * 2. Detecting and alerting for missed doses
     * 3. Updating the app badge count
     *
     * Designed to be called from background app refresh or when app becomes active.
     *
     * - Note: Gracefully handles authorization denial and notification center errors
     * - Note: Respects iOS 64-notification limit through prioritization
     */
    func performBackgroundRefresh() async throws {
        logger.info("Starting background refresh")

        // Skip if already refreshing
        guard !isRefreshing else {
            logger.info("Background refresh already in progress, skipping")
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            // Check authorization status
            let status = await checkAuthorizationStatus()
            guard status == .authorized else {
                logger.info("Notifications not authorized, skipping background refresh")
                await updateBadgeCount()
                return
            }

            // 1. Refresh notification queue with upcoming doses
            try await refreshNotificationQueue()

            // 2. Detect and alert for missed doses
            try await processMissedDoses()

            // 3. Update badge count
            await updateBadgeCount()

            logger.info("Background refresh completed successfully")
        } catch {
            logger.error("Background refresh failed: \(error.localizedDescription)")
            // Continue gracefully - update badge with what we have
            await updateBadgeCount()
        }
    }

    // MARK: - Badge Management

    /**
     * Update the app badge count based on pending notifications and missed doses.
     *
     * Badge count includes:
     * - Pending dose reminder notifications
     * - Missed dose notifications
     *
     * - Note: Badge count is set to 0 if queue is empty
     * - Note: Errors are logged but do not throw
     */
    func updateBadgeCount() async {
        logger.info("Updating badge count")

        // Calculate badge count from notification queue
        let pendingCount = notificationQueue.count

        // Add missed dose count
        let missedDoseCount = (try? await detectMissedDoses().count) ?? 0

        let totalCount = pendingCount + missedDoseCount

        do {
            try await notificationCenter.setBadgeCount(totalCount)
            logger.info("Badge count updated to \(totalCount)")
        } catch {
            logger.error("Failed to update badge count: \(error.localizedDescription)")
        }
    }

    // MARK: - Notification Content Creation

    /**
     * Create notification content for a dose reminder.
     *
     * - Parameter scheduledDose: The scheduled dose to create content for
     * - Returns: Localized notification content
     */
    func createDoseReminderContent(for scheduledDose: ScheduledDose) -> UNNotificationContent {
        let content = UNMutableNotificationContent()

        content.title = NSLocalizedString(
            "Time for your dose",
            comment: "Dose reminder notification title"
        )

        content.body = NSLocalizedString(
            "Your scheduled dose is coming up soon. Tap to log it.",
            comment: "Dose reminder notification body"
        )

        content.categoryIdentifier = "DOSE_REMINDER"
        content.sound = .default

        return content
    }

    /**
     * Create notification content for a missed dose alert.
     *
     * - Parameter scheduledDose: The missed dose to create content for
     * - Returns: Localized notification content
     */
    func createMissedDoseContent(for scheduledDose: ScheduledDose) -> UNNotificationContent {
        let content = UNMutableNotificationContent()

        content.title = NSLocalizedString(
            "Missed dose detected",
            comment: "Missed dose notification title"
        )

        content.body = NSLocalizedString(
            "You missed a scheduled dose. Tap to review your schedule.",
            comment: "Missed dose notification body"
        )

        content.categoryIdentifier = "MISSED_DOSE"
        content.sound = .default

        return content
    }
}
