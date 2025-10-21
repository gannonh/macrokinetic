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

    // MARK: - Test 1: Quick Add Dose Shows Correct Split-Dose Amount (Issue #180 Critical Bug Fix)

    func testQuickAddDoseShowsCorrectSplitDoseAmount() throws {
        // GIVEN: User with Semaglutide 1.0mg weekly split-dose schedule
        // Launch with 1.0mg dose so we can verify split shows 0.5mg
        app.launchEnvironment["TEST_DATA_DOSE"] = "1.0"  // Override setUp default
        app.launch()

        // Wait for app to load
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should appear after app launch")

        // Navigate to medication profile settings and create split-dose schedule
        // Note: Dose is formatted with 2 decimal places (1.00 not 1.0)
        TestUtilities.navigateToMedicationProfileSettings(
            app,
            profileIdentifier: "medication-profile-semaglutide-ozempic-1.00mg")
        try TestUtilities.createSplitDoseSchedule(app)

        // Navigate back to Home screen before using Quick Add
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 3), "Home tab should exist")
        homeTab.tap()

        // Wait for Home screen to load
        usleep(500_000)  // 0.5 seconds

        // WHEN: User taps Quick Add Dose button ("+" tab)
        let quickAddButton = app.tabBars.buttons["Add"]
        XCTAssertTrue(quickAddButton.waitForExistence(timeout: 3), "Quick Add button should exist")
        quickAddButton.tap()

        // Wait for sheet to appear
        usleep(1_000_000)  // 1 second for sheet animation

        // Wait for Quick Dose sheet to appear
        let quickDoseSheet = app.otherElements["quick-dose-sheet"]
        XCTAssertTrue(
            quickDoseSheet.waitForExistence(timeout: 3),
            "Quick Dose sheet should appear after tapping + button")

        // THEN: Dose amount shows 0.5mg (half of 1.0mg weekly dose)
        // QuickDoseEntry displays dose amount with accessibility identifier "quick-dose-amount"
        let doseAmountText = app.staticTexts["quick-dose-amount"]
        XCTAssertTrue(
            doseAmountText.waitForExistence(timeout: 3),
            "Dose amount should be displayed in Quick Dose sheet")

        let doseAmountValue = doseAmountText.label
        print("📊 Quick Dose shows: \(doseAmountValue)")

        // Verify it shows 0.50 mg (split-dose: 1.0mg / 2 = 0.5mg)
        XCTAssertTrue(
            doseAmountValue.contains("0.50") || doseAmountValue.contains("0.5"),
            "Split-dose should show 0.5mg (half of 1.0mg weekly dose), but showed: \(doseAmountValue)")

        XCTAssertFalse(
            doseAmountValue.contains("1.0") || doseAmountValue.contains("1.00"),
            "Split-dose should NOT show full 1.0mg dose (would cause overdose), but showed: \(doseAmountValue)")

        print("✅ Test 1 passed: Quick Add Dose correctly shows 0.5mg for split-dose (1.0mg weekly split)")
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
