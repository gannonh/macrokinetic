import XCTest

/// Injection sites, start date, compounded profiles and the hidden titration tool on the launch medication form.
final class MedicationProfileAdvancedUITests: XCTestCase {
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

    func testInjectionSitesSelection() throws {
        openAddForm()
        let abdomen = app.descendants(matching: .any)["add-injection-site-abdomen"].firstMatch
        XCTAssertTrue(abdomen.waitForExistence(timeout: 5))
        abdomen.tap()
        enterAmountAndSave("0.25")

        let row = TestUtilities.medicationProfileRow(app, medication: "semaglutide", brand: "Ozempic", amount: 0.25)
        TestUtilities.openMedicationProfile(app, row: row)
        XCTAssertTrue(app.staticTexts["Preferred Sites"].exists)
        XCTAssertTrue(app.staticTexts["Thigh, Abdomen"].exists, "Thigh is preselected; Abdomen is added")
    }

    func testStartDateFunctionality() throws {
        openAddForm()
        XCTAssertTrue(app.datePickers["add-start-date-picker"].exists)
        enterAmountAndSave("0.25")

        let row = TestUtilities.medicationProfileRow(app, medication: "semaglutide", brand: "Ozempic", amount: 0.25)
        TestUtilities.openMedicationProfile(app, row: row)
        XCTAssertTrue(app.staticTexts["Start Date"].exists)
        XCTAssertTrue(app.staticTexts[Date().formatted(date: .abbreviated, time: .omitted)].exists)
    }

    func testCompoundedMedicationSetup() throws {
        openAddForm()
        let compounded = app.switches["add-compounded-medication-toggle"].switches.firstMatch
        XCTAssertTrue(compounded.exists)
        XCTAssertEqual(compounded.value as? String, "0")
        compounded.tap()
        XCTAssertEqual(compounded.value as? String, "1")

        XCTAssertFalse(app.buttons["add-brand-picker"].exists, "A compounded profile has a fixed Generic brand")
        XCTAssertTrue(app.staticTexts["Generic"].exists)
        XCTAssertFalse(app.textFields["add-vial-strength-input"].exists)
        XCTAssertFalse(app.textFields["add-target-dose-input"].exists)
        XCTAssertFalse(app.buttons["add-calculate-reconstitution"].exists)
        enterAmountAndSave("1.5")

        let row = TestUtilities.medicationProfileRow(app, medication: "semaglutide", brand: "Generic", amount: 1.5)
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.staticTexts["Semaglutide (Generic)"].exists)
        XCTAssertTrue(row.staticTexts["Compounded"].exists)
        XCTAssertTrue(row.staticTexts["1.50 mg"].exists)
    }

    func testDoseTitrationIsAbsentUnderLaunchPolicy() throws {
        let row = TestUtilities.createMedicationProfile(app, amount: "0.25")
        TestUtilities.openMedicationProfile(app, row: row)

        XCTAssertTrue(app.staticTexts["Current Dose"].exists)
        XCTAssertTrue(app.staticTexts["0.25 mg"].exists)
        XCTAssertFalse(app.buttons["dose-escalation-button"].exists)
        XCTAssertFalse(app.staticTexts["Dose Titration Plan"].exists)
        XCTAssertFalse(app.staticTexts["Half-life"].exists)
    }

    private func openAddForm() {
        TestUtilities.navigateToMedicationProfiles(app)
        app.buttons["add-medication-button"].tap()
        XCTAssertTrue(app.textFields["add-prescribed-dose-input"].waitForExistence(timeout: 5))
    }

    private func enterAmountAndSave(_ amount: String) {
        let field = app.textFields["add-prescribed-dose-input"]
        field.tap()
        field.typeText(amount)
        XCTAssertEqual(field.value as? String, amount)
        app.buttons["save-medication-profile"].tap()
        XCTAssertTrue(field.waitForNonExistence(timeout: 5))
    }
}
