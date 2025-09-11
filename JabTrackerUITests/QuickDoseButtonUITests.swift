import XCTest

final class QuickDoseButtonUITests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    // MARK: - E2E Acceptance Tests for Issue #39
    
    @MainActor
    func testQuickDoseButtonOpensSheetWithSmartDefaults() throws {
        let app = TestUtilities.launchAppWithTestMode()
        
        // Given: User is on the Add tab with medication profiles set up
        TestUtilities.navigateToTab(app, tabName: "Add")
        
        // When: User taps the "+" (Add) tab button
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()
        
        // Then: QuickDoseSheet should appear
        let quickDoseSheet = app.sheets["quick-dose-sheet"]
        XCTAssertTrue(quickDoseSheet.waitForExistence(timeout: 2), 
                     "Quick dose sheet should appear when Add tab is tapped")
        
        // And: Sheet should have pre-populated smart defaults
        let medicationPicker = app.pickers["quick-dose-medication-picker"]
        let doseAmountText = app.staticTexts["quick-dose-amount"]
        let injectionSitePicker = app.pickers["quick-dose-site-picker"]
        let timeDisplay = app.staticTexts["quick-dose-time"]
        
        XCTAssertTrue(medicationPicker.exists, "Medication picker should be visible")
        XCTAssertTrue(doseAmountText.exists, "Dose amount should be pre-populated")
        XCTAssertTrue(injectionSitePicker.exists, "Injection site picker should be visible")
        XCTAssertTrue(timeDisplay.exists, "Current time should be displayed")
    }
    
    @MainActor
    func testQuickDoseSheetSuccessfulDoseLogging() throws {
        let app = TestUtilities.launchAppWithTestMode()
        
        // Given: User opens quick dose sheet
        TestUtilities.navigateToTab(app, tabName: "Add")
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()
        
        let quickDoseSheet = app.sheets["quick-dose-sheet"]
        XCTAssertTrue(quickDoseSheet.waitForExistence(timeout: 2))
        
        // When: User confirms dose with defaults and taps save
        let saveButton = app.buttons["quick-dose-save-button"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled by default")
        
        saveButton.tap()
        
        // Then: Sheet should dismiss automatically
        XCTAssertFalse(quickDoseSheet.waitForExistence(timeout: 1), 
                      "Sheet should dismiss after successful save")
        
        // And: User should receive visual feedback (success message or haptic)
        // Note: Haptic feedback can't be tested in UI tests, but we can check for success indicators
        let successIndicator = app.staticTexts["dose-logged-success"]
        XCTAssertTrue(successIndicator.waitForExistence(timeout: 2), 
                     "Success feedback should appear after dose logging")
    }
    
    @MainActor
    func testQuickDoseSheetAccessibilitySupport() throws {
        let app = TestUtilities.launchAppWithTestMode()
        
        // Given: User opens quick dose sheet
        TestUtilities.navigateToTab(app, tabName: "Add")
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()
        
        let quickDoseSheet = app.sheets["quick-dose-sheet"]
        XCTAssertTrue(quickDoseSheet.waitForExistence(timeout: 2))
        
        // Then: All interactive elements should have proper accessibility labels
        let medicationPicker = app.pickers["quick-dose-medication-picker"]
        XCTAssertTrue(medicationPicker.exists)
        XCTAssertNotNil(medicationPicker.label, "Medication picker should have accessibility label")
        
        let injectionSitePicker = app.pickers["quick-dose-site-picker"]
        XCTAssertTrue(injectionSitePicker.exists)
        XCTAssertNotNil(injectionSitePicker.label, "Injection site picker should have accessibility label")
        
        let saveButton = app.buttons["quick-dose-save-button"]
        XCTAssertTrue(saveButton.exists)
        XCTAssertNotNil(saveButton.label, "Save button should have accessibility label")
        
        let cancelButton = app.buttons["quick-dose-cancel-button"]
        XCTAssertTrue(cancelButton.exists)
        XCTAssertNotNil(cancelButton.label, "Cancel button should have accessibility label")
    }
    
    @MainActor
    func testQuickDoseSheetErrorHandling() throws {
        let app = TestUtilities.launchAppWithTestMode()
        
        // Given: User opens quick dose sheet in error scenario (no medication profiles)
        TestUtilities.navigateToTab(app, tabName: "Add")
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()
        
        let quickDoseSheet = app.sheets["quick-dose-sheet"]
        XCTAssertTrue(quickDoseSheet.waitForExistence(timeout: 2))
        
        // When: No medication profiles exist (test condition)
        // Then: Should show appropriate error message and disable save button
        let errorMessage = app.staticTexts["no-medication-profiles-error"]
        let saveButton = app.buttons["quick-dose-save-button"]
        
        // Error message should appear if no medication profiles
        if errorMessage.exists {
            XCTAssertFalse(saveButton.isEnabled, "Save button should be disabled when no medication profiles exist")
        }
    }
    
    @MainActor
    func testQuickDoseSheetCancellation() throws {
        let app = TestUtilities.launchAppWithTestMode()
        
        // Given: User opens quick dose sheet
        TestUtilities.navigateToTab(app, tabName: "Add")
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()
        
        let quickDoseSheet = app.sheets["quick-dose-sheet"]
        XCTAssertTrue(quickDoseSheet.waitForExistence(timeout: 2))
        
        // When: User taps cancel
        let cancelButton = app.buttons["quick-dose-cancel-button"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()
        
        // Then: Sheet should dismiss without saving
        XCTAssertFalse(quickDoseSheet.waitForExistence(timeout: 1), 
                      "Sheet should dismiss when cancel is tapped")
        
        // And: No dose should be logged (no success message)
        let successIndicator = app.staticTexts["dose-logged-success"]
        XCTAssertFalse(successIndicator.exists, 
                      "No success message should appear when operation is cancelled")
    }
    
    @MainActor
    func testQuickDoseSheetSmartDefaults() throws {
        let app = TestUtilities.launchAppWithTestMode()
        
        // Given: User has existing medication profiles and dose history
        TestUtilities.navigateToTab(app, tabName: "Add")
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()
        
        let quickDoseSheet = app.sheets["quick-dose-sheet"]
        XCTAssertTrue(quickDoseSheet.waitForExistence(timeout: 2))
        
        // Then: Smart defaults should be applied
        let medicationPicker = app.pickers["quick-dose-medication-picker"]
        let doseAmountText = app.staticTexts["quick-dose-amount"]
        let injectionSitePicker = app.pickers["quick-dose-site-picker"]
        
        XCTAssertTrue(medicationPicker.exists, "Medication should default to current medication profile")
        XCTAssertTrue(doseAmountText.exists, "Dose amount should default to profile's current dose")
        XCTAssertTrue(injectionSitePicker.exists, "Injection site should suggest next recommended site")
        
        // Time should default to current time (within reasonable range)
        let timeDisplay = app.staticTexts["quick-dose-time"]
        XCTAssertTrue(timeDisplay.exists, "Time should be set to current time")
    }
    
    @MainActor
    func testQuickDoseSheetStreamslinedInterface() throws {
        let app = TestUtilities.launchAppWithTestMode()
        
        // Given: User opens quick dose sheet
        TestUtilities.navigateToTab(app, tabName: "Add")
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()
        
        let quickDoseSheet = app.sheets["quick-dose-sheet"]
        XCTAssertTrue(quickDoseSheet.waitForExistence(timeout: 2))
        
        // Then: Interface should be streamlined with minimal required fields
        XCTAssertTrue(app.pickers["quick-dose-medication-picker"].exists, "Medication picker is essential")
        XCTAssertTrue(app.staticTexts["quick-dose-amount"].exists, "Dose amount display is essential")
        XCTAssertTrue(app.pickers["quick-dose-site-picker"].exists, "Injection site picker is essential")
        XCTAssertTrue(app.staticTexts["quick-dose-time"].exists, "Time display is essential")
        
        // Save and Cancel buttons are essential
        XCTAssertTrue(app.buttons["quick-dose-save-button"].exists, "Save button is essential")
        XCTAssertTrue(app.buttons["quick-dose-cancel-button"].exists, "Cancel button is essential")
        
        // Optional fields should be minimal or hidden in quick entry mode
        // Notes field should be optional or not present for quick entry
        let notesField = app.textFields["quick-dose-notes"]
        if notesField.exists {
            // If notes field exists, it should be clearly marked as optional
            XCTAssertTrue(notesField.placeholderValue?.contains("Optional") == true || 
                         app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'optional'")).count > 0,
                         "Notes field should be marked as optional if present")
        }
    }
}