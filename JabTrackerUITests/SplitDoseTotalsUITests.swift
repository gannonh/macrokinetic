import XCTest

/// KAT-3600: weekly dose totals stay literal around split dosing in the launch build.
/// A weekly schedule cannot be switched to split, and a recorded split schedule states its administration amount and
/// weekly total, and returns to weekly at the weekly total.
final class SplitDoseTotalsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "7"
        app.launchEnvironment["TEST_DATA_DOSE_COUNT"] = "1"
        app.launchEnvironment["TEST_DATA_MEDICATION"] = "semaglutide"
        app.launchEnvironment["TEST_DATA_BRAND"] = "Ozempic"
        app.launchEnvironment["TEST_DATA_DOSE"] = "5.0"
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
    }

    override func tearDown() {
        if testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
        super.tearDown()
    }

    func testWeeklyFiveMilligramScheduleCannotBeSwitchedToSplit() {
        openScheduleEditor()
        evidence("weekly-editor")
        XCTAssertTrue(app.buttons["pattern-picker"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Weekly"].exists || app.buttons["Weekly"].exists)
        XCTAssertFalse(app.buttons["Split Dose"].exists)
        XCTAssertFalse(app.staticTexts["Split Dose"].exists)
        XCTAssertFalse(app.buttons["Recorded Split Schedule"].exists)
        XCTAssertFalse(app.staticTexts["split-weekly-total"].exists)
        XCTAssertTrue(app.staticTexts["5.00 mg"].exists, "The weekly profile dose stays 5.00 mg")
        app.buttons["cancel-schedule-edit"].tap()
    }

    func testRecordedSplitScheduleStatesAdministrationAmountAndWeeklyTotal() {
        openScheduleEditor(seedSplitSchedule: true)
        evidence("split-editor")

        XCTAssertTrue(app.buttons["Recorded Split Schedule"].exists || app.staticTexts["Recorded Split Schedule"].exists)
        let perAdministration = app.staticTexts["split-per-administration"]
        let administrations = app.staticTexts["split-administrations-per-week"]
        let weeklyTotal = app.staticTexts["split-weekly-total"]
        XCTAssertTrue(perAdministration.waitForExistence(timeout: 5))
        XCTAssertEqual(perAdministration.label, "2.50 mg")
        XCTAssertEqual(administrations.label, "2")
        XCTAssertEqual(weeklyTotal.label, "5.00 mg")

        // Reverting to weekly returns the weekly total and removes the split amounts.
        let weekly = app.buttons["Weekly"]
        XCTAssertTrue(weekly.waitForExistence(timeout: 5))
        weekly.tap()
        XCTAssertFalse(app.staticTexts["split-weekly-total"].exists)
        evidence("reverted-to-weekly")
        app.buttons["save-schedule-edit"].tap()
        let edit = app.buttons["edit-schedule-button"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap()
        XCTAssertTrue(app.buttons["cancel-schedule-edit"].waitForExistence(timeout: 5))
        evidence("weekly-after-save")
        XCTAssertFalse(app.buttons["Recorded Split Schedule"].exists, "The saved schedule is weekly, not split")
        XCTAssertFalse(app.staticTexts["split-weekly-total"].exists)
        app.buttons["cancel-schedule-edit"].tap()
    }

    private func openScheduleEditor(seedSplitSchedule: Bool = false) {
        if seedSplitSchedule { app.launchEnvironment["TEST_DATA_SPLIT_SCHEDULE"] = "true" }
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        TestUtilities.navigateToTab(app, tabName: "More")
        let programs = app.buttons["glp1-programs-row"]
        XCTAssertTrue(programs.waitForExistence(timeout: 10))
        programs.tap()
        let medications = app.buttons["Medications"]
        XCTAssertTrue(medications.waitForExistence(timeout: 10))
        medications.tap()
        let profile = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH 'medication-profile-semaglutide-ozempic-'"
        )).firstMatch
        XCTAssertTrue(profile.waitForExistence(timeout: 10))
        profile.tap()
        let edit = app.buttons["edit-schedule-button"]
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        edit.tap()
        XCTAssertTrue(app.buttons["cancel-schedule-edit"].waitForExistence(timeout: 5))
    }

    private func evidence(_ name: String) {
        TestUtilities.debugScreenshot(app, name: "split-totals-\(name)")
        print(app.debugDescription)
    }
}
