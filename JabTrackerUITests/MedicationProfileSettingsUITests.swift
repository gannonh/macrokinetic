import XCTest

/// E2E acceptance tests for medication profile management UI
/// Tests define what "done" looks like for user-facing medication profile features
final class MedicationProfileSettingsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        self.app = XCUIApplication()
        self.app.launchArguments = ["--ui-testing", "--reset-app-data"]
        self.app.launch()

        // Wait for app to be ready
        XCTAssertTrue(self.app.tabBars.firstMatch.waitForExistence(timeout: 5.0))
    }

    // MARK: - E2E Acceptance Test: Medication Profile CRUD

    /// Acceptance Test: User can create, view, edit, and delete medication profiles
    /// This defines what "done" looks like for the medication profile management feature
    func testMedicationProfileCRUDFlow() throws {
        // GIVEN: User is on Settings tab
        self.app.tabBars.buttons["Settings"].tap()

        // WHEN: User navigates to Medication Profiles section
        let medicationProfilesButton = self.app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: 3.0),
                      "Medication Profiles button should exist in Settings")
        medicationProfilesButton.tap()

        // AND: User creates a new medication profile
        let addProfileButton = self.app.buttons["Add Medication Profile"]
        XCTAssertTrue(addProfileButton.waitForExistence(timeout: 3.0))
        addProfileButton.tap()

        // AND: User selects Semaglutide medication from picker
        let medicationPicker = self.app.buttons["medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 3.0))
        medicationPicker.tap()

        let semaglutideOption = self.app.buttons["medication-semaglutide"]
        XCTAssertTrue(semaglutideOption.waitForExistence(timeout: 3.0))
        semaglutideOption.tap()

        // AND: User selects Ozempic brand from picker
        let brandPicker = self.app.buttons["add-brand-picker"]
        XCTAssertTrue(brandPicker.waitForExistence(timeout: 3.0))
        brandPicker.tap()

        let ozempicOption = self.app.buttons["add-brand-ozempic"]
        XCTAssertTrue(ozempicOption.waitForExistence(timeout: 3.0))
        ozempicOption.tap()

        // AND: User selects 0.25 mg dose from picker
        let dosePicker = self.app.buttons["add-dose-picker"]
        XCTAssertTrue(dosePicker.waitForExistence(timeout: 3.0))
        dosePicker.tap()

        let doseOption = self.app.buttons["add-dose-option-0.25"]
        XCTAssertTrue(doseOption.waitForExistence(timeout: 3.0))
        doseOption.tap()

        // AND: User sets start date (DatePicker should exist and be interactable)
        // The DatePicker appears as a Button with label "Date Picker" in the accessibility hierarchy
        let startDatePicker = self.app.buttons["Date Picker"]
        XCTAssertTrue(startDatePicker.waitForExistence(timeout: 3.0),
                      "Start date picker should be accessible")
        // Note: DatePicker value testing is complex in XCUITest, we verify existence and basic interaction
        startDatePicker.tap()
        sleep(1) // Wait for calendar modal to appear

        // Dismiss the calendar modal by tapping the dismiss region
        let addDismissRegion = self.app.buttons["PopoverDismissRegion"]
        if addDismissRegion.exists {
            addDismissRegion.tap()
        }

        // AND: User selects preferred injection sites (default Thigh should be selected)
        let thighSite = self.app.staticTexts["add-injection-site-thigh"]
        XCTAssertTrue(thighSite.waitForExistence(timeout: 3.0))
        // Check for selected state by looking for the checkmark image with same identifier
        let thighCheckmark = self.app.images["add-injection-site-thigh"].firstMatch
        XCTAssertTrue(thighCheckmark.exists, "Thigh should be selected by default")

        // User adds Abdomen as additional site
        let abdomenSite = self.app.staticTexts["add-injection-site-abdomen"]
        XCTAssertTrue(abdomenSite.waitForExistence(timeout: 3.0))
        abdomenSite.tap()
        // Check for selected state by looking for the checkmark image that appears
        let abdomenCheckmark = self.app.images["add-injection-site-abdomen"].firstMatch
        XCTAssertTrue(abdomenCheckmark.waitForExistence(timeout: 2.0),
                      "Abdomen should be selected after tap")

        // AND: User saves the profile
        let saveButton = self.app.buttons["save-medication-profile"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3.0))
        saveButton.tap()

        // THEN: Profile should be created and visible in list
        let profileCell = self.app.buttons["medication-profile-semaglutide-ozempic-0.25mg"]
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0),
                      "Created medication profile should appear in list")

        // AND: Profile should display correct information
        XCTAssertTrue(profileCell.staticTexts["Semaglutide (Ozempic)"].exists)
        XCTAssertTrue(profileCell.staticTexts["0.25 mg"].exists)
        XCTAssertTrue(profileCell.staticTexts["Weekly"].exists)

        // WHEN: User taps to view profile details
        profileCell.tap()

        // THEN: Detail view should show all profile information
        XCTAssertTrue(self.app.staticTexts["Medication Details"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(self.app.staticTexts["Semaglutide"].exists)
        XCTAssertTrue(self.app.staticTexts["Ozempic"].exists)
        XCTAssertTrue(self.app.staticTexts["0.25 mg"].exists)
        XCTAssertTrue(self.app.staticTexts["7.0 days"].exists) // Half-life
        XCTAssertTrue(self.app.staticTexts["Weekly"].exists)

        // AND: Start Date and Preferred Sites should be displayed
        XCTAssertTrue(self.app.staticTexts["Start Date"].exists, "Start Date label should be visible")
        XCTAssertTrue(self.app.staticTexts["Preferred Sites"].exists, "Preferred Sites label should be visible")
        XCTAssertTrue(self.app.staticTexts["Thigh, Abdomen"].exists, "Selected injection sites should be displayed")

        // WHEN: User edits the profile
        let editButton = self.app.buttons["edit-medication-profile"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3.0))
        editButton.tap()

        // AND: User changes dose to 0.5mg
        let editDosePicker = self.app.buttons["edit-dose-picker"]
        XCTAssertTrue(editDosePicker.waitForExistence(timeout: 3.0))
        editDosePicker.tap()

        // AND: User selects 0.5 mg from the picker options
        let editDoseOption = self.app.buttons["edit-dose-option-0.50"]
        XCTAssertTrue(editDoseOption.waitForExistence(timeout: 3.0))
        editDoseOption.tap()

        // AND: User verifies start date picker is present and can be interacted with
        // The DatePicker appears as a Button with label "Date Picker" in the accessibility hierarchy
        let editStartDatePicker = self.app.buttons["Date Picker"]
        XCTAssertTrue(editStartDatePicker.waitForExistence(timeout: 3.0),
                      "Edit start date picker should be accessible")
        editStartDatePicker.tap()
        sleep(1) // Wait for calendar modal to appear

        // Dismiss the calendar modal by tapping the dismiss region
        let editDismissRegion = self.app.buttons["PopoverDismissRegion"]
        if editDismissRegion.exists {
            editDismissRegion.tap()
        }

        // AND: User modifies injection sites (remove Abdomen, add Upper Arm)
        let editAbdomenSite = self.app.staticTexts["edit-injection-site-abdomen"]
        XCTAssertTrue(editAbdomenSite.waitForExistence(timeout: 3.0))
        // Check for selected state by looking for the checkmark image with same identifier
        let editAbdomenCheckmark = self.app.images["edit-injection-site-abdomen"].firstMatch
        XCTAssertTrue(editAbdomenCheckmark.exists, "Abdomen should still be selected")
        editAbdomenSite.tap() // Deselect Abdomen

        let editUpperArmSite = self.app.staticTexts["edit-injection-site-upper arm"]
        XCTAssertTrue(editUpperArmSite.waitForExistence(timeout: 3.0))
        editUpperArmSite.tap() // Select Upper Arm
        // Check for selected state by looking for the checkmark image that appears
        let editUpperArmCheckmark = self.app.images["edit-injection-site-upper arm"].firstMatch
        XCTAssertTrue(editUpperArmCheckmark.waitForExistence(timeout: 2.0),
                      "Upper Arm should be selected after tap")

        // AND: User saves changes
        self.app.buttons["edit-save-button"].tap()

        // Navigate back to medication profiles list
        self.app.navigationBars.buttons.element(boundBy: 0).tap() // Back button

        // THEN: Updated profile should reflect changes
        let updatedCell = self.app.buttons["medication-profile-semaglutide-ozempic-0.50mg"]
        XCTAssertTrue(updatedCell.waitForExistence(timeout: 3.0))
        XCTAssertTrue(updatedCell.staticTexts["0.50 mg"].exists)

        // AND: Verify updated injection sites by viewing detail again
        updatedCell.tap()
        XCTAssertTrue(self.app.staticTexts["Thigh, Upper Arm"].waitForExistence(timeout: 3.0),
                      "Updated injection sites should be displayed")
        self.app.navigationBars.buttons.element(boundBy: 0).tap() // Back to list

        // WHEN: User deletes the profile
        updatedCell.swipeLeft()
        let deleteButton = self.app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3.0))
        deleteButton.tap()

        // THEN: Profile should be removed from list
        XCTAssertFalse(updatedCell.exists, "Deleted profile should not exist in list")

        // AND: Empty state should be shown
        let emptyStateLabel = self.app.staticTexts["No medication profiles yet"]
        XCTAssertTrue(emptyStateLabel.waitForExistence(timeout: 3.0))
    }

    // MARK: - E2E Acceptance Test: Injection Sites Selection

    /// Acceptance Test: User can select and modify preferred injection sites
    /// Tests the multi-selection functionality for injection site preferences
    func testInjectionSitesSelection() throws {
        // GIVEN: User is on Settings tab and creates new profile
        self.app.tabBars.buttons["Settings"].tap()
        self.app.buttons["Medication Profiles"].tap()
        self.app.buttons["Add Medication Profile"].tap()

        // AND: User selects basic medication info (Semaglutide, Ozempic, 0.25mg)
        let medicationPicker = self.app.buttons["medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 3.0))
        medicationPicker.tap()
        self.app.buttons["medication-semaglutide"].tap()

        self.app.buttons["add-brand-picker"].tap()
        self.app.buttons["add-brand-ozempic"].tap()

        self.app.buttons["add-dose-picker"].tap()
        self.app.buttons["add-dose-option-0.25"].tap()

        // WHEN: User interacts with injection site selection
        let thighSite = self.app.staticTexts["add-injection-site-thigh"]
        let abdomenSite = self.app.staticTexts["add-injection-site-abdomen"]
        let upperArmSite = self.app.staticTexts["add-injection-site-upper arm"]
        let buttocksSite = self.app.staticTexts["add-injection-site-buttocks"]

        // THEN: All injection site options should be available
        XCTAssertTrue(thighSite.waitForExistence(timeout: 3.0))
        XCTAssertTrue(abdomenSite.waitForExistence(timeout: 3.0))
        XCTAssertTrue(upperArmSite.waitForExistence(timeout: 3.0))
        XCTAssertTrue(buttocksSite.waitForExistence(timeout: 3.0))

        // AND: Thigh should be selected by default
        let thighCheckmark = self.app.images["add-injection-site-thigh"].firstMatch
        let abdomenCheckmark = self.app.images["add-injection-site-abdomen"].firstMatch
        let upperArmCheckmark = self.app.images["add-injection-site-upper arm"].firstMatch
        let buttocksCheckmark = self.app.images["add-injection-site-buttocks"].firstMatch

        XCTAssertTrue(thighCheckmark.exists, "Thigh should be selected by default")
        XCTAssertFalse(abdomenCheckmark.exists, "Abdomen should not be selected initially")
        XCTAssertFalse(upperArmCheckmark.exists, "Upper Arm should not be selected initially")
        XCTAssertFalse(buttocksCheckmark.exists, "Buttocks should not be selected initially")

        // WHEN: User selects multiple sites
        abdomenSite.tap()
        upperArmSite.tap()

        // THEN: Multiple sites should be selected
        XCTAssertTrue(thighCheckmark.exists, "Thigh should remain selected")
        XCTAssertTrue(abdomenCheckmark.waitForExistence(timeout: 2.0),
                      "Abdomen should be selected after tap")
        XCTAssertTrue(upperArmCheckmark.waitForExistence(timeout: 2.0),
                      "Upper Arm should be selected after tap")
        XCTAssertFalse(buttocksCheckmark.exists, "Buttocks should remain unselected")

        // WHEN: User deselects a site
        thighSite.tap()

        // THEN: That site should be deselected while others remain
        XCTAssertFalse(thighCheckmark.exists, "Thigh should be deselected after tap")
        XCTAssertTrue(abdomenCheckmark.exists, "Abdomen should remain selected")
        XCTAssertTrue(upperArmCheckmark.exists, "Upper Arm should remain selected")

        // WHEN: User saves profile with selected sites
        self.app.buttons["save-medication-profile"].tap()

        // AND: Views profile details
        let profileCell = self.app.buttons["medication-profile-semaglutide-ozempic-0.25mg"]
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))
        profileCell.tap()

        // THEN: Selected sites should be displayed correctly
        XCTAssertTrue(self.app.staticTexts["Preferred Sites"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(self.app.staticTexts["Abdomen, Upper Arm"].exists,
                      "Selected injection sites should be displayed in detail view")
    }

    // MARK: - E2E Acceptance Test: Start Date Functionality

    /// Acceptance Test: User can set and view start date for medication profile
    func testStartDateFunctionality() throws {
        // GIVEN: User is on Settings tab and creates new profile
        self.app.tabBars.buttons["Settings"].tap()
        self.app.buttons["Medication Profiles"].tap()
        self.app.buttons["Add Medication Profile"].tap()

        // AND: User selects basic medication info
        let medicationPicker = self.app.buttons["medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 3.0))
        medicationPicker.tap()
        self.app.buttons["medication-semaglutide"].tap()

        self.app.buttons["add-brand-picker"].tap()
        self.app.buttons["add-brand-ozempic"].tap()

        self.app.buttons["add-dose-picker"].tap()
        self.app.buttons["add-dose-option-0.25"].tap()

        // WHEN: User interacts with start date picker
        // The DatePicker appears as a Button with label "Date Picker" in the accessibility hierarchy
        let startDatePicker = self.app.buttons["Date Picker"]
        XCTAssertTrue(startDatePicker.waitForExistence(timeout: 3.0),
                      "Start date picker should be present")

        // THEN: Date picker should be interactable (tap to verify accessibility)
        startDatePicker.tap()
        sleep(1) // Wait for calendar modal to appear

        // Dismiss the calendar modal by tapping the dismiss region
        let startDismissRegion = self.app.buttons["PopoverDismissRegion"]
        if startDismissRegion.exists {
            startDismissRegion.tap()
        }

        // Verify picker is accessible after interaction
        XCTAssertTrue(self.app.buttons["Date Picker"].exists, "Start date picker should remain accessible after interaction")

        // WHEN: User saves profile
        self.app.buttons["save-medication-profile"].tap()

        // AND: Views profile details
        let profileCell = self.app.buttons["medication-profile-semaglutide-ozempic-0.25mg"]
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))
        profileCell.tap()

        // THEN: Start date should be displayed in detail view
        XCTAssertTrue(self.app.staticTexts["Start Date"].waitForExistence(timeout: 3.0),
                      "Start Date label should be visible in detail view")
        // Note: Actual date value testing requires more complex date manipulation
        // We verify the presence of the field and basic functionality
    }

    // MARK: - E2E Acceptance Test: Compounded Medication Setup

    /// Acceptance Test: User can set up compounded medication with reconstitution calculator
    func testCompoundedMedicationSetup() throws {
        // ReconstitutionCalculatorView is now implemented - test the full flow
        // GIVEN: User is on Settings tab
        self.app.tabBars.buttons["Settings"].tap()
        self.app.buttons["Medication Profiles"].tap()

        // WHEN: User creates new compounded medication profile
        self.app.buttons["Add Medication Profile"].tap()

        // AND: User selects Semaglutide medication from picker
        let medicationPicker = self.app.buttons["medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 3.0))
        medicationPicker.tap()

        let semaglutideOption = self.app.buttons["medication-semaglutide"]
        XCTAssertTrue(semaglutideOption.waitForExistence(timeout: 3.0))
        semaglutideOption.tap()

        // AND: User enables compounded medication option
        // SwiftUI Forms wrap toggles in cells, need to tap the toggle control specifically
        let compoundedToggle = self.app.switches["add-compounded-medication-toggle"]
        XCTAssertTrue(compoundedToggle.waitForExistence(timeout: 3.0), "Toggle should exist")

        // Get the current value
        let initialValue = compoundedToggle.value as? String
        print("Toggle initial value: \(initialValue ?? "nil")")

        // Pause briefly to ensure UI is stable
        sleep(1)

        // Perform coordinate-based tap
        compoundedToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        // Wait for animation
        sleep(1)

        // Verify the toggle changed state
        let newValue = compoundedToggle.value as? String
        print("Toggle new value: \(newValue ?? "nil")")
        XCTAssertNotEqual(initialValue, newValue, "Toggle should have changed state")

        // Wait for compounded UI elements to appear
        sleep(1)

        // AND: User enters vial strength
        let vialStrengthField = self.app.textFields["add-vial-strength-input"]
        XCTAssertTrue(vialStrengthField.waitForExistence(timeout: 3.0))
        vialStrengthField.tap()
        // Clear existing text if any
        vialStrengthField.doubleTap() // Select all existing text
        vialStrengthField.typeText("10")

        // AND: User enters target dose
        let targetDoseField = self.app.textFields["add-target-dose-input"]
        XCTAssertTrue(targetDoseField.waitForExistence(timeout: 3.0))
        targetDoseField.tap()
        // Clear existing text if any
        targetDoseField.doubleTap()
        targetDoseField.typeText("1")

        // AND: User requests calculation
        let calculateButton = self.app.buttons["add-calculate-reconstitution"]
        XCTAssertTrue(calculateButton.waitForExistence(timeout: 3.0))
        calculateButton.tap()

        // THEN: ReconstitutionCalculatorView should open as a sheet
        let calculatorTitle = self.app.staticTexts["Reconstitution Calculator"]
        XCTAssertTrue(calculatorTitle.waitForExistence(timeout: 3.0))

        // AND: User taps Calculate Reconstitution button in the sheet
        let calculateInSheetButton = self.app.buttons["calculate-reconstitution-sheet"]
        XCTAssertTrue(calculateInSheetButton.waitForExistence(timeout: 3.0))
        calculateInSheetButton.tap()

        // THEN: Calculator should show results
        XCTAssertTrue(self.app.staticTexts["Add 1.0 ml water. Your dose is 10.0 units"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(self.app.staticTexts["Units per dose: 10.0"].exists)
        XCTAssertTrue(self.app.staticTexts["Concentration: 10.00 mg/ml"].exists)
        XCTAssertTrue(self.app.staticTexts["Total units: 100.0"].exists)

        // Save the calculator results
        let saveButton = self.app.buttons["save-reconstitution-calculation"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3.0))
        saveButton.tap()

        // AND: User can save compounded profile
        self.app.buttons["save-medication-profile"].tap()

        // THEN: Compounded profile appears in list
        let compoundedCell = self.app.buttons["medication-profile-semaglutide-generic-1.00mg"]
        XCTAssertTrue(compoundedCell.waitForExistence(timeout: 3.0))
    }

    // MARK: - E2E Acceptance Test: Detail View Calculator Access

    /// Acceptance Test: User can access reconstitution calculator from profile detail view
    func testDetailViewCalculatorAccess() throws {
        // GIVEN: User has created a compounded medication profile
        self.app.tabBars.buttons["Settings"].tap()
        self.app.buttons["Medication Profiles"].tap()
        self.app.buttons["Add Medication Profile"].tap()

        // Create compounded semaglutide profile
        self.app.buttons["medication-picker"].tap()
        self.app.buttons["medication-semaglutide"].tap()

        let compoundedToggle = self.app.switches["add-compounded-medication-toggle"]
        XCTAssertTrue(compoundedToggle.waitForExistence(timeout: 3.0))
        compoundedToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        sleep(1)

        let vialStrengthField = self.app.textFields["add-vial-strength-input"]
        vialStrengthField.tap()
        sleep(1) // Wait for keyboard to appear
        vialStrengthField.doubleTap() // Select all existing text
        vialStrengthField.typeText("15")

        let targetDoseField = self.app.textFields["add-target-dose-input"]
        targetDoseField.tap()
        sleep(1) // Wait for focus change
        targetDoseField.doubleTap() // Select all existing text
        targetDoseField.typeText("2.5")

        self.app.buttons["save-medication-profile"].tap()

        // WHEN: User taps on the created profile to view details
        let profileCell = self.app.buttons["medication-profile-semaglutide-generic-2.50mg"]
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))
        profileCell.tap()

        // THEN: Detail view should display profile information
        XCTAssertTrue(self.app.staticTexts["Medication Details"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(self.app.staticTexts["Semaglutide"].exists)
        XCTAssertTrue(self.app.staticTexts["Generic"].exists)
        XCTAssertTrue(self.app.staticTexts["2.50 mg"].exists)

        // AND: Calculator button should be present as simple button (not NavigationLink)
        let calculatorButton = self.app.buttons["detail-reconstitution-calculator"]
        XCTAssertTrue(calculatorButton.waitForExistence(timeout: 3.0),
                      "Calculator button should be accessible from detail view")

        // WHEN: User taps calculator button
        calculatorButton.tap()

        // THEN: Calculator should open as sheet with profile values pre-filled
        let calculatorTitle = self.app.staticTexts["Reconstitution Calculator"]
        XCTAssertTrue(calculatorTitle.waitForExistence(timeout: 3.0))

        // AND: Calculator should show Reconstitution Parameters section
        XCTAssertTrue(self.app.staticTexts["Reconstitution Parameters"].exists ||
            self.app.staticTexts["RECONSTITUTION PARAMETERS"].exists,
            "Reconstitution Parameters section should be visible")

        // AND: Calculator fields should show profile values
        let calculatorVialField = self.app.textFields["vial-strength-input"]
        XCTAssertTrue(calculatorVialField.waitForExistence(timeout: 3.0))
        XCTAssertEqual(calculatorVialField.value as? String, "15.0")

        let calculatorDoseField = self.app.textFields["target-dose-input"]
        XCTAssertTrue(calculatorDoseField.waitForExistence(timeout: 3.0))
        XCTAssertEqual(calculatorDoseField.value as? String, "2.5")

        // WHEN: User calculates reconstitution
        self.app.buttons["calculate-reconstitution-sheet"].tap()

        // THEN: Results should be displayed (15mg vial, 2.5mg dose = 16.7 units)
        XCTAssertTrue(self.app.staticTexts["Add 1.0 ml water. Your dose is 16.7 units"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(self.app.staticTexts["Units per dose: 16.7"].exists)
        XCTAssertTrue(self.app.staticTexts["Concentration: 15.00 mg/ml"].exists)

        // AND: User can save updates to profile
        let saveButton = self.app.buttons["save-reconstitution-calculation"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3.0))
        saveButton.tap()

        // THEN: Should return to detail view and show updated information
        XCTAssertTrue(self.app.staticTexts["Medication Details"].waitForExistence(timeout: 3.0))
    }

    // MARK: - E2E Acceptance Test: Comprehensive Calculation Scenarios

    /// Acceptance Test: Calculator handles various medication strengths and doses
    func testCalculatorScenarios() throws {
        // GIVEN: User navigates to add medication profile
        self.app.tabBars.buttons["Settings"].tap()
        self.app.buttons["Medication Profiles"].tap()
        self.app.buttons["Add Medication Profile"].tap()

        // Set up compounded medication
        self.app.buttons["medication-picker"].tap()
        self.app.buttons["medication-semaglutide"].tap()

        let compoundedToggle = self.app.switches["add-compounded-medication-toggle"]
        XCTAssertTrue(compoundedToggle.waitForExistence(timeout: 3.0))
        compoundedToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        sleep(1)

        // SCENARIO 1: Standard 10mg vial with 1mg dose
        self.app.textFields["add-vial-strength-input"].tap()
        sleep(1) // Wait for focus change
        self.app.textFields["add-vial-strength-input"].doubleTap() // Select all existing text
        self.app.textFields["add-vial-strength-input"].typeText("10")

        self.app.textFields["add-target-dose-input"].tap()
        sleep(1) // Wait for focus change
        self.app.textFields["add-target-dose-input"].doubleTap() // Select all existing text
        self.app.textFields["add-target-dose-input"].typeText("1")

        self.app.buttons["add-calculate-reconstitution"].tap()

        // Verify calculator opened
        XCTAssertTrue(self.app.staticTexts["Reconstitution Calculator"].waitForExistence(timeout: 3.0))

        self.app.buttons["calculate-reconstitution-sheet"].tap()

        // THEN: Should show correct calculation for 10mg/1ml = 10mg/ml, 1mg dose = 10 units
        XCTAssertTrue(self.app.staticTexts["Add 1.0 ml water. Your dose is 10.0 units"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(self.app.staticTexts["Units per dose: 10.0"].exists)
        XCTAssertTrue(self.app.staticTexts["Concentration: 10.00 mg/ml"].exists)
        XCTAssertTrue(self.app.staticTexts["Total units: 100.0"].exists)

        // Close calculator without saving to test more scenarios
        self.app.buttons["Close"].tap()

        // SCENARIO 2: High-strength 25mg vial with 2.5mg dose
        let scenario2VialField = self.app.textFields["add-vial-strength-input"]
        scenario2VialField.tap()
        sleep(1)
        scenario2VialField.doubleTap()
        scenario2VialField.typeText("25")

        let scenario2DoseField = self.app.textFields["add-target-dose-input"]
        scenario2DoseField.tap()
        sleep(1)
        scenario2DoseField.doubleTap()
        scenario2DoseField.typeText("2.5")

        self.app.buttons["add-calculate-reconstitution"].tap()
        self.app.buttons["calculate-reconstitution-sheet"].tap()

        // THEN: Should show correct calculation for 25mg/1ml = 25mg/ml, 2.5mg dose = 10 units
        XCTAssertTrue(self.app.staticTexts["Add 1.0 ml water. Your dose is 10.0 units"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(self.app.staticTexts["Units per dose: 10.0"].exists)
        XCTAssertTrue(self.app.staticTexts["Concentration: 25.00 mg/ml"].exists)
        XCTAssertTrue(self.app.staticTexts["Total units: 100.0"].exists)

        // Save this scenario
        self.app.buttons["save-reconstitution-calculation"].tap()
        self.app.buttons["save-medication-profile"].tap()

        // Verify profile was created with correct dose
        let profileCell = self.app.buttons["medication-profile-semaglutide-generic-2.50mg"]
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))
    }

    // MARK: - E2E Acceptance Test: Calculator Error Handling

    /// Acceptance Test: Calculator properly handles invalid inputs and edge cases
    func testCalculatorErrorHandling() throws {
        // GIVEN: User navigates to calculator
        self.app.tabBars.buttons["Settings"].tap()
        self.app.buttons["Medication Profiles"].tap()
        self.app.buttons["Add Medication Profile"].tap()

        self.app.buttons["medication-picker"].tap()
        self.app.buttons["medication-semaglutide"].tap()

        let compoundedToggle = self.app.switches["add-compounded-medication-toggle"]
        XCTAssertTrue(compoundedToggle.waitForExistence(timeout: 3.0))
        compoundedToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        sleep(1)

        self.app.buttons["add-calculate-reconstitution"].tap()

        // SCENARIO 1: Calculator should work with default values (not empty)
        self.app.buttons["calculate-reconstitution-sheet"].tap()

        // THEN: Should show results with default values (10mg vial, 0.25mg dose)
        XCTAssertTrue(self.app.staticTexts["Add 1.0 ml water. Your dose is 2.5 units"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(self.app.staticTexts["Units per dose: 2.5"].exists)
        XCTAssertTrue(self.app.staticTexts["Concentration: 10.00 mg/ml"].exists)

        // SCENARIO 2: Invalid dose higher than vial strength
        self.app.textFields["vial-strength-input"].tap()
        sleep(1)
        self.app.textFields["vial-strength-input"].doubleTap()
        self.app.textFields["vial-strength-input"].typeText("5")

        self.app.textFields["target-dose-input"].tap()
        sleep(1)
        self.app.textFields["target-dose-input"].doubleTap()
        self.app.textFields["target-dose-input"].typeText("10") // Higher than vial strength

        self.app.buttons["calculate-reconstitution-sheet"].tap()

        // THEN: Should show validation error
        XCTAssertTrue(self.app.alerts["Calculation Error"].waitForExistence(timeout: 3.0))
        self.app.buttons["OK"].tap()

        // SCENARIO 3: Zero values should be handled
        let zeroVialField = self.app.textFields["vial-strength-input"]
        zeroVialField.tap()
        sleep(1)
        zeroVialField.doubleTap()
        zeroVialField.typeText("0")

        self.app.buttons["calculate-reconstitution-sheet"].tap()

        // THEN: Should show validation error
        XCTAssertTrue(self.app.alerts["Calculation Error"].waitForExistence(timeout: 3.0))
        self.app.buttons["OK"].tap()

        // SCENARIO 4: Valid calculation after fixing errors
        let fixedVialField = self.app.textFields["vial-strength-input"]
        fixedVialField.tap()
        sleep(1)
        fixedVialField.doubleTap()
        fixedVialField.typeText("10")

        let doseField = self.app.textFields["target-dose-input"]
        doseField.tap()
        sleep(1)
        doseField.doubleTap()
        doseField.typeText("1")

        self.app.buttons["calculate-reconstitution-sheet"].tap()

        // THEN: Should show successful calculation
        XCTAssertTrue(self.app.staticTexts["Add 1.0 ml water. Your dose is 10.0 units"].waitForExistence(timeout: 3.0))
        XCTAssertFalse(self.app.alerts.element.exists, "No error alerts should be present")

        // Close calculator
        self.app.buttons["Close"].tap()
    }

    // MARK: - E2E Acceptance Test: Dose Escalation Tracking

    /// Acceptance Test: User can schedule and track dose escalations for medication profiles
    /// This defines what "done" looks like for dose escalation functionality from user perspective
    func testDoseEscalationTracking() throws {
        // GIVEN: User has an existing medication profile at starting dose
        self.app.tabBars.buttons["Settings"].tap()
        self.app.buttons["Medication Profiles"].tap()
        self.app.buttons["Add Medication Profile"].tap()

        // Create Semaglutide profile starting at 0.25mg
        self.app.buttons["medication-picker"].tap()
        self.app.buttons["medication-semaglutide"].tap()

        self.app.buttons["add-brand-picker"].tap()
        self.app.buttons["add-brand-ozempic"].tap()

        self.app.buttons["add-dose-picker"].tap()
        self.app.buttons["add-dose-option-0.25"].tap()

        self.app.buttons["save-medication-profile"].tap()

        // Navigate to profile details
        let profileCell = self.app.buttons["medication-profile-semaglutide-ozempic-0.25mg"]
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))
        profileCell.tap()

        // WHEN: User accesses dose escalation planning
        let escalationButton = self.app.buttons["dose-escalation-button"]
        XCTAssertTrue(escalationButton.waitForExistence(timeout: 3.0),
                      "Dose escalation button should be accessible from profile detail")
        escalationButton.tap()

        // THEN: Escalation management view should open
        let escalationTitle = self.app.staticTexts["Dose Escalation Plan"]
        XCTAssertTrue(escalationTitle.waitForExistence(timeout: 3.0),
                      "Dose escalation view should open")

        // AND: Current dose should be displayed
        XCTAssertTrue(self.app.staticTexts["Current Dose"].exists)
        XCTAssertTrue(self.app.staticTexts["0.25 mg"].exists)

        // WHEN: User creates new escalation plan
        let createEscalationButton = self.app.buttons["create-escalation-plan"]
        XCTAssertTrue(createEscalationButton.waitForExistence(timeout: 3.0))
        createEscalationButton.tap()

        // AND: User selects target dose (0.5mg - next level up)
        let targetDosePicker = self.app.buttons["escalation-target-dose-picker"]
        XCTAssertTrue(targetDosePicker.waitForExistence(timeout: 3.0))
        targetDosePicker.tap()

        let targetDoseOption = self.app.buttons["escalation-dose-option-0.50"]
        XCTAssertTrue(targetDoseOption.waitForExistence(timeout: 3.0))
        targetDoseOption.tap()

        // AND: User sets escalation date (4 weeks from now)
        let escalationDatePicker = self.app.buttons["Date Picker"]
        XCTAssertTrue(escalationDatePicker.waitForExistence(timeout: 3.0))
        escalationDatePicker.tap()
        sleep(1) // Wait for calendar modal

        // Set date to 4 weeks in future - for now just dismiss modal
        // TODO: Implement specific date selection logic
        let dismissRegion = self.app.buttons["PopoverDismissRegion"]
        if dismissRegion.exists {
            dismissRegion.tap()
        }

        // AND: User saves escalation plan
        let saveEscalationButton = self.app.buttons["save-escalation-plan"]
        XCTAssertTrue(saveEscalationButton.waitForExistence(timeout: 3.0))
        saveEscalationButton.tap()

        // THEN: Escalation should appear in timeline
        let escalationTimeline = self.app.staticTexts["Escalation Timeline"]
        XCTAssertTrue(escalationTimeline.waitForExistence(timeout: 3.0))

        let scheduledEscalation = self.app.staticTexts["Scheduled: 0.25 mg → 0.50 mg"]
        XCTAssertTrue(scheduledEscalation.waitForExistence(timeout: 3.0),
                      "Scheduled escalation should appear in timeline")

        // AND: Escalation date should be displayed
        XCTAssertTrue(self.app.staticTexts["Escalation Date"].exists,
                      "Escalation date should be visible")

        // WHEN: User marks escalation as completed
        let markCompleteButton = self.app.buttons["mark-escalation-complete"]
        XCTAssertTrue(markCompleteButton.waitForExistence(timeout: 3.0))
        markCompleteButton.tap()

        // THEN: Profile should be updated with new dose
        XCTAssertTrue(self.app.staticTexts["Completed: 0.25 mg → 0.50 mg"].waitForExistence(timeout: 3.0),
                      "Completed escalation should be marked in timeline")

        // AND: Current dose should be updated
        XCTAssertTrue(self.app.staticTexts["Current Dose"].exists)
        XCTAssertTrue(self.app.staticTexts["0.50 mg"].exists, "Current dose should be updated to new level")

        // WHEN: User creates another escalation (0.5mg -> 1.0mg)
        let createSecondEscalationButton = self.app.buttons["create-escalation-plan"]
        XCTAssertTrue(createSecondEscalationButton.waitForExistence(timeout: 3.0))
        createSecondEscalationButton.tap()

        // Select 1.0mg as next target
        let secondTargetPicker = self.app.buttons["escalation-target-dose-picker"]
        secondTargetPicker.tap()

        let onePartZeroDoseOption = self.app.buttons["escalation-dose-option-1.00"]
        XCTAssertTrue(onePartZeroDoseOption.waitForExistence(timeout: 3.0))
        onePartZeroDoseOption.tap()

        // Set escalation date
        let secondDatePicker = self.app.buttons["Date Picker"]
        secondDatePicker.tap()
        sleep(1)

        let secondDismissRegion = self.app.buttons["PopoverDismissRegion"]
        if secondDismissRegion.exists {
            secondDismissRegion.tap()
        }

        // Save second escalation
        let saveSecondEscalationButton = self.app.buttons["save-escalation-plan"]
        saveSecondEscalationButton.tap()

        // THEN: Multiple escalations should be visible in timeline
        let firstCompleted = self.app.staticTexts["Completed: 0.25 mg → 0.50 mg"]
        let secondScheduled = self.app.staticTexts["Scheduled: 0.50 mg → 1.00 mg"]

        XCTAssertTrue(firstCompleted.exists, "First completed escalation should remain visible")
        XCTAssertTrue(secondScheduled.waitForExistence(timeout: 3.0), "Second scheduled escalation should be visible")

        // WHEN: User deletes future escalation
        let deleteEscalationButton = self.app.buttons["delete-escalation-1.00mg"]
        XCTAssertTrue(deleteEscalationButton.waitForExistence(timeout: 3.0))
        deleteEscalationButton.tap()

        // Confirm deletion
        let confirmDeleteButton = self.app.buttons["Confirm Delete"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 3.0))
        confirmDeleteButton.tap()

        // THEN: Scheduled escalation should be removed
        XCTAssertFalse(secondScheduled.exists, "Deleted escalation should not appear in timeline")
        XCTAssertTrue(firstCompleted.exists, "Completed escalation should remain")

        // WHEN: User returns to profile list
        self.app.navigationBars.buttons.element(boundBy: 0).tap() // Back to detail
        self.app.navigationBars.buttons.element(boundBy: 0).tap() // Back to list

        // THEN: Profile should show updated dose from escalation
        let updatedProfileCell = self.app.buttons["medication-profile-semaglutide-ozempic-0.50mg"]
        XCTAssertTrue(updatedProfileCell.waitForExistence(timeout: 3.0),
                      "Profile should show updated dose after escalation completion")

        // Clean up - delete the test profile
        updatedProfileCell.swipeLeft()
        let deleteButton = self.app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3.0))
        deleteButton.tap()
    }
}
