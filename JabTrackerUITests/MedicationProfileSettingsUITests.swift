import XCTest

/// E2E acceptance tests for medication profile management UI
/// Tests define what "done" looks like for user-facing medication profile features
final class MedicationProfileSettingsUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
        app.launch()
        
        // Wait for app to be ready
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5.0))
    }
    
    // MARK: - E2E Acceptance Test: Medication Profile CRUD
    
    /// Acceptance Test: User can create, view, edit, and delete medication profiles
    /// This defines what "done" looks like for the medication profile management feature
    func testMedicationProfileCRUDFlow() throws {
        // GIVEN: User is on Settings tab
        app.tabBars.buttons["Settings"].tap()
        
        // WHEN: User navigates to Medication Profiles section
        let medicationProfilesButton = app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: 3.0), 
                     "Medication Profiles button should exist in Settings")
        medicationProfilesButton.tap()
        
        // AND: User creates a new medication profile
        let addProfileButton = app.buttons["Add Medication Profile"]
        XCTAssertTrue(addProfileButton.waitForExistence(timeout: 3.0))
        addProfileButton.tap()
        
        // AND: User selects Semaglutide medication from picker
        let medicationPicker = app.buttons["medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 3.0))
        medicationPicker.tap()
        
        let semaglutideOption = app.buttons["medication-semaglutide"]
        XCTAssertTrue(semaglutideOption.waitForExistence(timeout: 3.0))
        semaglutideOption.tap()
        
        // AND: User selects Ozempic brand from picker
        let brandPicker = app.buttons["brand-picker"]
        XCTAssertTrue(brandPicker.waitForExistence(timeout: 3.0))
        brandPicker.tap()
        
        let ozempicOption = app.buttons["brand-ozempic"]
        XCTAssertTrue(ozempicOption.waitForExistence(timeout: 3.0))
        ozempicOption.tap()
        
        // AND: User selects 0.25 mg dose from picker
        let dosePicker = app.buttons["dose-picker"]
        XCTAssertTrue(dosePicker.waitForExistence(timeout: 3.0))
        dosePicker.tap()
        
        let doseOption = app.buttons["dose-option-0.25"]
        XCTAssertTrue(doseOption.waitForExistence(timeout: 3.0))
        doseOption.tap()
        
        // AND: User saves the profile
        let saveButton = app.buttons["save-medication-profile"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3.0))
        saveButton.tap()
        
        // THEN: Profile should be created and visible in list
        let profileCell = app.buttons["medication-profile-semaglutide-ozempic-0.25mg"]
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0), 
                     "Created medication profile should appear in list")
        
        // AND: Profile should display correct information
        XCTAssertTrue(profileCell.staticTexts["Semaglutide (Ozempic)"].exists)
        XCTAssertTrue(profileCell.staticTexts["0.25 mg"].exists)
        XCTAssertTrue(profileCell.staticTexts["Weekly"].exists)
        
        // WHEN: User taps to view profile details
        profileCell.tap()
        
        // THEN: Detail view should show all profile information
        XCTAssertTrue(app.staticTexts["Medication Details"].waitForExistence(timeout: 3.0))
        XCTAssertTrue(app.staticTexts["Semaglutide"].exists)
        XCTAssertTrue(app.staticTexts["Ozempic"].exists)
        XCTAssertTrue(app.staticTexts["0.25 mg"].exists)
        XCTAssertTrue(app.staticTexts["7.0 days"].exists) // Half-life
        XCTAssertTrue(app.staticTexts["Weekly"].exists)
        
        // WHEN: User edits the profile
        let editButton = app.buttons["edit-medication-profile"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3.0))
        editButton.tap()
        
        // AND: User changes dose to 0.5mg
        let editDosePicker = app.buttons["edit-dose-picker"]
        XCTAssertTrue(editDosePicker.waitForExistence(timeout: 3.0))
        editDosePicker.tap()
        
        // AND: User selects 0.5 mg from the picker options
        let editDoseOption = app.buttons["edit-dose-option-0.50"]
        XCTAssertTrue(editDoseOption.waitForExistence(timeout: 3.0))
        editDoseOption.tap()
        
        // AND: User saves changes
        app.buttons["edit-save-button"].tap()
        
        // Navigate back to medication profiles list
        app.navigationBars.buttons.element(boundBy: 0).tap() // Back button
        
        // THEN: Updated profile should reflect changes
        let updatedCell = app.buttons["medication-profile-semaglutide-ozempic-0.50mg"]
        XCTAssertTrue(updatedCell.waitForExistence(timeout: 3.0))
        XCTAssertTrue(updatedCell.staticTexts["0.50 mg"].exists)
        
        // WHEN: User deletes the profile
        updatedCell.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3.0))
        deleteButton.tap()
        
        // THEN: Profile should be removed from list
        XCTAssertFalse(updatedCell.exists, "Deleted profile should not exist in list")
        
        // AND: Empty state should be shown
        let emptyStateLabel = app.staticTexts["No medication profiles yet"]
        XCTAssertTrue(emptyStateLabel.waitForExistence(timeout: 3.0))
    }
    
    // MARK: - E2E Acceptance Test: Compounded Medication Setup
    
    /// Acceptance Test: User can set up compounded medication with reconstitution calculator
    /// TODO: Compounded medication and reconstitution calculator not yet implemented
    func testCompoundedMedicationSetup() throws {
        throw XCTSkip("Compounded medication and reconstitution calculator features not yet implemented")
        // GIVEN: User is on Settings tab
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Medication Profiles"].tap()
        
        // WHEN: User creates new compounded medication profile
        app.buttons["Add Medication Profile"].tap()
        
        // AND: User selects Semaglutide medication from picker
        let medicationPicker = app.buttons["medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 3.0))
        medicationPicker.tap()
        
        let semaglutideOption = app.buttons["medication-semaglutide"]
        XCTAssertTrue(semaglutideOption.waitForExistence(timeout: 3.0))
        semaglutideOption.tap()
        
        // AND: User enables compounded medication option
        // SwiftUI Forms wrap toggles in cells, need to tap the toggle control specifically
        let compoundedToggle = app.switches["compounded-medication-toggle"]
        XCTAssertTrue(compoundedToggle.waitForExistence(timeout: 3.0), "Toggle should exist")
        
        // Get the current value
        let initialValue = compoundedToggle.value as? String
        print("Toggle initial value: \(initialValue ?? "nil")")
        
        // In SwiftUI Forms, we need to tap at the toggle's actual control position
        // The toggle control is usually on the right side of the cell
        let toggleFrame = compoundedToggle.frame
        let toggleControlPoint = CGPoint(
            x: toggleFrame.maxX - 30, // Tap near the right edge where the switch control is
            y: toggleFrame.midY
        )
        
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
        let vialStrengthField = app.textFields["vial-strength-input"]
        XCTAssertTrue(vialStrengthField.waitForExistence(timeout: 3.0))
        vialStrengthField.tap()
        vialStrengthField.typeText("10")
        
        // AND: User enters target dose
        let targetDoseField = app.textFields["target-dose-input"]
        XCTAssertTrue(targetDoseField.waitForExistence(timeout: 3.0))
        targetDoseField.tap()
        targetDoseField.typeText("1")
        
        // TODO: Reconstitution calculator not yet implemented
        // When implemented, uncomment the following:
        /*
        // AND: User requests calculation
        let calculateButton = app.buttons["calculate-reconstitution"]
        XCTAssertTrue(calculateButton.waitForExistence(timeout: 3.0))
        calculateButton.tap()
        
        // THEN: Reconstitution instructions should appear
        let instructionLabel = app.staticTexts["Add 10.0 ml water. Your dose is 10.0 units"]
        XCTAssertTrue(instructionLabel.waitForExistence(timeout: 3.0))
        */
        
        // AND: User can save compounded profile
        app.buttons["save-medication-profile"].tap()
        
        // THEN: Compounded profile appears in list
        let compoundedCell = app.buttons["medication-profile-semaglutide-generic-1.00mg"]
        XCTAssertTrue(compoundedCell.waitForExistence(timeout: 3.0))
    }
    
    // MARK: - E2E Acceptance Test: Pen Click Calculator
    
    /// Acceptance Test: User can calculate pen clicks for dose adjustments
    /// TODO: Pen click calculator feature not yet implemented
    func testPenClickCalculator() throws {
        throw XCTSkip("Pen click calculator feature not yet implemented")
        // GIVEN: User has branded medication profile
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Medication Profiles"].tap()
        app.buttons["Add Medication Profile"].tap()
        app.buttons["medication-semaglutide"].tap()
        app.buttons["brand-ozempic"].tap()
        app.buttons["dose-button-0.5"].tap()
        app.buttons["save-medication-profile"].tap()
        
        // WHEN: User accesses pen click calculator
        let profileCell = app.cells["medication-profile-semaglutide-ozempic-0.5mg"]
        profileCell.tap()
        
        let penCalculatorButton = app.buttons["pen-click-calculator"]
        XCTAssertTrue(penCalculatorButton.waitForExistence(timeout: 3.0))
        penCalculatorButton.tap()
        
        // AND: User changes target dose
        let targetDoseSlider = app.sliders["target-dose-slider"]
        XCTAssertTrue(targetDoseSlider.waitForExistence(timeout: 3.0))
        targetDoseSlider.adjust(toNormalizedSliderPosition: 0.25) // 0.25mg
        
        // THEN: Pen click instructions should update
        let clickInstruction = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'clicks for your 0.25 mg dose'")).firstMatch
        XCTAssertTrue(clickInstruction.waitForExistence(timeout: 3.0))
    }
}
