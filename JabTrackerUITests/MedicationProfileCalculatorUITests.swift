import XCTest

/// E2E tests for medication profile calculator functionality
final class MedicationProfileCalculatorUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        self.app = XCUIApplication()
        self.app.launchArguments = ["--ui-testing", "--reset-app-data"]
        self.app.launch()

        XCTAssertTrue(self.app.tabBars.firstMatch.waitForExistence(timeout: 5.0))
    }

    private func createTestProfile() {
        TestUtilities.navigateToSettings(self.app)
        let medicationProfilesButton = self.app.buttons["Medication Profiles"]
        medicationProfilesButton.tap()

        let addProfileButton = self.app.buttons["Add Medication Profile"]
        addProfileButton.tap()

        // Create compounded medication profile for calculator testing
        let medicationPicker = self.app.buttons["medication-picker"]
        medicationPicker.tap()
        let semaglutideOption = self.app.buttons["medication-semaglutide"]
        semaglutideOption.tap()

        let compoundedToggle = self.app.switches["add-compounded-medication-toggle"]
        compoundedToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        let saveButton = self.app.buttons["save-medication-profile"]
        saveButton.tap()
    }

    func testCalculatorAccess() throws {
        self.createTestProfile()

        // Select the created compounded medication profile
        let profileCell = self.app.buttons["medication-profile-semaglutide-generic-0.25mg"]
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))
        profileCell.tap()

        let calculatorButton = self.app.buttons["detail-reconstitution-calculator"]
        XCTAssertTrue(calculatorButton.waitForExistence(timeout: 3.0))
        calculatorButton.tap()

        XCTAssertTrue(self.app.staticTexts["Reconstitution Calculator"].waitForExistence(timeout: 3.0))
    }

    func testCalculatorBasicCalculation() throws {
        self.createTestProfile()

        // Select the created compounded medication profile
        let profileCell = self.app.buttons["medication-profile-semaglutide-generic-0.25mg"]
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))
        profileCell.tap()

        let calculatorButton = self.app.buttons["detail-reconstitution-calculator"]
        calculatorButton.tap()

        // Enter calculation values
        let vialStrengthField = self.app.textFields["vial-strength-input"]
        XCTAssertTrue(vialStrengthField.waitForExistence(timeout: 3.0))
        vialStrengthField.doubleTap()
        vialStrengthField.typeText("10")

        let targetDoseField = self.app.textFields["target-dose-input"]
        targetDoseField.doubleTap()
        targetDoseField.typeText("1")

        let waterVolumeField = self.app.textFields["water-volume-input"]
        waterVolumeField.doubleTap()
        waterVolumeField.typeText("1")

        let calculateButton = self.app.buttons["calculate-reconstitution-sheet"]
        calculateButton.tap()

        // Swipe up to see results (they might be below the fold)
        self.app.swipeUp()
        // Verify results are displayed
        XCTAssertTrue(self.app.staticTexts["RECONSTITUTION INSTRUCTIONS"].exists)
        XCTAssertTrue(self.app.staticTexts["Add 1.0 ml water. Your dose is 10.0 units"].exists)

        XCTAssertTrue(self.app.staticTexts["Units per dose: 10.0"].exists)

        XCTAssertTrue(self.app.staticTexts["Concentration: 10.00 mg/ml"].exists)
        XCTAssertTrue(self.app.staticTexts["Total units: 100.0"].exists)
    }

    func testCalculatorErrorHandling() throws {
        self.createTestProfile()

        // Select the created compounded medication profile
        let profileCell = self.app.buttons["medication-profile-semaglutide-generic-0.25mg"]
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))
        profileCell.tap()

        let calculatorButton = self.app.buttons["detail-reconstitution-calculator"]
        calculatorButton.tap()

        // Enter invalid values

        // vial strength = 0
        let vialStrengthField = self.app.textFields["vial-strength-input"]
        vialStrengthField.doubleTap()
        vialStrengthField.typeText("0")
        let calculateButton = self.app.buttons["calculate-reconstitution-sheet"]
        calculateButton.tap()
        // Verify error message
        XCTAssertTrue(
            self.app.staticTexts["Vial strength must be greater than 0"]
                .waitForExistence(timeout: 3.0))

        let oKButton = self.app.buttons["OK"]
        oKButton.tap()
        // fix it
        vialStrengthField.doubleTap()
        vialStrengthField.typeText("10")

        // target dose = 20
        let targetDoseInputTextField = self.app.textFields["target-dose-input"]
        targetDoseInputTextField.doubleTap()
        targetDoseInputTextField.typeText("20")
        calculateButton.tap()
        // Verify error message
        XCTAssertTrue(
            self.app.staticTexts["Target dose cannot exceed vial strength"]
                .waitForExistence(timeout: 3.0))
        oKButton.tap()
        // fix it
        targetDoseInputTextField.doubleTap()
        targetDoseInputTextField.typeText("1")

        // water volume = 0
        let waterVolumeInputTextField = self.app.textFields["water-volume-input"]
        waterVolumeInputTextField.doubleTap()
        waterVolumeInputTextField.typeText("0")
        calculateButton.tap()
        // Verify error message
        XCTAssertTrue(
            self.app.staticTexts["Water volume must be greater than 0"]
                .waitForExistence(timeout: 3.0))
        oKButton.tap()
    }
}
