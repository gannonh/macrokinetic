import Foundation
import OSLog
import UserNotifications

/// NotificationService manages all notification functionality for the dose scheduling system.
///
/// This service orchestrates dose reminder notifications, handles notification actions (take, skip, snooze),
/// manages a 30-day rolling notification queue, and detects missed doses for timely alerts.
///
/// Architecture:
/// - Uses @Observable pattern for real-time updates (iOS 17+)
/// - Implements UNUserNotificationCenterDelegate as singleton for app-wide delegate access
/// - Integrates with ScheduleService for dose schedule access
/// - Respects iOS 64-notification limit through prioritization
///
/// Notification Lifecycle:
/// 1. Authorization requested on first use
/// 2. Categories registered with actionable buttons (Take, Skip, Snooze)
/// 3. Queue refreshed with 30 days of upcoming doses
/// 4. Notifications scheduled at reminder time (default: 1 hour before dose)
/// 5. User receives notification with actions
/// 6. Actions handled through delegate methods
/// 7. Queue updated after dose taken/skipped
/// 8. Background refresh keeps queue current
///
/// Thread Safety: All public methods are @MainActor to ensure safe access to @Observable properties
@Observable
@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    // MARK: - Properties

    /// Injected ScheduleService dependency for accessing dose schedules
    internal let scheduleService: ScheduleService

    /// User notification center for scheduling and managing notifications
    internal var notificationCenter: NotificationCenterProtocol

    /// Current notification queue (pending notifications)
    var notificationQueue: [PendingNotification] = []

    /// Current authorization status for notifications
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Indicates if notification queue is currently being refreshed
    var isRefreshing: Bool = false

    /// Logger for notification service operations
    internal let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "NotificationService")

    // MARK: - Constants

    /// Keys for notification userInfo dictionary
    enum UserInfoKeys {
        static let scheduledDoseId = "scheduledDoseId"
        static let titrationId = "titrationId"
    }

    // MARK: - Initialization

    /**
     * Initialize NotificationService with required dependencies.
     *
     * - Parameters:
     *   - scheduleService: Service for accessing dose schedules
     *   - notificationCenter: User notification center (default: .current())
     *
     * - Note: Sets self as UNUserNotificationCenter delegate and registers notification categories
     */
    init(
        scheduleService: ScheduleService,
        notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current()
    ) {
        self.scheduleService = scheduleService
        self.notificationCenter = notificationCenter
        super.init()
        self.notificationCenter.delegate = self
        registerNotificationCategories()
    }

    // MARK: - Authorization

    /**
     * Request notification authorization from the user.
     *
     * Requests permissions for alert, sound, and badge notifications. Updates the authorizationStatus
     * property based on the user's response.
     *
     * - Returns: True if authorized, false if denied
     * - Throws: NotificationServiceError.authorizationDenied if user denies permission
     */
    func requestAuthorization() async throws -> Bool {
        logger.info("Requesting notification authorization")

        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            let status = await checkAuthorizationStatus()

            logger.info("Authorization request completed: granted=\(granted), status=\(String(describing: status))")

            if !granted {
                throw NotificationServiceError.authorizationDenied
            }

            return granted
        } catch {
            logger.error("Authorization request failed: \(error.localizedDescription)")
            throw error
        }
    }

    /**
     * Check the current notification authorization status.
     *
     * Queries the notification center for current settings and updates the authorizationStatus property.
     *
     * - Returns: Current UNAuthorizationStatus
     */
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus

        logger.debug("Authorization status checked: \(String(describing: self.authorizationStatus))")

        return authorizationStatus
    }

    /**
     * Register notification categories with actionable buttons.
     *
     * Registers three categories:
     * - DOSE_REMINDER: Take, Skip, Snooze actions for upcoming doses
     * - MISSED_DOSE: Take Now, Skip actions for missed doses
     * - TITRATION: Complete, Reschedule, Remind Later actions for titration
     *
     * Called automatically during initialization.
     */
    func registerNotificationCategories() {  // swiftlint:disable:this function_body_length
        logger.info("Registering notification categories")

        // Dose Reminder Category
        let takeAction = UNNotificationAction(
            identifier: "TAKE_DOSE",
            title: NSLocalizedString("Take Dose", comment: "Notification action"),
            options: [.foreground]
        )
        let skipAction = UNNotificationAction(
            identifier: "SKIP_DOSE",
            title: NSLocalizedString("Skip", comment: "Notification action"),
            options: [.destructive]
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE",
            title: NSLocalizedString("Snooze 15m", comment: "Notification action"),
            options: []
        )
        let doseReminderCategory = UNNotificationCategory(
            identifier: "DOSE_REMINDER",
            actions: [takeAction, skipAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        // Missed Dose Category
        let takeNowAction = UNNotificationAction(
            identifier: "TAKE_NOW",
            title: NSLocalizedString("Take Now", comment: "Notification action"),
            options: [.foreground]
        )
        let skipMissedAction = UNNotificationAction(
            identifier: "SKIP_MISSED",
            title: NSLocalizedString("Skip", comment: "Notification action"),
            options: [.destructive]
        )
        let missedDoseCategory = UNNotificationCategory(
            identifier: "MISSED_DOSE",
            actions: [takeNowAction, skipMissedAction],
            intentIdentifiers: [],
            options: []
        )

        // Titration Category
        let completeTitrationAction = UNNotificationAction(
            identifier: "COMPLETE_TITRATION",
            title: NSLocalizedString("Complete", comment: "Notification action"),
            options: [.foreground]
        )
        let rescheduleTitrationAction = UNNotificationAction(
            identifier: "RESCHEDULE_TITRATION",
            title: NSLocalizedString("Reschedule", comment: "Notification action"),
            options: [.foreground]
        )
        let remindLaterTitrationAction = UNNotificationAction(
            identifier: "REMIND_LATER_TITRATION",
            title: NSLocalizedString("Remind Later", comment: "Notification action"),
            options: []
        )
        let titrationCategory = UNNotificationCategory(
            identifier: "TITRATION",
            actions: [completeTitrationAction, rescheduleTitrationAction, remindLaterTitrationAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            doseReminderCategory,
            missedDoseCategory,
            titrationCategory,
        ])

        logger.info("Notification categories registered successfully")
    }

    // MARK: - Queue Management

    /**
     * Refresh the notification queue with upcoming doses for the next 30 days.
     *
     * Cancels all existing pending notifications and schedules new ones based on the current
     * dose schedule. Respects iOS 64-notification limit by prioritizing nearest doses.
     *
     * - Throws: NotificationServiceError if scheduling fails
     */
    func refreshNotificationQueue() async throws {
        logger.info("Refreshing notification queue")
        isRefreshing = true
        defer { isRefreshing = false }

        // Refresh upcoming doses from ScheduleService (30 days ahead by default)
        scheduleService.refreshUpcomingDoses()

        // Get upcoming doses from ScheduleService
        let upcomingDoses = scheduleService.upcomingDoses
        logger.debug("Found \(upcomingDoses.count) upcoming doses")

        // Cancel all existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        logger.debug("Cancelled all existing pending notifications")

        // Limit to 64 notifications (iOS constraint)
        let dosesToSchedule = Array(upcomingDoses.prefix(64))
        if upcomingDoses.count > 64 {
            logger.warning(
                "Upcoming doses (\(upcomingDoses.count)) exceeds iOS 64-notification limit, scheduling only first 64")
        }

        // Schedule notifications for upcoming doses
        for scheduledDose in dosesToSchedule {
            try await scheduleDoseReminder(for: scheduledDose)
        }
        logger.debug("Scheduled \(dosesToSchedule.count) dose reminders")

        // Update queue property from pending notifications
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        notificationQueue = pendingRequests.compactMap { request in
            guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                let triggerDate = trigger.nextTriggerDate(),
                let doseIDString = request.content.userInfo[UserInfoKeys.scheduledDoseId] as? String,
                let doseID = UUID(uuidString: doseIDString)
            else {
                return nil
            }

            let content = NotificationContent(
                title: request.content.title,
                body: request.content.body,
                categoryIdentifier: request.content.categoryIdentifier
            )

            return PendingNotification(
                id: request.identifier,
                scheduledDoseId: doseID,
                triggerDate: triggerDate,
                content: content
            )
        }

        logger.info("Notification queue refreshed with \(self.notificationQueue.count) notifications")
    }

    /**
     * Schedule a dose reminder notification.
     *
     * Creates and schedules a notification for the specified dose at the configured reminder time.
     * Default reminder is 1 hour before the scheduled dose time.
     *
     * - Parameters:
     *   - scheduledDose: The scheduled dose to remind about
     *   - reminderOffset: Time offset before dose (negative value, default: -3600 seconds / -1 hour)
     * - Throws: NotificationServiceError.schedulingFailed if notification cannot be scheduled
     */
    func scheduleDoseReminder(for scheduledDose: ScheduledDose, reminderOffset: TimeInterval = -3600) async throws {
        logger.info("Scheduling dose reminder for dose: \(scheduledDose.id)")

        // Calculate trigger time
        let triggerDate = scheduledDose.scheduledTime.addingTimeInterval(reminderOffset)

        // Don't schedule notifications in the past
        guard triggerDate > Date() else {
            logger.debug("Skipping notification for dose in the past: \(scheduledDose.id)")
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Time for your dose", comment: "Dose reminder title")
        content.body = NSLocalizedString("Medication reminder", comment: "Dose reminder body")
        content.sound = .default
        content.categoryIdentifier = "DOSE_REMINDER"

        // Include scheduledDoseId in userInfo for action handling
        content.userInfo = [UserInfoKeys.scheduledDoseId: scheduledDose.id.uuidString]

        // Create calendar trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: scheduledDose.id.uuidString,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        do {
            try await notificationCenter.add(request)
            logger.info("Notification scheduled for \(triggerDate)")
        } catch {
            logger.error("Failed to schedule notification: \(error.localizedDescription)")
        }
    }

    /**
     * Schedule a titration notification for dose change reminder.
     *
     * Creates and schedules a notification for the specified titration on the scheduled date.
     * The notification includes Complete, Reschedule, and Remind Later actions.
     *
     * - Parameter titration: The dose titration to remind about
     * - Throws: NotificationServiceError.schedulingFailed if notification cannot be scheduled
     */
    func scheduleTitrationNotification(for titration: DoseTitration) async throws {
        logger.info("Scheduling titration notification for titration: \(titration.id)")

        // Don't schedule notifications in the past
        guard titration.scheduledDate > Date() else {
            logger.debug("Skipping notification for titration in the past: \(titration.id)")
            return
        }

        // Verify medication profile exists for notification content
        guard titration.medicationProfile != nil else {
            logger.error("Titration missing medication profile")
            throw NotificationServiceError.invalidScheduledDose
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        let changeDirection = titration.toDose > titration.fromDose ? "Increase" : "Decrease"
        content.title = NSLocalizedString("Dose \(changeDirection) Scheduled", comment: "Titration notification title")
        content.body = NSLocalizedString(
            "Time to increase your dose from \(titration.fromDose)mg to \(titration.toDose)mg",
            comment: "Titration notification body"
        )
        content.sound = .default
        content.categoryIdentifier = "TITRATION"

        // Include titrationId in userInfo for action handling
        content.userInfo = [UserInfoKeys.titrationId: titration.id.uuidString]

        // Create calendar trigger for titration date
        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: titration.scheduledDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: "titration-\(titration.id.uuidString)",
            content: content,
            trigger: trigger
        )

        // Schedule notification
        do {
            try await notificationCenter.add(request)
            logger.info("Titration notification scheduled for \(titration.scheduledDate)")
        } catch {
            logger.error("Failed to schedule titration notification: \(error.localizedDescription)")
            throw NotificationServiceError.schedulingFailed
        }
    }

    /**
     * Cancel a notification for a specific scheduled dose.
     *
     * Removes the pending notification from the notification center and updates the queue.
     *
     * - Parameter scheduledDose: The scheduled dose whose notification should be cancelled
     */
    func cancelNotification(for scheduledDose: ScheduledDose) {
        logger.info("Cancelling notification for dose: \(scheduledDose.id)")

        notificationCenter.removePendingNotificationRequests(withIdentifiers: [scheduledDose.id.uuidString])

        // Update queue to remove cancelled notification
        notificationQueue.removeAll { $0.scheduledDoseId == scheduledDose.id }

        logger.debug("Notification cancelled and queue updated")
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await Task { @MainActor in
            do {
                try await self.handleNotificationResponse(response)
                self.logger.info("Successfully handled notification response: \(response.actionIdentifier)")
            } catch {
                self.logger.error("Failed to handle notification response: \(error.localizedDescription)")
            }
        }.value
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notifications even when app is in foreground
        [.banner, .sound, .badge]
    }
}

// MARK: - NotificationServiceError

/// Errors specific to NotificationService operations.
enum NotificationServiceError: LocalizedError {
    case authorizationDenied
    case schedulingFailed
    case notificationLimitExceeded
    case invalidScheduledDose

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return NSLocalizedString(
                "Notification authorization was denied. Please enable notifications in Settings.",
                comment: "Authorization denied error"
            )
        case .schedulingFailed:
            return NSLocalizedString(
                "Failed to schedule notification. Please try again.",
                comment: "Scheduling failed error"
            )
        case .notificationLimitExceeded:
            return NSLocalizedString(
                "Cannot schedule more notifications. iOS limit of 64 notifications reached.",
                comment: "Notification limit error"
            )
        case .invalidScheduledDose:
            return NSLocalizedString(
                "Invalid scheduled dose. Cannot create notification.",
                comment: "Invalid dose error"
            )
        }
    }
}
