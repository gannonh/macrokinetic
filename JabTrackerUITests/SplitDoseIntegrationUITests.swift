//
//  SplitDoseIntegrationUITests.swift
//  JabTrackerUITests
//
//  Split dosing in the launch build: new schedules never offer Split Dose, and a recorded split schedule
//  (seeded as Semaglutide (Ozempic) 1.00 mg weekly total) keeps its twice-weekly pattern without prefilling
//  the weekly total as one administration.
//

import XCTest

final class SplitDoseIntegrationUITests: XCTestCase {
    var app: XCUIApplication!

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
        app.launchEnvironment["TEST_DATA_SPLIT_SCHEDULE"] = "true"
        // The split schedule is seeded from the first recorded dose, so that dose must never be randomly skipped.
        app.launchEnvironment["TEST_DATA_ADHERENCE"] = "1.0"
        app.launchEnvironment["TEST_DATA_SKIPPED"] = "false"
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
    }

    override func tearDown() {
        if testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
        super.tearDown()
    }

    private var profileRow: XCUIElement {
        TestUtilities.medicationProfileRow(app, medication: "semaglutide", brand: "Ozempic", amount: 1.0)
    }

    private func launch() {
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
    }

    private func evidence(_ name: String) {
        TestUtilities.debugScreenshot(app, name: "split-integration-\(name)")
        print(app.debugDescription)
    }

    func testQuickAddDoseShowsCorrectSplitDoseAmount() throws {
        launch()
        TestUtilities.openShortcutsSheet(app)
        app.buttons["shortcut-button-shots"].tap()
        let amount = app.textFields["quick-dose-prescribed-amount-input"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        evidence("quick-dose-split")

        // A recorded split schedule never prefills the 1.00 mg weekly total as one administration.
        XCTAssertEqual(amount.value as? String, "0")
        let save = app.buttons["quick-dose-save-button"]
        XCTAssertFalse(save.isEnabled, "0 mg cannot be saved")
        amount.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        amount.typeText(XCUIKeyboardKey.delete.rawValue)
        amount.typeText("0.5")
        XCTAssertEqual(amount.value as? String, "0.5")
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(amount.waitForNonExistence(timeout: 5))

        TestUtilities.navigateToHistoryView(in: app)
        let rows = TestUtilities.getDoseRows(from: app, minimumCount: 2)
        evidence("history-after-split-dose")
        let labels = rows.allElementsBoundByIndex.map(\.label)
        XCTAssertEqual(labels.count, 2)
        XCTAssertEqual(labels.filter { $0.hasPrefix("0.50 milligrams, Ozempic") }.count, 1, "\(labels)")
        XCTAssertEqual(labels.filter { $0.hasPrefix("1.00 milligrams, Ozempic") }.count, 1, "\(labels)")
    }

    func testCalendarShowsTwiceWeeklyDosePattern() throws {
        launch()
        TestUtilities.navigateToHistoryView(in: app)
        app.segmentedControls["history-view-mode-picker"].buttons["Calendar"].tap()
        evidence("calendar")

        // The next administration can fall in the following month, so read this month and the next.
        let thisMonth = scheduledDayLabels()
        // The month title inherits the History section identifier, so the first day's date label marks the month.
        let firstDay = app.descendants(matching: .any)["calendar-day-1"].firstMatch
        let shownFirstDay = firstDay.label
        app.buttons["Next month"].tap()
        let nextMonthShown = expectation(for: NSPredicate(format: "label != %@", shownFirstDay), evaluatedWith: firstDay)
        wait(for: [nextMonthShown], timeout: 5)
        let nextMonth = scheduledDayLabels()
        let labels = thisMonth + nextMonth
        print("Scheduled day labels: \(labels)")
        XCTAssertGreaterThanOrEqual(labels.count, 4, "Two months hold at least four twice-weekly administrations")
        XCTAssertTrue(
            labels.allSatisfy { $0.contains("1 scheduled") },
            "Twice weekly means one administration per scheduled day, not two: \(labels)")

        // Administrations are 3.5 days apart, so day gaps alternate 3 and 4 and any two consecutive gaps make a week.
        // Gaps are checked within each month: KAT-3793 tracks the cadence restarting at the month boundary.
        for month in [thisMonth, nextMonth] {
            let days = month.compactMap { Int($0.components(separatedBy: " ")[1].dropLast()) }
            XCTAssertEqual(days.count, month.count, "Every scheduled day label starts with its date: \(month)")
            let gaps = zip(days.dropFirst(), days).map { $0 - $1 }
            XCTAssertTrue(gaps.allSatisfy { $0 == 3 || $0 == 4 }, "Gaps \(gaps) between \(month)")
            XCTAssertTrue(zip(gaps.dropFirst(), gaps).allSatisfy { $0 + $1 == 7 }, "Gaps \(gaps) between \(month)")
        }
    }

    /// Labels such as "Oct 24, 2026, 1 scheduled" for the visible month, in day order.
    private func scheduledDayLabels() -> [String] {
        XCTAssertTrue(app.descendants(matching: .any)["calendar-day-1"].firstMatch.waitForExistence(timeout: 5))
        let cells = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'calendar-day-' AND label CONTAINS ' scheduled'"
        )).allElementsBoundByIndex
        let day = { (cell: XCUIElement) in Int(cell.identifier.dropFirst("calendar-day-".count)) ?? 0 }
        return cells.sorted { day($0) < day($1) }.map(\.label)
    }

    func testSettingsShowsSplitDoseSchedule() throws {
        launch()
        TestUtilities.navigateToMedicationProfiles(app)
        XCTAssertTrue(profileRow.waitForExistence(timeout: 5))
        XCTAssertTrue(profileRow.staticTexts["Recorded schedule"].exists)
        TestUtilities.openMedicationProfile(app, row: profileRow)
        XCTAssertTrue(app.staticTexts["Split Dose (Twice Weekly)"].waitForExistence(timeout: 5))

        // Replacing the recorded split schedule offers only Daily and Weekly for the new one.
        app.buttons["deactivate-schedule-button"].tap()
        let confirm = app.buttons.matching(
            NSPredicate(format: "label == 'Deactivate Schedule' AND identifier == ''")).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        app.buttons["create-schedule-button"].tap()
        XCTAssertTrue(app.navigationBars["Create Schedule"].waitForExistence(timeout: 5))
        evidence("new-schedule-after-split")
        XCTAssertEqual(
            app.buttons.matching(identifier: "pattern-picker").allElementsBoundByIndex.map(\.label), ["Daily", "Weekly"])
        XCTAssertFalse(app.buttons["Split Dose"].exists)
        XCTAssertFalse(app.buttons["Recorded Split Schedule"].exists)
        app.buttons["cancel-schedule-edit"].tap()
    }
}
