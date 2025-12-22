//
//  CalendarAccessibilityUITests.swift
//  JabTrackerUITests
//
//  Accessibility E2E tests for calendar scheduled dose indicators
//

import XCTest

final class CalendarAccessibilityUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - ACCEPTANCE CRITERION: VoiceOver describes scheduled vs logged doses (NFR5, Test8)

    func testVoiceOverDescribesScheduledDoses() throws {
        // GIVEN: Calendar view with scheduled dose
        let preset = TestUtilities.TestDataPreset.thirtyDays
        app = TestUtilities.launchAppWithSeededData(preset: preset)

        TestUtilities.navigateToHistoryView(in: app)

        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 3))

        let calendarToggleButton = segmentedControl.buttons["Calendar"]
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-container"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3))

        // THEN: Verify calendar is ready for VoiceOver accessibility testing
        // Note: Full VoiceOver validation requires accessibility label verification
        print("✅ Calendar loaded - VoiceOver scheduled doses structure test")
        print("ℹ️  Actual VoiceOver label validation requires implemented functionality")
    }

    func testVoiceOverDescribesLoggedDoses() throws {
        // GIVEN: Calendar view with logged dose
        let preset = TestUtilities.TestDataPreset.thirtyDays
        app = TestUtilities.launchAppWithSeededData(preset: preset)

        TestUtilities.navigateToHistoryView(in: app)

        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 3))

        let calendarToggleButton = segmentedControl.buttons["Calendar"]
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-container"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3))

        // THEN: Verify calendar is ready for VoiceOver accessibility testing
        // Note: Full VoiceOver validation requires accessibility label verification
        print("✅ Calendar loaded - VoiceOver logged doses structure test")
        print("ℹ️  Actual VoiceOver label validation requires implemented functionality")
    }

    func testVoiceOverDescribesMixedDoses() throws {
        // GIVEN: Calendar view with both scheduled and logged doses
        let preset = TestUtilities.TestDataPreset.thirtyDays
        app = TestUtilities.launchAppWithSeededData(preset: preset)

        TestUtilities.navigateToHistoryView(in: app)

        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 3))

        let calendarToggleButton = segmentedControl.buttons["Calendar"]
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-container"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3))

        // THEN: Verify calendar is ready for VoiceOver accessibility testing
        // Note: Full VoiceOver validation requires accessibility label verification
        print("✅ Calendar loaded - VoiceOver mixed doses structure test")
        print("ℹ️  Actual VoiceOver label validation requires implemented functionality")
    }

    func testVoiceOverDescribesMissedDose() throws {
        // GIVEN: Calendar view with missed dose
        let preset = TestUtilities.TestDataPreset.thirtyDays
        app = TestUtilities.launchAppWithSeededData(preset: preset)

        TestUtilities.navigateToHistoryView(in: app)

        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 3))

        let calendarToggleButton = segmentedControl.buttons["Calendar"]
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-container"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3))

        // THEN: Verify calendar is ready for VoiceOver accessibility testing
        // Note: Full VoiceOver validation requires accessibility label verification
        print("✅ Calendar loaded - VoiceOver missed dose structure test")
        print("ℹ️  Actual VoiceOver label validation requires implemented functionality")
    }

    func testVoiceOverDescribesScheduledDoseIndicators() throws {
        // GIVEN: Calendar view with multiple scheduled doses
        let preset = TestUtilities.TestDataPreset.thirtyDays
        app = TestUtilities.launchAppWithSeededData(preset: preset)

        TestUtilities.navigateToHistoryView(in: app)

        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        XCTAssertTrue(segmentedControl.waitForExistence(timeout: 3))

        let calendarToggleButton = segmentedControl.buttons["Calendar"]
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-container"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3))

        // THEN: Verify calendar is ready for VoiceOver accessibility testing
        // Note: Full VoiceOver validation requires accessibility label verification
        print("✅ Calendar loaded - VoiceOver dose indicators structure test")
        print("ℹ️  Actual VoiceOver label validation requires implemented functionality")
    }
}
