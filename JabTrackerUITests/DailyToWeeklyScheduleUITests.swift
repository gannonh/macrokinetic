import XCTest

/// KAT-3612: a saved Daily schedule switched to Weekly starts at a 7-day interval and projects weekly doses.
final class DailyToWeeklyScheduleUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "7"
        app.launchEnvironment["TEST_DATA_DOSE_COUNT"] = "1"
        app.launchEnvironment["TEST_DATA_MEDICATION"] = "semaglutide"
        app.launchEnvironment["TEST_DATA_BRAND"] = "Ozempic"
        app.launchEnvironment["TEST_DATA_DOSE"] = "1.0"
        app.launchEnvironment["TEST_DATA_DAILY_SCHEDULE"] = "true"
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
    }

    override func tearDown() {
        if testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
        super.tearDown()
    }

    func testSwitchingDailyScheduleToWeeklyProjectsDosesSevenDaysApart() {
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        openScheduleEditor()
        evidence("daily-editor")
        XCTAssertFalse(app.staticTexts["1 day"].exists, "Daily has no interval stepper")

        let weekly = app.buttons["Weekly"]
        XCTAssertTrue(weekly.waitForExistence(timeout: 5))
        weekly.tap()
        XCTAssertTrue(app.staticTexts["7 days"].waitForExistence(timeout: 5), "Weekly starts at a 7-day interval")
        XCTAssertFalse(app.staticTexts["1 day"].exists)
        evidence("switched-to-weekly")
        app.buttons["save-schedule-edit"].tap()

        let edit = app.buttons["edit-schedule-button"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap()
        XCTAssertTrue(app.staticTexts["7 days"].waitForExistence(timeout: 5), "The saved schedule is weekly every 7 days")
        evidence("weekly-after-save")
        app.buttons["cancel-schedule-edit"].tap()

        // Next month on the dose calendar holds only projected doses: one every 7 days.
        TestUtilities.navigateToHistoryView(in: app)
        app.segmentedControls["history-view-mode-picker"].buttons["Calendar"].tap()
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: calendar.dateInterval(of: .month, for: Date())!.start)!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let today = app.descendants(matching: .any)["calendar-day-\(calendar.component(.day, from: Date()))"].firstMatch
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        XCTAssertTrue(today.label.hasSuffix("today, 1 logged"), "The past dose stays recorded: \(today.label)")
        let nextMonthButton = app.buttons.matching(NSPredicate(format: "label == 'Next month'")).firstMatch
        XCTAssertTrue(nextMonthButton.waitForExistence(timeout: 5))
        nextMonthButton.tap()
        let firstOfNextMonth = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'calendar-day-1' AND label BEGINSWITH %@", formatter.string(from: nextMonth)))
        XCTAssertTrue(firstOfNextMonth.firstMatch.waitForExistence(timeout: 5))
        let scheduledDays = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'calendar-day-' AND label CONTAINS 'scheduled'"))
        XCTAssertTrue(scheduledDays.firstMatch.waitForExistence(timeout: 5))
        evidence("next-month-calendar")
        let days = scheduledDays.allElementsBoundByIndex
            .compactMap { Int($0.identifier.replacingOccurrences(of: "calendar-day-", with: "")) }
            .sorted()
        XCTAssertGreaterThanOrEqual(days.count, 4, "Scheduled days: \(days)")
        XCTAssertLessThanOrEqual(days.count, 5, "Scheduled days: \(days)")
        XCTAssertEqual(zip(days, days.dropFirst()).map { $1 - $0 }, Array(repeating: 7, count: days.count - 1))
    }

    func testSwitchingWeeklyScheduleToDailyAndBackKeepsEachInterval() {
        app.launchEnvironment["TEST_DATA_DAILY_SCHEDULE"] = nil
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        openScheduleEditor()
        XCTAssertTrue(app.staticTexts["7 days"].waitForExistence(timeout: 5), "The seeded schedule is weekly")
        app.buttons["Daily"].tap()
        XCTAssertFalse(app.staticTexts["7 days"].exists, "Daily has no interval stepper")
        evidence("weekly-switched-to-daily")
        app.buttons["save-schedule-edit"].tap()

        // Next month on the dose calendar holds a projected dose every day.
        TestUtilities.navigateToHistoryView(in: app)
        app.segmentedControls["history-view-mode-picker"].buttons["Calendar"].tap()
        let nextMonthButton = app.buttons.matching(NSPredicate(format: "label == 'Next month'")).firstMatch
        XCTAssertTrue(nextMonthButton.waitForExistence(timeout: 5))
        nextMonthButton.tap()
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: calendar.dateInterval(of: .month, for: Date())!.start)!
        let dayCount = calendar.range(of: .day, in: .month, for: nextMonth)!.count
        let scheduledDays = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'calendar-day-' AND label CONTAINS 'scheduled'"))
        XCTAssertTrue(scheduledDays.firstMatch.waitForExistence(timeout: 5))
        evidence("daily-next-month-calendar")
        let days = scheduledDays.allElementsBoundByIndex
            .compactMap { Int($0.identifier.replacingOccurrences(of: "calendar-day-", with: "")) }
            .sorted()
        XCTAssertEqual(days, Array(1...dayCount))

        // Back to Weekly: the stepper starts at 7 days again.
        openScheduleEditor()
        app.buttons["Weekly"].tap()
        XCTAssertTrue(app.staticTexts["7 days"].waitForExistence(timeout: 5), "Weekly starts at a 7-day interval")
        evidence("daily-switched-back-to-weekly")
        app.buttons["cancel-schedule-edit"].tap()
    }

    private func openScheduleEditor() {
        TestUtilities.navigateToTab(app, tabName: "More")
        let programs = app.buttons["glp1-programs-row"]
        XCTAssertTrue(programs.waitForExistence(timeout: 10))
        programs.tap()
        let medications = app.buttons["Medications"]
        XCTAssertTrue(medications.waitForExistence(timeout: 10))
        medications.tap()
        let profile = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH 'medication-profile-semaglutide-ozempic-'"
        )).firstMatch
        XCTAssertTrue(profile.waitForExistence(timeout: 10))
        profile.tap()
        let edit = app.buttons["edit-schedule-button"]
        XCTAssertTrue(edit.waitForExistence(timeout: 10))
        edit.tap()
        XCTAssertTrue(app.buttons["cancel-schedule-edit"].waitForExistence(timeout: 5))
    }

    private func evidence(_ name: String) {
        TestUtilities.debugScreenshot(app, name: "daily-to-weekly-\(name)")
        print(app.debugDescription)
    }
}
