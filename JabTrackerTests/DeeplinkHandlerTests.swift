import Foundation
import Testing
import XCTest

@testable import JabTracker

/// Unit tests for DeeplinkHandler URL parsing and routing logic
@Suite("DeeplinkHandler Tests")
struct DeeplinkHandlerTests {

    // MARK: - Valid URL Parsing Tests

    @Test("Parse valid dose log deeplink with scheduledDoseId")
    func testParseValidDoseLogDeeplink() throws {
        // Arrange
        let scheduledDoseId = UUID()
        let urlString = "jab-tracker://dose/log?scheduledDoseId=\(scheduledDoseId.uuidString)"
        let url = try #require(URL(string: urlString))

        // Act
        let result = DeeplinkHandler.parse(url: url)

        // Assert
        guard case .doseLog(let parsedId) = result else {
            #expect(Bool(false), "Expected .doseLog result, got \(result)")
            return
        }
        #expect(parsedId == scheduledDoseId)
    }

    @Test("Parse valid dose log deeplink with different UUID")
    func testParseValidDoseLogDeeplinkDifferentUUID() throws {
        // Arrange
        let scheduledDoseId = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
        let urlString = "jab-tracker://dose/log?scheduledDoseId=\(scheduledDoseId.uuidString)"
        let url = try #require(URL(string: urlString))

        // Act
        let result = DeeplinkHandler.parse(url: url)

        // Assert
        guard case .doseLog(let parsedId) = result else {
            #expect(Bool(false), "Expected .doseLog result, got \(result)")
            return
        }
        #expect(parsedId == scheduledDoseId)
    }

    // MARK: - Invalid URL Tests

    @Test("Parse invalid URL scheme returns unsupported")
    func testParseInvalidScheme() throws {
        // Arrange
        let url = try #require(URL(string: "https://example.com/dose/log?scheduledDoseId=test"))

        // Act
        let result = DeeplinkHandler.parse(url: url)

        // Assert
        guard case .unsupported = result else {
            #expect(Bool(false), "Expected .unsupported result, got \(result)")
            return
        }
    }

    @Test("Parse URL with wrong host returns unsupported")
    func testParseWrongHost() throws {
        // Arrange
        let url = try #require(URL(string: "jab-tracker://wronghost/action"))

        // Act
        let result = DeeplinkHandler.parse(url: url)

        // Assert
        guard case .unsupported = result else {
            #expect(Bool(false), "Expected .unsupported result, got \(result)")
            return
        }
    }

    @Test("Parse URL without path returns unsupported")
    func testParseNoPath() throws {
        // Arrange
        let url = try #require(URL(string: "jab-tracker://dose"))

        // Act
        let result = DeeplinkHandler.parse(url: url)

        // Assert
        guard case .unsupported = result else {
            #expect(Bool(false), "Expected .unsupported result, got \(result)")
            return
        }
    }

    @Test("Parse URL with missing scheduledDoseId parameter returns unsupported")
    func testParseMissingScheduledDoseId() throws {
        // Arrange
        let url = try #require(URL(string: "jab-tracker://dose/log"))

        // Act
        let result = DeeplinkHandler.parse(url: url)

        // Assert
        guard case .unsupported = result else {
            #expect(Bool(false), "Expected .unsupported result, got \(result)")
            return
        }
    }

    @Test("Parse URL with invalid UUID format returns unsupported")
    func testParseInvalidUUID() throws {
        // Arrange
        let url = try #require(URL(string: "jab-tracker://dose/log?scheduledDoseId=not-a-uuid"))

        // Act
        let result = DeeplinkHandler.parse(url: url)

        // Assert
        guard case .unsupported = result else {
            #expect(Bool(false), "Expected .unsupported result, got \(result)")
            return
        }
    }

    @Test("Parse URL with empty scheduledDoseId returns unsupported")
    func testParseEmptyScheduledDoseId() throws {
        // Arrange
        let url = try #require(URL(string: "jab-tracker://dose/log?scheduledDoseId="))

        // Act
        let result = DeeplinkHandler.parse(url: url)

        // Assert
        guard case .unsupported = result else {
            #expect(Bool(false), "Expected .unsupported result, got \(result)")
            return
        }
    }

    // MARK: - URL Query Parameter Parsing

    @Test("Parse URL with multiple query parameters extracts scheduledDoseId")
    func testParseMultipleQueryParameters() throws {
        // Arrange
        let scheduledDoseId = UUID()
        let urlString = "jab-tracker://dose/log?scheduledDoseId=\(scheduledDoseId.uuidString)&extra=value"
        let url = try #require(URL(string: urlString))

        // Act
        let result = DeeplinkHandler.parse(url: url)

        // Assert
        guard case .doseLog(let parsedId) = result else {
            #expect(Bool(false), "Expected .doseLog result, got \(result)")
            return
        }
        #expect(parsedId == scheduledDoseId)
    }

    // MARK: - Case Sensitivity Tests

    @Test("Parse URL with uppercase UUID succeeds")
    func testParseUppercaseUUID() throws {
        // Arrange
        let scheduledDoseId = UUID()
        let uppercaseUUID = scheduledDoseId.uuidString.uppercased()
        let urlString = "jab-tracker://dose/log?scheduledDoseId=\(uppercaseUUID)"
        let url = try #require(URL(string: urlString))

        // Act
        let result = DeeplinkHandler.parse(url: url)

        // Assert
        guard case .doseLog(let parsedId) = result else {
            #expect(Bool(false), "Expected .doseLog result, got \(result)")
            return
        }
        // UUID parsing is case-insensitive, so this should work
        #expect(parsedId.uuidString.lowercased() == scheduledDoseId.uuidString.lowercased())
    }

    // MARK: - Edge Cases

    @Test("Parse URL with fragment identifier ignores fragment")
    func testParseURLWithFragment() throws {
        // Arrange
        let scheduledDoseId = UUID()
        let urlString = "jab-tracker://dose/log?scheduledDoseId=\(scheduledDoseId.uuidString)#section"
        let url = try #require(URL(string: urlString))

        // Act
        let result = DeeplinkHandler.parse(url: url)

        // Assert
        guard case .doseLog(let parsedId) = result else {
            #expect(Bool(false), "Expected .doseLog result, got \(result)")
            return
        }
        #expect(parsedId == scheduledDoseId)
    }

    @Test("Parse URL with encoded characters succeeds")
    func testParseURLWithEncodedCharacters() throws {
        // Arrange
        let scheduledDoseId = UUID()
        let urlString = "jab-tracker://dose/log?scheduledDoseId=%5B\(scheduledDoseId.uuidString)%5D"
        let url = try #require(URL(string: urlString))

        // Act
        let result = DeeplinkHandler.parse(url: url)

        // Assert
        // This should fail because [UUID] is not a valid UUID format
        guard case .unsupported = result else {
            #expect(Bool(false), "Expected .unsupported result for malformed UUID, got \(result)")
            return
        }
    }

    // MARK: - Handle Method Tests

    @Test("Handle valid deeplink posts notification")
    @MainActor
    func testHandleValidDeeplinkPostsNotification() throws {
        // Arrange
        let scheduledDoseId = UUID()
        let urlString = "jab-tracker://dose/log?scheduledDoseId=\(scheduledDoseId.uuidString)"
        let url = try #require(URL(string: urlString))

        nonisolated(unsafe) var receivedNotification: Notification?
        let expectation = XCTestExpectation(description: "Notification received")

        let observer = NotificationCenter.default.addObserver(
            forName: .showQuickDoseSheet,
            object: nil,
            queue: .main
        ) { notification in
            receivedNotification = notification
            expectation.fulfill()
        }

        // Act
        DeeplinkHandler.handle(url: url)

        // Wait for notification
        _ = XCTWaiter.wait(for: [expectation], timeout: 1.0)

        // Cleanup
        NotificationCenter.default.removeObserver(observer)

        // Assert
        #expect(receivedNotification != nil, "Should have received notification")
        if let userInfo = receivedNotification?.userInfo,
            let receivedId = userInfo["scheduledDoseId"] as? UUID
        {
            #expect(receivedId == scheduledDoseId, "Should have correct scheduledDoseId in userInfo")
        } else {
            #expect(Bool(false), "Should have valid userInfo with scheduledDoseId")
        }
    }

    @Test("Handle unsupported deeplink does not post notification")
    func testHandleUnsupportedDeeplinkDoesNotPostNotification() throws {
        // Arrange
        let url = try #require(URL(string: "https://example.com/invalid"))

        var receivedNotification: Notification?
        let observer = NotificationCenter.default.addObserver(
            forName: .showQuickDoseSheet,
            object: nil,
            queue: .main
        ) { notification in
            receivedNotification = notification
        }

        // Act
        DeeplinkHandler.handle(url: url)

        // Small delay to ensure notification would have been received if posted
        Thread.sleep(forTimeInterval: 0.1)

        // Cleanup
        NotificationCenter.default.removeObserver(observer)

        // Assert
        #expect(receivedNotification == nil, "Should not have received notification for unsupported URL")
    }

    @Test("Handle deeplink with wrong path does not post notification")
    func testHandleWrongPathDoesNotPostNotification() throws {
        // Arrange
        let url = try #require(URL(string: "jab-tracker://dose/wrong"))

        var receivedNotification: Notification?
        let observer = NotificationCenter.default.addObserver(
            forName: .showQuickDoseSheet,
            object: nil,
            queue: .main
        ) { notification in
            receivedNotification = notification
        }

        // Act
        DeeplinkHandler.handle(url: url)

        // Small delay
        Thread.sleep(forTimeInterval: 0.1)

        // Cleanup
        NotificationCenter.default.removeObserver(observer)

        // Assert
        #expect(receivedNotification == nil, "Should not have received notification for wrong path")
    }
}
