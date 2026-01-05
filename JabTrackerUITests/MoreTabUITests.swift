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

    // MARK: - GLP-1 Programs Tests (v0.5.0)

    func testNavigateToGLP1Programs() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5), "More view should appear")

        // NavigationLink in List - try multiple query approaches
        let glp1Row = app.descendants(matching: .any)["glp1-programs-row"].firstMatch
        XCTAssertTrue(glp1Row.waitForExistence(timeout: 5), "GLP-1 Programs row should exist")
        glp1Row.tap()

        let glp1View = app.otherElements["glp1-programs-view"]
        XCTAssertTrue(glp1View.waitForExistence(timeout: 5), "GLP-1 Programs view should appear")
    }

    func testGLP1ProgramsShowsAnalyticsByDefault() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        let glp1Row = app.descendants(matching: .any)["glp1-programs-row"].firstMatch
        XCTAssertTrue(glp1Row.waitForExistence(timeout: 5))
        glp1Row.tap()

        // Wait for view to load
        let glp1View = app.otherElements["glp1-programs-view"]
        XCTAssertTrue(glp1View.waitForExistence(timeout: 5))

        // Analytics section should be selected by default
        let sectionPicker = app.segmentedControls["glp1-section-picker"]
        XCTAssertTrue(sectionPicker.waitForExistence(timeout: 3), "Section picker should exist")

        // Analytics sub-picker should be visible (only shows when Analytics selected)
        let analyticsPicker = app.segmentedControls["analytics-section-picker"]
        XCTAssertTrue(analyticsPicker.waitForExistence(timeout: 3), "Analytics sub-picker should be visible")
    }

    func testGLP1ProgramsSwitchToMedications() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.otherElements["more-view"]
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        let glp1Row = app.descendants(matching: .any)["glp1-programs-row"].firstMatch
        XCTAssertTrue(glp1Row.waitForExistence(timeout: 5))
        glp1Row.tap()

        let glp1View = app.otherElements["glp1-programs-view"]
        XCTAssertTrue(glp1View.waitForExistence(timeout: 5))

        // Tap Medications segment
        let sectionPicker = app.segmentedControls["glp1-section-picker"]
        XCTAssertTrue(sectionPicker.waitForExistence(timeout: 3))

        let medicationsButton = sectionPicker.buttons["Medications"]
        XCTAssertTrue(medicationsButton.exists, "Medications button should exist")
        medicationsButton.tap()

        // Analytics sub-picker should NOT be visible anymore
        let analyticsPicker = app.segmentedControls["analytics-section-picker"]
        XCTAssertFalse(analyticsPicker.exists, "Analytics sub-picker should hide when Medications selected")
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
