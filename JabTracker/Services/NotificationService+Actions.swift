import Foundation
import OSLog
import SwiftData
import UserNotifications

// MARK: - NotificationService+Actions

extension NotificationService {
    // MARK: - Timing Constants

    private enum NotificationTiming {
        /// Snooze interval for delayed dose reminders (1 hour)
        static let snoozeInterval: TimeInterval = 3600

        /// Delay for missed dose alerts to ensure delivery (1 second)
        static let missedAlertDelay: TimeInterval = 1.0
    }

    // MARK: - Private Properties

    /// Logger for action handling operations
    private let actionLogger = Logger(subsystem: "com.gannonhall.JabTracker", category: "NotificationService.Actions")

    // MARK: - Action Handling

    /// Handle a notification action for a scheduled dose
    ///
    /// - Parameters:
    ///   - actionIdentifier: The action identifier (TAKE_DOSE, SKIP_DOSE, SNOOZE)
    ///   - scheduledDose: The scheduled dose to act upon
    /// - Throws: NotificationServiceError if action fails
    func handleNotificationAction(
        _ actionIdentifier: String,
        for scheduledDose: ScheduledDose
    ) async throws {
        actionLogger.info("Handling notification action: \(actionIdentifier) for dose: \(scheduledDose.id)")

        switch actionIdentifier {
        case "TAKE_DOSE":
            try await handleTakeDoseAction(for: scheduledDose)
        case "SKIP_DOSE":
            try await handleSkipDoseAction(for: scheduledDose)
        case "SNOOZE":
            try await handleSnoozeAction(for: scheduledDose)
        default:
            actionLogger.error("Invalid action identifier: \(actionIdentifier)")
            throw NotificationServiceError.invalidAction
        }

        // Refresh notification queue after action
        try await refreshNotificationQueue()
    }

    /// Handle UNNotificationResponse by routing to appropriate action handler
    ///
    /// - Parameter response: The notification response from UNUserNotificationCenter
    /// - Throws: NotificationServiceError if response handling fails
    func handleNotificationResponse(_ response: UNNotificationResponse) async throws {
        actionLogger.info("Handling notification response: \(response.actionIdentifier)")

        // Extract scheduled dose ID from user info
        guard
            let doseIDString = response.notification.request.content.userInfo[
                NotificationService.UserInfoKeys.scheduledDoseId] as? String,
            let doseID = UUID(uuidString: doseIDString)
        else {
            actionLogger.error("Missing or invalid scheduledDoseId in notification user info")
            throw NotificationServiceError.invalidScheduledDose
        }

        // Fetch scheduled dose from SwiftData
        let context = scheduleService.context
        let descriptor = FetchDescriptor<ScheduledDose>(
            predicate: #Predicate { $0.id == doseID }
        )
        guard let scheduledDose = try context.fetch(descriptor).first else {
            actionLogger.error("Could not find scheduled dose with ID: \(doseID)")
            throw NotificationServiceError.invalidScheduledDose
        }

        // Route to action handler
        try await handleNotificationAction(response.actionIdentifier, for: scheduledDose)
    }

    // MARK: - Private Action Handlers

    /// Handle "Take Dose" action by creating actual dose
    private func handleTakeDoseAction(for scheduledDose: ScheduledDose) async throws {
        actionLogger.info("Taking dose for scheduled dose: \(scheduledDose.id)")

        let context = scheduleService.context

        // Get medication profile
        let medicationProfile = try validateMedicationProfile(for: scheduledDose)

        // Create actual dose at current time
        let dose = Dose(
            amount: scheduledDose.doseAmount,
            timestamp: Date(),  // Use current time when user taps "Take"
            site: medicationProfile.preferredInjectionSites.first ?? "Abdomen",
            medication: medicationProfile,
            scheduledDose: scheduledDose
        )

        context.insert(dose)

        // Link to scheduled dose
        scheduledDose.actualDose = dose

        // Save context
        try context.save()

        actionLogger.info("Successfully created dose for scheduled dose: \(scheduledDose.id)")
    }

    /// Handle "Skip Dose" action by creating skipped dose
    private func handleSkipDoseAction(for scheduledDose: ScheduledDose) async throws {
        actionLogger.info("Skipping dose for scheduled dose: \(scheduledDose.id)")

        let context = scheduleService.context

        // Validate medication profile exists
        _ = try validateMedicationProfile(for: scheduledDose)

        // Mark scheduled dose as skipped
        scheduledDose.skippedAt = Date()
        scheduledDose.skipReason = "User chose to skip dose via notification"

        // Save context
        try context.save()

        actionLogger.info("Successfully marked dose as skipped for scheduled dose: \(scheduledDose.id)")
    }

    /// Handle "Snooze" action by rescheduling notification
    private func handleSnoozeAction(for scheduledDose: ScheduledDose) async throws {
        actionLogger.info("Snoozing dose for scheduled dose: \(scheduledDose.id)")

        // Cancel existing notification
        cancelNotification(for: scheduledDose)

        // Create new scheduled dose for configured snooze interval
        let context = scheduleService.context
        let snoozeTime = Date().addingTimeInterval(NotificationTiming.snoozeInterval)

        // Get medication profile
        guard let schedule = scheduledDose.schedule else {
            actionLogger.error("Scheduled dose missing schedule")
            throw NotificationServiceError.invalidScheduledDose
        }

        let snoozedDose = ScheduledDose(
            scheduledTime: snoozeTime,
            doseAmount: scheduledDose.doseAmount,
            windowStart: snoozeTime.addingTimeInterval(-7200),  // 2 hours before
            windowEnd: snoozeTime.addingTimeInterval(7200)  // 2 hours after
        )
        snoozedDose.schedule = schedule
        snoozedDose.rescheduledFrom = scheduledDose.scheduledTime
        context.insert(snoozedDose)
        try context.save()

        // Schedule notification for snoozed dose (immediate - no offset)
        try await scheduleDoseReminder(for: snoozedDose, reminderOffset: 0)

        actionLogger.info("Successfully snoozed dose notification for 1 hour")
    }

    // MARK: - Missed Dose Detection

    /// Detect all missed doses (scheduled but not taken)
    ///
    /// - Returns: Array of scheduled doses that are overdue
    /// - Throws: Error if query fails
    func detectMissedDoses() async throws -> [ScheduledDose] {
        actionLogger.info("Detecting missed doses...")

        let context = scheduleService.context
        let now = Date()

        // Query for overdue scheduled doses that haven't been taken or skipped
        let descriptor = FetchDescriptor<ScheduledDose>(
            predicate: #Predicate { dose in
                dose.windowEnd < now && dose.actualDose == nil && dose.skippedAt == nil
            }
        )

        let missedDoses = try context.fetch(descriptor)

        actionLogger.info("Found \(missedDoses.count) missed doses")
        return missedDoses
    }

    /// Schedule a missed dose alert notification
    ///
    /// - Parameter scheduledDose: The missed scheduled dose
    /// - Throws: NotificationServiceError if scheduling fails
    func scheduleMissedDoseAlert(for scheduledDose: ScheduledDose) async throws {
        actionLogger.info("Scheduling missed dose alert for: \(scheduledDose.id)")

        // Get medication profile
        let medicationProfile = try validateMedicationProfile(for: scheduledDose)

        // Create notification content for missed dose
        let content = UNMutableNotificationContent()
        content.title = "Missed Dose Alert"
        let scheduledTime = formatTime(scheduledDose.scheduledTime)
        content.body = "You missed your \(medicationProfile.brandName) dose scheduled for \(scheduledTime)"
        content.sound = .default
        content.categoryIdentifier = "MISSED_DOSE"
        content.userInfo = [NotificationService.UserInfoKeys.scheduledDoseId: scheduledDose.id.uuidString]

        // Schedule for immediate delivery with configured delay to ensure delivery
        let triggerDate = Date().addingTimeInterval(NotificationTiming.missedAlertDelay)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "missed-\(scheduledDose.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        actionLogger.info("Missed dose alert scheduled for immediate delivery")
    }

    /// Process all missed doses and schedule alerts
    ///
    /// - Throws: Error if detection or scheduling fails
    func processMissedDoses() async throws {
        actionLogger.info("Processing missed doses...")

        let missedDoses = try await detectMissedDoses()

        for missedDose in missedDoses {
            try await scheduleMissedDoseAlert(for: missedDose)
        }

        actionLogger.info("Processed \(missedDoses.count) missed doses")
    }

    // MARK: - Titration Action Handlers (Stream D)

    /// Handle a titration notification action
    ///
    /// - Parameters:
    ///   - actionIdentifier: The action identifier (COMPLETE_TITRATION, RESCHEDULE_TITRATION, REMIND_LATER_TITRATION)
    ///   - titration: The dose titration to act upon
    ///   - schedule: The dose schedule to update (required for COMPLETE_TITRATION)
    ///   - newDate: The new scheduled date (required for RESCHEDULE_TITRATION)
    /// - Throws: NotificationServiceError if action fails
    func handleTitrationAction(
        _ actionIdentifier: String,
        for titration: DoseTitration,
        schedule: DoseSchedule? = nil,
        newDate: Date? = nil
    ) async throws {
        actionLogger.info("Handling titration action: \(actionIdentifier) for titration: \(titration.id)")

        switch actionIdentifier {
        case "COMPLETE_TITRATION":
            guard let schedule = schedule else {
                actionLogger.error("COMPLETE_TITRATION requires schedule parameter")
                throw NotificationServiceError.invalidScheduledDose
            }
            try await handleCompleteTitrationAction(for: titration, schedule: schedule)
        case "RESCHEDULE_TITRATION":
            guard let newDate = newDate else {
                actionLogger.error("RESCHEDULE_TITRATION requires newDate parameter")
                throw NotificationServiceError.invalidAction
            }
            try await handleRescheduleTitrationAction(for: titration, newDate: newDate)
        case "REMIND_LATER_TITRATION":
            try await handleRemindLaterTitrationAction(for: titration)
        default:
            actionLogger.error("Invalid titration action identifier: \(actionIdentifier)")
            throw NotificationServiceError.invalidAction
        }
    }

    /// Handle "Complete Titration" action by marking titration complete and updating schedule
    private func handleCompleteTitrationAction(
        for titration: DoseTitration,
        schedule: DoseSchedule
    ) async throws {
        actionLogger.info("Completing titration: \(titration.id)")

        let context = scheduleService.context

        // Mark titration complete
        titration.isCompleted = true
        titration.completedDate = Date()

        // Update schedule using ScheduleService+Titration
        try scheduleService.handleCompletedTitration(titration, schedule: schedule)

        // Save context
        try context.save()

        actionLogger.info("Successfully completed titration: \(titration.id)")
    }

    /// Handle "Reschedule Titration" action by updating scheduled date and rescheduling notification
    private func handleRescheduleTitrationAction(
        for titration: DoseTitration,
        newDate: Date
    ) async throws {
        actionLogger.info("Rescheduling titration: \(titration.id) to \(newDate)")

        let context = scheduleService.context

        // Update titration scheduled date
        titration.scheduledDate = newDate
        titration.updatedAt = Date()

        // Save context
        try context.save()

        // Cancel old notification
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["titration-\(titration.id.uuidString)"])

        // Schedule new notification
        try await scheduleTitrationNotification(for: titration)

        actionLogger.info("Successfully rescheduled titration notification")
    }

    /// Handle "Remind Later" action by rescheduling notification for 1 hour later
    private func handleRemindLaterTitrationAction(for titration: DoseTitration) async throws {
        actionLogger.info("Reminding later for titration: \(titration.id)")

        // Cancel existing notification
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["titration-\(titration.id.uuidString)"])

        // Create temporary titration with new date (1 hour from now)
        let tempDate = Date().addingTimeInterval(3600)  // 1 hour

        // Schedule notification for 1 hour later
        // Note: We'll create a new notification with same titration but trigger 1 hour from now
        let content = UNMutableNotificationContent()
        let changeDirection = titration.toDose > titration.fromDose ? "Increase" : "Decrease"
        content.title = NSLocalizedString("Dose \(changeDirection) Reminder", comment: "Titration reminder title")
        content.body = NSLocalizedString(
            "Time to increase your dose from \(titration.fromDose)mg to \(titration.toDose)mg",
            comment: "Titration reminder body"
        )
        content.sound = .default
        content.categoryIdentifier = "TITRATION"
        content.userInfo = [NotificationService.UserInfoKeys.titrationId: titration.id.uuidString]

        // Create trigger for 1 hour from now
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: tempDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "titration-remind-\(titration.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        actionLogger.info("Titration reminder scheduled for 1 hour later")
    }

    // MARK: - Helper Methods

    /// Validate and extract medication profile from scheduled dose
    ///
    /// - Parameter scheduledDose: The scheduled dose to validate
    /// - Returns: The medication profile associated with the scheduled dose
    /// - Throws: NotificationServiceError.invalidScheduledDose if profile is missing
    private func validateMedicationProfile(
        for scheduledDose: ScheduledDose
    ) throws -> MedicationProfile {
        guard let medicationProfile = scheduledDose.schedule?.medicationProfile else {
            actionLogger.error("Scheduled dose missing medication profile")
            throw NotificationServiceError.invalidScheduledDose
        }
        return medicationProfile
    }

    /// Format time for display in notifications
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - NotificationServiceError Extension

extension NotificationServiceError {
    /// Invalid notification action identifier
    static var invalidAction: NotificationServiceError {
        .schedulingFailed
    }
}
