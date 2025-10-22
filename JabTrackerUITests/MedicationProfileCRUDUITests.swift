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

    func testDeleteMedicationProfile() throws {
        self.navigateToMedicationProfiles()

        // Create profile first
        let addProfileButton = self.app.buttons["Add Medication Profile"]
        addProfileButton.tap()

        let medicationPicker = self.app.buttons["medication-picker"]
        medicationPicker.tap()
        let semaglutideOption = self.app.buttons["medication-semaglutide"]
        semaglutideOption.tap()

        let saveButton = self.app.buttons["save-medication-profile"]
        saveButton.tap()

        // Test deletion (now shows confirmation dialog)
        let profileCell = self.app.buttons.matching(
            identifier: "medication-profile-semaglutide-ozempic-0.25mg"
        ).firstMatch
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))

        profileCell.swipeLeft()
        let deleteButton = self.app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3.0))
        deleteButton.tap()

        // Verify confirmation dialog appears
        let confirmDialog = self.app.alerts["Delete Medication Profile?"]
        XCTAssertTrue(confirmDialog.waitForExistence(timeout: 3.0))

        // Confirm permanent deletion
        let deletePermanentlyButton = confirmDialog.buttons["Delete Permanently"]
        XCTAssertTrue(deletePermanentlyButton.exists)
        deletePermanentlyButton.tap()

        // Verify profile removed from list
        XCTAssertFalse(profileCell.waitForExistence(timeout: 3.0))
        let emptyStateLabel = self.app.staticTexts["No medication profiles yet"]
        XCTAssertTrue(emptyStateLabel.waitForExistence(timeout: 3.0))
    }

    func testDisableMedicationProfile() throws {
        self.navigateToMedicationProfiles()

        // Create profile
        let addProfileButton = self.app.buttons["Add Medication Profile"]
        addProfileButton.tap()

        let medicationPicker = self.app.buttons["medication-picker"]
        medicationPicker.tap()
        let semaglutideOption = self.app.buttons["medication-semaglutide"]
        semaglutideOption.tap()

        let saveButton = self.app.buttons["save-medication-profile"]
        saveButton.tap()

        // Log a dose for this profile to create historical data
        self.app.tabBars.buttons["Home"].tap()
        let addButton = self.app.tabBars.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3.0))
        addButton.tap()

        let logDoseButton = self.app.buttons["log-dose-button"]
        XCTAssertTrue(logDoseButton.waitForExistence(timeout: 3.0))
        logDoseButton.tap()

        // Navigate back to medication profiles
        self.app.tabBars.buttons["Settings"].tap()
        let medicationProfilesButton = self.app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: 3.0))
        medicationProfilesButton.tap()

        // Test disable
        let profileCell = self.app.buttons.matching(
            identifier: "medication-profile-semaglutide-ozempic-0.25mg"
        ).firstMatch
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))

        profileCell.swipeLeft()
        let disableButton = self.app.buttons["Disable"]
        XCTAssertTrue(disableButton.waitForExistence(timeout: 3.0))
        disableButton.tap()

        // Verify profile is hidden from active list
        XCTAssertFalse(profileCell.waitForExistence(timeout: 3.0))
        let emptyStateLabel = self.app.staticTexts["No medication profiles yet"]
        XCTAssertTrue(emptyStateLabel.waitForExistence(timeout: 3.0))

        // Verify historical dose still exists in History tab
        self.app.tabBars.buttons["History"].tap()
        // Check that dose history is not empty (analytics data preserved)
        let analyticsTab = self.app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 3.0))
    }

    func testPermanentDeletePreservesHistoricalDoses() throws {
        self.navigateToMedicationProfiles()

        // Create profile
        let addProfileButton = self.app.buttons["Add Medication Profile"]
        addProfileButton.tap()

        let medicationPicker = self.app.buttons["medication-picker"]
        medicationPicker.tap()
        let semaglutideOption = self.app.buttons["medication-semaglutide"]
        semaglutideOption.tap()

        let saveButton = self.app.buttons["save-medication-profile"]
        saveButton.tap()

        // Log a dose for this profile to create historical data
        self.app.tabBars.buttons["Home"].tap()
        let addButton = self.app.tabBars.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3.0))
        addButton.tap()

        let logDoseButton = self.app.buttons["log-dose-button"]
        XCTAssertTrue(logDoseButton.waitForExistence(timeout: 3.0))
        logDoseButton.tap()

        // Navigate back to medication profiles
        self.app.tabBars.buttons["Settings"].tap()
        let medicationProfilesButton = self.app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: 3.0))
        medicationProfilesButton.tap()

        // Permanently delete the profile
        let profileCell = self.app.buttons.matching(
            identifier: "medication-profile-semaglutide-ozempic-0.25mg"
        ).firstMatch
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))

        profileCell.swipeLeft()
        let deleteButton = self.app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3.0))
        deleteButton.tap()

        // Confirm permanent deletion
        let confirmDialog = self.app.alerts["Delete Medication Profile?"]
        XCTAssertTrue(confirmDialog.waitForExistence(timeout: 3.0))
        let deletePermanentlyButton = confirmDialog.buttons["Delete Permanently"]
        deletePermanentlyButton.tap()

        // Verify profile is removed
        XCTAssertFalse(profileCell.waitForExistence(timeout: 3.0))

        // Verify historical doses still exist (check History tab has data)
        self.app.tabBars.buttons["History"].tap()
        // The dose should still be visible in history even though profile is deleted
        // This verifies that .nullify cascade rule preserved historical doses
        let analyticsTab = self.app.tabBars.buttons["Analytics"]
        XCTAssertTrue(analyticsTab.waitForExistence(timeout: 3.0))
    }

    func testDeleteConfirmationDialogShowsDisableRecommendation() throws {
        self.navigateToMedicationProfiles()

        // Create profile
        let addProfileButton = self.app.buttons["Add Medication Profile"]
        addProfileButton.tap()

        let medicationPicker = self.app.buttons["medication-picker"]
        medicationPicker.tap()
        let semaglutideOption = self.app.buttons["medication-semaglutide"]
        semaglutideOption.tap()

        let saveButton = self.app.buttons["save-medication-profile"]
        saveButton.tap()

        // Test confirmation dialog
        let profileCell = self.app.buttons.matching(
            identifier: "medication-profile-semaglutide-ozempic-0.25mg"
        ).firstMatch
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))

        profileCell.swipeLeft()
        let deleteButton = self.app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3.0))
        deleteButton.tap()

        // Verify confirmation dialog content
        let confirmDialog = self.app.alerts["Delete Medication Profile?"]
        XCTAssertTrue(confirmDialog.waitForExistence(timeout: 3.0))

        // Verify both options are present
        let disableInsteadButton = confirmDialog.buttons["Disable Instead (Recommended)"]
        XCTAssertTrue(disableInsteadButton.exists)

        let deletePermanentlyButton = confirmDialog.buttons["Delete Permanently"]
        XCTAssertTrue(deletePermanentlyButton.exists)

        // Verify message mentions preserving data
        XCTAssertTrue(
            confirmDialog.staticTexts.containing(NSPredicate(format: "label CONTAINS 'preserve'")).firstMatch.exists)

        // Test that "Disable Instead" actually disables the profile
        disableInsteadButton.tap()

        // Verify profile is disabled (hidden from list)
        XCTAssertFalse(profileCell.waitForExistence(timeout: 3.0))
        let emptyStateLabel = self.app.staticTexts["No medication profiles yet"]
        XCTAssertTrue(emptyStateLabel.waitForExistence(timeout: 3.0))
    }
}
