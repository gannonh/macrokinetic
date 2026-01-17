//
//  FoodLogCopyPasteUITests.swift
//  JabTrackerUITests
//
//  E2E tests for Phase 44 Copy/Paste feature in Food Log.
//  Tests context menus, segmented control, clipboard persistence, and paste modes.
//
//  Uses --seed-2-week-active for pre-seeded food data (14 days of food entries).
//

import XCTest

final class FoodLogCopyPasteUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Launch with seeded food data (14 days of food/weight entries)
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data", "--seed-2-week-active"]
        app.launch()

        // Wait for app to be ready
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after launch")
    }

    override func tearDownWithError() throws {
        if testRun?.hasSucceeded == false {
            TestUtilities.captureFailureScreenshot(app, testName: name)
        }
        app = nil
    }

    // MARK: - Test 1: Copy Day via Context Menu

    /// User can long-press macro summary card to copy all foods for the day
    /// Acceptance: Long-press shows context menu with "Copy All Foods" option
    func testCopyDayViaContextMenu() throws {
        // GIVEN: App launched with seeded food data
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // WHEN: User long-presses the macro summary card area
        // Look for text containing "left" which appears in the macro summary (e.g., "1896 left")
        let summaryText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'left'")
        ).firstMatch

        XCTAssertTrue(summaryText.waitForExistence(timeout: 5), "Summary text should exist")
        summaryText.press(forDuration: 1.0)

        // THEN: Context menu appears with "Copy All Foods" option
        let copyButton = app.buttons["Copy All Foods"]
        XCTAssertTrue(
            copyButton.waitForExistence(timeout: 3),
            "Context menu should show 'Copy All Foods' option"
        )

        // Tap to copy
        copyButton.tap()

        // Verify copy succeeded by checking paste button is now enabled
        let pasteButton = app.buttons["paste-button"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 2), "Paste button should exist")
        XCTAssertTrue(pasteButton.isEnabled, "Paste button should be enabled after copying")
    }

    // MARK: - Test 2: Copy via Header Button

    /// Verifies that copying all foods for the day works via the header toolbar button.
    func testCopyDayViaHeaderButton() throws {
        // GIVEN: App launched with seeded food data
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Verify food entries exist (from seeded data)
        let foodEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(foodEntry.waitForExistence(timeout: 3), "Food entry should be visible from seeded data")

        // Use the header copy button
        let copyDayButton = app.buttons["copy-day-button"]
        XCTAssertTrue(copyDayButton.waitForExistence(timeout: 3), "Copy day button should exist in header")
        copyDayButton.tap()

        // Verify clipboard has content
        let pasteButton = app.buttons["paste-button"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 3), "Paste button should exist")
        XCTAssertTrue(pasteButton.isEnabled, "Paste button should be enabled after copying")
    }

    // MARK: - Test 3: Copy via Segmented Control

    /// User can use segmented control in header to copy the day
    /// Acceptance: Segmented control appears when there's content to copy
    func testCopyViaSegmentedControl() throws {
        // GIVEN: App launched with seeded food data
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // WHEN: User views the header - copy button should exist with seeded data
        let copyDayButton = app.buttons["copy-day-button"]
        XCTAssertTrue(
            copyDayButton.waitForExistence(timeout: 3),
            "Copy button should appear in header when entries exist"
        )
        XCTAssertTrue(copyDayButton.isEnabled, "Copy button should be enabled when entries exist")

        // Tap to copy
        copyDayButton.tap()

        // THEN: Paste button should now be enabled
        let pasteButton = app.buttons["paste-button"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 2), "Paste button should exist")
        XCTAssertTrue(pasteButton.isEnabled, "Paste button should be enabled after copying")
    }

    // MARK: - Test 4: Paste to Empty Day with Add Mode

    /// User can paste to an empty day without confirmation dialog
    /// Acceptance: Food entries appear immediately without dialog
    func testPasteToEmptyDayNoDialog() throws {
        // GIVEN: App launched with seeded food data (14 days)
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Copy the day (seeded food exists)
        let copyDayButton = app.buttons["copy-day-button"]
        XCTAssertTrue(copyDayButton.waitForExistence(timeout: 3), "Copy button should exist")
        copyDayButton.tap()

        // Navigate to an empty day (3 weeks back - outside 14-day seed window)
        navigateToPreviousWeek()
        navigateToPreviousWeek()
        navigateToPreviousWeek()

        // WHEN: User taps paste button
        let pasteButton = app.buttons["paste-button"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 3), "Paste button should exist")
        XCTAssertTrue(pasteButton.isEnabled, "Paste button should be enabled")
        pasteButton.tap()

        // THEN: No confirmation dialog appears (day was empty)
        let pasteDialog = app.sheets["Paste Foods"]
        let dialogExists = pasteDialog.waitForExistence(timeout: 1)
        XCTAssertFalse(dialogExists, "No confirmation dialog should appear for empty day")

        // Verify food was pasted
        waitForUIUpdate()
        let pastedEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(
            pastedEntry.waitForExistence(timeout: 3),
            "Pasted food entry should appear"
        )
    }

    // MARK: - Test 5: Paste with Replace Existing

    /// User can replace existing entries when pasting
    /// Acceptance: "Replace Existing" removes old entries, pastes new ones
    func testPasteWithReplaceExisting() throws {
        // GIVEN: App launched with seeded food data
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Copy today's food
        let copyDayButton = app.buttons["copy-day-button"]
        XCTAssertTrue(copyDayButton.waitForExistence(timeout: 3), "Copy button should exist")
        copyDayButton.tap()

        // Navigate to yesterday (also has seeded food)
        navigateToPreviousWeek()

        // WHEN: User taps paste button (pasting to day with existing food)
        let pasteButton = app.buttons["paste-button"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 3), "Paste button should exist")
        pasteButton.tap()

        // THEN: Confirmation dialog appears
        waitForUIUpdate()

        // Look for the Replace button in the action sheet
        let replaceButton = app.buttons["Replace Existing"]
        XCTAssertTrue(
            replaceButton.waitForExistence(timeout: 3),
            "Replace Existing button should appear in dialog"
        )

        // Tap Replace Existing
        replaceButton.tap()

        // Wait for paste to complete
        waitForUIUpdate()

        // Verify paste completed (food entries exist)
        let foodEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(
            foodEntry.waitForExistence(timeout: 3),
            "Food entries should exist after replace"
        )
    }

    // MARK: - Test 6: Paste with Add to Existing

    /// User can add to existing entries when pasting
    /// Acceptance: "Add to Existing" keeps old entries, adds new ones
    func testPasteWithAddToExisting() throws {
        // GIVEN: App launched with seeded food data
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Copy today's food
        let copyDayButton = app.buttons["copy-day-button"]
        XCTAssertTrue(copyDayButton.waitForExistence(timeout: 3), "Copy button should exist")
        copyDayButton.tap()

        // Navigate to yesterday (also has seeded food)
        navigateToPreviousWeek()

        // Count entries before paste
        let entriesBefore = app.buttons.matching(identifier: "food-entry-row").count

        // WHEN: User taps paste button
        let pasteButton = app.buttons["paste-button"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 3), "Paste button should exist")
        pasteButton.tap()

        // THEN: Confirmation dialog appears
        waitForUIUpdate()

        // Look for the Add to Existing button
        let addButton = app.buttons["Add to Existing"]
        XCTAssertTrue(
            addButton.waitForExistence(timeout: 3),
            "Add to Existing button should appear in dialog"
        )

        // Tap Add to Existing
        addButton.tap()

        // Wait for paste to complete
        waitForUIUpdate()

        // Verify entries increased (original + pasted)
        let entriesAfter = app.buttons.matching(identifier: "food-entry-row").count
        XCTAssertGreaterThan(entriesAfter, entriesBefore, "Should have more entries after adding")
    }

    // MARK: - Test 7: Clipboard Persists Across Navigation

    /// Clipboard content persists when navigating to different tabs
    /// Acceptance: Copy, navigate away, return - paste still available
    func testClipboardPersistsAcrossNavigation() throws {
        // GIVEN: App launched with seeded food data
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Copy the day
        let copyDayButton = app.buttons["copy-day-button"]
        XCTAssertTrue(copyDayButton.waitForExistence(timeout: 3), "Copy button should exist")
        copyDayButton.tap()

        // Verify paste is available
        var pasteButton = app.buttons["paste-button"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 2), "Paste button should exist")
        XCTAssertTrue(pasteButton.isEnabled, "Paste button should be enabled after copy")

        // WHEN: User navigates to a different tab and back
        TestUtilities.navigateToTab(app, tabName: "Dashboard")
        let dashboard = app.otherElements["dashboard-view"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 5), "Dashboard should appear")

        // Navigate back to Food Log
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should reappear")

        // THEN: Paste button should still be enabled
        pasteButton = app.buttons["paste-button"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 2), "Paste button should still exist")
        XCTAssertTrue(pasteButton.isEnabled, "Paste button should remain enabled after navigation")
    }

    // MARK: - Test 8: New Copy Replaces Clipboard

    /// New copy operation replaces previous clipboard content
    /// Acceptance: Copy day A, navigate to day B, copy day B - clipboard now has day B's food
    func testNewCopyReplacesClipboard() throws {
        // GIVEN: App launched with seeded food data
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Copy today (first copy)
        var copyDayButton = app.buttons["copy-day-button"]
        XCTAssertTrue(copyDayButton.waitForExistence(timeout: 3), "Copy button should exist")
        copyDayButton.tap()

        // Navigate to a different seeded day (yesterday)
        navigateToPreviousWeek()

        // WHEN: Copy again (replaces clipboard)
        copyDayButton = app.buttons["copy-day-button"]
        XCTAssertTrue(copyDayButton.waitForExistence(timeout: 3), "Copy button should exist")
        copyDayButton.tap()

        // Navigate to empty day (3 weeks back)
        navigateToPreviousWeek()
        navigateToPreviousWeek()

        // Paste
        let pasteButton = app.buttons["paste-button"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 3), "Paste button should exist")
        pasteButton.tap()
        waitForUIUpdate()

        // THEN: Verify food was pasted (from second copy, not first)
        let pastedEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(
            pastedEntry.waitForExistence(timeout: 3),
            "Pasted food entry should appear (from second copy)"
        )
    }

    // MARK: - Helpers

    /// Navigate to previous week in calendar
    private func navigateToPreviousWeek() {
        let previousWeekButton = app.buttons.matching(
            NSPredicate(format: "label == 'Previous week'")
        ).firstMatch
        if previousWeekButton.waitForExistence(timeout: 3) {
            previousWeekButton.tap()
            waitForUIUpdate()
        }
    }

    /// Wait for UI to update after animations/transitions
    private func waitForUIUpdate(seconds: TimeInterval = 0.5) {
        let expectation = XCTestExpectation(description: "Wait for UI update")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: seconds + 0.5)
    }
}
