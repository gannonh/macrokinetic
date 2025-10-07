import Foundation
import Testing

@testable import JabTracker

/// Tests for PendingNotification and NotificationContent models
@Suite("PendingNotification Model Tests")
struct PendingNotificationTests {
    // MARK: - PendingNotification Tests

    @Test("PendingNotification can be created with all required fields")
    func testPendingNotificationCreation() {
        // GIVEN: Notification data
        let id = "test-notification-id"
        let scheduledDoseId = UUID()
        let triggerDate = Date()
        let content = NotificationContent(
            title: "Test Notification",
            body: "Test body",
            categoryIdentifier: "DOSE_REMINDER"
        )

        // WHEN: Creating a PendingNotification
        let notification = PendingNotification(
            id: id,
            scheduledDoseId: scheduledDoseId,
            triggerDate: triggerDate,
            content: content
        )

        // THEN: All properties should be set correctly
        #expect(notification.id == id)
        #expect(notification.scheduledDoseId == scheduledDoseId)
        #expect(notification.triggerDate == triggerDate)
        #expect(notification.content == content)
    }

    @Test("PendingNotification conforms to Identifiable protocol")
    func testPendingNotificationIdentifiable() {
        // GIVEN: A PendingNotification
        let content = NotificationContent(
            title: "Test",
            body: "Body",
            categoryIdentifier: "DOSE_REMINDER"
        )
        let notification = PendingNotification(
            id: "unique-id",
            scheduledDoseId: UUID(),
            triggerDate: Date(),
            content: content
        )

        // THEN: Should have an id property accessible
        #expect(notification.id == "unique-id")

        // THEN: Can be used in collections requiring Identifiable
        let array: [PendingNotification] = [notification]
        #expect(array.first?.id == "unique-id")
    }

    @Test("PendingNotification equality based on id")
    func testPendingNotificationEquality() {
        // GIVEN: Two notifications with same id but different content
        let sharedId = "same-id"
        let content1 = NotificationContent(
            title: "Title 1",
            body: "Body 1",
            categoryIdentifier: "DOSE_REMINDER"
        )
        let content2 = NotificationContent(
            title: "Title 2",
            body: "Body 2",
            categoryIdentifier: "MISSED_DOSE"
        )

        let notification1 = PendingNotification(
            id: sharedId,
            scheduledDoseId: UUID(),
            triggerDate: Date(),
            content: content1
        )
        let notification2 = PendingNotification(
            id: sharedId,
            scheduledDoseId: UUID(),  // Different UUID
            triggerDate: Date().addingTimeInterval(3600),  // Different date
            content: content2  // Different content
        )

        // THEN: Should be equal based on id alone
        #expect(notification1 == notification2)
    }

    @Test("PendingNotification inequality with different ids")
    func testPendingNotificationInequality() {
        // GIVEN: Two notifications with different ids
        let content = NotificationContent(
            title: "Same Title",
            body: "Same Body",
            categoryIdentifier: "DOSE_REMINDER"
        )

        let notification1 = PendingNotification(
            id: "id-1",
            scheduledDoseId: UUID(),
            triggerDate: Date(),
            content: content
        )
        let notification2 = PendingNotification(
            id: "id-2",
            scheduledDoseId: UUID(),
            triggerDate: Date(),
            content: content
        )

        // THEN: Should not be equal due to different ids
        #expect(notification1 != notification2)
    }

    // MARK: - NotificationContent Tests

    @Test("NotificationContent can be created with all required fields")
    func testNotificationContentCreation() {
        // GIVEN: Content data
        let title = "Dose Reminder"
        let body = "Time for your semaglutide dose"
        let categoryIdentifier = "DOSE_REMINDER"

        // WHEN: Creating NotificationContent
        let content = NotificationContent(
            title: title,
            body: body,
            categoryIdentifier: categoryIdentifier
        )

        // THEN: All properties should be set correctly
        #expect(content.title == title)
        #expect(content.body == body)
        #expect(content.categoryIdentifier == categoryIdentifier)
    }

    @Test("NotificationContent equality with same values")
    func testNotificationContentEquality() {
        // GIVEN: Two content instances with same values
        let content1 = NotificationContent(
            title: "Same Title",
            body: "Same Body",
            categoryIdentifier: "DOSE_REMINDER"
        )
        let content2 = NotificationContent(
            title: "Same Title",
            body: "Same Body",
            categoryIdentifier: "DOSE_REMINDER"
        )

        // THEN: Should be equal
        #expect(content1 == content2)
    }

    @Test("NotificationContent inequality with different values")
    func testNotificationContentInequality() {
        // GIVEN: Two content instances with different values
        let content1 = NotificationContent(
            title: "Title 1",
            body: "Body 1",
            categoryIdentifier: "DOSE_REMINDER"
        )
        let content2 = NotificationContent(
            title: "Title 2",
            body: "Body 1",
            categoryIdentifier: "DOSE_REMINDER"
        )

        // THEN: Should not be equal
        #expect(content1 != content2)
    }

    @Test("NotificationContent handles empty strings")
    func testNotificationContentEmptyStrings() {
        // GIVEN: Content with empty strings
        let content = NotificationContent(
            title: "",
            body: "",
            categoryIdentifier: ""
        )

        // THEN: Should handle empty strings correctly
        #expect(content.title == "")
        #expect(content.body == "")
        #expect(content.categoryIdentifier == "")
    }

    @Test("PendingNotification with different scheduledDoseIds are equal if same id")
    func testPendingNotificationEqualityIgnoresScheduledDoseId() {
        // GIVEN: Two notifications with same id but different scheduledDoseIds
        let sharedId = "notification-123"
        let content = NotificationContent(
            title: "Test",
            body: "Test",
            categoryIdentifier: "DOSE_REMINDER"
        )

        let notification1 = PendingNotification(
            id: sharedId,
            scheduledDoseId: UUID(),
            triggerDate: Date(),
            content: content
        )
        let notification2 = PendingNotification(
            id: sharedId,
            scheduledDoseId: UUID(),
            triggerDate: Date(),
            content: content
        )

        // THEN: Should be equal (equality based only on id)
        #expect(notification1 == notification2)
        #expect(notification1.scheduledDoseId != notification2.scheduledDoseId)
    }

    @Test("PendingNotification with different trigger dates are equal if same id")
    func testPendingNotificationEqualityIgnoresTriggerDate() {
        // GIVEN: Two notifications with same id but different trigger dates
        let sharedId = "notification-456"
        let content = NotificationContent(
            title: "Test",
            body: "Test",
            categoryIdentifier: "DOSE_REMINDER"
        )

        let notification1 = PendingNotification(
            id: sharedId,
            scheduledDoseId: UUID(),
            triggerDate: Date(),
            content: content
        )
        let notification2 = PendingNotification(
            id: sharedId,
            scheduledDoseId: UUID(),
            triggerDate: Date().addingTimeInterval(7200),  // 2 hours later
            content: content
        )

        // THEN: Should be equal (equality based only on id)
        #expect(notification1 == notification2)
        #expect(notification1.triggerDate != notification2.triggerDate)
    }
}
