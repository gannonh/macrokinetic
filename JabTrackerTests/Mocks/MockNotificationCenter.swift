import Foundation
import UserNotifications

@testable import JabTracker

/// Mock implementation of NotificationCenterProtocol for testing
///
/// This mock tracks all interactions with the notification center, allowing tests to verify
/// that NotificationService correctly schedules, removes, and manages notifications.
///
/// Key Features:
/// - Tracks all notification requests added
/// - Tracks all removed identifiers
/// - Simulates authorization states
/// - Provides verification methods for test assertions
///
/// Usage in Tests:
/// ```swift
/// let mockCenter = MockNotificationCenter()
/// let service = NotificationService(
///     scheduleService: scheduleService,
///     notificationCenter: mockCenter
/// )
///
/// try await service.scheduleMissedDoseAlert(for: missedDose)
///
/// #expect(mockCenter.addedRequests.count == 1)
/// #expect(mockCenter.addedRequests.first?.content.categoryIdentifier == "MISSED_DOSE")
/// ```
@MainActor
final class MockNotificationCenter: NotificationCenterProtocol {
    // MARK: - Tracked State

    /// All notification requests that have been added
    var addedRequests: [UNNotificationRequest] = []

    /// All identifier arrays passed to removePendingNotificationRequests
    var removedIdentifiers: [[String]] = []

    /// Whether removeAllPendingNotificationRequests was called
    var didRemoveAll: Bool = false

    /// Current authorization status to return
    var authorizationStatus: UNAuthorizationStatus = .authorized

    /// Whether authorization should be granted
    var shouldGrantAuthorization: Bool = true

    /// Current badge count
    var badgeCount: Int = 0

    /// Categories that have been set
    var setCategories: Set<UNNotificationCategory> = []

    /// Delegate assigned to the notification center
    weak var delegate: UNUserNotificationCenterDelegate?

    // MARK: - Protocol Implementation

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        // Update authorization status when authorization is granted
        if shouldGrantAuthorization {
            authorizationStatus = .authorized
        } else {
            authorizationStatus = .denied
        }
        return shouldGrantAuthorization
    }

    func notificationSettings() async -> UNNotificationSettings {
        // UNNotificationSettings cannot be initialized directly in tests
        // The authorization status is managed through the authorizationStatus property
        // which gets set when requestAuthorization() is called.
        // For tests that don't call requestAuthorization(), manually set authorizationStatus before testing.
        await UNUserNotificationCenter.current().notificationSettings()
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        // Return the mock's authorization status directly
        // This allows tests to verify status without needing to create UNNotificationSettings
        authorizationStatus
    }

    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        self.setCategories = categories
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(identifiers)
        // Remove from our tracked requests
        addedRequests.removeAll { request in
            identifiers.contains(request.identifier)
        }
    }

    func removeAllPendingNotificationRequests() {
        didRemoveAll = true
        addedRequests.removeAll()
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        addedRequests
    }

    func setBadgeCount(_ newBadgeCount: Int) async throws {
        badgeCount = newBadgeCount
    }

    // MARK: - Test Helpers

    /// Reset all tracked state (useful between tests)
    func reset() {
        addedRequests.removeAll()
        removedIdentifiers.removeAll()
        didRemoveAll = false
        authorizationStatus = .authorized
        shouldGrantAuthorization = true
        badgeCount = 0
        setCategories.removeAll()
    }

    /// Find a request by identifier
    func request(withIdentifier identifier: String) -> UNNotificationRequest? {
        addedRequests.first { $0.identifier == identifier }
    }

    /// Check if a specific identifier was removed
    func wasRemoved(identifier: String) -> Bool {
        removedIdentifiers.contains { $0.contains(identifier) }
    }
}
