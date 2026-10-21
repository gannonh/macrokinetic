import Foundation
import OSLog
import UserNotifications

/// NotificationService manages all notification functionality for the dose scheduling system.
///
/// This service orchestrates dose reminder notifications, handles notification actions (take, skip, snooze),
/// manages a rolling notification queue within iOS's 64 pending requests, and detects missed doses.
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
/// 3. Queue refreshed with the nearest upcoming doses on every foreground and schedule change
/// 4. Notifications scheduled at reminder time (default: 1 hour before dose), plus a renewal notice
///    at the last queued dose
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

    /// Indicates if notifications are currently enabled by the user
    public var notificationsEnabled: Bool = false

    /// Minutes before scheduled dose time to send reminder notification
    public var reminderMinutesBefore: Int = 60

    // MARK: - Weigh-in Reminders

    /// Indicates if daily weigh-in reminders are enabled
    public var weighInDailyEnabled: Bool = false

    /// Time of day for daily weigh-in reminder
    public var weighInDailyTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()

    /// Indicates if weekly weigh-in reminders are enabled
    public var weighInWeeklyEnabled: Bool = false

    /// Day of week for weekly weigh-in reminder (1 = Sunday, 2 = Monday, etc.)
    public var weighInWeeklyDay: Int = 2

    /// Time of day for weekly weigh-in reminder
    public var weighInWeeklyTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()

    // MARK: - Food Logging Reminders

    /// Indicates if breakfast reminder is enabled
    public var breakfastReminderEnabled: Bool = false

    /// Time of day for breakfast reminder
    public var breakfastReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

    /// Indicates if lunch reminder is enabled
    public var lunchReminderEnabled: Bool = false

    /// Time of day for lunch reminder
    public var lunchReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()

    /// Indicates if snack reminder is enabled
    public var snackReminderEnabled: Bool = false

    /// Time of day for snack reminder
    public var snackReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 15, minute: 0)) ?? Date()

    /// Indicates if dinner reminder is enabled
    public var dinnerReminderEnabled: Bool = false

    /// Time of day for dinner reminder
    public var dinnerReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()

    /// Indicates if end of day reminder is enabled
    public var endOfDayReminderEnabled: Bool = false

    /// Time of day for end of day reminder
    public var endOfDayReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date()

    /// Refreshes the queue when any ScheduleService changes a schedule
    @ObservationIgnored private var scheduleObserver: NSObjectProtocol?

    /// The latest queue rebuild; each rebuild waits for the one before it
    @ObservationIgnored private var queueRebuild: Task<Void, Error>?

    /// Logger for notification service operations
    internal let logger = Logger(subsystem: "com.gannonhall.JabTracker", category: "NotificationService")

    // MARK: - Constants

    /// Keys for notification userInfo dictionary
    enum UserInfoKeys {
        static let scheduledDoseId = "scheduledDoseId"
        static let titrationId = "titrationId"
    }

    /// iOS keeps at most this many pending local notification requests per app
    static let pendingRequestLimit = 64

    /// Identifier of the notice telling the user to open the app before reminders run out
    static let renewalRequestIdentifier = "dose-reminders-renewal"

    /// Furthest ahead the dose reminder queue looks
    static let reminderHorizonDays = 365

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
        let launchResponses = LaunchNotificationDelegate.shared.takeResponses()
        Task {
            for response in launchResponses {
                do {
                    try await handleNotificationResponse(
                        actionIdentifier: response.actionIdentifier, request: response.request)
                } catch {
                    logger.error("Failed to handle launch notification response: \(error.localizedDescription)")
                }
            }
        }
        scheduleObserver = NotificationCenter.default.addObserver(
            forName: .doseSchedulesChanged, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in await self?.refreshIfEnabled() }
        }
        logger.info("NotificationService initialized")
    }

    static func cancelUnavailableTitrationNotifications(
        notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current()
    ) async {
        guard !ReleasePolicy.isEnabled(.medicalCalculators) else { return }
        let requests = await notificationCenter.pendingNotificationRequests()
        let identifiers = requests.filter(isTitrationRequest).map(\.identifier)
        if !identifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    static func isTitrationRequest(_ request: UNNotificationRequest) -> Bool {
        request.content.categoryIdentifier == "TITRATION"
            || request.content.userInfo[UserInfoKeys.titrationId] != nil
            || request.identifier.hasPrefix("titration-")
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

        #if DEBUG || JABTRACKER_TEST_HARNESS
        // In UI testing mode, automatically grant authorization to avoid system alert interaction
        // IMPORTANT: Only apply in non-unit-test context (UI tests run the actual app)
        let isUnitTestEnvironment =
            ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.environment["XCTestSessionIdentifier"] != nil
        let isUITesting =
            ProcessInfo.processInfo.arguments.contains("--ui-testing") && !isUnitTestEnvironment
        if isUITesting {
            logger.info("UI testing mode detected - automatically granting authorization")
            authorizationStatus = .authorized
            return true
        }

        #endif

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
        authorizationStatus = await notificationCenter.authorizationStatus()

        logger.debug("Authorization status checked: \(String(describing: self.authorizationStatus))")

        return authorizationStatus
    }

    /**
     * Register notification categories with actionable buttons.
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

        // Weigh-in Reminder Category
        let weighInCategory = UNNotificationCategory(
            identifier: "WEIGH_IN_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        // Food Log Reminder Category
        let foodLogCategory = UNNotificationCategory(
            identifier: "FOOD_LOG_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        var categories: Set<UNNotificationCategory> = [
            doseReminderCategory,
            missedDoseCategory,
            weighInCategory,
            foodLogCategory,
        ]
        if ReleasePolicy.isEnabled(.medicalCalculators) {
            categories.insert(titrationCategory)
        }
        notificationCenter.setNotificationCategories(categories)

        logger.info("Notification categories registered successfully")
    }

    // MARK: - Queue Management

    /**
     * Rebuild the dose reminder queue with the nearest upcoming doses.
     *
     * Dose reminders share iOS's 64 pending requests with weigh-in and food reminders. They take
     * every free slot but one, which holds a notice at the last queued dose telling the user to open
     * the app. Only dose reminders and that notice are replaced; other reminders stay.
     *
     * Rebuilds run one at a time, so a schedule change during a rebuild is applied after it.
     *
     * - Parameter now: Doses after this time are queued
     * - Throws: NotificationServiceError if scheduling fails
     */
    func refreshNotificationQueue(now: Date = Date()) async throws {
        let previous = queueRebuild
        let rebuild = Task {
            _ = await previous?.result
            try await rebuildNotificationQueue(now: now)
        }
        queueRebuild = rebuild
        try await rebuild.value
    }

    private func rebuildNotificationQueue(now: Date) async throws {
        logger.info("Refreshing notification queue")
        isRefreshing = true
        defer { isRefreshing = false }

        let pending = await notificationCenter.pendingNotificationRequests()
        let stale = pending.filter(Self.isDoseQueueRequest).map(\.identifier)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: stale)
        let budget = max(0, Self.pendingRequestLimit - (pending.count - stale.count) - 1)

        scheduleService.refreshUpcomingDoses(from: now, daysAhead: Self.reminderHorizonDays, limit: budget)
        let doses = scheduleService.upcomingDoses
        let reminderOffset = -TimeInterval(reminderMinutesBefore * 60)
        for scheduledDose in doses {
            try await scheduleDoseReminder(for: scheduledDose, reminderOffset: reminderOffset)
        }
        if let lastDose = doses.last {
            try await scheduleRenewalNotice(at: lastDose.scheduledTime)
        }
        logger.debug("Scheduled \(doses.count) dose reminders within a budget of \(budget)")

        // Update queue property from pending notifications
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        #if DEBUG || JABTRACKER_TEST_HARNESS
        Self.writePendingRequestsForLiveChecks(pendingRequests)
        #endif
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

    /// Rebuild the queue when dose reminders are on and permitted. Runs on every foreground and
    /// after every schedule change.
    func refreshIfEnabled() async {
        guard notificationsEnabled, await checkAuthorizationStatus() == .authorized else { return }
        do {
            try await refreshNotificationQueue()
        } catch {
            logger.error("Failed to refresh notification queue: \(error.localizedDescription)")
        }
    }

    #if DEBUG || JABTRACKER_TEST_HARNESS
    /// Live checks read the pending queue from Documents; iOS offers no way to query it from outside the app.
    static func writePendingRequestsForLiveChecks(_ requests: [UNNotificationRequest]) {
        guard ProcessInfo.processInfo.arguments.contains("--dump-pending-notifications"),
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let rows = requests.map { request in
            let fireDate = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
            return [
                fireDate.map(formatter.string) ?? "repeating", request.content.categoryIdentifier,
                request.identifier, request.content.title,
            ].joined(separator: "\t")
        }
        try? rows.sorted().joined(separator: "\n")
            .write(to: documents.appendingPathComponent("pending-notifications.tsv"), atomically: true, encoding: .utf8)
    }
    #endif

    static func isDoseQueueRequest(_ request: UNNotificationRequest) -> Bool {
        request.content.categoryIdentifier == "DOSE_REMINDER" || request.identifier == renewalRequestIdentifier
    }

    /// Reminders stop after the last queued dose unless the app runs again, so say so when it fires.
    private func scheduleRenewalNotice(at date: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Open JabTracker to keep dose reminders", comment: "Renewal notice title")
        content.body = NSLocalizedString(
            "That was your last scheduled dose reminder. Open the app to schedule more.",
            comment: "Renewal notice body"
        )
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        try await notificationCenter.add(
            UNNotificationRequest(
                identifier: Self.renewalRequestIdentifier,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            ))
    }

    // MARK: - Activation Methods

    /**
     * Enable notifications and schedule reminders for all active schedules.
     *
     * This method:
     * 1. Requests notification authorization (if not already granted)
     * 2. Refreshes the notification queue with upcoming doses
     * 3. Schedules background refresh to keep queue current
     * 4. Updates notificationsEnabled state
     * 5. Persists state to UserDefaults
     *
     * - Throws: NotificationServiceError.authorizationDenied if user denies permission
     */
    public func enable() async throws {
        logger.info("[NOTIF_SERVICE] enable() called - current state: \(self.notificationsEnabled)")

        // 1. Check/request authorization
        let granted = try await requestAuthorization()
        logger.info("[NOTIF_SERVICE] requestAuthorization() returned: \(granted)")
        guard granted else {
            logger.warning("Authorization denied")
            throw NotificationServiceError.authorizationDenied
        }

        // 2. Refresh notification queue for all active schedules
        try await refreshNotificationQueue()
        logger.info("[NOTIF_SERVICE] refreshNotificationQueue() completed")

        // 3. Schedule background refresh
        scheduleBackgroundRefresh()

        // 4. Update enabled state
        notificationsEnabled = true
        logger.info("[NOTIF_SERVICE] Set notificationsEnabled = true")

        // 5. Persist state to UserDefaults
        saveState()
        logger.info("[NOTIF_SERVICE] saveState() called")

        logger.info("[NOTIF_SERVICE] Notifications enabled successfully - final state: \(self.notificationsEnabled)")
    }

    /**
     * Disable notifications and cancel all pending reminders.
     *
     * This method:
     * 1. Cancels all pending notifications
     * 2. Clears the notification queue
     * 3. Resets badge count to zero
     * 4. Updates notificationsEnabled state
     * 5. Persists state to UserDefaults
     */
    public func disable() async {
        logger.info("Disabling notifications")

        // 1. Cancel all pending notifications
        notificationCenter.removeAllPendingNotificationRequests()
        logger.debug("Cancelled all pending notifications")

        // 2. Clear notification queue
        notificationQueue.removeAll()

        // 3. Update badge count
        await updateBadgeCount()

        // 4. Update enabled state
        notificationsEnabled = false

        // 5. Persist state to UserDefaults
        saveState()

        logger.info("Notifications disabled successfully")
    }

    /**
     * Update reminder timing preference and reschedule notifications.
     *
     * Valid timing values are: 15, 30, 60, or 120 minutes before scheduled dose time.
     *
     * - Parameter minutes: Minutes before dose to send reminder (must be 15, 30, 60, or 120)
     * - Throws: NotificationServiceError.invalidReminderTiming if value is not valid
     */
    public func updateReminderTiming(_ minutes: Int) async throws {
        logger.info("Updating reminder timing to \(minutes) minutes")

        // Validate input
        guard [15, 30, 60, 120].contains(minutes) else {
            logger.error("Invalid reminder timing: \(minutes)")
            throw NotificationServiceError.invalidReminderTiming
        }

        // Update property
        reminderMinutesBefore = minutes

        // Reschedule all notifications with new timing if enabled
        if notificationsEnabled {
            try await refreshNotificationQueue()
            logger.info("Rescheduled notifications with new timing: \(minutes) minutes")
        }
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
        guard ReleasePolicy.isEnabled(.medicalCalculators) else {
            throw NotificationServiceError.medicalCalculatorsUnavailable
        }
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

    /// Uses the completion-handler form: iOS calls the async form's completion off the main thread, which
    /// crashes UIKit when the user taps a reminder.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        Task { @MainActor in
            do {
                try await self.handleNotificationResponse(response)
                self.logger.info("Successfully handled notification response: \(response.actionIdentifier)")
            } catch {
                self.logger.error("Failed to handle notification response: \(error.localizedDescription)")
            }
            completionHandler()
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await foregroundPresentationOptions(for: notification.request)
    }

    func foregroundPresentationOptions(for request: UNNotificationRequest) -> UNNotificationPresentationOptions {
        if !ReleasePolicy.isEnabled(.medicalCalculators) && Self.isTitrationRequest(request) {
            return []
        }
        return [.banner, .sound, .badge]
    }
}

// MARK: - LaunchNotificationDelegate

/// Holds notification responses that arrive before NotificationService exists, such as the tap that launched
/// the app. iOS delivers a launch tap only to a delegate set before launch finishes, and NotificationService
/// needs the model container, so it is created later and replays these.
@MainActor
final class LaunchNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LaunchNotificationDelegate()

    private var responses: [(actionIdentifier: String, request: UNNotificationRequest)] = []

    func takeResponses() -> [(actionIdentifier: String, request: UNNotificationRequest)] {
        defer { responses = [] }
        return responses
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        Task { @MainActor in
            self.responses.append((response.actionIdentifier, response.notification.request))
            completionHandler()
        }
    }
}

// MARK: - NotificationServiceError

/// Errors specific to NotificationService operations.
enum NotificationServiceError: LocalizedError, Equatable {
    case authorizationDenied
    case schedulingFailed
    case notificationLimitExceeded
    case invalidScheduledDose
    case invalidReminderTiming
    case medicalCalculatorsUnavailable

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
        case .invalidReminderTiming:
            return NSLocalizedString(
                "Invalid reminder timing. Please choose 15, 30, 60, or 120 minutes.",
                comment: "Invalid reminder timing error"
            )
        case .medicalCalculatorsUnavailable:
            return NSLocalizedString(
                "Medical calculators are unavailable in this release.",
                comment: "Medical calculators unavailable error"
            )
        }
    }
}
