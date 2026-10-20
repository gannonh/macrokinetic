import XCTest

/// Add, view and edit a medication profile through More > GLP-1 Programs > Medications.
final class MedicationProfileCRUDUITests: XCTestCase {
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

    func testCreateMedicationProfile() throws {
        let row = TestUtilities.createMedicationProfile(app, amount: "0.25")

        XCTAssertTrue(row.staticTexts["Semaglutide (Ozempic)"].exists)
        XCTAssertTrue(row.staticTexts["0.25 mg"].exists)
        XCTAssertTrue(row.staticTexts["Schedule not set"].exists)
        XCTAssertFalse(app.staticTexts["No medication profiles yet"].exists)
    }

    func testViewMedicationProfileDetail() throws {
        let row = TestUtilities.createMedicationProfile(app, medication: "tirzepatide", brand: "Mounjaro", amount: "2.5")
        TestUtilities.openMedicationProfile(app, row: row)

        XCTAssertTrue(app.navigationBars["Tirzepatide (Mounjaro)"].exists)
        XCTAssertTrue(app.staticTexts["Medication Details"].exists)
        assertDetail("Medication", "Tirzepatide")
        assertDetail("Brand", "Mounjaro")
        assertDetail("Current Dose", "2.50 mg")
        assertDetail("Preferred Sites", "Thigh")
        XCTAssertTrue(app.staticTexts["Dose Schedule"].exists)
        XCTAssertTrue(app.buttons["create-schedule-button"].exists)
    }

    func testEditMedicationProfileAmount() throws {
        let row = TestUtilities.createMedicationProfile(app, amount: "0.25")
        TestUtilities.openMedicationProfile(app, row: row)

        app.buttons["edit-medication-profile"].tap()
        let amount = app.textFields["edit-prescribed-dose-input"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        XCTAssertEqual(amount.value as? String, "0.25")
        let save = app.buttons["edit-save-button"]
        amount.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        amount.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4))
        XCTAssertFalse(save.isEnabled, "Save stays disabled while the amount is empty")
        amount.typeText("0.5")
        XCTAssertEqual(amount.value as? String, "0.5")
        save.tap()
        XCTAssertTrue(amount.waitForNonExistence(timeout: 5))

        assertDetail("Current Dose", "0.50 mg")
        app.navigationBars.buttons["BackButton"].tap()
        let editedRow = TestUtilities.medicationProfileRow(app, medication: "semaglutide", brand: "Ozempic", amount: 0.5)
        XCTAssertTrue(editedRow.waitForExistence(timeout: 5))
        XCTAssertTrue(editedRow.staticTexts["0.50 mg"].exists)
        XCTAssertFalse(row.exists, "The 0.25 mg row is replaced, not duplicated")
    }

    /// A DetailRow renders its title and value as sibling texts.
    private func assertDetail(_ title: String, _ value: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5), "Missing \(title)", file: file, line: line)
        XCTAssertTrue(app.staticTexts[value].exists, "\(title) should read \(value)", file: file, line: line)
    }
}
