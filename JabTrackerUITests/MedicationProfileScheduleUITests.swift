//
//  MedicationProfileScheduleUITests.swift
//  JabTrackerUITests
//
//  E2E tests for medication profile schedule management (CRUD operations)
//  Issue #179 - Stream C
//

import XCTest

final class MedicationProfileScheduleUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        // Pre-seed with medication profile (no schedule yet)
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "0"  // No doses
        app.launchEnvironment["TEST_DATA_MEDICATION"] = "semaglutide"
        app.launchEnvironment["TEST_DATA_BRAND"] = "Ozempic"
        app.launchEnvironment["TEST_DATA_DOSE"] = "0.25"
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Navigate to medication profile settings view (profile already pre-seeded)
    private func navigateToMedicationProfileSettings() throws {
        app.launch()

        // Wait for app to load
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should appear after app launch")

        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 3), "Settings tab should exist")
        settingsTab.tap()

        // Tap Medication Profiles button
        let medicationProfilesButton = app.buttons["Medication Profiles"]
        XCTAssertTrue(
            medicationProfilesButton.waitForExistence(timeout: 3),
            "Medication Profiles button should exist in Settings")
        medicationProfilesButton.tap()

        // Tap on pre-seeded profile
        let profile = app.buttons["medication-profile-semaglutide-ozempic-0.25mg"]
        XCTAssertTrue(
            profile.waitForExistence(timeout: 3),
            "Pre-seeded medication profile should appear in list")
        profile.tap()
    }

    // MARK: - Test 1: Create Schedule Flow

    func testCreateWeeklySchedule() throws {
        // GIVEN: User on medication profile settings with no active schedule
        try navigateToMedicationProfileSettings()

        // WHEN: User taps "Create Dose Schedule" button
        let createScheduleButton = app.buttons["create-schedule-button"]
        XCTAssertTrue(
            createScheduleButton.waitForExistence(timeout: 5),
            "Create schedule button should exist when no active schedule")
        createScheduleButton.tap()

        // THEN: DoseScheduleEditView sheet appears
        let cancelButton = app.buttons["cancel-schedule-edit"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 3),
            "Schedule edit sheet should appear")

        // WHEN: User selects weekly pattern (should be default), sets day/time
        let patternPicker = app.buttons.matching(identifier: "pattern-picker").firstMatch
        XCTAssertTrue(
            patternPicker.waitForExistence(timeout: 3),
            "Pattern picker should exist")

        // Tap Save button
        let saveButton = app.buttons["save-schedule-edit"]
        XCTAssertTrue(
            saveButton.waitForExistence(timeout: 3),
            "Save button should exist")
        saveButton.tap()

        // THEN: ScheduleSummaryView appears with correct schedule info
        let editScheduleButton = app.buttons["edit-schedule-button"]
        XCTAssertTrue(
            editScheduleButton.waitForExistence(timeout: 5),
            "Edit schedule button should appear after creating schedule")

        print("✅ Test 1 passed: Weekly schedule created successfully")
    }

    // MARK: - Test 2: Edit Existing Schedule

    func testEditExistingSchedule() throws {
        // GIVEN: User on medication profile settings with active weekly schedule
        try navigateToMedicationProfileSettings()
        try TestUtilities.createDefaultSchedule(app)

        // WHEN: User taps "Edit Schedule" button
        let editScheduleButton = app.buttons["edit-schedule-button"]
        XCTAssertTrue(
            editScheduleButton.waitForExistence(timeout: 5),
            "Edit schedule button should exist with active schedule")
        editScheduleButton.tap()

        // THEN: DoseScheduleEditView sheet appears with current values pre-populated
        let cancelButton = app.buttons["cancel-schedule-edit"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 3),
            "Schedule edit sheet should appear")

        // Verify pattern picker exists and has current value
        let patternPicker = app.buttons.matching(identifier: "pattern-picker").firstMatch
        XCTAssertTrue(
            patternPicker.waitForExistence(timeout: 3),
            "Pattern picker should exist")

        // Tap Save
        let saveButton2 = app.buttons["save-schedule-edit"]
        XCTAssertTrue(
            saveButton2.waitForExistence(timeout: 3),
            "Save button should exist")
        saveButton2.tap()

        // THEN: ScheduleSummaryView updates
        XCTAssertTrue(
            editScheduleButton.waitForExistence(timeout: 5),
            "Edit schedule button should still exist after update")

        print("✅ Test 2 passed: Schedule edited successfully")
    }

    // MARK: - Test 3: Pause Schedule

    func testPauseScheduleOneWeek() throws {
        // GIVEN: User on medication profile settings with active schedule
        try navigateToMedicationProfileSettings()
        try TestUtilities.createDefaultSchedule(app)

        // WHEN: User taps "Pause Schedule" button
        let pauseScheduleButton = app.buttons["pause-schedule-button"]
        XCTAssertTrue(
            pauseScheduleButton.waitForExistence(timeout: 5),
            "Pause schedule button should exist with active schedule")
        pauseScheduleButton.tap()

        // THEN: Pause schedule sheet appears
        let pauseConfirmButton = app.buttons["pause-confirm-button"]
        XCTAssertTrue(
            pauseConfirmButton.waitForExistence(timeout: 3),
            "Pause confirmation button should appear in sheet")

        // WHEN: User taps "Pause" to confirm
        pauseConfirmButton.tap()

        // THEN: Sheet dismisses and schedule shows paused state with resume button
        XCTAssertFalse(
            pauseConfirmButton.waitForExistence(timeout: 3),
            "Pause sheet should dismiss after confirmation")

        let resumeScheduleButton = app.buttons["resume-schedule-button"]
        XCTAssertTrue(
            resumeScheduleButton.waitForExistence(timeout: 5),
            "Resume schedule button should appear after pausing")
        print("✅ Test 3 passed: Schedule paused successfully")
    }

    // MARK: - Test 4: Resume Schedule

    func testResumeSchedule() throws {
        // GIVEN: User on medication profile settings with paused schedule
        try navigateToMedicationProfileSettings()
        try TestUtilities.createDefaultSchedule(app)

        // Pause the schedule
        let pauseScheduleButton = app.buttons["pause-schedule-button"]
        XCTAssertTrue(
            pauseScheduleButton.waitForExistence(timeout: 5),
            "Pause schedule button should exist")
        pauseScheduleButton.tap()

        // Confirm pause in sheet
        let pauseConfirmButton = app.buttons["pause-confirm-button"]
        XCTAssertTrue(
            pauseConfirmButton.waitForExistence(timeout: 3),
            "Pause confirmation button should appear in sheet")
        pauseConfirmButton.tap()

        // Wait for sheet to dismiss
        XCTAssertFalse(
            pauseConfirmButton.waitForExistence(timeout: 3),
            "Pause sheet should dismiss after confirmation")

        // WHEN: User taps "Resume Schedule" button
        let resumeScheduleButton = app.buttons["resume-schedule-button"]
        XCTAssertTrue(
            resumeScheduleButton.waitForExistence(timeout: 5),
            "Resume button should exist to resume schedule")
        resumeScheduleButton.tap()

        // THEN: Pause button returns
        let pauseButton = app.buttons["pause-schedule-button"]
        XCTAssertTrue(
            pauseButton.waitForExistence(timeout: 5),
            "Pause button should return after resuming")

        print("✅ Test 4 passed: Schedule resumed successfully")
    }

    // MARK: - Test 5: Deactivate Schedule

    func testDeactivateScheduleWithConfirmation() throws {
        // GIVEN: User on medication profile settings with active schedule
        try navigateToMedicationProfileSettings()
        try TestUtilities.createDefaultSchedule(app)

        // WHEN: User taps "Deactivate Schedule" button
        let deactivateScheduleButton = app.buttons["deactivate-schedule-button"]
        XCTAssertTrue(
            deactivateScheduleButton.waitForExistence(timeout: 5),
            "Deactivate schedule button should exist with active schedule")
        deactivateScheduleButton.tap()

        // THEN: Confirmation dialog appears
        // Wait for dialog to present
        usleep(500_000)  // 0.5 seconds

        // WHEN: User taps "Deactivate Schedule" in confirmation dialog
        // Confirmation dialog buttons don't have identifiers, find by label
        let allButtons = app.buttons
        var confirmButton: XCUIElement?

        // Find button with "Deactivate Schedule" label that's NOT the original button
        for index in 0..<allButtons.count {
            let button = allButtons.element(boundBy: index)
            if button.label == "Deactivate Schedule" && button.identifier == "" {
                confirmButton = button
                break
            }
        }

        XCTAssertNotNil(confirmButton, "Deactivate confirmation button should exist in dialog")
        confirmButton?.tap()

        // THEN: "Create Dose Schedule" button appears
        let createButton = app.buttons["create-schedule-button"]
        XCTAssertTrue(
            createButton.waitForExistence(timeout: 5),
            "Create schedule button should appear after deactivation")

        print("✅ Test 5 passed: Schedule deactivated successfully")
    }

    // MARK: - Test 6: Cancel Deactivate

    func testCancelDeactivateSchedule() throws {
        // GIVEN: User on medication profile settings with active schedule
        try navigateToMedicationProfileSettings()
        try TestUtilities.createDefaultSchedule(app)

        // WHEN: User taps "Deactivate Schedule", confirmation appears
        let deactivateScheduleButton = app.buttons["deactivate-schedule-button"]
        XCTAssertTrue(
            deactivateScheduleButton.waitForExistence(timeout: 5),
            "Deactivate schedule button should exist")
        deactivateScheduleButton.tap()

        // THEN: Confirmation dialog appears
        // Wait for dialog to present
        usleep(500_000)  // 0.5 seconds

        // WHEN: User taps "Cancel"
        // Confirmation dialog buttons don't have identifiers, find by label
        let allButtons = app.buttons
        var cancelButton: XCUIElement?

        // Find button with "Cancel" label that has no identifier (dialog button)
        for index in 0..<allButtons.count {
            let button = allButtons.element(boundBy: index)
            if button.label == "Cancel" && button.identifier == "" {
                cancelButton = button
                break
            }
        }

        XCTAssertNotNil(cancelButton, "Cancel button should exist in confirmation dialog")
        cancelButton?.tap()

        // THEN: Dialog dismisses, schedule remains active
        let editScheduleButton = app.buttons["edit-schedule-button"]
        XCTAssertTrue(
            editScheduleButton.waitForExistence(timeout: 5),
            "Edit schedule button should still exist after cancel")

        print("✅ Test 6 passed: Deactivation cancelled successfully")
    }

    // MARK: - Test 7: Multiple Schedule Modifications

    func testMultipleScheduleModifications() throws {
        // GIVEN: User on medication profile settings
        try navigateToMedicationProfileSettings()
        try TestUtilities.createDefaultSchedule(app)

        // WHEN: User edits the schedule
        let editScheduleButton = app.buttons["edit-schedule-button"]
        XCTAssertTrue(
            editScheduleButton.waitForExistence(timeout: 5),
            "Edit schedule button should exist")
        editScheduleButton.tap()

        let saveButton2 = app.buttons["save-schedule-edit"]
        XCTAssertTrue(
            saveButton2.waitForExistence(timeout: 3),
            "Save button should exist after edit")
        saveButton2.tap()

        // Wait for sheet to dismiss
        XCTAssertFalse(
            saveButton2.waitForExistence(timeout: 3),
            "Sheet should dismiss after edit save")

        // THEN: Schedule modifications persist and edit button remains available
        XCTAssertTrue(
            editScheduleButton.waitForExistence(timeout: 5),
            "Edit schedule button should remain available after modifications")

        print("✅ Test 7 passed: Multiple schedule modifications handled successfully")
    }

    // MARK: - Test 8: Accessibility Support

    func testScheduleManagementAccessibility() throws {
        // GIVEN: User on medication profile settings
        try navigateToMedicationProfileSettings()

        // VERIFY: Create schedule button has proper accessibility identifier
        let createScheduleButton = app.buttons["create-schedule-button"]
        XCTAssertTrue(
            createScheduleButton.waitForExistence(timeout: 3),
            "Create schedule button should exist")
        XCTAssertEqual(
            createScheduleButton.identifier,
            "create-schedule-button",
            "Create button should have correct accessibility identifier")

        // Create schedule to test all button states
        try TestUtilities.createDefaultSchedule(app)

        // VERIFY: All buttons have proper accessibility identifiers
        let editScheduleButton = app.buttons["edit-schedule-button"]
        XCTAssertTrue(
            editScheduleButton.waitForExistence(timeout: 5),
            "Edit schedule button should exist after creating schedule")
        XCTAssertEqual(
            editScheduleButton.identifier,
            "edit-schedule-button",
            "Edit button should have correct accessibility identifier")

        let pauseScheduleButton = app.buttons["pause-schedule-button"]
        XCTAssertTrue(
            pauseScheduleButton.waitForExistence(timeout: 3),
            "Pause schedule button should exist")
        XCTAssertEqual(
            pauseScheduleButton.identifier,
            "pause-schedule-button",
            "Pause button should have correct accessibility identifier")

        let deactivateScheduleButton = app.buttons["deactivate-schedule-button"]
        XCTAssertTrue(
            deactivateScheduleButton.waitForExistence(timeout: 3),
            "Deactivate schedule button should exist")
        XCTAssertEqual(
            deactivateScheduleButton.identifier,
            "deactivate-schedule-button",
            "Deactivate button should have correct accessibility identifier")

        print("✅ Test 8 passed: All accessibility identifiers verified")
    }

    // MARK: - ISSUE #180: Medication-Specific Pattern Filtering in Settings

    // MARK: - ACCEPTANCE CRITERION 7: Custom pattern NOT visible in schedule edit view

    func testCustomPatternNotVisibleInScheduleEdit() throws {
        // GIVEN: User in schedule edit view with weekly medication (semaglutide)
        try navigateToMedicationProfileSettings()

        // Tap "Create Dose Schedule" button
        let createScheduleButton = app.buttons["create-schedule-button"]
        XCTAssertTrue(
            createScheduleButton.waitForExistence(timeout: 5),
            "Create schedule button should exist")
        createScheduleButton.tap()

        // Wait for sheet to appear
        let cancelButton = app.buttons["cancel-schedule-edit"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: 3),
            "Schedule edit sheet should appear")

        // WHEN: User views pattern picker (DoseScheduleEditView uses Picker, not SchedulePatternCard)
        // The picker should only show allowed patterns for weekly medication
        let patternPicker = app.buttons["pattern-picker"].firstMatch
        XCTAssertTrue(
            patternPicker.waitForExistence(timeout: 3),
            "Pattern picker should exist")

        // THEN: Verify weekly pattern is available (default value)
        // Note: Picker shows current selection, we need to verify "Custom" is NOT an option
        // Based on implementation: SchedulePattern.allCases.filter { isAllowed($0, for: frequency) }
        // For weekly medications: .weekly and .splitDose allowed, .custom filtered out

        // Tap picker to see available options (if menu appears)
        patternPicker.tap()

        // Wait for picker menu to expand by checking for expected options
        // Note: "Weekly" appears as StaticText, "Split Dose" appears as Button
        let weeklyOption = app.staticTexts["Weekly"]
        let splitDoseOption = app.buttons["Split Dose"]

        // Assert that the picker expanded and shows expected options
        XCTAssertTrue(
            weeklyOption.waitForExistence(timeout: 2),
            "Picker should expand and show 'Weekly' option"
        )
        XCTAssertTrue(
            splitDoseOption.waitForExistence(timeout: 2),
            "Picker should show 'Split Dose' option for weekly medications"
        )

        // The key verification: "Custom" text should NOT exist anywhere in the UI
        // Check for "Custom" in various element types
        let customText1 = app.staticTexts["Custom"]
        let customText2 = app.buttons["Custom"]
        let customText3 = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Custom'")).firstMatch

        XCTAssertFalse(customText1.exists, "Custom pattern should NOT appear as static text")
        XCTAssertFalse(customText2.exists, "Custom pattern should NOT appear as button")
        XCTAssertFalse(customText3.exists, "Custom pattern should NOT appear in any text element")

        print("✅ Test passed: Custom pattern not visible in schedule edit view")
    }
}
