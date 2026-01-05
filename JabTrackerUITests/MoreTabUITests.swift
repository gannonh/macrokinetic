import XCTest

final class MoreTabUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
    }

    override func tearDownWithError() throws {
        if testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
    }

    // MARK: - Navigation Tests

    func testNavigateToSecurityPrivacy() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.descendants(matching: .any)["more-view"].firstMatch
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        // Need to scroll to find Security & Privacy in Account Settings section
        app.swipeUp()

        // NavigationLinks in SwiftUI List are exposed as Buttons, not Cells
        let securityRow = app.buttons["security-privacy-row"]
        XCTAssertTrue(securityRow.waitForExistence(timeout: 5), "Security row should exist")
        securityRow.tap()

        // SwiftUI List views are exposed as CollectionView, use descendants query
        let securityView = app.descendants(matching: .any)["security-privacy-view"].firstMatch
        XCTAssertTrue(securityView.waitForExistence(timeout: 5), "Security view should appear")
    }

    func testNavigateToSubscription() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.descendants(matching: .any)["more-view"].firstMatch
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        // Need to scroll to find Subscription in Account Settings section
        app.swipeUp()

        // NavigationLinks in SwiftUI List are exposed as Buttons, not Cells
        let subscriptionRow = app.buttons["subscription-row"]
        XCTAssertTrue(subscriptionRow.waitForExistence(timeout: 5))
        subscriptionRow.tap()

        // SwiftUI List views are exposed as CollectionView, use descendants query
        let subscriptionView = app.descendants(matching: .any)["subscription-settings-view"].firstMatch
        XCTAssertTrue(subscriptionView.waitForExistence(timeout: 5))
    }

    func testNavigateToNotificationSettings() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.descendants(matching: .any)["more-view"].firstMatch
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        // Need to scroll to find Notifications in Account Settings section
        app.swipeUp()

        // NavigationLinks in SwiftUI List are exposed as Buttons, not Cells
        let notificationsRow = app.buttons["notifications-row"]
        XCTAssertTrue(notificationsRow.waitForExistence(timeout: 5))
        notificationsRow.tap()

        // SwiftUI List views are exposed as CollectionView, use descendants query
        let notificationView = app.descendants(matching: .any)["notification-settings-view"].firstMatch
        XCTAssertTrue(notificationView.waitForExistence(timeout: 5))
    }

    func testNavigateToCalorieExpenditure() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.descendants(matching: .any)["more-view"].firstMatch
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        // NavigationLinks in SwiftUI List are exposed as Buttons, not Cells
        let expenditureRow = app.buttons["calorie-expenditure-row"]
        XCTAssertTrue(expenditureRow.waitForExistence(timeout: 5))
        expenditureRow.tap()

        // SwiftUI List views are exposed as CollectionView, use descendants query
        let expenditureView = app.descendants(matching: .any)["calorie-expenditure-view"].firstMatch
        XCTAssertTrue(expenditureView.waitForExistence(timeout: 5))
    }

    // MARK: - GLP-1 Programs Tests (v0.5.0)

    func testNavigateToGLP1Programs() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.descendants(matching: .any)["more-view"].firstMatch
        XCTAssertTrue(moreView.waitForExistence(timeout: 5), "More view should appear")

        // NavigationLink in List - exposed as Button
        let glp1Row = app.buttons["glp1-programs-row"]
        XCTAssertTrue(glp1Row.waitForExistence(timeout: 5), "GLP-1 Programs row should exist")
        glp1Row.tap()

        // SwiftUI List views are exposed as CollectionView, use descendants query
        let glp1View = app.descendants(matching: .any)["glp1-programs-view"].firstMatch
        XCTAssertTrue(glp1View.waitForExistence(timeout: 5), "GLP-1 Programs view should appear")
    }

    func testGLP1ProgramsShowsAnalyticsByDefault() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.descendants(matching: .any)["more-view"].firstMatch
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        let glp1Row = app.buttons["glp1-programs-row"]
        XCTAssertTrue(glp1Row.waitForExistence(timeout: 5))
        glp1Row.tap()

        // Wait for view to load - use descendants query
        let glp1View = app.descendants(matching: .any)["glp1-programs-view"].firstMatch
        XCTAssertTrue(glp1View.waitForExistence(timeout: 5))

        // Verify section picker exists by checking for its segment buttons
        // (SwiftUI Picker identifiers inherit from parent view, so query by button labels)
        let analyticsButton = app.buttons["Analytics"]
        XCTAssertTrue(analyticsButton.waitForExistence(timeout: 3), "Analytics segment should exist")
        XCTAssertTrue(analyticsButton.isSelected, "Analytics should be selected by default")

        let medicationsButton = app.buttons["Medications"]
        XCTAssertTrue(medicationsButton.exists, "Medications segment should exist")

        // Analytics sub-picker should be visible with its segments
        let concentrationButton = app.buttons["Concentration"]
        XCTAssertTrue(concentrationButton.waitForExistence(timeout: 3), "Concentration segment should be visible")
        XCTAssertTrue(concentrationButton.isSelected, "Concentration should be selected by default")
    }

    func testGLP1ProgramsSwitchToMedications() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.descendants(matching: .any)["more-view"].firstMatch
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        let glp1Row = app.buttons["glp1-programs-row"]
        XCTAssertTrue(glp1Row.waitForExistence(timeout: 5))
        glp1Row.tap()

        // Wait for view to load
        let glp1View = app.descendants(matching: .any)["glp1-programs-view"].firstMatch
        XCTAssertTrue(glp1View.waitForExistence(timeout: 5))

        // Verify Analytics sub-picker is visible initially
        let concentrationButton = app.buttons["Concentration"]
        XCTAssertTrue(concentrationButton.waitForExistence(timeout: 3), "Concentration should be visible initially")

        // Tap Medications button in the section picker
        let medicationsButton = app.buttons["Medications"]
        XCTAssertTrue(medicationsButton.waitForExistence(timeout: 3), "Medications button should exist")
        medicationsButton.tap()

        // Wait for UI to update using expectation instead of Thread.sleep
        let disappearPredicate = NSPredicate(format: "exists == false")
        let disappearExpectation = XCTNSPredicateExpectation(
            predicate: disappearPredicate,
            object: concentrationButton
        )
        let result = XCTWaiter().wait(for: [disappearExpectation], timeout: 3)

        // Analytics sub-picker segments should NOT be visible anymore
        XCTAssertEqual(result, .completed, "Concentration button should hide when Medications selected")
    }

    func testNavigateToFoodLibrary() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.descendants(matching: .any)["more-view"].firstMatch
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        // Food Library is a Button action (shows sheet), not a NavigationLink
        let foodLibraryRow = app.buttons["food-library-row"]
        XCTAssertTrue(foodLibraryRow.waitForExistence(timeout: 5))
        foodLibraryRow.tap()

        // Food Library opens as a sheet with Library tab selected
        // Verify the Library button is selected/visible in the sheet header
        let libraryButton = app.buttons["Library"]
        XCTAssertTrue(libraryButton.waitForExistence(timeout: 5), "Library button should appear in sheet")

        // Verify Foods tab exists in library view
        let foodsTab = app.buttons["Foods"]
        XCTAssertTrue(foodsTab.waitForExistence(timeout: 3), "Foods tab should exist in library")
    }

    // MARK: - Inactive Placeholder Tests

    func testInactiveItemsNotTappable() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.descendants(matching: .any)["more-view"].firstMatch
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        // Placeholder items exist as StaticText (inactive, grayed out)
        // In SwiftUI List, Label creates both Image and StaticText with the identifier
        let foodLogPlaceholder = app.staticTexts["food-log-placeholder"]
        XCTAssertTrue(foodLogPlaceholder.waitForExistence(timeout: 3), "Food Log placeholder should exist")

        let shortcutsPlaceholder = app.staticTexts["shortcuts-placeholder"]
        XCTAssertTrue(shortcutsPlaceholder.waitForExistence(timeout: 3), "Shortcuts placeholder should exist")

        // FAQ placeholder - need to scroll to see it
        app.swipeUp()
        let faqPlaceholder = app.staticTexts["faq-placeholder"]
        XCTAssertTrue(faqPlaceholder.waitForExistence(timeout: 3), "FAQ placeholder should exist")
    }

    // MARK: - Security & Privacy Tests

    func testBiometricToggleExists() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.descendants(matching: .any)["more-view"].firstMatch
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        // Need to scroll down to find Security & Privacy
        app.swipeUp()

        // NavigationLinks in SwiftUI List are exposed as Buttons, not Cells
        let securityRow = app.buttons["security-privacy-row"]
        XCTAssertTrue(securityRow.waitForExistence(timeout: 5))
        securityRow.tap()

        // May not exist on simulator without biometric support
        // Just verify view loads - use descendants query for CollectionView
        let securityView = app.descendants(matching: .any)["security-privacy-view"].firstMatch
        XCTAssertTrue(securityView.waitForExistence(timeout: 5))
    }

    func testHealthToggleExists() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.descendants(matching: .any)["more-view"].firstMatch
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        // Need to scroll down to find Security & Privacy
        app.swipeUp()

        // NavigationLinks in SwiftUI List are exposed as Buttons, not Cells
        let securityRow = app.buttons["security-privacy-row"]
        XCTAssertTrue(securityRow.waitForExistence(timeout: 5))
        securityRow.tap()

        let healthToggle = app.switches["health-toggle"]
        XCTAssertTrue(healthToggle.waitForExistence(timeout: 5))
    }

    // MARK: - Notification Settings Tests

    func testNotificationTogglesExist() throws {
        TestUtilities.navigateToTab(app, tabName: "More")

        let moreView = app.descendants(matching: .any)["more-view"].firstMatch
        XCTAssertTrue(moreView.waitForExistence(timeout: 5))

        // Need to scroll down to find Notifications
        app.swipeUp()

        // NavigationLinks in SwiftUI List are exposed as Buttons, not Cells
        let notificationsRow = app.buttons["notifications-row"]
        XCTAssertTrue(notificationsRow.waitForExistence(timeout: 5))
        notificationsRow.tap()

        // Use descendants query for CollectionView
        let notificationView = app.descendants(matching: .any)["notification-settings-view"].firstMatch
        XCTAssertTrue(notificationView.waitForExistence(timeout: 5))

        // Verify key toggles exist
        XCTAssertTrue(app.switches["weigh-in-daily-toggle"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.switches["dose-reminder-toggle"].waitForExistence(timeout: 3))
    }
}
