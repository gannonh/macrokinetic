import XCTest

/// E2E tests for advanced medication profile features
final class MedicationProfileAdvancedUITests: XCTestCase {
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

    func testInjectionSitesSelection() throws {
        self.navigateToMedicationProfiles()

        let addProfileButton = self.app.buttons["Add Medication Profile"]
        XCTAssertTrue(addProfileButton.waitForExistence(timeout: 3.0))
        addProfileButton.tap()

        // Select medication
        let medicationPicker = self.app.buttons["medication-picker"]
        medicationPicker.tap()
        let semaglutideOption = self.app.buttons["medication-semaglutide"]
        semaglutideOption.tap()

        // Test default injection site selection
        let thighSite = self.app.staticTexts["add-injection-site-thigh"]
        XCTAssertTrue(thighSite.waitForExistence(timeout: 3.0))

        let thighCheckmark = self.app.images["add-injection-site-thigh"].firstMatch
        XCTAssertTrue(thighCheckmark.exists, "Thigh should be selected by default")

        // Add additional injection site
        let abdomenSite = self.app.staticTexts["add-injection-site-abdomen"]
        XCTAssertTrue(abdomenSite.waitForExistence(timeout: 3.0))
        abdomenSite.tap()

        let abdomenCheckmark = self.app.images["add-injection-site-abdomen"].firstMatch
        XCTAssertTrue(abdomenCheckmark.waitForExistence(timeout: 2.0),
                      "Abdomen should be selected after tap")
    }

    func testStartDateFunctionality() throws {
        self.navigateToMedicationProfiles()

        let addProfileButton = self.app.buttons["Add Medication Profile"]
        addProfileButton.tap()

        // Select medication
        let medicationPicker = self.app.buttons["medication-picker"]
        medicationPicker.tap()
        let semaglutideOption = self.app.buttons["medication-semaglutide"]
        semaglutideOption.tap()

        // Test start date picker
        let startDatePicker = self.app.buttons["Date Picker"]
        XCTAssertTrue(startDatePicker.waitForExistence(timeout: 3.0),
                      "Start date picker should be accessible")
        startDatePicker.tap()
        sleep(1)

        // Dismiss calendar modal
        let dismissRegion = self.app.buttons["PopoverDismissRegion"]
        if dismissRegion.exists {
            dismissRegion.tap()
        }
    }

    func testCompoundedMedicationSetup() throws {
        self.navigateToMedicationProfiles()

        let addProfileButton = self.app.buttons["Add Medication Profile"]
        addProfileButton.tap()

        // Select medication
        let medicationPicker = self.app.buttons["medication-picker"]
        medicationPicker.tap()
        let semaglutideOption = self.app.buttons["medication-semaglutide"]
        semaglutideOption.tap()

        // Test compounded medication toggle
        let compoundedToggle = self.app.switches["add-compounded-medication-toggle"]
        XCTAssertTrue(compoundedToggle.waitForExistence(timeout: 3.0),
                      "Compounded toggle should be present")

        // Verify initial state (should be off)
        XCTAssertEqual(compoundedToggle.value as? String, "Off",
                       "Compounded toggle should be off by default")

        // Toggle on using coordinate-based approach (required for SwiftUI Form toggles)
        compoundedToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(compoundedToggle.value as? String, "On",
                       "Compounded toggle should be on after tap")

        // Verify compounded fields appear
        let vialStrengthField = self.app.textFields["add-vial-strength-input"]
        XCTAssertTrue(vialStrengthField.waitForExistence(timeout: 2.0),
                      "Vial strength field should appear for compounded medication")

        let targetDoseField = self.app.textFields["add-target-dose-input"]
        XCTAssertTrue(targetDoseField.waitForExistence(timeout: 2.0),
                      "Target dose field should appear for compounded medication")
    }

    func testDoseEscalationTracking() throws {
        self.navigateToMedicationProfiles()

        // Create test profile
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

        let dosePicker = self.app.buttons["add-dose-picker"]
        dosePicker.tap()
        let doseOption = self.app.buttons["add-dose-option-0.25"]
        doseOption.tap()

        let saveButton = self.app.buttons["save-medication-profile"]
        saveButton.tap()

        // Navigate to profile details
        let profileCell = self.app.buttons["medication-profile-semaglutide-ozempic-0.25mg"]
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))
        profileCell.tap()

        // Test dose escalation functionality
        let escalationButton = self.app.buttons["dose-escalation-button"]
        XCTAssertTrue(escalationButton.waitForExistence(timeout: 3.0),
                      "Dose escalation button should be accessible from profile detail")
        escalationButton.tap()

        let escalationTitle = self.app.staticTexts["Dose Escalation Plan"]
        XCTAssertTrue(escalationTitle.waitForExistence(timeout: 3.0),
                      "Dose escalation view should open")

        // Verify current dose is displayed
        XCTAssertTrue(self.app.staticTexts["Current Dose"].exists)
        XCTAssertTrue(self.app.staticTexts["0.25 mg"].exists)
    }
}
