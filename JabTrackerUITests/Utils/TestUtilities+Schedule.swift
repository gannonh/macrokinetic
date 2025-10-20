//
//  TestUtilities+Schedule.swift
//  JabTrackerUITests
//
//  Schedule-related test utilities for medication schedule management
//

import XCTest

// MARK: - Schedule Helpers

extension TestUtilities {
    /// Create a default schedule for the current medication profile
    ///
    /// This helper creates a schedule using default settings (weekly pattern)
    /// by tapping the Create Schedule button and saving with defaults.
    /// Used to reduce duplication across schedule management tests.
    ///
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - timeout: Maximum time to wait for UI elements (default: 3 seconds)
    /// - Throws: XCTestError if schedule creation fails
    ///
    /// ## Usage
    /// ```swift
    /// func testEditExistingSchedule() throws {
    ///     try navigateToMedicationProfileSettings()
    ///     try TestUtilities.createDefaultSchedule(app)
    ///     // ... continue with edit schedule test
    /// }
    /// ```
    static func createDefaultSchedule(_ app: XCUIApplication, timeout: TimeInterval = 3) throws {
        let createScheduleButton = app.buttons["create-schedule-button"]
        guard createScheduleButton.waitForExistence(timeout: timeout) else {
            XCTFail("Schedule already exists or view not ready")
            return
        }
        createScheduleButton.tap()

        let saveButton = app.buttons["save-schedule-edit"]
        XCTAssertTrue(
            saveButton.waitForExistence(timeout: timeout),
            "Save button should exist in schedule edit sheet")
        saveButton.tap()

        XCTAssertFalse(
            saveButton.waitForExistence(timeout: timeout),
            "Sheet should dismiss after saving schedule")
    }

    /// Create a split-dose schedule for the current medication profile
    ///
    /// This helper creates a split-dose schedule (twice-weekly pattern)
    /// by tapping the Create Schedule button, selecting split-dose pattern, and saving.
    /// Used for testing split-dose functionality across different views.
    ///
    /// - Parameters:
    ///   - app: The XCUIApplication instance
    ///   - timeout: Maximum time to wait for UI elements (default: 3 seconds)
    /// - Throws: XCTestError if schedule creation fails
    ///
    /// ## Usage
    /// ```swift
    /// func testCalendarShowsSplitDose() throws {
    ///     try navigateToMedicationProfileSettings()
    ///     try TestUtilities.createSplitDoseSchedule(app)
    ///     // ... continue with calendar test
    /// }
    /// ```
    static func createSplitDoseSchedule(_ app: XCUIApplication, timeout: TimeInterval = 3) throws {
        let createScheduleButton = app.buttons["create-schedule-button"]
        guard createScheduleButton.waitForExistence(timeout: timeout) else {
            XCTFail("Schedule already exists or view not ready")
            return
        }
        createScheduleButton.tap()

        // Wait for schedule edit sheet to appear
        let cancelButton = app.buttons["cancel-schedule-edit"]
        XCTAssertTrue(
            cancelButton.waitForExistence(timeout: timeout),
            "Schedule edit sheet should appear")

        // Select split-dose pattern (inline picker - tap the row directly)
        let splitDoseOption = app.buttons["Split Dose"]
        XCTAssertTrue(
            splitDoseOption.waitForExistence(timeout: timeout),
            "Split Dose option should exist in pattern picker")
        splitDoseOption.tap()

        // Save the schedule
        let saveButton = app.buttons["save-schedule-edit"]
        XCTAssertTrue(
            saveButton.waitForExistence(timeout: timeout),
            "Save button should exist in schedule edit sheet")
        saveButton.tap()

        // Verify sheet dismisses
        XCTAssertFalse(
            saveButton.waitForExistence(timeout: timeout),
            "Sheet should dismiss after saving schedule")
    }
}
