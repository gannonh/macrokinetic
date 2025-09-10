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
        self.app.tabBars.buttons["Settings"].tap()
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

        //
        let app = XCUIApplication()
        let onboardingContinueBuButton = app/*@START_MENU_TOKEN@*/ .buttons["onboarding-continue-button"]/*[[".otherElements",".buttons[\"Continue\"]",".buttons[\"onboarding-continue-button\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        onboardingContinueBuButton.tap()
        app/*@START_MENU_TOKEN@*/ .buttons["medication-semaglutide"]/*[[".buttons",".containing(.staticText, identifier: \"7.0 days\").firstMatch",".containing(.staticText, identifier: \"Ozempic, Wegovy, Rybelsus (oral), Generic\").firstMatch",".containing(.staticText, identifier: \"Semaglutide\").firstMatch",".otherElements",".buttons[\"Semaglutide - Ozempic, Wegovy, Rybelsus (oral), Generic\"]",".buttons[\"medication-semaglutide\"]"],[[[-1,6],[-1,5],[-1,4,2],[-1,0,1]],[[-1,3],[-1,2],[-1,1]],[[-1,6],[-1,5]]],[0]]@END_MENU_TOKEN@*/ .tap()
        onboardingContinueBuButton.tap()
        onboardingContinueBuButton.tap()
        onboardingContinueBuButton.tap()
        onboardingContinueBuButton.tap()
        app/*@START_MENU_TOKEN@*/ .buttons["onboarding-complete-button"]/*[[".otherElements",".buttons[\"Get Started\"]",".buttons[\"onboarding-complete-button\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ .tap()
        app/*@START_MENU_TOKEN@*/ .buttons["Settings"]/*[[".tabBars.buttons[\"Settings\"]",".buttons[\"Settings\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ .tap()
        app/*@START_MENU_TOKEN@*/ .staticTexts["Manage your medications and calculations"]/*[[".buttons[\"Medication Profiles, Manage your medications and calculations\"].staticTexts.firstMatch",".buttons.staticTexts[\"Manage your medications and calculations\"]",".staticTexts[\"Manage your medications and calculations\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ .tap()
        app/*@START_MENU_TOKEN@*/ .buttons["medication-profile-semaglutide-generic-0.25mg"]/*[[".buttons",".containing(.staticText, identifier: \"Compounded\").firstMatch",".containing(.staticText, identifier: \"Semaglutide (Generic)\").firstMatch",".otherElements",".buttons[\"Semaglutide (Generic), Compounded, 0.25 mg, •, Weekly\"]",".buttons[\"medication-profile-semaglutide-generic-0.25mg\"]"],[[[-1,5],[-1,4],[-1,3,2],[-1,0,1]],[[-1,2],[-1,1]],[[-1,5],[-1,4]]],[0]]@END_MENU_TOKEN@*/ .tap()
        app/*@START_MENU_TOKEN@*/ .staticTexts["Calculate water volume and units per dose"]/*[[".buttons[\"Reconstitution Calculator, Calculate water volume and units per dose\"].staticTexts.firstMatch",".buttons.staticTexts[\"Calculate water volume and units per dose\"]",".staticTexts[\"Calculate water volume and units per dose\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ .tap()

        let vialStrengthInputTextField = app/*@START_MENU_TOKEN@*/ .textFields["vial-strength-input"]/*[[".otherElements",".textFields[\"Enter vial strength\"]",".textFields[\"10.0\"]",".textFields[\"vial-strength-input\"]"],[[[-1,3],[-1,2],[-1,1],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        vialStrengthInputTextField.tap()
        vialStrengthInputTextField.tap()
        vialStrengthInputTextField.tap()

        let calculateReconstitutButton = app/*@START_MENU_TOKEN@*/ .buttons["calculate-reconstitution-sheet"]/*[[".cells.buttons.firstMatch",".otherElements",".buttons[\"Calculate Reconstitution\"]",".buttons[\"calculate-reconstitution-sheet\"]"],[[[-1,3],[-1,2],[-1,1,1],[-1,0]],[[-1,3],[-1,2]]],[0]]@END_MENU_TOKEN@*/
        calculateReconstitutButton.tap()
        app/*@START_MENU_TOKEN@*/ .staticTexts["Vial strength must be greater than 0"]/*[[".otherElements.staticTexts[\"Vial strength must be greater than 0\"]",".staticTexts[\"Vial strength must be greater than 0\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ .tap()

        let oKButton = app/*@START_MENU_TOKEN@*/ .buttons["OK"]/*[[".otherElements.buttons[\"OK\"]",".buttons.firstMatch",".buttons[\"OK\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        oKButton.tap()

        let targetDoseInputTextField = app/*@START_MENU_TOKEN@*/ .textFields["target-dose-input"]/*[[".otherElements",".textFields[\"Enter target dose\"]",".textFields[\"0.25\"]",".textFields[\"target-dose-input\"]"],[[[-1,3],[-1,2],[-1,1],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        targetDoseInputTextField.tap()
        targetDoseInputTextField.tap()
        targetDoseInputTextField.tap()
        calculateReconstitutButton.tap()
        oKButton.tap()

        let vialStrengthInputTextField2 = app/*@START_MENU_TOKEN@*/ .textFields["vial-strength-input"]/*[[".otherElements",".textFields[\"Enter vial strength\"]",".textFields[\"0\"]",".textFields[\"vial-strength-input\"]"],[[[-1,3],[-1,2],[-1,1],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        vialStrengthInputTextField2.tap()
        vialStrengthInputTextField2.tap()
        vialStrengthInputTextField2.tap()
        calculateReconstitutButton.tap()
        app/*@START_MENU_TOKEN@*/ .staticTexts["Target dose cannot exceed vial strength"]/*[[".otherElements.staticTexts[\"Target dose cannot exceed vial strength\"]",".staticTexts[\"Target dose cannot exceed vial strength\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ .tap()
        oKButton.tap()

        let waterVolumeInputTextField = app/*@START_MENU_TOKEN@*/ .textFields["water-volume-input"]/*[[".otherElements",".textFields[\"Enter water volume\"]",".textFields[\"1.0\"]",".textFields[\"water-volume-input\"]"],[[[-1,3],[-1,2],[-1,1],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        waterVolumeInputTextField.tap()
        waterVolumeInputTextField.tap()
        waterVolumeInputTextField.tap()
        calculateReconstitutButton.tap()
        oKButton.tap()

        let targetDoseInputTextField2 = app/*@START_MENU_TOKEN@*/ .textFields["target-dose-input"]/*[[".otherElements",".textFields[\"Enter target dose\"]",".textFields[\"10\"]",".textFields[\"target-dose-input\"]"],[[[-1,3],[-1,2],[-1,1],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        targetDoseInputTextField2.tap()
        targetDoseInputTextField2.tap()
        targetDoseInputTextField2.tap()
        targetDoseInputTextField2.tap()
        app/*@START_MENU_TOKEN@*/ .textFields["vial-strength-input"]/*[[".otherElements",".textFields[\"Enter vial strength\"]",".textFields[\"1\"]",".textFields[\"vial-strength-input\"]"],[[[-1,3],[-1,2],[-1,1],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/ .tap()

        let targetDoseInputTextField3 = app/*@START_MENU_TOKEN@*/ .textFields["target-dose-input"]/*[[".otherElements",".textFields[\"Enter target dose\"]",".textFields[\"target-dose-input\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        targetDoseInputTextField3.tap()
        targetDoseInputTextField3.tap()
        calculateReconstitutButton.tap()
        app/*@START_MENU_TOKEN@*/ .staticTexts["Water volume must be greater than 0"]/*[[".otherElements.staticTexts[\"Water volume must be greater than 0\"]",".staticTexts[\"Water volume must be greater than 0\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/ .tap()
        oKButton.tap()

        //
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
        XCTAssertTrue(self.app.staticTexts["Vial strength must be greater than 0"]
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
        XCTAssertTrue(self.app.staticTexts["Target dose cannot exceed vial strength"]
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
        XCTAssertTrue(self.app.staticTexts["Water volume must be greater than 0"]
            .waitForExistence(timeout: 3.0))
        oKButton.tap()
    }
}
