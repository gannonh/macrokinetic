import XCTest

/// Disable, enable and permanent delete of a medication profile through More > GLP-1 Programs > Medications.
/// Seeded profiles are Semaglutide (Ozempic) 1.00 mg with three recorded weekly doses.
final class MedicationProfileDeleteUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        if let app, testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
    }

    private var seededRow: XCUIElement {
        TestUtilities.medicationProfileRow(app, medication: "semaglutide", brand: "Ozempic", amount: 1.0)
    }

    private func launchSeeded() {
        app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 3, dose: "1.0")
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }

    private func launchEmpty() {
        app = TestUtilities.launchAppWithTestMode(resetData: true)
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }

    private func historyRowCount() -> Int {
        TestUtilities.navigateToHistoryView(in: app)
        return TestUtilities.getDoseRows(from: app).count
    }

    private func swipeAction(_ identifier: String) -> XCUIElement {
        seededRow.swipeLeft()
        let action = app.buttons[identifier]
        XCTAssertTrue(action.waitForExistence(timeout: 5), "\(identifier) swipe action should appear")
        return action
    }

    func testDisableMedicationProfile() throws {
        launchSeeded()
        XCTAssertEqual(historyRowCount(), 3)

        TestUtilities.navigateToMedicationProfiles(app)
        XCTAssertTrue(seededRow.waitForExistence(timeout: 5))
        swipeAction("disable-medication-profile").tap()

        XCTAssertTrue(seededRow.staticTexts["Disabled"].waitForExistence(timeout: 5))
        XCTAssertTrue(seededRow.staticTexts["1.00 mg"].exists)
        let enable = swipeAction("enable-medication-profile")
        XCTAssertEqual(enable.label, "Enable")
        seededRow.swipeRight()

        XCTAssertEqual(historyRowCount(), 3, "Disabling keeps all three recorded doses")
    }

    func testPermanentDeleteRemovesAllData() throws {
        launchSeeded()
        XCTAssertEqual(historyRowCount(), 3)

        TestUtilities.navigateToMedicationProfiles(app)
        XCTAssertTrue(seededRow.waitForExistence(timeout: 5))
        swipeAction("delete-medication-profile").tap()
        let deletePermanently = app.buttons["delete-permanently-button"].firstMatch
        XCTAssertTrue(deletePermanently.waitForExistence(timeout: 5))
        deletePermanently.tap()

        XCTAssertTrue(seededRow.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No medication profiles yet"].waitForExistence(timeout: 5))
        TestUtilities.navigateToHistory(app)
        XCTAssertTrue(app.staticTexts["No doses logged yet"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "dose-history-row").count, 0)
    }

    func testCancelDeleteConfirmation() throws {
        launchSeeded()
        TestUtilities.navigateToMedicationProfiles(app)
        XCTAssertTrue(seededRow.waitForExistence(timeout: 5))
        swipeAction("delete-medication-profile").tap()

        let disableInstead = app.buttons["disable-instead-button"].firstMatch
        XCTAssertTrue(disableInstead.waitForExistence(timeout: 5))
        XCTAssertEqual(disableInstead.label, "Disable Instead (Recommended)")
        XCTAssertEqual(app.buttons["delete-permanently-button"].firstMatch.label, "Delete Permanently")
        // The dialog renders as a popover over the top of the list with no Cancel button; tapping below cancels it.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).tap()
        XCTAssertTrue(disableInstead.waitForNonExistence(timeout: 5))

        XCTAssertTrue(seededRow.exists)
        XCTAssertFalse(seededRow.staticTexts["Disabled"].exists)
        XCTAssertEqual(swipeAction("disable-medication-profile").label, "Disable")
        seededRow.swipeRight()
        XCTAssertEqual(historyRowCount(), 3)
    }

    func testDisabledProfileCannotBeUsedForDoseLogging() throws {
        launchSeeded()
        TestUtilities.navigateToMedicationProfiles(app)
        XCTAssertTrue(seededRow.waitForExistence(timeout: 5))
        swipeAction("disable-medication-profile").tap()
        XCTAssertTrue(seededRow.staticTexts["Disabled"].waitForExistence(timeout: 5))

        TestUtilities.openShortcutsSheet(app)
        app.buttons["shortcut-button-shots"].tap()
        let error = app.staticTexts["No medication profiles found. Please create a medication profile first."]
        XCTAssertTrue(error.waitForExistence(timeout: 5), "Disabled profiles are not offered for dose logging")
    }

    func testReEnabledProfileHasNoScheduleUntilOneIsRecorded() throws {
        launchSeeded()
        TestUtilities.navigateToMedicationProfiles(app)
        XCTAssertTrue(seededRow.waitForExistence(timeout: 5))
        XCTAssertTrue(seededRow.staticTexts["Recorded schedule"].exists)
        swipeAction("disable-medication-profile").tap()
        XCTAssertTrue(seededRow.staticTexts["Disabled"].waitForExistence(timeout: 5))
        swipeAction("enable-medication-profile").tap()
        XCTAssertTrue(seededRow.staticTexts["Disabled"].waitForNonExistence(timeout: 5))

        // Disabling ends the schedule; the launch build never invents one, so the user records it again.
        XCTAssertTrue(seededRow.staticTexts["Schedule not set"].exists)
        TestUtilities.openMedicationProfile(app, row: seededRow)
        XCTAssertTrue(app.buttons["create-schedule-button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["edit-schedule-button"].exists)
    }

    func testNewProfileHasNoScheduleUntilOneIsRecorded() throws {
        launchEmpty()
        let row = TestUtilities.createMedicationProfile(app, amount: "0.25")
        XCTAssertTrue(row.staticTexts["Schedule not set"].exists)
        TestUtilities.openMedicationProfile(app, row: row)
        XCTAssertTrue(app.buttons["create-schedule-button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["edit-schedule-button"].exists)
    }

    func testAnalyticsEmptyStateForNewProfile() throws {
        launchEmpty()
        TestUtilities.createMedicationProfile(app, amount: "0.25")

        TestUtilities.navigateToAdherence(app)
        // With no recorded doses the adherence card reads 0%, and the Concentration estimate stays hidden.
        TestUtilities.requireLabeled(app, "Adherence rate: 0%, Needs Improvement adherence", value: "0%", timeout: 10)
        TestUtilities.requireLabeled(app, "Current streak: 0 days")
        XCTAssertFalse(app.segmentedControls["analytics-section-picker"].buttons["Concentration"].exists)
        TestUtilities.navigateToHistory(app)
        XCTAssertTrue(app.staticTexts["No doses logged yet"].waitForExistence(timeout: 5))
    }
}
