//
//  DoseHistoryStatesUITests.swift
//  JabTrackerUITests
//
//  Dose History States and Advanced Features Tests
//  Tests for empty states, date sections, accessibility, visual indicators, and performance
//

import XCTest

final class DoseHistoryStatesUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Empty States and Advanced Features

    func test_doseHistory_showsEmptyStateWhenNoDoses() throws {
        // GIVEN: No doses exist (fresh app state from reset-app-data)
        let app = TestUtilities.launchAppWithTestMode()

        // Don't create any doses - start with empty state
        // Just launch app and navigate to History

        // WHEN: User navigates to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // THEN: Empty state is displayed with helpful message
        XCTAssertTrue(app.staticTexts["No doses logged yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.staticTexts["Start tracking your medication doses to see your history here."].exists)
        XCTAssertTrue(app.buttons["Log Your First Dose"].exists)

        // Verify no dose rows exist separately
        let doseRows = app.buttons.matching(identifier: "dose-history-row")
        XCTAssertEqual(doseRows.count, 0, "No dose rows should exist in empty state")

        XCTAssertTrue(app.segmentedControls["analytics-section-picker"].buttons["History"].isSelected)
        XCTAssertTrue(app.segmentedControls["history-view-mode-picker"].buttons["List"].isSelected)
    }

    func test_doseHistory_addFirstDose() throws {
        var environment = TestUtilities.TestDataPreset.custom(doseCount: 0).launchEnvironment
        environment["TEST_DATA_DAYS"] = "1" // Seed the medication profile without any doses.
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--bypass-onboarding"],
            additionalEnvironment: environment)
        TestUtilities.navigateToHistoryView(in: app)
        XCTAssertTrue(app.staticTexts["No doses logged yet"].exists)
        XCTAssertTrue(
            app.staticTexts["Start tracking your medication doses to see your history here."].exists)
        XCTAssertEqual(app.buttons.matching(identifier: "dose-history-row").count, 0)

        app.buttons["Log Your First Dose"].tap()
        let sheet = app.navigationBars["Quick Add Dose"]
        let sheetAppeared = sheet.waitForExistence(timeout: 5)
        TestUtilities.debugScreenshot(app, name: "history-first-dose-form")
        print(app.debugDescription)
        XCTAssertTrue(sheetAppeared)
        XCTAssertTrue(app.buttons["quick-dose-medication-picker"].staticTexts["Ozempic (0.25 mg)"].exists)
        let amount = app.textFields["quick-dose-prescribed-amount-input"]
        XCTAssertTrue(amount.exists)
        XCTAssertEqual(amount.value as? String, "0.25")
        XCTAssertTrue(app.buttons["quick-dose-site-picker"].staticTexts["Thigh"].exists)
        let datePicker = app.datePickers["quick-dose-datetime-picker"]
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let expectedDate = formatter.string(from: Date())
        XCTAssertTrue(datePicker.buttons[expectedDate].exists)
        let expectedTime = datePicker.buttons["Date and Time Picker"].buttons.element(boundBy: 1).label
        XCTAssertFalse(expectedTime.isEmpty)

        let save = app.buttons["quick-dose-save-button"]
        TestUtilities.replaceHistoryPrescribedAmount(
            in: app, with: "0.25", evidenceName: "history-first-prescribed-amount")
        XCTAssertTrue(save.isEnabled)
        save.tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5))
        TestUtilities.debugScreenshot(app, name: "history-first-dose-saved")
        print(app.debugDescription)
        XCTAssertTrue(app.segmentedControls["analytics-section-picker"].buttons["History"].isSelected)
        XCTAssertTrue(app.staticTexts["1 of 1 doses shown"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["No doses logged yet"].exists)
        let expectedLabel = "0.25 milligrams, Ozempic, at \(expectedTime), injection site Thigh"
        let rows = TestUtilities.getDoseRows(from: app)
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.firstMatch.label, expectedLabel)
        XCTAssertEqual(rows.firstMatch.staticTexts["dose-amount"].label, "0.25 mg")
        XCTAssertEqual(rows.firstMatch.staticTexts["dose-medication"].label, "Ozempic")
        XCTAssertEqual(rows.firstMatch.staticTexts["dose-timestamp"].label, expectedTime)
        XCTAssertTrue(app.staticTexts[expectedDate].exists)

        app.terminate()
        let relaunched = TestUtilities.launchAppWithTestMode(resetData: false)
        TestUtilities.navigateToHistoryView(in: relaunched)
        let persisted = TestUtilities.getDoseRows(from: relaunched)
        XCTAssertEqual(persisted.count, 1)
        XCTAssertEqual(persisted.firstMatch.label, expectedLabel)
        XCTAssertEqual(persisted.firstMatch.staticTexts["dose-amount"].label, "0.25 mg")
        XCTAssertEqual(persisted.firstMatch.staticTexts["dose-timestamp"].label, expectedTime)
        XCTAssertTrue(relaunched.staticTexts[expectedDate].exists)
    }

    func test_doseHistory_groupsDosesByDateSections() throws {
        let today = Date()
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 5)
        TestUtilities.navigateToHistoryView(in: app)
        XCTAssertTrue(app.staticTexts["5 of 5 doses shown"].waitForExistence(timeout: 5))

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let expectedDates = [0, 7, 14, 21, 28].map { daysAgo in
            formatter.string(from: Calendar.current.date(byAdding: .day, value: -daysAgo, to: today)!)
        }
        let sectionHeaders = app.staticTexts.matching(identifier: "dose-date-section-header")
        XCTAssertEqual(sectionHeaders.allElementsBoundByIndex.map(\.label), expectedDates)

        let firstDose = TestUtilities.getDoseRows(from: app, minimumCount: 4).firstMatch
        XCTAssertEqual(firstDose.staticTexts["dose-amount"].label, "0.25 mg")
        XCTAssertEqual(firstDose.staticTexts["dose-medication"].label, "Ozempic")
        XCTAssertEqual(firstDose.staticTexts["injection-site"].label, "Abdomen")

        let list = app.collectionViews["history-section"]
        list.swipeUp()
        let visibleRows = list.buttons.matching(identifier: "dose-history-row")
        let lastDose = visibleRows.element(boundBy: visibleRows.count - 1)
        if !lastDose.waitForExistence(timeout: 5) {
            TestUtilities.debugScreenshot(app, name: "before-missing-last-dose")
            print(app.debugDescription)
            XCTFail("Fifth dose should appear after scrolling")
        }
        XCTAssertTrue(lastDose.isHittable)
        XCTAssertEqual(lastDose.staticTexts["dose-amount"].label, "0.25 mg")
        XCTAssertEqual(lastDose.staticTexts["dose-medication"].label, "Ozempic")
        XCTAssertEqual(lastDose.staticTexts["injection-site"].label, "Abdomen")
        let lastHeader = list.staticTexts[expectedDates[4]]
        XCTAssertTrue(lastHeader.isHittable)
        XCTAssertGreaterThanOrEqual(lastDose.frame.minY, lastHeader.frame.maxY)
    }

    func test_doseHistory_voiceOverAccessibility() throws {
        // GIVEN: Doses exist in history

        // Create doses for accessibility testing
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 2)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // WHEN: VoiceOver examines the history list
        let doseRows = TestUtilities.getDoseRows(from: app, minimumCount: 2)
        XCTAssertEqual(doseRows.count, 2, "Should have 2 doses for accessibility testing")

        // THEN: All elements have proper accessibility labels
        let firstDoseRow = doseRows.element(boundBy: 0)
        XCTAssertTrue(firstDoseRow.exists, "First dose row should exist")

        XCTAssertEqual(firstDoseRow.staticTexts["dose-amount"].label, "0.25 mg")
        XCTAssertEqual(firstDoseRow.staticTexts["dose-medication"].label, "Ozempic")
        XCTAssertEqual(firstDoseRow.staticTexts["injection-site"].label, "Thigh")
        let timestamp = firstDoseRow.staticTexts["dose-timestamp"]
        XCTAssertTrue(timestamp.exists)
        XCTAssertFalse(timestamp.label.isEmpty)
        XCTAssertEqual(
            firstDoseRow.label,
            "0.25 milligrams, Ozempic, at \(timestamp.label), injection site Thigh")

        // Note: Full VoiceOver testing requires device testing, this verifies accessibility setup
    }

    func test_doseHistory_editActionPrePopulatesDoseEntryForm() throws {
        // GIVEN: A dose with specific data exists

        // Create a dose with specific data for pre-population testing
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 1)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Find the dose row
        let doseRows = TestUtilities.getDoseRows(from: app, minimumCount: 1)
        let firstDoseRow = doseRows.element(boundBy: 0)
        let originalLabel = firstDoseRow.label
        let originalTime = firstDoseRow.staticTexts["dose-timestamp"].label
        let originalDate = app.staticTexts.matching(identifier: "dose-date-section-header").firstMatch.label

        // WHEN: User edits the dose
        firstDoseRow.swipeLeft()

        let editButton = app.buttons["Edit"]
        XCTAssertTrue(
            editButton.waitForExistence(timeout: 3),
            "Edit button should appear after swipe")

        editButton.tap()

        // Wait for edit sheet to appear
        let editSheet = app.navigationBars["Edit Dose"]
        let editSheetAppeared = editSheet.waitForExistence(timeout: 5)
        TestUtilities.debugScreenshot(app, name: "edit-dose-prepopulation")
        print(app.debugDescription)
        XCTAssertTrue(
            editSheetAppeared,
            "Edit dose sheet should appear")

        let medicationPicker = app.buttons["quick-dose-medication-picker"]
        XCTAssertTrue(medicationPicker.staticTexts["Ozempic (0.25 mg)"].exists)
        let amount = app.textFields["quick-dose-prescribed-amount-input"]
        XCTAssertTrue(amount.exists)
        XCTAssertEqual(amount.value as? String, "0.25")
        XCTAssertTrue(app.buttons["quick-dose-site-picker"].staticTexts["Abdomen"].exists)

        // Verify date/time picker shows current values
        let dateTimePicker = app.datePickers["quick-dose-datetime-picker"]
        XCTAssertTrue(dateTimePicker.buttons[originalDate].exists)
        XCTAssertTrue(dateTimePicker.buttons[originalTime].exists)

        // Verify save and cancel buttons are available
        let saveButton = app.buttons["quick-dose-save-button"]
        let cancelButton = app.buttons["quick-dose-cancel-button"]

        XCTAssertTrue(saveButton.exists, "Save button should be present in edit form")
        XCTAssertTrue(cancelButton.exists, "Cancel button should be present in edit form")

        TestUtilities.replaceHistoryPrescribedAmount(
            in: app, with: "0.50", evidenceName: "history-cancel-prescribed-amount-edit")
        cancelButton.tap()
        XCTAssertTrue(editSheet.waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.segmentedControls["analytics-section-picker"].buttons["History"].isSelected)
        let unchanged = TestUtilities.getDoseRows(from: app)
        XCTAssertEqual(unchanged.count, 1)
        XCTAssertEqual(unchanged.firstMatch.label, originalLabel)
        XCTAssertEqual(unchanged.firstMatch.staticTexts["dose-amount"].label, "0.25 mg")
    }

    func test_doseHistory_visualIndicatorsForSkippedDoses() throws {
        // GIVEN: skipped doses exist

        // Create regular doses first
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 2)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Get initial dose rows
        let initialDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 2)
        let firstDoseRow = initialDoseRows.element(boundBy: 0)

        // Create a skipped dose by marking the first dose as skipped
        firstDoseRow.swipeRight()

        let skipButton = app.buttons["Mark as Skipped"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 3))
        skipButton.tap()
        let skippedIndicator = app.images["skipped-dose-indicator"]
        XCTAssertTrue(
            skippedIndicator.waitForExistence(timeout: 5),
            "Skipped dose should show orange X mark indicator")
    }
}
