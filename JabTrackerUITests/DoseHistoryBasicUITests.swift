//
//  DoseHistoryBasicUITests.swift
//  JabTrackerUITests
//
//  Basic Dose History Display and Edit Tests
//  Tests for chronological ordering and basic edit functionality
//

import XCTest

final class DoseHistoryBasicUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Basic Display and Edit Actions

    @MainActor
    func test_doseHistory_displaysInReverseChronologicalOrder() throws {
        let today = Date()
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 3)
        TestUtilities.navigateToHistoryView(in: app)
        let doseRows = TestUtilities.getDoseRows(from: app, minimumCount: 3)
        XCTAssertEqual(doseRows.count, 3)
        XCTAssertTrue(app.staticTexts["3 of 3 doses shown"].exists)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let expectedDates = [0, 7, 14].map { daysAgo in
            formatter.string(from: Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!)
        }
        XCTAssertEqual(
            app.staticTexts.matching(identifier: "dose-date-section-header")
                .allElementsBoundByIndex.map(\.label), expectedDates)
        for row in doseRows.allElementsBoundByIndex {
            XCTAssertEqual(row.staticTexts["dose-amount"].label, "0.25 mg")
            XCTAssertEqual(row.staticTexts["dose-medication"].label, "Ozempic")
        }
        XCTAssertEqual(doseRows.element(boundBy: 0).staticTexts["injection-site"].label, "Abdomen")
        XCTAssertEqual(doseRows.element(boundBy: 1).staticTexts["injection-site"].label, "Thigh")
        XCTAssertEqual(doseRows.element(boundBy: 2).staticTexts["injection-site"].label, "Abdomen")
    }

    func test_doseHistory_swipeActionsEditDose() throws {
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 1)
        TestUtilities.navigateToHistoryView(in: app)
        let original = TestUtilities.getDoseRows(from: app).firstMatch
        XCTAssertEqual(original.staticTexts["dose-amount"].label, "0.25 mg")
        XCTAssertEqual(original.staticTexts["dose-medication"].label, "Ozempic")
        XCTAssertEqual(original.staticTexts["injection-site"].label, "Abdomen")
        let originalTime = original.staticTexts["dose-timestamp"].label
        let originalDate = app.staticTexts.matching(identifier: "dose-date-section-header").firstMatch.label

        original.swipeLeft()
        let edit = app.buttons["Edit"]
        XCTAssertTrue(edit.waitForExistence(timeout: 3))
        edit.tap()
        let sheet = app.navigationBars["Edit Dose"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["quick-dose-medication-picker"].staticTexts["Ozempic (0.25 mg)"].exists)
        let amount = app.textFields["quick-dose-prescribed-amount-input"]
        TestUtilities.debugScreenshot(app, name: "history-prescribed-amount-prepopulation")
        print(app.debugDescription)
        XCTAssertTrue(amount.exists)
        XCTAssertEqual(amount.value as? String, "0.25")
        XCTAssertTrue(app.datePickers["quick-dose-datetime-picker"].buttons[originalDate].exists)
        XCTAssertTrue(app.datePickers["quick-dose-datetime-picker"].buttons[originalTime].exists)

        TestUtilities.replaceHistoryPrescribedAmount(
            in: app, with: "0.50", evidenceName: "history-save-prescribed-amount-edit")
        let notes = app.textFields["quick-dose-notes"]
        notes.tap()
        notes.typeText("History edit persistence")
        let save = app.buttons["quick-dose-save-button"]
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5))
        TestUtilities.debugScreenshot(app, name: "history-edited-dose")
        print(app.debugDescription)

        let expectedLabel = "0.50 milligrams, Ozempic, at \(originalTime), injection site Abdomen, with notes"
        let updated = TestUtilities.getDoseRows(from: app)
        XCTAssertEqual(updated.count, 1)
        XCTAssertEqual(updated.firstMatch.label, expectedLabel)
        XCTAssertEqual(updated.firstMatch.staticTexts["dose-amount"].label, "0.50 mg")
        XCTAssertTrue(updated.firstMatch.staticTexts["History edit persistence"].exists)
        XCTAssertEqual(
            app.staticTexts.matching(identifier: "dose-date-section-header").firstMatch.label,
            originalDate)

        app.terminate()
        let relaunched = TestUtilities.launchAppWithTestMode(resetData: false)
        TestUtilities.navigateToHistoryView(in: relaunched)
        let persisted = TestUtilities.getDoseRows(from: relaunched)
        XCTAssertEqual(persisted.count, 1)
        XCTAssertEqual(persisted.firstMatch.label, expectedLabel)
        XCTAssertEqual(persisted.firstMatch.staticTexts["dose-amount"].label, "0.50 mg")
        XCTAssertTrue(persisted.firstMatch.staticTexts["History edit persistence"].exists)
        XCTAssertEqual(
            relaunched.staticTexts.matching(identifier: "dose-date-section-header").firstMatch.label,
            originalDate)
    }

    func test_doseHistory_searchMatchesMedicationName() throws {
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 2)
        TestUtilities.navigateToHistoryView(in: app)
        let search = app.textFields["history-section"]
        XCTAssertTrue(search.exists)
        search.tap()
        search.typeText("Ozempic")
        XCTAssertTrue(app.staticTexts["2 of 2 doses shown"].waitForExistence(timeout: 5))
        let matches = TestUtilities.getDoseRows(from: app, minimumCount: 2)
        XCTAssertEqual(matches.count, 2)
        for row in matches.allElementsBoundByIndex {
            XCTAssertEqual(row.staticTexts["dose-amount"].label, "0.25 mg")
            XCTAssertEqual(row.staticTexts["dose-medication"].label, "Ozempic")
        }

        app.buttons["Clear text"].tap()
        search.tap()
        search.typeText("Mounjaro")
        let noMatches = app.staticTexts["0 of 2 doses shown"]
        if !noMatches.waitForExistence(timeout: 5) {
            TestUtilities.debugScreenshot(app, name: "history-search-no-matches")
            print(app.debugDescription)
            XCTFail("Searching for Mounjaro should match none of the Ozempic doses")
        }
        XCTAssertEqual(app.buttons.matching(identifier: "dose-history-row").count, 0)
        XCTAssertTrue(app.staticTexts["No doses match your current filters."].exists)
        XCTAssertFalse(app.buttons["Log Your First Dose"].exists)

        app.buttons["Clear text"].tap()
        XCTAssertTrue(app.staticTexts["2 of 2 doses shown"].waitForExistence(timeout: 5))
        XCTAssertEqual(TestUtilities.getDoseRows(from: app, minimumCount: 2).count, 2)
    }
}
