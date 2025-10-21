//
//  SplitDoseIntegrationUITests.swift
//  JabTrackerUITests
//
//  E2E tests for split-dose integration validation (Issue #180)
//

import XCTest

final class SplitDoseIntegrationUITests: XCTestCase {
    var app: XCUIApplication!
    var screenshotCapture: ScreenshotCapture!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        screenshotCapture = ScreenshotCapture(app: app, testCase: self, phase: "split-dose-integration")

        // Pre-seed with medication profile (no schedule yet)
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "0"
        app.launchEnvironment["TEST_DATA_MEDICATION"] = "semaglutide"
        app.launchEnvironment["TEST_DATA_BRAND"] = "Ozempic"
        app.launchEnvironment["TEST_DATA_DOSE"] = "0.25"
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Test 2: Calendar Shows Twice-Weekly Pattern (NOT 14 doses/week)

    func testCalendarShowsTwiceWeeklyDosePattern() throws {
        // GIVEN: User on medication profile settings with split-dose schedule
        app.launch()

        // Wait for app to load
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should appear after app launch")

        TestUtilities.navigateToMedicationProfileSettings(app)
        try TestUtilities.createSplitDoseSchedule(app)

        // WHEN: User navigates to History tab calendar view (directly via tab bar)
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 3))
        historyTab.tap()

        let segmentedControl = app.segmentedControls["history-view-mode-picker"]
        XCTAssertTrue(
            segmentedControl.waitForExistence(timeout: 3),
            "View mode picker should be available")

        let calendarToggleButton = segmentedControl.buttons["history-calendar-toggle"]
        XCTAssertTrue(calendarToggleButton.exists, "Calendar toggle should be available")
        calendarToggleButton.tap()

        let calendarView = app.descendants(matching: .any)["dose-calendar-view"]
        XCTAssertTrue(calendarView.waitForExistence(timeout: 3), "Calendar view should appear")

        // Wait for scheduled doses to be generated and displayed
        usleep(500_000)  // 0.5 seconds for dose generation

        // THEN: Calendar shows scheduled dose indicators with correct counts
        // DoseIndicatorsView has accessibility labels like "1 scheduled", "2 scheduled", etc.
        let indicatorsWithScheduled = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS 'scheduled'"))

        // For split-dose (twice weekly), we expect ~8-9 scheduled doses for 30-day window
        // Each day with scheduled dose(s) has DoseIndicatorsView with label containing "scheduled"
        let scheduledDaysCount = indicatorsWithScheduled.count
        print("📊 Found \(scheduledDaysCount) calendar days with scheduled doses")

        XCTAssertGreaterThan(
            scheduledDaysCount, 0,
            "Calendar should show scheduled doses for split-dose pattern")
        XCTAssertLessThan(
            scheduledDaysCount, 15,
            "Calendar should NOT show twice-daily pattern (14+ days with doses)")

        print("✅ Test 2 passed: Calendar shows twice-weekly pattern (NOT twice-daily)")
    }

    // MARK: - Test 3: Settings Workflow Shows Split-Dose Schedule

    func testSettingsShowsSplitDoseSchedule() throws {
        // GIVEN: User on medication profile settings with split-dose schedule
        app.launch()

        // Wait for app to load
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should appear after app launch")

        TestUtilities.navigateToMedicationProfileSettings(app)
        try TestUtilities.createSplitDoseSchedule(app)

        // THEN: Schedule summary shows split-dose pattern information
        // Note: ScheduleSummaryView renders as StaticText in accessibility hierarchy
        let scheduleSummary = app.staticTexts["schedule-summary-view"]
        XCTAssertTrue(
            scheduleSummary.waitForExistence(timeout: 5),
            "Schedule summary should appear in medication profile settings")

        // Verify edit schedule button exists (confirms schedule is active)
        let editScheduleButton = app.buttons["edit-schedule-button"]
        XCTAssertTrue(
            editScheduleButton.waitForExistence(timeout: 3),
            "Edit schedule button should exist for active split-dose schedule")

        print("✅ Test 3 passed: Settings workflow displays split-dose schedule")
    }

}
