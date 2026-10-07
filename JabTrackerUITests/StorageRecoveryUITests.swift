import XCTest

final class StorageRecoveryUITests: XCTestCase {
    private var app: XCUIApplication!
    private let fixtureID = UUID()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        if let app {
            if testRun?.hasSucceeded == false { capture("storage-failure") }
            app.terminate()
        }
        app = nil
    }

    private func launch(
        failure: String? = nil,
        additional: [String] = [],
        seedDose: Bool = false,
        largeText: Bool = false
    ) {
        app = XCUIApplication()
        app.launchArguments = ["--storage-fixture=\(fixtureID.uuidString)", "--ui-testing", "--bypass-onboarding"]
        if let failure { app.launchArguments.append(failure) }
        app.launchArguments += additional
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launchEnvironment = ["UI_TESTING": "true"]
        if seedDose {
            app.launchEnvironment.merge([
                "TEST_DATA_SEED": "true", "TEST_DATA_DAYS": "7", "TEST_DATA_DOSE_COUNT": "1",
                "TEST_DATA_DOSE": "0.75", "TEST_DATA_ADHERENCE": "1.0",
                "TEST_DATA_VARIABILITY": "false", "TEST_DATA_SKIPPED": "false",
            ]) { _, new in new }
        }
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func capture(_ label: String) {
        TestUtilities.debugScreenshot(app, name: label)
        print(app.debugDescription)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = label
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func check(_ condition: Bool, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        if !condition { capture("before-storage-assertion") }
        XCTAssertTrue(condition, message, file: file, line: line)
    }

    private func waitForNormalApp() {
        check(app.tabBars.element.waitForExistence(timeout: 10), "Normal app should open after disk initialization")
        check(!element("storage-recovery-title").exists, "Recovery should be absent when storage is ready")
    }

    private func waitForRecovery() {
        check(element("storage-recovery-title").waitForExistence(timeout: 10), "Storage failure should show recovery")
        check(element("storage-recovery-title").label == "Can't open saved data", "Recovery title should be clear")
        check(!app.tabBars.element.exists, "Normal tabs must not exist during failure")
    }

    private func checkLoggingIsUnavailable() {
        for identifier in ["food-log-view", "food-search-sheet", "add-food-button", "add-button",
                           "quick-dose-medication-picker", "quick-dose-save-button", "dashboard-view"] {
            check(!element(identifier).exists, "\(identifier) must not be mounted during storage failure")
        }
    }

    private func openFoodLog() {
        let tab = app.tabBars.buttons["Food Log"]
        check(tab.waitForExistence(timeout: 5), "Food Log tab should exist")
        tab.tap()
        check(element("food-log-view").waitForExistence(timeout: 5), "Food Log should open")
    }

    private func logFoodAndReadLabel() -> String {
        openFoodLog()
        let addFood = app.buttons["add-food-button"].firstMatch
        check(addFood.waitForExistence(timeout: 5), "Food logging action should exist")
        addFood.tap()
        check(element("food-search-sheet").waitForExistence(timeout: 5), "Food search should open")
        let search = app.textFields["food-search-field"]
        check(search.waitForExistence(timeout: 5), "Food search input should exist")
        search.tap()
        search.typeText("chicken")
        let result = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'food-result-'")).firstMatch
        check(result.waitForExistence(timeout: 10), "Bundled database should return chicken")
        result.tap()
        check(element("food-detail-sheet").waitForExistence(timeout: 5), "Food details should open")
        let save = app.buttons["add-food-button"].firstMatch
        check(save.waitForExistence(timeout: 5), "Food details should provide Add")
        save.tap()
        check(element("food-search-sheet").waitForNonExistence(timeout: 5), "Food logging sheets should dismiss")
        let row = app.buttons.matching(identifier: "food-entry-row").firstMatch
        check(row.waitForExistence(timeout: 5), "Saved food should be visible")
        check(!row.label.isEmpty, "Saved food should expose its displayed values")
        return row.label
    }

    private func checkOriginalFood(_ label: String) {
        openFoodLog()
        let rows = app.buttons.matching(identifier: "food-entry-row")
        check(rows.firstMatch.waitForExistence(timeout: 5), "Original food should remain")
        check(rows.count == 1, "Recovery must not replace or duplicate the original food")
        check(rows.firstMatch.label == label, "Original food name, serving and displayed nutrition should remain")
    }

    private func checkOriginalDose() {
        app.tabBars.buttons["More"].tap()
        let programs = app.buttons["glp1-programs-row"]
        check(programs.waitForExistence(timeout: 5), "GLP-1 Programs should be available through More")
        programs.tap()
        let history = app.segmentedControls["analytics-section-picker"].buttons["History"]
        check(history.waitForExistence(timeout: 5), "History section should exist")
        history.tap()
        let rows = app.descendants(matching: .any).matching(identifier: "dose-history-row")
        check(rows.firstMatch.waitForExistence(timeout: 5), "Original dose should remain in history")
        check(rows.count == 1, "Recovery must not replace or duplicate the original dose")
        check(rows.firstMatch.label.contains("0.75 milligrams"), "The preexisting 0.75 dose should retain its amount")
    }

    func test01NormalLaunchHasNoRecovery() {
        launch()
        waitForNormalApp()
        capture("01-storage-normal-branch")
    }

    func test02SuccessfulDiskStartupRetainsFoodAndDoseAcrossRelaunch() {
        launch(seedDose: true)
        waitForNormalApp()
        let food = logFoodAndReadLabel()
        checkOriginalDose()
        app.terminate()
        launch()
        waitForNormalApp()
        checkOriginalFood(food)
        checkOriginalDose()
        capture("02-storage-disk-relaunch")
    }

    func test03PersistentFailureBlocksStartupEvenWithResetAndSeedInputs() {
        launch(failure: "--storage-always-fail-open", additional: [
            "--reset-app-data", "--force-onboarding", "--test-titration-data", "--seed-calorie-user",
            "--seed-test-1y", "--cloudkit-testing", "-inMemory",
        ])
        waitForRecovery()
        checkLoggingIsUnavailable()
        capture("03-storage-startup-blocked")
    }

    func test04FoodLoggingCannotOpenWhileStorageIsFailed() {
        launch(failure: "--storage-always-fail-open")
        waitForRecovery()
        check(!app.tabBars.buttons["Food Log"].exists, "Food Log must be unavailable")
        app.swipeUp()
        checkLoggingIsUnavailable()
        capture("04-storage-no-food-logging")
    }

    func test05DoseDeeplinkAndForegroundCannotEscapeRecovery() {
        let url = "jab-tracker://dose/log?scheduledDoseId=\(UUID().uuidString)"
        launch(failure: "--storage-always-fail-open", additional: ["--deeplink-url=\(url)"])
        waitForRecovery()
        XCUIDevice.shared.press(.home)
        app.activate()
        waitForRecovery()
        checkLoggingIsUnavailable()
        capture("05-storage-no-dose-logging")
    }

    func test06RecoveryExplainsThatLoggingIsUnavailable() {
        launch(failure: "--storage-always-fail-open")
        waitForRecovery()
        let message = element("storage-recovery-message")
        check(message.label == "You can't log changes until storage is available. JabTracker hasn't deleted your existing data. "
              + "Try again, or close and reopen the app.", "Recovery should describe blocked logging and preserved data")
        check(!element("dose-logged-success").exists, "A saved-dose confirmation must not appear")
        capture("06-storage-recovery-copy")
    }

    func test07RepeatedRetryFailuresStayBlocked() {
        launch(failure: "--storage-always-fail-open")
        waitForRecovery()
        for count in 2...3 {
            app.buttons["storage-retry"].tap()
            let feedback = element("storage-retry-failure")
            check(feedback.waitForExistence(timeout: 5), "Retry failure should provide feedback")
            check(feedback.label == "Still unable to open saved data after \(count) attempts.", "Retry should complete a new attempt")
            checkLoggingIsUnavailable()
        }
        capture("07-storage-repeat-failure")
    }

    func test08RetryRestoresPreexistingFoodAndDoseWithoutReseeding() {
        launch(seedDose: true)
        waitForNormalApp()
        let food = logFoodAndReadLabel()
        checkOriginalDose()
        app.terminate()
        launch(failure: "--storage-fail-first-open")
        waitForRecovery()
        capture("08-storage-before-retry")
        app.buttons["storage-retry"].tap()
        waitForNormalApp()
        checkOriginalFood(food)
        checkOriginalDose()
        capture("08-storage-original-data-recovered")
    }

    func test09RelaunchAfterFailurePreservesOriginalStore() {
        launch(seedDose: true)
        waitForNormalApp()
        let food = logFoodAndReadLabel()
        checkOriginalDose()
        app.terminate()
        launch(failure: "--storage-always-fail-open", additional: ["--reset-app-data", "--seed-calorie-user"])
        waitForRecovery()
        app.terminate()
        launch()
        waitForNormalApp()
        checkOriginalFood(food)
        checkOriginalDose()
        capture("09-storage-original-data-after-relaunch")
    }

    func test10LargeTextRecoveryProvidesSafeSupportInformation() {
        launch(failure: "--storage-always-fail-open", largeText: true)
        waitForRecovery()
        let recovery = app.scrollViews["storage-recovery"]
        for _ in 0..<3 where !app.buttons["storage-support"].isHittable { recovery.swipeUp() }
        let support = app.buttons["storage-support"]
        check(support.isHittable, "Support should remain reachable at accessibility text sizes")
        support.tap()
        let information = element("storage-support-info")
        check(information.waitForExistence(timeout: 5), "Support metadata should open without storage")
        let keys = Set(information.label.split(separator: "\n").map { String($0.split(separator: "=")[0]) })
        check(keys == ["app", "version", "build", "os", "event", "attempt", "stage", "code"], "Support fields should be allowlisted")
        check(information.label.contains("event=storage-open-failed"), "Support should identify the storage failure")
        let copy = app.buttons["storage-support-copy"]
        let share = app.buttons["storage-support-share"]
        if !copy.isHittable { app.scrollViews.firstMatch.swipeUp() }
        check(copy.isHittable, "Copy should be reachable")
        copy.tap()
        check(copy.label == "Copied", "Copy should confirm only the local copy action")
        check(share.exists, "System share should be offered")
        capture("10-storage-safe-support-large-text")
        app.buttons["storage-support-done"].tap()
        waitForRecovery()
    }

    func test11DuplicateFixtureArgumentsFailClosedInsteadOfOpeningTheOrdinaryStore() {
        launch(additional: ["--storage-fixture=\(UUID().uuidString)"])
        waitForRecovery()
        checkLoggingIsUnavailable()
        capture("11-storage-duplicate-fixture-fails-closed")
    }

    func test12MalformedFixtureArgumentFailsClosedInsteadOfOpeningTheOrdinaryStore() {
        app = XCUIApplication()
        app.launchArguments = ["--storage-fixture=../../patient", "--ui-testing", "--bypass-onboarding"]
        app.launchEnvironment = ["UI_TESTING": "true"]
        app.launch()
        waitForRecovery()
        checkLoggingIsUnavailable()
        capture("12-storage-malformed-fixture-fails-closed")
    }
}
