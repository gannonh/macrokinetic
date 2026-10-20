//
//  DailyMedicationProfileScheduleUITests.swift
//  JabTrackerUITests
//
//  Daily schedule management for a seeded Liraglutide (Victoza) 0.60 mg profile,
//  reached through More > GLP-1 Programs > Medications.
//

import XCTest

final class DailyMedicationProfileScheduleUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        // Pre-seed a Liraglutide profile with no doses, so it has no schedule yet
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "0"
        app.launchEnvironment["TEST_DATA_MEDICATION"] = "liraglutide"
        app.launchEnvironment["TEST_DATA_BRAND"] = "Victoza"
        app.launchEnvironment["TEST_DATA_DOSE"] = "0.6"
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
    }

    override func tearDown() {
        if testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
        super.tearDown()
    }

    private func openSeededProfile() {
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        let row = TestUtilities.medicationProfileRow(app, medication: "liraglutide", brand: "Victoza", amount: 0.6)
        TestUtilities.openMedicationProfile(app, row: row)
        XCTAssertTrue(app.navigationBars["Liraglutide (Victoza)"].exists)
        XCTAssertTrue(app.staticTexts["0.60 mg"].exists)
    }

    private func patternOptions() -> [String] {
        app.buttons.matching(identifier: "pattern-picker").allElementsBoundByIndex.map(\.label)
    }

    func testDailyMedicationScheduleCreation() throws {
        openSeededProfile()
        app.buttons["create-schedule-button"].tap()
        XCTAssertTrue(app.navigationBars["Create Schedule"].waitForExistence(timeout: 5))

        // The launch editor records the prescribed pattern and never offers Split Dose.
        XCTAssertEqual(patternOptions(), ["Daily", "Weekly"])
        XCTAssertFalse(app.buttons["Split Dose"].exists)
        XCTAssertTrue(app.staticTexts["0.60 mg"].exists, "The editor states the profile amount")
        let create = app.buttons["save-schedule-edit"]
        XCTAssertFalse(create.isEnabled)

        app.buttons["Daily"].tap()
        XCTAssertTrue(create.isEnabled)
        XCTAssertFalse(app.steppers["interval-stepper"].exists, "Daily has no interval")
        create.tap()
        XCTAssertTrue(create.waitForNonExistence(timeout: 5))

        XCTAssertTrue(app.buttons["edit-schedule-button"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Standard Daily"].exists)
    }

    func testDailyMedicationEditSchedulePatternRestriction() throws {
        openSeededProfile()
        try TestUtilities.createDefaultSchedule(app, pattern: "Daily")

        app.buttons["edit-schedule-button"].tap()
        XCTAssertTrue(app.navigationBars["Edit Schedule"].waitForExistence(timeout: 5))
        XCTAssertEqual(patternOptions(), ["Daily", "Weekly"])
        XCTAssertTrue(app.buttons["Daily"].isSelected)
        XCTAssertFalse(app.buttons["Split Dose"].exists)
        XCTAssertFalse(app.buttons["Recorded Split Schedule"].exists)

        app.buttons["cancel-schedule-edit"].tap()
        XCTAssertTrue(app.staticTexts["Standard Daily"].waitForExistence(timeout: 5))
    }

    func testDailyMedicationPauseResumeSchedule() throws {
        openSeededProfile()
        try TestUtilities.createDefaultSchedule(app, pattern: "Daily")

        app.buttons["pause-schedule-button"].tap()
        let confirm = app.buttons["pause-confirm-button"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(confirm.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Schedule Paused"].waitForExistence(timeout: 5))

        app.buttons["resume-schedule-button"].tap()
        XCTAssertTrue(app.buttons["pause-schedule-button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Schedule Paused"].exists)
        XCTAssertTrue(app.staticTexts["Standard Daily"].exists)
    }
}
