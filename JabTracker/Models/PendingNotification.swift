import Foundation

/// Represents a pending notification in the notification queue.
///
/// Used to track scheduled notifications and their metadata. The ID matches the
/// UNNotificationRequest.identifier for easy lookup and cancellation.
struct PendingNotification: Identifiable, Equatable {
    /// Unique identifier matching UNNotificationRequest.identifier
    let id: String

    /// ID of the ScheduledDose this notification is for
    let scheduledDoseId: UUID

    /// Date and time when the notification will trigger
    let triggerDate: Date

    /// Notification content details
    let content: NotificationContent

    // MARK: - Equatable

    static func == (lhs: PendingNotification, rhs: PendingNotification) -> Bool {
        lhs.id == rhs.id
    }
}

/// Content for a notification.
///
/// Stores the user-facing notification text and category identifier.
struct NotificationContent: Equatable {
    /// Notification title
    let title: String

    /// Notification body text
    let body: String

    /// Category identifier (DOSE_REMINDER or MISSED_DOSE)
    let categoryIdentifier: String
}
