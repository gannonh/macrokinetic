import XCTest

/// The medication list is reached through More > GLP-1 Programs > Medications.
final class MedicationProfileSettingsUITests: XCTestCase {
    var app: XCUIApplication!

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

    func testMedicationProfilesNavigation() throws {
        TestUtilities.navigateToMedicationProfiles(app)

        XCTAssertTrue(app.navigationBars["GLP-1 Programs"].exists)
        let sections = app.segmentedControls["glp1-programs-view"]
        XCTAssertEqual(sections.buttons.allElementsBoundByIndex.map(\.label), ["Analytics", "Medications"])
        XCTAssertTrue(sections.buttons["Medications"].isSelected)
        XCTAssertEqual(app.buttons["add-medication-button"].label, "Add")
    }

    func testEmptyStateDisplay() throws {
        TestUtilities.navigateToMedicationProfiles(app)

        XCTAssertTrue(app.staticTexts["No medication profiles yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.staticTexts["Add your first medication profile to record prescribed doses and schedules."].exists)
        let addFirst = app.buttons["add-medication-empty-button"]
        XCTAssertEqual(addFirst.label, "Add Medication")
        addFirst.tap()
        XCTAssertTrue(app.navigationBars["Add Medication"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["add-prescribed-dose-input"].exists)
    }
}
