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
}
