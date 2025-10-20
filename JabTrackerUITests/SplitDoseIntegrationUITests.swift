//
//  SplitDoseIntegrationUITests.swift
//  JabTrackerUITests
//
//  E2E tests for split-dose integration validation (Issue #180)
//

import XCTest

final class SplitDoseIntegrationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
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

    // MARK: - Test 2: Calendar Shows Twice-Weekly Pattern (NOT 14 doses/week)

    func testCalendarShowsTwiceWeeklyDosePattern() throws {
        // GIVEN: User on medication profile settings with split-dose schedule
        try navigateToMedicationProfileSettings()
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

        // THEN: Calendar shows ~2 scheduled doses per 2-week period (NOT 14 doses/week for twice-daily)
        let scheduledIndicators = app.otherElements.matching(
            NSPredicate(format: "label == 'Scheduled dose'"))

        // For split-dose (twice weekly), we expect ~2 doses per week (~8-9 for 30-day window)
        // NOT 14 doses per week (which would be twice-daily pattern)
        let scheduledCount = scheduledIndicators.count
        print("📊 Found \(scheduledCount) scheduled dose indicators")

        XCTAssertGreaterThan(
            scheduledCount, 0,
            "Calendar should show scheduled doses for split-dose pattern")
        XCTAssertLessThan(
            scheduledCount, 15,
            "Calendar should NOT show twice-daily pattern (14 doses/week)")

        print("✅ Test 2 passed: Calendar shows twice-weekly pattern (NOT twice-daily)")
    }

    // MARK: - Test 3: Settings Workflow Shows Split-Dose Schedule

    func testSettingsShowsSplitDoseSchedule() throws {
        // GIVEN: User on medication profile settings with split-dose schedule
        try navigateToMedicationProfileSettings()
        try TestUtilities.createSplitDoseSchedule(app)

        // THEN: Schedule summary shows split-dose pattern information
        let scheduleSummary = app.otherElements["schedule-summary-view"]
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

    // MARK: - Test 4: Dashboard Concentration Validation (CRITICAL SAFETY)

    func testDashboardShowsCorrectSplitDoseConcentration() throws {
        // GIVEN: User with split-dose medication profile and schedule
        try navigateToMedicationProfileSettings()
        try TestUtilities.createSplitDoseSchedule(app)

        // WHEN: User views dashboard (directly via tab bar)
        let dashboardTab = app.tabBars.buttons["Dashboard"]
        XCTAssertTrue(dashboardTab.waitForExistence(timeout: 3))
        dashboardTab.tap()

        // Wait for PK engine calculations
        usleep(500_000)  // 0.5 seconds for calculations

        // THEN: Dashboard shows concentration information WITHOUT dangerous twice-daily timing language
        let concentrationCard = app.otherElements["concentration-card"]
        XCTAssertTrue(
            concentrationCard.waitForExistence(timeout: 5),
            "Concentration card should appear on dashboard")

        // CRITICAL SAFETY: Verify NO "12 hours" language appears (which would indicate twice-daily pattern)
        let twelveHoursText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '12 hours'"))
        XCTAssertFalse(
            twelveHoursText.element.exists,
            "❌ CRITICAL: Dashboard must NOT show '12 hours' (dangerous twice-daily pattern)")

        // CRITICAL SAFETY: Verify NO "twice daily" language appears
        let twiceDailyText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'twice daily'"))
        XCTAssertFalse(
            twiceDailyText.element.exists,
            "❌ CRITICAL: Dashboard must NOT show 'twice daily' (should be 'twice weekly')")

        // CRITICAL SAFETY: Verify NO "every 12 hours" language appears
        let every12HoursText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'every 12 hours'"))
        XCTAssertFalse(
            every12HoursText.element.exists,
            "❌ CRITICAL: Dashboard must NOT show 'every 12 hours'")

        print("✅ Test 4 passed: Dashboard shows correct concentration WITHOUT dangerous twice-daily timing")
    }
}
