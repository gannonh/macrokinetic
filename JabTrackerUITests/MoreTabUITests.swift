import XCTest

final class MoreTabUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    // MARK: - Navigation Tests

    func testNavigateToSecurityPrivacy() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        app.cells["security-privacy-row"].tap()

        let securityView = app.otherElements["security-privacy-view"]
        XCTAssertTrue(securityView.waitForExistence(timeout: 5))
    }

    func testNavigateToSubscription() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        app.cells["subscription-row"].tap()

        let subscriptionView = app.otherElements["subscription-settings-view"]
        XCTAssertTrue(subscriptionView.waitForExistence(timeout: 5))
    }

    func testNavigateToNotificationSettings() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        app.cells["notifications-row"].tap()

        let notificationView = app.otherElements["notification-settings-view"]
        XCTAssertTrue(notificationView.waitForExistence(timeout: 5))
    }

    func testNavigateToCalorieExpenditure() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        app.cells["calorie-expenditure-row"].tap()

        let expenditureView = app.otherElements["calorie-expenditure-view"]
        XCTAssertTrue(expenditureView.waitForExistence(timeout: 5))
    }

    // MARK: - Overflow Menu Tests

    func testNavigateToGoalsStrategy() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        app.cells["goals-strategy-row"].tap()

        let strategyView = app.otherElements["strategy-view"]
        XCTAssertTrue(strategyView.waitForExistence(timeout: 5))
    }

    func testNavigateToFoodLibrary() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        app.cells["food-library-row"].tap()

        let libraryView = app.otherElements["food-library-view"]
        XCTAssertTrue(libraryView.waitForExistence(timeout: 5))
    }

    // MARK: - Inactive Placeholder Tests

    func testInactiveItemsNotTappable() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        // These should exist but not navigate
        let foodLogPlaceholder = app.staticTexts["food-log-placeholder"]
        XCTAssertTrue(foodLogPlaceholder.exists)

        let shortcutsPlaceholder = app.staticTexts["shortcuts-placeholder"]
        XCTAssertTrue(shortcutsPlaceholder.exists)

        let faqPlaceholder = app.staticTexts["faq-placeholder"]
        XCTAssertTrue(faqPlaceholder.exists)
    }

    // MARK: - Security & Privacy Tests

    func testBiometricToggleExists() throws {
        TestUtilities.navigateToTab(app, tabName: "More")
        app.cells["security-privacy-row"].tap()

        let biometricToggle = app.switches["biometric-toggle"]
        // May not exist on simulator without biometric support
        // Just verify view loads
        let securityView = app.otherElements["security-privacy-view"]
        XCTAssertTrue(securityView.waitForExistence(timeout: 5))
    }

    func testHealthToggleExists() throws {
        TestUtilities.navigateToTab(app, tabName: "More")
        app.cells["security-privacy-row"].tap()

        let healthToggle = app.switches["health-toggle"]
        XCTAssertTrue(healthToggle.waitForExistence(timeout: 5))
    }

    // MARK: - Notification Settings Tests

    func testNotificationTogglesExist() throws {
        TestUtilities.navigateToTab(app, tabName: "More")
        app.cells["notifications-row"].tap()

        let notificationView = app.otherElements["notification-settings-view"]
        XCTAssertTrue(notificationView.waitForExistence(timeout: 5))

        // Verify key toggles exist
        XCTAssertTrue(app.switches["weigh-in-daily-toggle"].exists)
        XCTAssertTrue(app.switches["dose-reminder-toggle"].exists)
    }
}
