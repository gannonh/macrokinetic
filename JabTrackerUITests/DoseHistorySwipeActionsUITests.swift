//
//  DoseHistorySwipeActionsUITests.swift
//  JabTrackerUITests
//
//  Dose History Swipe Actions Tests
//  Tests for delete, duplicate, skip actions and confirmation flows
//

import XCTest

final class DoseHistorySwipeActionsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Swipe Actions

    func test_doseHistory_swipeActionsDeleteDose() throws {
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 2)
        TestUtilities.debugScreenshot(app, step: 1, description: "after-setup")
        TestUtilities.navigateToHistoryView(in: app)
        TestUtilities.debugScreenshot(app, step: 2, description: "after-navigate-history")

        let rows = TestUtilities.getDoseRows(from: app, minimumCount: 2)
        XCTAssertEqual(rows.count, 2)
        let target = rows.element(boundBy: 0)
        let survivor = rows.element(boundBy: 1)
        XCTAssertEqual(target.staticTexts["dose-amount"].label, "0.25 mg")
        XCTAssertEqual(target.staticTexts["dose-medication"].label, "Ozempic")
        XCTAssertEqual(target.staticTexts["injection-site"].label, "Thigh")
        XCTAssertEqual(survivor.staticTexts["injection-site"].label, "Abdomen")
        let survivorLabel = survivor.label
        let survivorDate = app.staticTexts.matching(identifier: "dose-date-section-header")
            .element(boundBy: 1).label

        target.swipeLeft()
        let delete = app.buttons["Delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 3))
        delete.tap()
        let alert = app.alerts["Delete Dose"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.buttons["Cancel"].exists)
        alert.buttons["Delete"].tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 3))
        TestUtilities.debugScreenshot(app, step: 3, description: "after-delete-confirmed")

        XCTAssertTrue(app.staticTexts["1 of 1 doses shown"].waitForExistence(timeout: 5))
        let remaining = TestUtilities.getDoseRows(from: app)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.firstMatch.label, survivorLabel)
        XCTAssertEqual(remaining.firstMatch.staticTexts["dose-amount"].label, "0.25 mg")
        XCTAssertEqual(remaining.firstMatch.staticTexts["dose-medication"].label, "Ozempic")
        XCTAssertEqual(remaining.firstMatch.staticTexts["injection-site"].label, "Abdomen")
        XCTAssertEqual(
            app.staticTexts.matching(identifier: "dose-date-section-header").firstMatch.label,
            survivorDate)

        app.terminate()
        let relaunched = TestUtilities.launchAppWithTestMode(resetData: false)
        TestUtilities.navigateToHistoryView(in: relaunched)
        XCTAssertTrue(relaunched.staticTexts["1 of 1 doses shown"].waitForExistence(timeout: 5))
        let persisted = TestUtilities.getDoseRows(from: relaunched)
        XCTAssertEqual(persisted.count, 1)
        XCTAssertEqual(persisted.firstMatch.label, survivorLabel)
        XCTAssertEqual(
            relaunched.staticTexts.matching(identifier: "dose-date-section-header").firstMatch.label,
            survivorDate)
    }

    func test_doseHistory_swipeActionsDuplicateDose() throws {
        // GIVEN: A dose exists in history

        // Given: User has a medication profile and a dose for it
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 1)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Find the first dose row and verify there's only one dose initially
        let initialDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 1)
        let firstDoseRow = initialDoseRows.element(boundBy: 0)
        XCTAssertEqual(initialDoseRows.count, 1, "Should start with exactly 1 dose")

        // WHEN: User swipes right on dose row to reveal leading actions (duplicate is on leading edge)
        firstDoseRow.swipeRight()

        // THEN: Duplicate action appears
        let duplicateButton = app.buttons["Duplicate"]
        XCTAssertTrue(
            duplicateButton.waitForExistence(timeout: 3),
            "Duplicate button should appear after right swipe")

        // Tap the Duplicate button
        duplicateButton.tap()

        // THEN: New dose is created with same data but current timestamp

        XCTAssertTrue(app.segmentedControls["analytics-section-picker"].buttons["History"].isSelected)
        XCTAssertTrue(app.segmentedControls["history-view-mode-picker"].buttons["List"].isSelected)
        XCTAssertTrue(app.staticTexts["2 of 2 doses shown"].waitForExistence(timeout: 5))

        // THEN: Dose count should increase to 2 (original + duplicate)
        let updatedDoseRows = app.buttons.matching(identifier: "dose-history-row")
        XCTAssertEqual(
            updatedDoseRows.count, 2,
            "Should have 2 doses after duplication (original + duplicate)")

        // Verify both dose rows exist and are accessible
        XCTAssertTrue(
            updatedDoseRows.element(boundBy: 0).exists,
            "First dose row should exist")
        XCTAssertTrue(
            updatedDoseRows.element(boundBy: 1).exists,
            "Second dose row (duplicate) should exist")
        for row in updatedDoseRows.allElementsBoundByIndex {
            XCTAssertEqual(row.staticTexts["dose-amount"].label, "0.25 mg")
            XCTAssertEqual(row.staticTexts["dose-medication"].label, "Ozempic")
            XCTAssertEqual(row.staticTexts["injection-site"].label, "Abdomen")
        }
    }

    func test_doseHistory_swipeActionsSkipDose() throws {
        // GIVEN: A non-skipped dose exists in history

        // Given: User has a medication profile and a dose for it
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 1)

        // Navigate to History tab
        TestUtilities.navigateToHistoryView(in: app)

        // Find the first dose row
        let doseRows = TestUtilities.getDoseRows(from: app, minimumCount: 1)
        let firstDoseRow = doseRows.element(boundBy: 0)
        let timestamp = firstDoseRow.staticTexts["dose-timestamp"].label

        // WHEN: User swipes right on dose row to reveal leading actions
        firstDoseRow.swipeRight()

        // THEN: Mark as Skipped action appears (for non-skipped doses)
        let skipButton = app.buttons["Mark as Skipped"]
        XCTAssertTrue(
            skipButton.waitForExistence(timeout: 3),
            "Mark as Skipped button should appear after right swipe")

        // Tap the Skip button
        skipButton.tap()

        // THEN: Dose row shows skipped styling/indicator
        // Wait a moment for the skip status to update

        XCTAssertTrue(app.segmentedControls["analytics-section-picker"].buttons["History"].isSelected)
        XCTAssertTrue(app.segmentedControls["history-view-mode-picker"].buttons["List"].isSelected)

        // Verify the dose is still there (count should remain 1)
        let updatedDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 1)
        XCTAssertEqual(
            updatedDoseRows.count, 1,
            "Should still have 1 dose after marking as skipped")

        // Verify the dose row still exists and is accessible after being marked as skipped
        XCTAssertTrue(
            updatedDoseRows.element(boundBy: 0).exists,
            "Dose row should still exist after being marked as skipped")

        // Verify the skipped dose shows the X mark symbol indicator
        let skippedIndicator = app.images["skipped-dose-indicator"]
        XCTAssertTrue(
            skippedIndicator.waitForExistence(timeout: 3),
            "Skipped dose should show orange X mark indicator symbol")
        XCTAssertEqual(
            updatedDoseRows.firstMatch.label,
            "0.25 milligrams, Ozempic, at \(timestamp), skipped, injection site Abdomen")
    }

    func test_doseHistory_deleteConfirmationPreventsAccidentalDeletion() throws {
        let app = TestUtilities.setupDoseHistoryTest(app: XCUIApplication(), doseCount: 1)
        TestUtilities.navigateToHistoryView(in: app)
        let original = TestUtilities.getDoseRows(from: app).firstMatch
        XCTAssertEqual(original.staticTexts["dose-amount"].label, "0.25 mg")
        XCTAssertEqual(original.staticTexts["dose-medication"].label, "Ozempic")
        XCTAssertEqual(original.staticTexts["injection-site"].label, "Abdomen")
        let originalLabel = original.label
        let originalDate = app.staticTexts.matching(identifier: "dose-date-section-header").firstMatch.label

        original.swipeLeft()
        let delete = app.buttons["Delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: 3))
        delete.tap()
        let alert = app.alerts["Delete Dose"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.buttons["Delete"].exists)
        alert.buttons["Cancel"].tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 3))

        let remaining = TestUtilities.getDoseRows(from: app)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.firstMatch.label, originalLabel)
        XCTAssertTrue(app.staticTexts["1 of 1 doses shown"].exists)
        XCTAssertEqual(
            app.staticTexts.matching(identifier: "dose-date-section-header").firstMatch.label,
            originalDate)

        app.terminate()
        let relaunched = TestUtilities.launchAppWithTestMode(resetData: false)
        TestUtilities.navigateToHistoryView(in: relaunched)
        let persisted = TestUtilities.getDoseRows(from: relaunched)
        XCTAssertEqual(persisted.count, 1)
        XCTAssertEqual(persisted.firstMatch.label, originalLabel)
        XCTAssertEqual(persisted.firstMatch.staticTexts["dose-amount"].label, "0.25 mg")
        XCTAssertEqual(persisted.firstMatch.staticTexts["dose-medication"].label, "Ozempic")
        XCTAssertEqual(persisted.firstMatch.staticTexts["injection-site"].label, "Abdomen")
        XCTAssertEqual(
            relaunched.staticTexts.matching(identifier: "dose-date-section-header").firstMatch.label,
            originalDate)
    }
}
