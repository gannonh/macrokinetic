//
//  TestUtilities+Schedule.swift
//  JabTrackerUITests
//
//  Schedule-related test utilities for medication schedule management
//

import XCTest

// MARK: - Schedule Helpers

extension TestUtilities {
    /// Create a schedule for the open medication profile by choosing `pattern` and tapping Create.
    /// The launch editor preselects no pattern, so Create stays disabled until one is chosen.
    static func createDefaultSchedule(
        _ app: XCUIApplication, pattern: String = "Weekly", timeout: TimeInterval = 5
    ) throws {
        let createScheduleButton = app.buttons["create-schedule-button"]
        guard createScheduleButton.waitForExistence(timeout: timeout) else {
            debugScreenshot(app, name: "missing-create-schedule")
            print(app.debugDescription)
            XCTFail("Schedule already exists or view not ready")
            return
        }
        createScheduleButton.tap()

        let saveButton = app.buttons["save-schedule-edit"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: timeout), "Schedule editor should open")
        XCTAssertFalse(saveButton.isEnabled, "Create stays disabled until a pattern is chosen")
        let option = app.buttons[pattern]
        XCTAssertTrue(option.waitForExistence(timeout: timeout), "\(pattern) pattern should exist")
        option.tap()
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        XCTAssertTrue(saveButton.waitForNonExistence(timeout: timeout), "Editor should close after Create")
        XCTAssertTrue(app.buttons["edit-schedule-button"].waitForExistence(timeout: timeout))
    }
}
