//
//  MedicationProfileScheduleUITests.swift
//  JabTrackerUITests
//
//  Schedule create, edit, pause, resume and deactivate for a seeded Semaglutide (Ozempic) 0.25 mg profile,
//  reached through More > GLP-1 Programs > Medications.
//

import XCTest

final class MedicationProfileScheduleUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        // Pre-seed a medication profile with no doses, so it has no schedule yet
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "0"
        app.launchEnvironment["TEST_DATA_MEDICATION"] = "semaglutide"
        app.launchEnvironment["TEST_DATA_BRAND"] = "Ozempic"
        app.launchEnvironment["TEST_DATA_DOSE"] = "0.25"
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
        TestUtilities.medicationProfileRow(app, medication: "semaglutide", brand: "Ozempic", amount: 0.25)
    }

    private func openSeededProfile() {
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        TestUtilities.navigateToMedicationProfiles(app)
        XCTAssertTrue(profileRow.waitForExistence(timeout: 5))
        XCTAssertTrue(profileRow.staticTexts["Schedule not set"].exists)
        TestUtilities.openMedicationProfile(app, row: profileRow)
    }

    private func patternOptions() -> [String] {
        app.buttons.matching(identifier: "pattern-picker").allElementsBoundByIndex.map(\.label)
    }

    private func openEditor() {
        app.buttons["edit-schedule-button"].tap()
        XCTAssertTrue(app.navigationBars["Edit Schedule"].waitForExistence(timeout: 5))
    }

    private func incrementInterval() {
        app.steppers["interval-stepper"].buttons["Increment"].tap()
    }

    private func saveEditor() {
        let save = app.buttons["save-schedule-edit"]
        XCTAssertEqual(save.label, "Save")
        save.tap()
        XCTAssertTrue(save.waitForNonExistence(timeout: 5))
    }

    private func pause() {
        app.buttons["pause-schedule-button"].tap()
        let confirm = app.buttons["pause-confirm-button"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(confirm.waitForNonExistence(timeout: 5))
    }

    private func confirmDeactivateButton() -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == 'Deactivate Schedule' AND identifier == ''")).firstMatch
    }

    func testCreateWeeklySchedule() throws {
        openSeededProfile()
        app.buttons["create-schedule-button"].tap()
        XCTAssertTrue(app.navigationBars["Create Schedule"].waitForExistence(timeout: 5))
        let create = app.buttons["save-schedule-edit"]
        XCTAssertEqual(create.label, "Create")
        XCTAssertFalse(create.isEnabled, "No pattern is preselected for a new schedule")

        app.buttons["Weekly"].tap()
        XCTAssertTrue(create.isEnabled)
        XCTAssertTrue(app.staticTexts["7 days"].exists, "A weekly schedule starts at a 7 day interval")
        create.tap()
        XCTAssertTrue(create.waitForNonExistence(timeout: 5))

        XCTAssertTrue(app.staticTexts["Standard Weekly"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Once weekly"].exists)
        app.navigationBars.buttons["BackButton"].tap()
        XCTAssertTrue(profileRow.staticTexts["Recorded schedule"].waitForExistence(timeout: 5))
    }

    func testEditExistingSchedule() throws {
        openSeededProfile()
        try TestUtilities.createDefaultSchedule(app)

        openEditor()
        XCTAssertTrue(app.buttons["Weekly"].isSelected)
        XCTAssertTrue(app.staticTexts["7 days"].exists)
        incrementInterval()
        XCTAssertTrue(app.staticTexts["8 days"].exists)
        saveEditor()

        openEditor()
        XCTAssertTrue(app.staticTexts["8 days"].exists, "The saved interval reopens as 8 days")
        app.buttons["cancel-schedule-edit"].tap()
    }

    func testPauseScheduleOneWeek() throws {
        openSeededProfile()
        try TestUtilities.createDefaultSchedule(app)
        XCTAssertFalse(app.staticTexts["Schedule Paused"].exists)

        pause()

        XCTAssertTrue(app.staticTexts["Schedule Paused"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["resume-schedule-button"].label, "Resume Schedule")
        XCTAssertFalse(app.buttons["pause-schedule-button"].exists)
    }

    func testResumeSchedule() throws {
        openSeededProfile()
        try TestUtilities.createDefaultSchedule(app)
        pause()
        XCTAssertTrue(app.staticTexts["Schedule Paused"].waitForExistence(timeout: 5))

        app.buttons["resume-schedule-button"].tap()

        XCTAssertTrue(app.buttons["pause-schedule-button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Schedule Paused"].exists)
        XCTAssertTrue(app.staticTexts["Standard Weekly"].exists)
    }

    func testDeactivateScheduleWithConfirmation() throws {
        openSeededProfile()
        try TestUtilities.createDefaultSchedule(app)

        app.buttons["deactivate-schedule-button"].tap()
        let confirm = confirmDeactivateButton()
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        XCTAssertTrue(app.buttons["create-schedule-button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["edit-schedule-button"].exists)
        app.navigationBars.buttons["BackButton"].tap()
        XCTAssertTrue(profileRow.staticTexts["Schedule not set"].waitForExistence(timeout: 5))
    }

    func testCancelDeactivateSchedule() throws {
        openSeededProfile()
        try TestUtilities.createDefaultSchedule(app)

        app.buttons["deactivate-schedule-button"].tap()
        let confirm = confirmDeactivateButton()
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        // The confirmation dialog has no Cancel button on iPhone; tapping outside dismisses it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.15)).tap()
        XCTAssertTrue(confirm.waitForNonExistence(timeout: 5))

        XCTAssertTrue(app.buttons["edit-schedule-button"].exists)
        XCTAssertTrue(app.staticTexts["Standard Weekly"].exists)
    }

    func testMultipleScheduleModifications() throws {
        openSeededProfile()
        try TestUtilities.createDefaultSchedule(app)

        openEditor()
        incrementInterval()
        saveEditor()
        openEditor()
        XCTAssertTrue(app.staticTexts["8 days"].exists)
        incrementInterval()
        saveEditor()

        openEditor()
        XCTAssertTrue(app.staticTexts["9 days"].exists, "The second edit builds on the first")
        app.buttons["cancel-schedule-edit"].tap()
        XCTAssertTrue(app.staticTexts["Standard Weekly"].waitForExistence(timeout: 5))
    }

    func testScheduleManagementAccessibility() throws {
        openSeededProfile()
        XCTAssertEqual(app.buttons["create-schedule-button"].label, "Create Dose Schedule")

        try TestUtilities.createDefaultSchedule(app)

        XCTAssertEqual(app.buttons["edit-schedule-button"].label, "Edit Schedule")
        XCTAssertEqual(app.buttons["pause-schedule-button"].label, "Pause Schedule")
        XCTAssertEqual(app.buttons["deactivate-schedule-button"].label, "Deactivate Schedule")
    }

    func testNewScheduleOffersOnlyDailyAndWeekly() throws {
        openSeededProfile()
        app.buttons["create-schedule-button"].tap()
        XCTAssertTrue(app.navigationBars["Create Schedule"].waitForExistence(timeout: 5))
        TestUtilities.debugScreenshot(app, name: "new-schedule-patterns")
        print(app.debugDescription)

        XCTAssertEqual(patternOptions(), ["Daily", "Weekly"])
        XCTAssertFalse(app.buttons["Split Dose"].exists)
        XCTAssertFalse(app.staticTexts["Split Dose"].exists)
        XCTAssertFalse(app.buttons["Recorded Split Schedule"].exists)
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Custom'")).count, 0)
        XCTAssertTrue(app.staticTexts[
            "Record the schedule prescribed by your clinician. This app does not recommend a dosing schedule."
        ].exists)
        app.buttons["cancel-schedule-edit"].tap()
    }
}
