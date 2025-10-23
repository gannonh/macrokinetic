import XCTest

/// E2E tests for basic medication profile CRUD operations
final class MedicationProfileCRUDUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        self.app = XCUIApplication()
        self.app.launchArguments = ["--ui-testing", "--reset-app-data"]
        self.app.launch()

        XCTAssertTrue(self.app.tabBars.firstMatch.waitForExistence(timeout: 5.0))
    }

    private func navigateToMedicationProfiles() {
        self.app.tabBars.buttons["Settings"].tap()
        let medicationProfilesButton = self.app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: 3.0))
        medicationProfilesButton.tap()
    }

    func testCreateMedicationProfile() throws {
        self.navigateToMedicationProfiles()

        let addProfileButton = self.app.buttons["Add Medication Profile"]
        XCTAssertTrue(addProfileButton.waitForExistence(timeout: 3.0))
        addProfileButton.tap()

        // Select medication
        let medicationPicker = self.app.buttons["medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 3.0))
        medicationPicker.tap()

        let semaglutideOption = self.app.buttons["medication-semaglutide"]
        XCTAssertTrue(semaglutideOption.waitForExistence(timeout: 3.0))
        semaglutideOption.tap()

        // Select brand
        let brandPicker = self.app.buttons["add-brand-picker"]
        XCTAssertTrue(brandPicker.waitForExistence(timeout: 3.0))
        brandPicker.tap()

        let ozempicOption = self.app.buttons["add-brand-ozempic"]
        XCTAssertTrue(ozempicOption.waitForExistence(timeout: 3.0))
        ozempicOption.tap()

        // Select dose
        let dosePicker = self.app.buttons["add-dose-picker"]
        XCTAssertTrue(dosePicker.waitForExistence(timeout: 3.0))
        dosePicker.tap()

        let doseOption = self.app.buttons["add-dose-option-0.25"]
        XCTAssertTrue(doseOption.waitForExistence(timeout: 3.0))
        doseOption.tap()

        // Save profile
        let saveButton = self.app.buttons["save-medication-profile"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3.0))
        saveButton.tap()

        // Verify profile created
        let profileCell = self.app.buttons["medication-profile-semaglutide-ozempic-0.25mg"]
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))
        XCTAssertTrue(profileCell.staticTexts["Semaglutide (Ozempic)"].exists)
        XCTAssertTrue(profileCell.staticTexts["0.25 mg"].exists)
    }

    func testViewMedicationProfileDetail() throws {
        self.navigateToMedicationProfiles()

        // First create a profile (simplified)
        let addProfileButton = self.app.buttons["Add Medication Profile"]
        addProfileButton.tap()

        let medicationPicker = self.app.buttons["medication-picker"]
        medicationPicker.tap()
        let semaglutideOption = self.app.buttons["medication-semaglutide"]
        semaglutideOption.tap()

        let brandPicker = self.app.buttons["add-brand-picker"]
        brandPicker.tap()
        let ozempicOption = self.app.buttons["add-brand-ozempic"]
        ozempicOption.tap()

        let saveButton = self.app.buttons["save-medication-profile"]
        saveButton.tap()

        // Now test detail view
        let profileCell = self.app.buttons.matching(
            identifier: "medication-profile-semaglutide-ozempic-0.25mg"
        ).firstMatch
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))
        profileCell.tap()

        // Verify detail view content
        XCTAssertTrue(self.app.staticTexts["Medication Details"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(self.app.staticTexts["Semaglutide"].exists)
        XCTAssertTrue(self.app.staticTexts["Ozempic"].exists)
    }
}
