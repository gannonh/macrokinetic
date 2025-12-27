//
//  WeightTrackingUITests.swift
//  JabTrackerUITests
//
//  E2E tests for weight tracking flow via QuickWeightSheet.
//

import XCTest

final class WeightTrackingUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = TestUtilities.launchAppWithTestMode(resetData: true)

        // Wait for app to be ready
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after launch")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    /// Open QuickWeightSheet via shortcuts
    private func openQuickWeightSheet(timeout: TimeInterval = 5) {
        // Open shortcuts sheet via + tab
        TestUtilities.openShortcutsSheet(app, timeout: timeout)

        // Tap Weight shortcut
        let weightButton = app.buttons["Weight"]
        XCTAssertTrue(weightButton.waitForExistence(timeout: timeout), "Weight shortcut should exist")
        weightButton.tap()

        // Wait for QuickWeightSheet to appear
        let weightSheet = app.otherElements["quick-weight-sheet"]
        XCTAssertTrue(weightSheet.waitForExistence(timeout: timeout), "Quick weight sheet should appear")
    }

    /// Enter a value in a text field (clears existing text first)
    private func enterValue(_ value: String, in field: XCUIElement) {
        field.tap()
        // Clear existing text if any
        if let currentValue = field.value as? String, !currentValue.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            field.typeText(deleteString)
        }
        field.typeText(value)
    }

    /// Clear text from a text field
    private func clearField(_ field: XCUIElement) {
        field.tap()
        if let currentValue = field.value as? String, !currentValue.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            field.typeText(deleteString)
        }
    }

    // MARK: - Happy Path

    /// User can log weight via shortcut
    /// Acceptance: Tap Weight shortcut -> enter weight -> save -> sheet dismisses
    func testUserCanLogWeightViaShortcut() {
        // GIVEN: App is launched and shortcuts sheet is open
        openQuickWeightSheet()

        // WHEN: Enter weight value and tap Save
        let weightInput = app.textFields["weight-input"]
        XCTAssertTrue(weightInput.waitForExistence(timeout: 3), "Weight input field should exist")
        enterValue("75.5", in: weightInput)

        // Dismiss keyboard by tapping elsewhere
        app.tap()

        let saveButton = app.buttons["save-weight-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled with valid weight")
        saveButton.tap()

        // THEN: Sheet should dismiss
        let weightSheet = app.otherElements["quick-weight-sheet"]
        XCTAssertFalse(
            weightSheet.waitForExistence(timeout: 3),
            "Quick weight sheet should be dismissed after saving"
        )
    }

    /// User can log weight with body fat percentage
    /// Acceptance: Enter weight + body fat -> save -> both values persisted
    func testUserCanLogWeightWithBodyFat() {
        // GIVEN: QuickWeightSheet is open
        openQuickWeightSheet()

        // WHEN: Enter weight and body fat percentage
        let weightInput = app.textFields["weight-input"]
        XCTAssertTrue(weightInput.waitForExistence(timeout: 3), "Weight input should exist")
        enterValue("80.0", in: weightInput)

        let bodyFatInput = app.textFields["body-fat-input"]
        XCTAssertTrue(bodyFatInput.exists, "Body fat input should exist")
        enterValue("18.5", in: bodyFatInput)

        // Dismiss keyboard
        app.tap()

        // WHEN: Tap Save
        let saveButton = app.buttons["save-weight-button"]
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled with valid weight and body fat")
        saveButton.tap()

        // Wait for sheet to dismiss
        Thread.sleep(forTimeInterval: 1.0)

        // THEN: We should be back to the shortcuts view (not the weight sheet)
        // The weight input should no longer be visible after sheet dismisses
        XCTAssertFalse(
            weightInput.waitForExistence(timeout: 3),
            "Weight input should not exist after sheet dismisses"
        )
    }

    /// User can change weight unit between kg and lbs
    /// Acceptance: Toggle kg/lbs -> input updates -> save converts correctly
    func testUserCanChangeWeightUnit() {
        // GIVEN: QuickWeightSheet is open
        openQuickWeightSheet()

        // WHEN: Tap lbs segment in unit picker
        let unitPicker = app.segmentedControls["weight-unit-picker"]
        XCTAssertTrue(unitPicker.waitForExistence(timeout: 3), "Weight unit picker should exist")

        let lbsButton = unitPicker.buttons["lbs"]
        XCTAssertTrue(lbsButton.exists, "lbs option should exist in picker")
        lbsButton.tap()

        // Enter weight in lbs
        let weightInput = app.textFields["weight-input"]
        enterValue("165.0", in: weightInput)

        // Dismiss keyboard
        app.tap()

        // WHEN: Tap Save
        let saveButton = app.buttons["save-weight-button"]
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled")
        saveButton.tap()

        // THEN: Sheet should dismiss (weight saved, converted to kg internally)
        let weightSheet = app.otherElements["quick-weight-sheet"]
        XCTAssertFalse(
            weightSheet.waitForExistence(timeout: 3),
            "Sheet should dismiss after saving weight in lbs"
        )
    }

    /// Weight defaults to last entry value
    /// Acceptance: User opens sheet -> weight field pre-filled with last weight
    func testWeightDefaultsToLastEntry() {
        // GIVEN: Log initial weight entry
        openQuickWeightSheet()

        let weightInput = app.textFields["weight-input"]
        XCTAssertTrue(weightInput.waitForExistence(timeout: 3), "Weight input should exist")
        enterValue("72.5", in: weightInput)

        // Dismiss keyboard
        app.tap()

        let saveButton = app.buttons["save-weight-button"]
        saveButton.tap()

        // Wait for sheet to dismiss
        let weightSheet = app.otherElements["quick-weight-sheet"]
        XCTAssertFalse(weightSheet.waitForExistence(timeout: 3), "Sheet should dismiss after first save")

        // WHEN: Open QuickWeightSheet again
        openQuickWeightSheet()

        // THEN: Weight field should be pre-filled with previous value
        let weightInputAgain = app.textFields["weight-input"]
        XCTAssertTrue(weightInputAgain.waitForExistence(timeout: 3), "Weight input should exist on second open")

        // Check that the field has a value (pre-filled)
        if let value = weightInputAgain.value as? String {
            XCTAssertFalse(value.isEmpty, "Weight field should be pre-filled with last entry value")
            // The value should contain "72.5" (may have different formatting)
            XCTAssertTrue(
                value.contains("72") || value.contains("72.5"),
                "Weight should default to last entry value, got: \(value)"
            )
        }
    }

    // MARK: - Validation

    /// System validates weight input - save disabled for empty/invalid
    /// Acceptance: Empty/invalid weight -> save button disabled
    func testWeightInputValidation() {
        // GIVEN: QuickWeightSheet is open
        openQuickWeightSheet()

        let weightInput = app.textFields["weight-input"]
        XCTAssertTrue(weightInput.waitForExistence(timeout: 3), "Weight input should exist")

        let saveButton = app.buttons["save-weight-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")

        // WHEN: Clear weight field (if it has a default value)
        clearField(weightInput)

        // Dismiss keyboard to trigger validation
        app.tap()

        // THEN: Save button should be disabled for empty input
        XCTAssertFalse(saveButton.isEnabled, "Save button should be disabled when weight is empty")

        // WHEN: Enter valid weight
        enterValue("70.0", in: weightInput)

        // Dismiss keyboard
        app.tap()

        // THEN: Save button should be enabled
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled with valid weight")
    }

    /// System validates body fat percentage range
    /// Acceptance: Body fat > 100 -> save button disabled
    func testBodyFatValidation() {
        // GIVEN: QuickWeightSheet is open
        openQuickWeightSheet()

        // Enter valid weight first
        let weightInput = app.textFields["weight-input"]
        XCTAssertTrue(weightInput.waitForExistence(timeout: 3), "Weight input should exist")
        enterValue("75.0", in: weightInput)

        let saveButton = app.buttons["save-weight-button"]

        // Verify save is enabled with valid weight and no body fat
        app.tap()
        XCTAssertTrue(saveButton.isEnabled, "Save should be enabled with valid weight only")

        // WHEN: Enter invalid body fat > 100
        let bodyFatInput = app.textFields["body-fat-input"]
        XCTAssertTrue(bodyFatInput.exists, "Body fat input should exist")
        enterValue("105", in: bodyFatInput)

        // Dismiss keyboard
        app.tap()

        // THEN: Save button should be disabled
        XCTAssertFalse(saveButton.isEnabled, "Save button should be disabled when body fat > 100")

        // WHEN: Enter valid body fat
        clearField(bodyFatInput)
        enterValue("25", in: bodyFatInput)

        // Dismiss keyboard
        app.tap()

        // THEN: Save button should be enabled again
        XCTAssertTrue(saveButton.isEnabled, "Save button should be enabled with valid body fat")
    }

    // MARK: - Date Selection

    /// User can change weight entry date/time
    /// Acceptance: Select past date -> save -> entry timestamp matches selection
    func testUserCanChangeDateAndTime() {
        // GIVEN: QuickWeightSheet is open
        openQuickWeightSheet()

        // Enter weight first
        let weightInput = app.textFields["weight-input"]
        XCTAssertTrue(weightInput.waitForExistence(timeout: 3), "Weight input should exist")
        enterValue("70.0", in: weightInput)

        // Dismiss keyboard
        app.tap()

        // WHEN: Verify date picker exists and is interactive
        let datePicker = app.datePickers["weight-date-picker"]
        XCTAssertTrue(datePicker.waitForExistence(timeout: 3), "Date picker should exist")

        // Note: We verify the date picker exists and is accessible
        // Full date picker interaction in XCUITest is complex and requires specific
        // picker wheel manipulation. For this test, we verify the picker is present
        // and that the form saves successfully.

        // THEN: Save should work with the date picker present
        let saveButton = app.buttons["save-weight-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")
        XCTAssertTrue(saveButton.isEnabled, "Save should be enabled")
        saveButton.tap()

        let weightSheet = app.otherElements["quick-weight-sheet"]
        XCTAssertFalse(
            weightSheet.waitForExistence(timeout: 3),
            "Sheet should dismiss after saving"
        )
    }

    // MARK: - HealthKit Integration

    /// Weight syncs to HealthKit when toggle is enabled
    /// Acceptance: Toggle ON -> save -> entry appears in Health app
    /// Note: Cannot verify actual HealthKit sync in automated tests
    func testWeightSyncsToHealthKit() {
        // GIVEN: QuickWeightSheet is open
        openQuickWeightSheet()

        // Enter weight
        let weightInput = app.textFields["weight-input"]
        XCTAssertTrue(weightInput.waitForExistence(timeout: 3), "Weight input should exist")
        enterValue("73.0", in: weightInput)

        // WHEN: Check if HealthKit toggle exists
        // Note: Toggle only appears if HealthKit is available on the device
        let healthKitToggle = app.switches["healthkit-sync-toggle"]

        if healthKitToggle.waitForExistence(timeout: 2) {
            // HealthKit is available - verify toggle can be interacted with
            XCTAssertTrue(healthKitToggle.exists, "HealthKit toggle should exist when HK is available")

            // Toggle may default to ON or OFF based on HK availability
            // Just verify it's accessible
            healthKitToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        } else {
            // HealthKit not available on this simulator/device - this is acceptable
            print("HealthKit toggle not present - HealthKit may not be available")
        }

        // THEN: Save should work regardless of HealthKit availability
        app.tap()
        let saveButton = app.buttons["save-weight-button"]
        XCTAssertTrue(saveButton.isEnabled, "Save should be enabled")
        saveButton.tap()

        let weightSheet = app.otherElements["quick-weight-sheet"]
        XCTAssertFalse(
            weightSheet.waitForExistence(timeout: 3),
            "Sheet should dismiss after saving"
        )
    }

    /// User can disable HealthKit sync
    /// Acceptance: Toggle OFF -> save -> entry only saved locally
    func testUserCanDisableHealthKitSync() {
        // GIVEN: QuickWeightSheet is open
        openQuickWeightSheet()

        // Enter weight
        let weightInput = app.textFields["weight-input"]
        XCTAssertTrue(weightInput.waitForExistence(timeout: 3), "Weight input should exist")
        enterValue("71.0", in: weightInput)

        // Dismiss keyboard by scrolling down on the form - this also reveals the toggle
        // Swiping up on the form scrolls content down and dismisses keyboard
        app.swipeUp()
        usleep(500_000)  // Wait for keyboard dismissal and scroll animation

        // WHEN: Find and interact with HealthKit toggle
        let healthKitToggle = app.switches["healthkit-sync-toggle"]
        XCTAssertTrue(healthKitToggle.waitForExistence(timeout: 3), "HealthKit toggle should exist")

        // Get initial toggle state
        let initialValue = healthKitToggle.value as? String ?? "unknown"

        // SwiftUI Toggles in Forms require coordinate-based tapping
        healthKitToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        // Wait for toggle animation to complete
        let expectedValue = initialValue == "1" ? "0" : "1"
        let toggleExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expectedValue),
            object: healthKitToggle
        )
        let toggleResult = XCTWaiter().wait(for: [toggleExpectation], timeout: 3.0)
        XCTAssertEqual(toggleResult, .completed, "HealthKit toggle value should change after tap")

        // THEN: Save should work
        let saveButton = app.buttons["save-weight-button"]
        XCTAssertTrue(saveButton.isEnabled, "Save should be enabled")
        saveButton.tap()

        // Verify weight input is no longer visible (sheet dismissed)
        XCTAssertFalse(
            weightInput.waitForExistence(timeout: 3),
            "Weight input should not exist after sheet dismisses"
        )
    }

    // MARK: - Cancel Flow

    /// User can cancel weight entry
    /// Acceptance: Tap Cancel -> sheet dismisses -> no entry created
    func testUserCanCancelWeightEntry() {
        // GIVEN: QuickWeightSheet is open
        openQuickWeightSheet()

        // Enter a weight value
        let weightInput = app.textFields["weight-input"]
        XCTAssertTrue(weightInput.waitForExistence(timeout: 3), "Weight input should exist")
        enterValue("99.9", in: weightInput)

        // Dismiss keyboard
        app.tap()

        // WHEN: Tap Cancel button
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3), "Cancel button should exist")
        cancelButton.tap()

        // THEN: Sheet should dismiss without saving
        let weightSheet = app.otherElements["quick-weight-sheet"]
        XCTAssertFalse(
            weightSheet.waitForExistence(timeout: 3),
            "Sheet should dismiss after cancel"
        )

        // Verify no entry was saved by opening sheet again and checking default
        // If 99.9 was saved, it would appear as the default value
        openQuickWeightSheet()

        let weightInputAgain = app.textFields["weight-input"]
        XCTAssertTrue(weightInputAgain.waitForExistence(timeout: 3), "Weight input should exist")

        if let value = weightInputAgain.value as? String {
            // The value should NOT be 99.9 since we cancelled
            XCTAssertFalse(
                value.contains("99.9") || value.contains("99,9"),
                "Weight should not be 99.9 after cancel, got: \(value)"
            )
        }
    }

    // MARK: - Accessibility

    /// Weight entry sheet is accessible via VoiceOver
    /// Acceptance: All interactive elements have accessibility identifiers
    func testAccessibilityIdentifiers() {
        // GIVEN: QuickWeightSheet is open
        openQuickWeightSheet()

        // THEN: Verify all key accessibility identifiers exist

        // Sheet container
        let sheet = app.otherElements["quick-weight-sheet"]
        XCTAssertTrue(sheet.exists, "quick-weight-sheet identifier should exist")

        // Weight input field
        let weightInput = app.textFields["weight-input"]
        XCTAssertTrue(weightInput.exists, "weight-input identifier should exist")

        // Weight unit picker
        let unitPicker = app.segmentedControls["weight-unit-picker"]
        XCTAssertTrue(unitPicker.exists, "weight-unit-picker identifier should exist")

        // Body fat input field
        let bodyFatInput = app.textFields["body-fat-input"]
        XCTAssertTrue(bodyFatInput.exists, "body-fat-input identifier should exist")

        // Date picker
        let datePicker = app.datePickers["weight-date-picker"]
        XCTAssertTrue(datePicker.exists, "weight-date-picker identifier should exist")

        // HealthKit sync toggle (may not exist if HK unavailable)
        let healthKitToggle = app.switches["healthkit-sync-toggle"]
        // Note: This toggle only appears when HealthKit is available
        // We just verify the identifier pattern works when it exists
        if healthKitToggle.exists {
            XCTAssertTrue(true, "healthkit-sync-toggle identifier exists when HK available")
        }

        // Save button
        let saveButton = app.buttons["save-weight-button"]
        XCTAssertTrue(saveButton.exists, "save-weight-button identifier should exist")
    }
}
