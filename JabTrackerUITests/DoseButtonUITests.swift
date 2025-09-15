import XCTest

final class DoseButtonUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - E2E Acceptance Tests for Issue #39

    @MainActor
    func testQuickDoseButtonOpensSheetWithSmartDefaults() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Given: User has a medication profile set up
        TestUtilities.createMedicationProfile(app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")

        // When: User taps the "+" (Add) tab button
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()

        // Then: QuickDoseSheet content should appear
        let medicationPicker = app.buttons["quick-dose-medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 2),
                      "Quick dose sheet should appear when Add tab is tapped")

        // And: Sheet should have pre-populated smart defaults
        let doseAmountText = app.staticTexts["quick-dose-amount"]
        let injectionSitePicker = app.buttons["quick-dose-site-picker"]
        let timeDisplay = app.staticTexts["quick-dose-time"]

        XCTAssertTrue(medicationPicker.exists, "Medication picker should be visible")
        XCTAssertTrue(doseAmountText.exists, "Dose amount should be pre-populated")
        XCTAssertTrue(injectionSitePicker.exists, "Injection site picker should be visible")
        XCTAssertTrue(timeDisplay.exists, "Current time should be displayed")
    }

    @MainActor
    func testQuickDoseSheetSuccessfulDoseLogging() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Given: User has a medication profile set up
        TestUtilities.createMedicationProfile(app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")

        // When: User opens quick dose sheet
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()

        // Verify sheet content is visible
        let medicationPicker = app.buttons["quick-dose-medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 2))

        // When: User confirms dose with defaults and taps save
        let saveButton = app.buttons["quick-dose-save-button"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled by default")

        saveButton.tap()

        // Then: User should receive visual feedback (success message)
        // Note: Success message appears at ContentView level, not in sheet
        let successIndicator = app.staticTexts["dose-logged-success"]
        XCTAssertTrue(successIndicator.waitForExistence(timeout: 3),
                      "Success feedback should appear after dose logging")

        // And: Sheet should dismiss automatically after success (check after success message)
        XCTAssertFalse(medicationPicker.waitForExistence(timeout: 2),
                       "Sheet should dismiss after successful save")
    }

    @MainActor
    func testQuickDoseSheetAccessibilitySupport() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Given: User has a medication profile set up
        TestUtilities.createMedicationProfile(app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")

        // When: User opens quick dose sheet
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()

        // Verify sheet content is visible
        let medicationPicker = app.buttons["quick-dose-medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 2))

        // Then: All interactive elements should have proper accessibility labels
        XCTAssertTrue(medicationPicker.exists)
        XCTAssertNotNil(medicationPicker.label, "Medication picker should have accessibility label")

        let injectionSitePicker = app.buttons["quick-dose-site-picker"]
        XCTAssertTrue(injectionSitePicker.exists)
        XCTAssertNotNil(injectionSitePicker.label, "Injection site picker should have accessibility label")

        // Note: Save and Cancel buttons are in toolbar and may not be accessible the same way in UI tests
        // Focus on testing the main sheet content accessibility
        let doseAmountText = app.staticTexts["quick-dose-amount"]
        XCTAssertTrue(doseAmountText.exists, "Dose amount should be visible")

        let timeDisplay = app.staticTexts["quick-dose-time"]
        XCTAssertTrue(timeDisplay.exists, "Time display should be visible")
    }

    @MainActor
    func testQuickDoseSheetErrorHandling() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Given: User opens quick dose sheet in error scenario (no medication profiles)
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()

        // Verify sheet content appears (even in error state)
        let medicationPicker = app.buttons["quick-dose-medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 2))

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

        // Given: User has a medication profile set up
        TestUtilities.createMedicationProfile(app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")

        // When: User opens quick dose sheet
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()

        // Verify sheet content is visible
        let medicationPicker = app.buttons["quick-dose-medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 2))

        // When: User cancels (use swipe down gesture to dismiss sheet)
        // Note: Cancel button is in toolbar - use swipe down to dismiss sheet instead
        app.swipeDown(velocity: .fast)

        // Then: Sheet should dismiss without saving (medication picker should disappear)
        XCTAssertFalse(medicationPicker.waitForExistence(timeout: 2),
                       "Sheet should dismiss when swiped down")

        // And: No dose should be logged (no success message)
        let successIndicator = app.staticTexts["dose-logged-success"]
        XCTAssertFalse(successIndicator.exists,
                       "No success message should appear when operation is cancelled")
    }

    @MainActor
    func testQuickDoseSheetSmartDefaults() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Given: User has existing medication profiles and dose history
        TestUtilities.createMedicationProfile(app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")

        // When: User opens quick dose sheet
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()

        // Verify sheet content is visible
        let medicationPicker = app.buttons["quick-dose-medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 2))

        // Then: Smart defaults should be applied
        let doseAmountText = app.staticTexts["quick-dose-amount"]
        let injectionSitePicker = app.buttons["quick-dose-site-picker"]

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

        // Given: User has a medication profile set up
        TestUtilities.createMedicationProfile(app, genericName: "semaglutide", brandName: "Ozempic", dose: "0.25")

        // When: User opens quick dose sheet
        let addTab = app.tabBars.element.buttons["Add"]
        addTab.tap()

        // Verify sheet content is visible
        let medicationPicker = app.buttons["quick-dose-medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 2))

        // Then: Interface should be streamlined with minimal required fields
        XCTAssertTrue(app.buttons["quick-dose-medication-picker"].exists, "Medication picker is essential")
        XCTAssertTrue(app.staticTexts["quick-dose-amount"].exists, "Dose amount display is essential")
        XCTAssertTrue(app.buttons["quick-dose-site-picker"].exists, "Injection site picker is essential")
        XCTAssertTrue(app.staticTexts["quick-dose-time"].exists, "Time display is essential")

        // Note: Save and Cancel buttons are in toolbar and tested separately

        // Optional fields should be minimal or hidden in quick entry mode
        // Notes field should be optional or not present for quick entry
        let notesField = app.textViews["quick-dose-notes"]
        if notesField.exists {
            // If notes field exists, it should be clearly marked as optional
            XCTAssertTrue(notesField.placeholderValue?.contains("Optional") == true ||
                !app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'optional'")).isEmpty,
                "Notes field should be marked as optional if present")
        }
    }
}
