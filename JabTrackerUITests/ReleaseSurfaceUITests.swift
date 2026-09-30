import XCTest

final class ReleaseSurfaceUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }

    override func tearDownWithError() throws {
        if testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
    }

    func testSupportedShortcutsOpenSearchAndHideUnfinishedActions() {
        TestUtilities.openShortcutsSheet(app)
        TestUtilities.debugScreenshot(app, name: "release-shortcuts")
        print(app.debugDescription)
        for identifier in ["shortcut-button-search", "shortcut-button-barcode", "shortcut-button-shots",
                           "shortcut-row-weight", "shortcut-row-quick add", "shortcut-row-metrics", "shortcut-row-your foods"] {
            XCTAssertTrue(app.buttons[identifier].exists, "Supported shortcut missing: \(identifier)")
        }
        for identifier in ["shortcut-button-ai", "shortcut-row-recipes", "shortcut-row-edit days",
                           "shortcut-row-progress photos", "shortcuts-customize-button"] {
            XCTAssertFalse(app.buttons[identifier].exists, "Unfinished shortcut visible: \(identifier)")
        }

        app.buttons["shortcut-button-search"].tap()
        XCTAssertTrue(app.textFields["food-search-field"].waitForExistence(timeout: 5))
        TestUtilities.debugScreenshot(app, name: "release-search-methods")
        print(app.debugDescription)
        XCTAssertFalse(app.buttons["method-tab-ai"].exists)
        for method in ["scan", "search", "quickAdd", "library"] {
            XCTAssertTrue(app.buttons["method-tab-\(method)"].exists)
        }
        app.buttons["method-tab-library"].tap()
        XCTAssertTrue(app.buttons["food-library-tab-foods"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["food-library-tab-scheduled"].exists)
        XCTAssertFalse(app.buttons["food-library-tab-recipes"].exists)
        XCTAssertFalse(app.buttons["food-library-tab-favorites"].exists)
    }

    func testMoreHidesUnfinishedSettingsAndRetainsAccountAndGeneral() {
        TestUtilities.navigateToTab(app, tabName: "More")
        XCTAssertTrue(app.descendants(matching: .any)["more-view"].firstMatch.waitForExistence(timeout: 5))
        TestUtilities.debugScreenshot(app, name: "release-more-features")
        print(app.debugDescription)
        for identifier in ["dashboard-settings-placeholder", "food-log-placeholder", "shortcuts-placeholder"] {
            XCTAssertFalse(app.descendants(matching: .any)[identifier].firstMatch.exists)
        }
        XCTAssertTrue(app.buttons["metrics-settings-link"].exists)
        XCTAssertTrue(app.buttons["calorie-expenditure-row"].exists)
        app.swipeUp()
        TestUtilities.debugScreenshot(app, name: "release-more-account-help")
        print(app.debugDescription)
        for identifier in ["subscription-row", "faq-placeholder", "help-support-placeholder"] {
            XCTAssertFalse(app.descendants(matching: .any)[identifier].firstMatch.exists)
        }
        XCTAssertTrue(app.buttons["profile-link"].exists)
        XCTAssertTrue(app.buttons["security-privacy-row"].exists)
        XCTAssertTrue(app.buttons["notifications-row"].exists)
        XCTAssertTrue(app.buttons["general-link"].exists)
    }

    func testFoodDetailRetainsCopyToCustomAndScheduleWhileFavoriteIsHidden() {
        TestUtilities.openShortcutsSheet(app)
        app.buttons["shortcut-button-search"].tap()
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("egg")
        let result = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'food-result-'"))
            .firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        result.tap()
        TestUtilities.debugScreenshot(app, name: "before-release-food-detail")
        print(app.debugDescription)
        XCTAssertTrue(app.buttons["to-custom-button"].waitForExistence(timeout: 5))
        TestUtilities.debugScreenshot(app, name: "release-food-detail-actions")
        print(app.debugDescription)
        XCTAssertFalse(app.buttons["Favorite"].exists)
        XCTAssertTrue(app.buttons["schedule-food-button"].exists)
        XCTAssertTrue(app.buttons["add-food-button"].exists)
        app.buttons["to-custom-button"].tap()
        XCTAssertTrue(app.textFields["food-name-input"].waitForExistence(timeout: 5))
    }
}
