//
//  SplitDoseIntegrationUITests.swift
//  JabTrackerUITests
//
//  Split dosing in the launch build: new schedules never offer Split Dose, and a recorded split schedule
//  (seeded as Semaglutide (Ozempic) 1.00 mg weekly total) keeps its twice-weekly pattern without prefilling
//  the weekly total as one administration.
//

import XCTest

final class SplitDoseIntegrationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "7"
        app.launchEnvironment["TEST_DATA_DOSE_COUNT"] = "1"
        app.launchEnvironment["TEST_DATA_MEDICATION"] = "semaglutide"
        app.launchEnvironment["TEST_DATA_BRAND"] = "Ozempic"
        app.launchEnvironment["TEST_DATA_DOSE"] = "1.0"
        app.launchEnvironment["TEST_DATA_SPLIT_SCHEDULE"] = "true"
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
    }

    override func tearDown() {
        if testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
        super.tearDown()
    }

    private var profileRow: XCUIElement {
        TestUtilities.medicationProfileRow(app, medication: "semaglutide", brand: "Ozempic", amount: 1.0)
    }

    private func launch() {
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }

    private func evidence(_ name: String) {
        TestUtilities.debugScreenshot(app, name: "split-integration-\(name)")
        print(app.debugDescription)
    }

    func testQuickAddDoseShowsCorrectSplitDoseAmount() throws {
        launch()
        TestUtilities.openShortcutsSheet(app)
        app.buttons["shortcut-button-shots"].tap()
        let amount = app.textFields["quick-dose-prescribed-amount-input"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        evidence("quick-dose-split")

        // A recorded split schedule never prefills the 1.00 mg weekly total as one administration.
        XCTAssertEqual(amount.value as? String, amount.placeholderValue)
        XCTAssertEqual(amount.placeholderValue, "Amount")
        let save = app.buttons["quick-dose-save-button"]
        XCTAssertFalse(save.isEnabled)
        amount.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        amount.typeText("0.5")
        XCTAssertEqual(amount.value as? String, "0.5")
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(amount.waitForNonExistence(timeout: 5))

        TestUtilities.navigateToHistoryView(in: app)
        let rows = TestUtilities.getDoseRows(from: app, minimumCount: 2)
        evidence("history-after-split-dose")
        XCTAssertEqual(rows.count, 2)
        XCTAssertTrue(rows.element(boundBy: 0).label.contains("0.50 mg"), rows.element(boundBy: 0).label)
    }

    func testCalendarShowsTwiceWeeklyDosePattern() throws {
        launch()
        TestUtilities.navigateToHistoryView(in: app)
        app.segmentedControls["history-view-mode-picker"].buttons["Calendar"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["dose-calendar-container"].waitForExistence(timeout: 5))
        evidence("calendar")

        let scheduledDays = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS ' scheduled'")).allElementsBoundByIndex.map(\.label)
        print("Scheduled day labels: \(scheduledDays)")
        XCTAssertFalse(scheduledDays.isEmpty, "The recorded split schedule projects scheduled doses")
        XCTAssertTrue(
            scheduledDays.allSatisfy { $0.contains("1 scheduled") },
            "Twice weekly means one administration per scheduled day, not two: \(scheduledDays)")
    }

    func testSettingsShowsSplitDoseSchedule() throws {
        launch()
        TestUtilities.navigateToMedicationProfiles(app)
        XCTAssertTrue(profileRow.waitForExistence(timeout: 5))
        XCTAssertTrue(profileRow.staticTexts["Recorded schedule"].exists)
        TestUtilities.openMedicationProfile(app, row: profileRow)
        XCTAssertTrue(app.staticTexts["Split Dose (Twice Weekly)"].waitForExistence(timeout: 5))

        // Replacing the recorded split schedule offers only Daily and Weekly for the new one.
        app.buttons["deactivate-schedule-button"].tap()
        let confirm = app.buttons.matching(
            NSPredicate(format: "label == 'Deactivate Schedule' AND identifier == ''")).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        app.buttons["create-schedule-button"].tap()
        XCTAssertTrue(app.navigationBars["Create Schedule"].waitForExistence(timeout: 5))
        evidence("new-schedule-after-split")
        XCTAssertEqual(
            app.buttons.matching(identifier: "pattern-picker").allElementsBoundByIndex.map(\.label), ["Daily", "Weekly"])
        XCTAssertFalse(app.buttons["Split Dose"].exists)
        XCTAssertFalse(app.buttons["Recorded Split Schedule"].exists)
        app.buttons["cancel-schedule-edit"].tap()
    }
}
