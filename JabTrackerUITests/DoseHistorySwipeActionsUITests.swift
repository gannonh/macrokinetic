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
    // GIVEN: A dose exists in history
    let app = TestUtilities.launchAppWithTestMode()

    // Given: User has a medication profile and a dose for it
    TestUtilities.setupDoseHistoryTest(app: app, doseCount: 1)

    // Navigate to History tab
    TestUtilities.navigateToHistoryView(in: app)

    // Find the first dose row
    let doseRows = TestUtilities.getDoseRows(from: app, minimumCount: 1)
    let firstDoseRow = doseRows.element(boundBy: 0)

    // WHEN: User swipes left on dose row to reveal trailing actions
    firstDoseRow.swipeLeft()

    // THEN: Delete action appears
    let deleteButton = app.buttons["Delete"]
    XCTAssertTrue(
      deleteButton.waitForExistence(timeout: 3),
      "Delete button should appear after swipe")

    // Tap the Delete button
    deleteButton.tap()

    // THEN: Delete confirmation alert appears
    let deleteAlert = app.alerts["Delete Dose"]
    XCTAssertTrue(
      deleteAlert.waitForExistence(timeout: 5),
      "Delete confirmation alert should appear")

    // Verify alert has proper buttons
    let cancelAlertButton = deleteAlert.buttons["Cancel"]
    let deleteAlertButton = deleteAlert.buttons["Delete"]

    XCTAssertTrue(cancelAlertButton.exists, "Cancel button should exist in alert")
    XCTAssertTrue(deleteAlertButton.exists, "Delete button should exist in alert")

    // Confirm deletion
    deleteAlertButton.tap()

    // THEN: Dose is removed from list
    // Wait for alert to dismiss
    let alertDismissed = !deleteAlert.waitForExistence(timeout: 3)
    XCTAssertTrue(alertDismissed, "Delete alert should dismiss after confirmation")

    // Verify we're back on the History view
    let historyView = app.collectionViews["dose-history-list"]
    let historyViewExists = historyView.waitForExistence(timeout: 3)

    // If collection view doesn't exist, check for any dose-history-list elements
    if !historyViewExists {
      let historyElements = app.descendants(matching: .any).matching(
        identifier: "dose-history-list")
      XCTAssertTrue(historyElements.count > 0, "Should have dose-history-list elements")
    } else {
      XCTAssertTrue(historyViewExists, "Should return to history view")
    }

    // Verify the dose row no longer exists (empty state or reduced count)
    // Since we created 1 dose and deleted it, we should see empty state or no dose rows
    let updatedDoseRows = app.buttons.matching(identifier: "dose-history-row")
    XCTAssertEqual(
      updatedDoseRows.count, 0,
      "Dose row should be removed after deletion")
  }

  func test_doseHistory_swipeActionsDuplicateDose() throws {
    // GIVEN: A dose exists in history
    let app = TestUtilities.launchAppWithTestMode()

    // Given: User has a medication profile and a dose for it
    TestUtilities.setupDoseHistoryTest(app: app, doseCount: 1)

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
    // Wait a moment for the duplication to complete
    sleep(1)

    // Verify we're still on the History view
    let historyView = app.collectionViews["dose-history-list"]
    if !historyView.exists {
      let historyElements = app.descendants(matching: .any).matching(
        identifier: "dose-history-list")
      XCTAssertTrue(historyElements.count > 0, "Should have dose-history-list elements")
    } else {
      XCTAssertTrue(historyView.exists, "Should remain on history view")
    }

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

    // Note: Success message validation would require the UI to show a success indicator
    // The duplication action itself completing successfully is the main validation
  }

  func test_doseHistory_swipeActionsSkipDose() throws {
    // GIVEN: A non-skipped dose exists in history
    let app = TestUtilities.launchAppWithTestMode()

    // Given: User has a medication profile and a dose for it
    TestUtilities.setupDoseHistoryTest(app: app, doseCount: 1)

    // Navigate to History tab
    TestUtilities.navigateToHistoryView(in: app)

    // Find the first dose row
    let doseRows = TestUtilities.getDoseRows(from: app, minimumCount: 1)
    let firstDoseRow = doseRows.element(boundBy: 0)

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
    sleep(1)

    // Verify we're still on the History view
    let historyView = app.collectionViews["dose-history-list"]
    if !historyView.exists {
      let historyElements = app.descendants(matching: .any).matching(
        identifier: "dose-history-list")
      XCTAssertTrue(historyElements.count > 0, "Should have dose-history-list elements")
    } else {
      XCTAssertTrue(historyView.exists, "Should remain on history view")
    }

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
  }

  func test_doseHistory_deleteConfirmationPreventsAccidentalDeletion() throws {
    // GIVEN: A dose exists in history
    let app = TestUtilities.launchAppWithTestMode()

    // Given: User has a medication profile and a dose for it
    TestUtilities.setupDoseHistoryTest(app: app, doseCount: 1)

    // Navigate to History tab
    TestUtilities.navigateToHistoryView(in: app)

    // Find the first dose row
    let doseRows = TestUtilities.getDoseRows(from: app, minimumCount: 1)
    let firstDoseRow = doseRows.element(boundBy: 0)

    // WHEN: User starts delete process but cancels confirmation
    firstDoseRow.swipeLeft()

    // THEN: Delete action appears
    let deleteButton = app.buttons["Delete"]
    XCTAssertTrue(
      deleteButton.waitForExistence(timeout: 3),
      "Delete button should appear after swipe")

    // Tap the Delete button
    deleteButton.tap()

    // THEN: Delete confirmation alert appears
    let deleteAlert = app.alerts["Delete Dose"]
    XCTAssertTrue(
      deleteAlert.waitForExistence(timeout: 5),
      "Delete confirmation alert should appear")

    // Verify alert has proper buttons
    let cancelAlertButton = deleteAlert.buttons["Cancel"]
    let deleteAlertButton = deleteAlert.buttons["Delete"]

    XCTAssertTrue(cancelAlertButton.exists, "Cancel button should exist in alert")
    XCTAssertTrue(deleteAlertButton.exists, "Delete button should exist in alert")

    // WHEN: User cancels deletion
    cancelAlertButton.tap()

    // THEN: Alert dismisses and dose remains in list
    let alertDismissed = !deleteAlert.waitForExistence(timeout: 3)
    XCTAssertTrue(alertDismissed, "Delete alert should dismiss after cancellation")

    // Verify we're back on the History view
    let historyView = app.collectionViews["dose-history-list"]
    let historyViewExists = historyView.waitForExistence(timeout: 3)

    // If collection view doesn't exist, check for any dose-history-list elements
    if !historyViewExists {
      let historyElements = app.descendants(matching: .any).matching(
        identifier: "dose-history-list")
      XCTAssertTrue(historyElements.count > 0, "Should have dose-history-list elements")
    } else {
      XCTAssertTrue(historyViewExists, "Should return to history view")
    }

    // THEN: Dose remains in list (should still have the original dose)
    let remainingDoseRows = TestUtilities.getDoseRows(from: app, minimumCount: 1)
    XCTAssertEqual(
      remainingDoseRows.count, 1,
      "Dose row should remain after canceling deletion")

    // Verify the dose row still exists and is accessible
    XCTAssertTrue(
      remainingDoseRows.element(boundBy: 0).exists,
      "Original dose row should still exist after canceling deletion")
  }
}
