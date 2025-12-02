import Foundation
import UserNotifications

/// Protocol abstraction for UNUserNotificationCenter to enable testing
///
/// This protocol wraps the essential UNUserNotificationCenter methods needed by NotificationService,
/// allowing for proper unit testing through mock implementations while maintaining compatibility
/// with the real notification center in production.
///
/// Usage:
/// - Production: Use `UNUserNotificationCenter.current()` which conforms to this protocol via extension
/// - Testing: Use `MockNotificationCenter` which implements this protocol for test verification
@MainActor
protocol NotificationCenterProtocol {
    /// Request authorization for notifications
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool

    /// Get current notification settings
    func notificationSettings() async -> UNNotificationSettings

    /// Get current authorization status (optional - defaults to reading from notificationSettings)
    func authorizationStatus() async -> UNAuthorizationStatus

    /// Set notification categories
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>)

    /// Add a notification request
    func add(_ request: UNNotificationRequest) async throws

    /// Remove pending notification requests by identifier
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])

    /// Remove all pending notification requests
    func removeAllPendingNotificationRequests()

    /// Get all pending notification requests
    func pendingNotificationRequests() async -> [UNNotificationRequest]

    /// Set the badge count
    func setBadgeCount(_ newBadgeCount: Int) async throws

    /// The delegate for handling notification events
    var delegate: UNUserNotificationCenterDelegate? { get set }
}

// MARK: - UNUserNotificationCenter Conformance

/// Extend UNUserNotificationCenter to conform to the protocol
/// This allows the real notification center to be used in production without any code changes
extension UNUserNotificationCenter: NotificationCenterProtocol {
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationSettings()
        return settings.authorizationStatus
    }
}
