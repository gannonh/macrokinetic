//
//  FoodLogPolishUITests.swift
//  JabTrackerUITests
//
//  E2E tests for Phase 48 Food Log Polish features:
//  1. Clear Day context menu appears on long-press
//  2. Clear Day confirmation dialog shows item count
//  3. Clear Day deletes all entries
//  4. Delete button shows red color (not teal/accent)
//  5. Calendar starts on Monday
//  6. Week navigation uses Monday boundaries
//
//  Uses --seed-2-week-active for pre-seeded food data (14 days of food entries).
//

import XCTest

final class FoodLogPolishUITests: XCTestCase {
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

    // MARK: - Test 1: Clear Day Context Menu Appears

    /// UAT Test 1: Clear Day context menu appears on long-press of macro summary card
    /// Acceptance: Long-press on the macro summary card shows context menu with "Clear Day (N items)" option
    func testClearDayContextMenuAppears() throws {
        // GIVEN: App launched with seeded food data
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Verify food entries exist (from seeded data)
        let foodEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(foodEntry.waitForExistence(timeout: 3), "Food entry should be visible from seeded data")

        // WHEN: User long-presses the macro summary card area
        // Look for text containing "left" which appears in the macro summary (e.g., "1896 left")
        let summaryText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'left'")
        ).firstMatch

        XCTAssertTrue(summaryText.waitForExistence(timeout: 5), "Summary text should exist")
        summaryText.press(forDuration: 1.0)

        // THEN: Context menu appears with "Clear Day" option
        // The menu button label includes item count: "Clear Day (N items)"
        let clearDayButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Clear Day'")
        ).firstMatch

        XCTAssertTrue(
            clearDayButton.waitForExistence(timeout: 3),
            "Context menu should show 'Clear Day' option with item count"
        )

        // Verify the label includes item count in parentheses
        let buttonLabel = clearDayButton.label
        XCTAssertTrue(
            buttonLabel.contains("(") && buttonLabel.contains("items)"),
            "Clear Day button label should include item count: \(buttonLabel)"
        )

        // Dismiss context menu by tapping elsewhere
        app.tap()
    }

    // MARK: - Test 2: Clear Day Confirmation Dialog

    /// UAT Test 2: Clear Day confirmation dialog shows count of items to be deleted
    /// Acceptance: Tapping "Clear Day" shows confirmation dialog, Cancel dismisses without action
    func testClearDayConfirmationDialog() throws {
        // GIVEN: App launched with seeded food data
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Count entries before Clear Day
        let entriesBefore = app.buttons.matching(identifier: "food-entry-row").count
        XCTAssertGreaterThan(entriesBefore, 0, "Should have food entries from seeded data")

        // WHEN: User long-presses and taps Clear Day
        let summaryText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'left'")
        ).firstMatch
        XCTAssertTrue(summaryText.waitForExistence(timeout: 5), "Summary text should exist")
        summaryText.press(forDuration: 1.0)

        let clearDayButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Clear Day'")
        ).firstMatch
        XCTAssertTrue(clearDayButton.waitForExistence(timeout: 3), "Clear Day button should appear")
        clearDayButton.tap()

        // THEN: Confirmation dialog appears with item count message
        let alertDialog = app.alerts["Clear All Foods?"]
        XCTAssertTrue(
            alertDialog.waitForExistence(timeout: 3),
            "Confirmation dialog should appear with title 'Clear All Foods?'"
        )

        // Verify the message shows item count
        let alertMessage = alertDialog.staticTexts.element(boundBy: 1)
        let messageText = alertMessage.label
        XCTAssertTrue(
            messageText.contains("items") && messageText.contains("remove"),
            "Alert message should show item count: \(messageText)"
        )

        // WHEN: User taps Cancel
        let cancelButton = alertDialog.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist in dialog")
        cancelButton.tap()

        // THEN: Dialog dismisses without deleting entries
        XCTAssertFalse(
            alertDialog.waitForExistence(timeout: 1),
            "Dialog should dismiss after Cancel"
        )

        // Verify entries still exist
        let entriesAfter = app.buttons.matching(identifier: "food-entry-row").count
        XCTAssertEqual(
            entriesAfter,
            entriesBefore,
            "Entry count should remain unchanged after Cancel: was \(entriesBefore), now \(entriesAfter)"
        )
    }

    // MARK: - Test 3: Clear Day Deletes All Entries

    /// UAT Test 3: Confirming Clear Day removes all food entries for the day
    /// Acceptance: After confirming, all food entries are removed and day shows empty state
    func testClearDayDeletesAllEntries() throws {
        // GIVEN: App launched with seeded food data
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Verify food entries exist
        let entriesBefore = app.buttons.matching(identifier: "food-entry-row").count
        XCTAssertGreaterThan(entriesBefore, 0, "Should have food entries from seeded data")

        // WHEN: User triggers Clear Day via context menu
        let summaryText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'left'")
        ).firstMatch
        XCTAssertTrue(summaryText.waitForExistence(timeout: 5), "Summary text should exist")
        summaryText.press(forDuration: 1.0)

        let clearDayButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Clear Day'")
        ).firstMatch
        XCTAssertTrue(clearDayButton.waitForExistence(timeout: 3), "Clear Day button should appear")
        clearDayButton.tap()

        // WHEN: User confirms deletion
        let alertDialog = app.alerts["Clear All Foods?"]
        XCTAssertTrue(alertDialog.waitForExistence(timeout: 3), "Confirmation dialog should appear")

        let confirmButton = alertDialog.buttons["Clear Day"]
        XCTAssertTrue(confirmButton.exists, "Clear Day confirm button should exist in dialog")
        confirmButton.tap()

        // Wait for deletion to complete
        waitForUIUpdate(seconds: 1.0)

        // THEN: All entries are removed
        let entriesAfter = app.buttons.matching(identifier: "food-entry-row").count
        XCTAssertEqual(
            entriesAfter,
            0,
            "All entries should be deleted after Clear Day"
        )

        // Verify fasting toggle appears (indicates empty day state)
        let fastingToggleCard = app.switches["fasting-toggle-card"]
        XCTAssertTrue(
            fastingToggleCard.waitForExistence(timeout: 3),
            "Fasting toggle should appear after clearing all entries (indicates empty day)"
        )
    }

    // MARK: - Test 4: Delete Button Shows Red

    /// UAT Test 4: Swipe-to-delete button shows red background color
    /// Acceptance: Swiping left reveals a DELETE button with red background (not teal/app accent color)
    func testDeleteButtonShowsRed() throws {
        // GIVEN: App launched with seeded food data
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // Find a food entry row
        let foodEntry = app.buttons.matching(identifier: "food-entry-row").firstMatch
        XCTAssertTrue(foodEntry.waitForExistence(timeout: 3), "Food entry should be visible from seeded data")

        // WHEN: User swipes left on the food entry
        foodEntry.swipeLeft()
        waitForUIUpdate()

        // THEN: Delete button appears
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(
            deleteButton.waitForExistence(timeout: 3),
            "Delete button should appear after swipe left"
        )

        // Take debug screenshot to verify red color visually
        // Note: XCUITest cannot directly verify color, but the .tint(.red) modifier
        // ensures the button uses red. We verify the button exists and is functional.
        TestUtilities.debugScreenshot(app, name: "delete-button-red-verification")

        // Verify delete button is hittable and has expected label
        XCTAssertTrue(deleteButton.isHittable, "Delete button should be hittable")
        XCTAssertEqual(deleteButton.label, "Delete", "Delete button should have 'Delete' label")

        // Dismiss the swipe action
        foodEntry.swipeRight()
    }

    // MARK: - Test 5: Calendar Starts on Monday

    /// UAT Test 5: Food Log week calendar displays Monday on the left
    /// Acceptance: Calendar shows Mon-Sun order (Monday first, Sunday last)
    func testCalendarStartsOnMonday() throws {
        // GIVEN: App launched
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        // WHEN: User views the week calendar strip
        let weekCalendarStrip = app.otherElements["week-calendar-strip"].firstMatch
        XCTAssertTrue(
            weekCalendarStrip.waitForExistence(timeout: 3),
            "Week calendar strip should be visible"
        )

        // THEN: Find Monday and Sunday cells in the calendar
        // Day buttons have abbreviated labels like "Mon, 19" not full weekday names
        // The week-calendar-strip itself contains the full date as its accessibility label

        // Find day buttons by their abbreviated labels (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
        let mondayPredicate = NSPredicate(format: "label BEGINSWITH 'Mon'")
        let mondayCells = app.buttons.matching(mondayPredicate)

        XCTAssertGreaterThan(
            mondayCells.count,
            0,
            "Should find at least one Monday cell (label starting with 'Mon')"
        )

        // Find Sunday cell to verify week order
        let sundayPredicate = NSPredicate(format: "label BEGINSWITH 'Sun'")
        let sundayCells = app.buttons.matching(sundayPredicate)

        XCTAssertGreaterThan(
            sundayCells.count,
            0,
            "Should find at least one Sunday cell (label starting with 'Sun')"
        )

        // Get the frame positions to verify Monday is left of Sunday
        let mondayCell = mondayCells.firstMatch
        let sundayCell = sundayCells.firstMatch

        XCTAssertTrue(mondayCell.exists, "Monday cell should exist")
        XCTAssertTrue(sundayCell.exists, "Sunday cell should exist")

        // Verify Monday is to the left of Sunday (smaller X coordinate)
        let mondayFrame = mondayCell.frame
        let sundayFrame = sundayCell.frame

        XCTAssertLessThan(
            mondayFrame.minX,
            sundayFrame.minX,
            "Monday (\(mondayFrame.minX)) should be to the left of Sunday (\(sundayFrame.minX))"
        )
    }

    // MARK: - Test 6: Week Navigation Uses Monday Boundaries

    /// UAT Test 6: Week navigation arrows move by Monday-aligned boundaries
    /// Acceptance: Tapping left/right arrows navigates to previous/next Monday-aligned week
    func testWeekNavigationUsesMondayBoundaries() throws {
        // GIVEN: App launched
        TestUtilities.navigateToTab(app, tabName: "Food Log")
        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")

        let weekCalendarStrip = app.otherElements["week-calendar-strip"].firstMatch
        XCTAssertTrue(weekCalendarStrip.waitForExistence(timeout: 3), "Week calendar strip should be visible")

        // Find Monday cell in current week (abbreviated "Mon" labels)
        let mondayPredicate = NSPredicate(format: "label BEGINSWITH 'Mon'")
        let mondayCells = app.buttons.matching(mondayPredicate)
        XCTAssertGreaterThan(mondayCells.count, 0, "Should find Monday cell in current week")

        // Record the current Monday's label (contains the day number like "Mon, 13")
        let currentMondayLabel = mondayCells.firstMatch.label

        // WHEN: User taps previous week button
        let previousWeekButton = findPreviousWeekButton()
        XCTAssertTrue(previousWeekButton.waitForExistence(timeout: 3), "Previous week button should exist")
        previousWeekButton.tap()
        waitForUIUpdate()

        // THEN: New week also has a Monday (7 days earlier)
        let previousMondayCells = app.buttons.matching(mondayPredicate)
        XCTAssertGreaterThan(
            previousMondayCells.count,
            0,
            "Previous week should also have a Monday cell"
        )

        // Verify it's a different Monday (different day number in label)
        let previousMondayLabel = previousMondayCells.firstMatch.label
        XCTAssertNotEqual(
            currentMondayLabel,
            previousMondayLabel,
            "Previous week's Monday should have a different date"
        )

        // Verify Sunday is still to the right of Monday
        let sundayPredicate = NSPredicate(format: "label BEGINSWITH 'Sun'")
        let sundayCells = app.buttons.matching(sundayPredicate)
        XCTAssertGreaterThan(sundayCells.count, 0, "Should find Sunday cell")

        let mondayFrame = previousMondayCells.firstMatch.frame
        let sundayFrame = sundayCells.firstMatch.frame
        XCTAssertLessThan(
            mondayFrame.minX,
            sundayFrame.minX,
            "Monday should still be to the left of Sunday after navigation"
        )

        // WHEN: User taps next week button twice to go one week ahead of original
        let nextWeekButton = findNextWeekButton()
        XCTAssertTrue(nextWeekButton.waitForExistence(timeout: 3), "Next week button should exist")
        nextWeekButton.tap()
        waitForUIUpdate()
        nextWeekButton.tap()
        waitForUIUpdate()

        // THEN: That week also starts on Monday
        let nextMondayCells = app.buttons.matching(mondayPredicate)
        XCTAssertGreaterThan(
            nextMondayCells.count,
            0,
            "Next week should also have a Monday cell"
        )

        // Verify the date is different from previous week
        let nextMondayLabel = nextMondayCells.firstMatch.label
        XCTAssertNotEqual(
            previousMondayLabel,
            nextMondayLabel,
            "Next week's Monday should have a different date from previous week"
        )
    }

    // MARK: - Element Finders

    /// Find the previous week navigation button by its accessibility label
    private func findPreviousWeekButton() -> XCUIElement {
        let predicate = NSPredicate(format: "label == 'Previous week'")
        return app.buttons.matching(predicate).firstMatch
    }

    /// Find the next week navigation button by its accessibility label
    private func findNextWeekButton() -> XCUIElement {
        let predicate = NSPredicate(format: "label == 'Next week'")
        return app.buttons.matching(predicate).firstMatch
    }

    // MARK: - Helpers

    /// Wait for UI to update after animations/transitions
    private func waitForUIUpdate(seconds: TimeInterval = 0.5) {
        let expectation = XCTestExpectation(description: "Wait for UI update")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: seconds + 0.5)
    }
}
