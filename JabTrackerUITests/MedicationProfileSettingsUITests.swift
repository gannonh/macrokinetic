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
        
        // AND: User selects Semaglutide medication
        let semaglutideButton = app.buttons["medication-semaglutide"]
        XCTAssertTrue(semaglutideButton.waitForExistence(timeout: 3.0))
        semaglutideButton.tap()
        
        // AND: User selects Ozempic brand
        let ozempicButton = app.buttons["brand-ozempic"]
        XCTAssertTrue(ozempicButton.waitForExistence(timeout: 3.0))
        ozempicButton.tap()
        
        // AND: User sets initial dose to 0.25mg
        let doseButton = app.buttons["dose-button-0.25"]
        XCTAssertTrue(doseButton.waitForExistence(timeout: 3.0))
        doseButton.tap()
        
        // AND: User saves the profile
        let saveButton = app.buttons["save-medication-profile"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3.0))
        saveButton.tap()
        
        // THEN: Profile should be created and visible in list
        let profileCell = app.cells["medication-profile-semaglutide-ozempic-0.25mg"]
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
        let newDoseButton = app.buttons["dose-button-0.5"]
        XCTAssertTrue(newDoseButton.waitForExistence(timeout: 3.0))
        newDoseButton.tap()
        
        // AND: User saves changes
        app.buttons["save-medication-profile"].tap()
        
        // THEN: Updated profile should reflect changes
        let updatedCell = app.cells["medication-profile-semaglutide-ozempic-0.5mg"]
        XCTAssertTrue(updatedCell.waitForExistence(timeout: 3.0))
        XCTAssertTrue(updatedCell.staticTexts["0.5 mg"].exists)
        
        // WHEN: User deletes the profile
        updatedCell.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3.0))
        deleteButton.tap()
        
        // AND: User confirms deletion
        let confirmDeleteButton = app.buttons["Confirm Delete"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 3.0))
        confirmDeleteButton.tap()
        
        // THEN: Profile should be removed from list
        XCTAssertFalse(updatedCell.exists, "Deleted profile should not exist in list")
        
        // AND: Empty state should be shown
        let emptyStateLabel = app.staticTexts["No medication profiles yet"]
        XCTAssertTrue(emptyStateLabel.waitForExistence(timeout: 3.0))
    }
    
    // MARK: - E2E Acceptance Test: Compounded Medication Setup
    
    /// Acceptance Test: User can set up compounded medication with reconstitution calculator
    func testCompoundedMedicationSetup() throws {
        // GIVEN: User is on Settings tab
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Medication Profiles"].tap()
        
        // WHEN: User creates new compounded medication profile
        app.buttons["Add Medication Profile"].tap()
        app.buttons["medication-semaglutide"].tap()
        
        // AND: User enables compounded medication option
        let compoundedToggle = app.switches["compounded-medication-toggle"]
        XCTAssertTrue(compoundedToggle.waitForExistence(timeout: 3.0))
        compoundedToggle.tap()
        
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
        
        // AND: User requests calculation
        let calculateButton = app.buttons["calculate-reconstitution"]
        XCTAssertTrue(calculateButton.waitForExistence(timeout: 3.0))
        calculateButton.tap()
        
        // THEN: Reconstitution instructions should appear
        let instructionLabel = app.staticTexts["Add 10.0 ml water. Your dose is 10.0 units"]
        XCTAssertTrue(instructionLabel.waitForExistence(timeout: 3.0))
        
        // AND: User can save compounded profile
        app.buttons["save-medication-profile"].tap()
        
        // THEN: Compounded profile appears in list
        let compoundedCell = app.cells["medication-profile-semaglutide-compounded-1.0mg"]
        XCTAssertTrue(compoundedCell.waitForExistence(timeout: 3.0))
    }
    
    // MARK: - E2E Acceptance Test: Pen Click Calculator
    
    /// Acceptance Test: User can calculate pen clicks for dose adjustments
    func testPenClickCalculator() throws {
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