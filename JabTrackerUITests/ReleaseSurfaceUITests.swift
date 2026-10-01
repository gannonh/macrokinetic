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

    func testStrategyAndCalorieSettingsOmitUnfinishedControlsAndKeepSupportedAdjustments() {
        TestUtilities.navigateToTab(app, tabName: "Strategy")
        TestUtilities.debugScreenshot(app, name: "release-strategy")
        print(app.debugDescription)
        for label in ["Edit Days", "Customize", "Coming Soon"] {
            XCTAssertFalse(app.staticTexts[label].exists, "Unfinished Strategy text visible: \(label)")
            XCTAssertFalse(app.buttons[label].exists, "Unfinished Strategy control visible: \(label)")
        }

        TestUtilities.navigateToTab(app, tabName: "More")
        XCTAssertTrue(app.buttons["calorie-expenditure-row"].waitForExistence(timeout: 5))
        app.buttons["calorie-expenditure-row"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["calorie-expenditure-view"].firstMatch.waitForExistence(timeout: 5))
        TestUtilities.debugScreenshot(app, name: "release-calorie-settings")
        print(app.debugDescription)
        for identifier in ["add-burned-calories-toggle", "predictive-activity-toggle", "rollover-calories-toggle"] {
            XCTAssertTrue(app.switches[identifier].exists, "Implemented calorie adjustment missing: \(identifier)")
        }
        XCTAssertFalse(app.staticTexts["Coming Soon"].exists)
    }

    func testQuickAddLogsFoodWhileUnfinishedChoicesStayHidden() {
        TestUtilities.openShortcutsSheet(app)
        app.buttons["shortcut-button-search"].tap()
        XCTAssertTrue(app.textFields["food-search-field"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["method-tab-ai"].exists)
        app.buttons["method-tab-quickAdd"].tap()
        let energy = app.textFields["quick-add-energy-input"]
        XCTAssertTrue(energy.waitForExistence(timeout: 5))
        energy.tap()
        energy.typeText("250")
        TestUtilities.debugScreenshot(app, name: "release-quick-add-entry")
        app.buttons["quick-add-add-button"].tap()
        XCTAssertTrue(app.textFields["food-search-field"].waitForNonExistence(timeout: 5))
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let total = app.staticTexts.matching(identifier: "macro-consumed-cal").firstMatch
        XCTAssertTrue(total.waitForExistence(timeout: 5))
        TestUtilities.debugScreenshot(app, name: "release-quick-add-logged")
        print(app.debugDescription)
        XCTAssertTrue(total.label.hasPrefix("250/"), "Logged 250 kcal should be the literal total; got \(total.label)")
    }

    func testStaleFlagPreferencesAndOverrideInputsCannotRevealHiddenFeaturesAfterRelaunch() {
        app.terminate()
        app = XCUIApplication()
        app.launchEnvironment = [
            "UI_TESTING": "true", "RELEASE_FEATURES": "all", "ENABLE_SUBSCRIPTIONS": "1", "ENABLE_AI_FOOD_CAPTURE": "1",
        ]
        app.launchArguments = [
            "--ui-testing", "--enable-all-features", "--enable-subscriptions", "--enable-ai-food-capture",
            "--enable-progress-photos", "--enable-recipes", "-subscriptions", "YES", "-aiFoodCapture", "YES",
            "-progressPhotos", "YES", "-recipes", "YES", "-ReleaseFeature.subscriptions", "YES",
        ]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        TestUtilities.openShortcutsSheet(app)
        TestUtilities.debugScreenshot(app, name: "release-hostile-shortcuts")
        for identifier in ["shortcut-button-ai", "shortcut-row-recipes", "shortcut-row-progress photos"] {
            XCTAssertFalse(app.buttons[identifier].exists, "Override revealed \(identifier)")
        }
        app.buttons["shortcuts-close-button"].tap()
        TestUtilities.navigateToTab(app, tabName: "More")
        XCTAssertTrue(app.descendants(matching: .any)["more-view"].firstMatch.waitForExistence(timeout: 5))
        app.swipeUp()
        TestUtilities.debugScreenshot(app, name: "release-hostile-more")
        XCTAssertFalse(app.descendants(matching: .any)["subscription-row"].firstMatch.exists)
        XCTAssertTrue(app.buttons["profile-link"].exists)
    }

    func testWeightLoggedFromShortcutIsRetainedAsNextDefaultWhileUnfinishedChoicesStayHidden() {
        TestUtilities.openShortcutsSheet(app)
        app.buttons["Weight"].tap()
        XCTAssertTrue(app.otherElements["quick-weight-sheet"].waitForExistence(timeout: 5))
        TestUtilities.debugScreenshot(app, name: "release-weight-sheet")
        print(app.debugDescription)
        let wheels = app.pickerWheels
        XCTAssertTrue(wheels.firstMatch.waitForExistence(timeout: 5), "Weight wheel should exist")
        wheels.element(boundBy: 0).adjust(toPickerWheelValue: "81")
        app.buttons["save-weight-button"].tap()
        XCTAssertTrue(app.otherElements["quick-weight-sheet"].waitForNonExistence(timeout: 5), "Save should dismiss the sheet")

        TestUtilities.openShortcutsSheet(app)
        app.buttons["Weight"].tap()
        XCTAssertTrue(app.otherElements["quick-weight-sheet"].waitForExistence(timeout: 5))
        TestUtilities.debugScreenshot(app, name: "release-weight-default-after-save")
        XCTAssertEqual(app.pickerWheels.element(boundBy: 0).value as? String, "81", "Saved weight should become the next default")
    }

    func testDashboardFoodLogMoreComparisonFlow() {
        TestUtilities.debugScreenshot(app, name: "scenario1-dashboard")
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        XCTAssertTrue(app.staticTexts.matching(identifier: "macro-consumed-cal").firstMatch.waitForExistence(timeout: 5))
        TestUtilities.debugScreenshot(app, name: "scenario1-food-log")
        TestUtilities.navigateToTab(app, tabName: "More")
        XCTAssertTrue(app.descendants(matching: .any)["more-view"].firstMatch.waitForExistence(timeout: 5))
        TestUtilities.debugScreenshot(app, name: "scenario1-more")
        app.swipeUp()
        TestUtilities.debugScreenshot(app, name: "scenario1-more-account")
    }
}
