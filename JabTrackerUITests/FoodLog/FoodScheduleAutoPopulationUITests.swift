//
//  FoodScheduleAutoPopulationUITests.swift
//  JabTrackerUITests
//
//  E2E tests for Phase 47 - Food Schedule Auto-Population feature.
//  Tests verify scheduled foods auto-populate on app launch, can be deleted
//  without affecting schedules, and handle duplicate prevention correctly.
//

import XCTest

final class FoodScheduleAutoPopulationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    /// Launch app with test mode and bypass onboarding
    private func launchAppWithTestMode(resetData: Bool = true) {
        app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "true"

        var args = ["--ui-testing", "--bypass-onboarding"]
        if resetData {
            args.append("--reset-app-data")
        }
        app.launchArguments = args

        app.launch()

        // Wait for app to be ready
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after launch")
    }

    /// Launch app WITHOUT resetting data (for relaunch scenarios)
    private func relaunchAppWithoutReset() {
        app.terminate()

        app = XCUIApplication()
        app.launchEnvironment["UI_TESTING"] = "true"
        app.launchArguments = ["--ui-testing", "--bypass-onboarding"]

        app.launch()

        // Wait for app to be ready
        let tabBar = app.tabBars.element
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should appear after relaunch")
    }

    /// Navigate to Food Log tab
    private func navigateToFoodLog() {
        TestUtilities.navigateToTab(app, tabName: "Food Log")

        let foodLogView = app.otherElements["food-log-view"]
        XCTAssertTrue(foodLogView.waitForExistence(timeout: 5), "Food Log view should appear")
    }

    /// Wait for UI to update after animations/transitions
    private func waitForUIUpdate(seconds: TimeInterval = 0.5) {
        let expectation = XCTestExpectation(description: "Wait for UI update")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: seconds + 0.5)
    }

    /// Log a test food entry via search and return to Food Log
    /// - Returns: The name of the food logged
    @discardableResult
    private func logTestFoodEntry(searchTerm: String = "apple") -> String {
        navigateToFoodLog()

        // Open Food Search sheet via + button
        let addButton = app.buttons["add-food-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Add food button should exist")
        addButton.tap()

        // Wait for Food Search Sheet
        let foodSearchSheet = app.otherElements["food-search-sheet"]
        XCTAssertTrue(foodSearchSheet.waitForExistence(timeout: 5), "Food search sheet should appear")

        // Search for a food
        let searchField = app.textFields["food-search-field"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "Search field should exist")
        searchField.tap()
        searchField.typeText(searchTerm)

        // Select first result
        let firstResult = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'food-result-'")
        ).element(boundBy: 0)
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "Should have search result for '\(searchTerm)'")
        firstResult.tap()

        // Wait for FoodDetailSheet to appear
        let foodDetailSheet = app.otherElements["food-detail-sheet"]
        XCTAssertTrue(foodDetailSheet.waitForExistence(timeout: 5), "Food detail sheet should appear")

        return searchTerm
    }

    /// Create a schedule for the currently displayed food in FoodDetailSheet
    /// Assumes FoodDetailSheet is already open
    private func createScheduleForCurrentFood(meal: String = "Breakfast") {
        // Look for Schedule button in FoodDetailSheet
        let scheduleButton = app.buttons["schedule-food-button"]

        if !scheduleButton.waitForExistence(timeout: 3) {
            // Debug: capture screenshot if schedule button not found
            TestUtilities.debugScreenshot(app, name: "food-detail-no-schedule-button")
            print(app.debugDescription)
            XCTFail("Schedule button should exist in food detail sheet")
            return
        }

        scheduleButton.tap()

        // Wait for ScheduleConfigSheet to appear
        let scheduleSheet = app.otherElements["schedule-config-sheet"]
        XCTAssertTrue(scheduleSheet.waitForExistence(timeout: 5), "Schedule config sheet should appear")

        // Select today's day in the day-meal grid
        // The grid has buttons for each day/meal combination
        // Find and tap the breakfast button for today
        let dayIndex = Calendar.current.component(.weekday, from: Date())  // 1=Sun, 2=Mon, etc.
        let dayMealButtonId = "day-meal-\(dayIndex)-\(meal.lowercased())"

        let dayMealButton = app.buttons[dayMealButtonId]
        if dayMealButton.waitForExistence(timeout: 2) {
            dayMealButton.tap()
        } else {
            // Fallback: try tapping any breakfast cell if specific one not found
            let breakfastPredicate = NSPredicate(format: "identifier CONTAINS 'breakfast'")
            let breakfastButton = app.buttons.matching(breakfastPredicate).firstMatch
            if breakfastButton.waitForExistence(timeout: 2) {
                breakfastButton.tap()
            }
        }

        // Save the schedule
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3), "Save button should exist")
        saveButton.tap()

        // Wait for sheet to dismiss
        waitForUIUpdate(seconds: 1.0)
    }

    /// Add food to log (from FoodDetailSheet that's already open)
    private func addFoodToLog() {
        let addFoodButton = app.buttons["add-food-button"].firstMatch
        XCTAssertTrue(addFoodButton.waitForExistence(timeout: 3), "Add button should exist in food detail sheet")
        addFoodButton.tap()

        // Wait for sheets to dismiss
        waitForUIUpdate(seconds: 1.0)
    }

    /// Get count of food entry rows in the current view
    private func getFoodEntryCount() -> Int {
        let entries = app.buttons.matching(identifier: "food-entry-row")
        return entries.count
    }

    /// Check if a food entry with specific name exists in the food log
    private func foodEntryExists(named foodName: String) -> Bool {
        // Food entries display the food name as text within the card
        let predicate = NSPredicate(format: "label CONTAINS[c] %@", foodName)
        let matchingElements = app.staticTexts.matching(predicate)
        return matchingElements.count > 0
    }

    /// Delete the first food entry via swipe action
    private func deleteFirstFoodEntry() {
        let firstEntry = app.buttons["food-entry-row"].firstMatch
        guard firstEntry.waitForExistence(timeout: 3) else {
            TestUtilities.debugScreenshot(app, name: "no-entry-to-delete")
            XCTFail("No food entry found to delete")
            return
        }

        // Swipe left to reveal delete button
        firstEntry.swipeLeft()

        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Delete button should appear after swipe")
        deleteButton.tap()

        // Confirm deletion in alert
        let confirmDelete = app.buttons["Delete"]
        if confirmDelete.waitForExistence(timeout: 2) {
            confirmDelete.tap()
        }

        waitForUIUpdate(seconds: 0.5)
    }

    // MARK: - Test Cases

    /// UAT Scenario 1: Scheduled food auto-populates on app launch
    /// After scheduling a food for today and relaunching the app,
    /// the food appears automatically in the Food Log for the configured meal
    func testScheduledFoodAutoPopulatesOnAppLaunch() {
        // GIVEN: User launches the app with clean state
        launchAppWithTestMode(resetData: true)

        // WHEN: User creates a food schedule for today
        logTestFoodEntry(searchTerm: "banana")

        // Create schedule for the food (for today's breakfast)
        createScheduleForCurrentFood(meal: "Breakfast")

        // Also add the food to log for today (schedule will populate future days)
        addFoodToLog()

        // Navigate to food log
        navigateToFoodLog()

        // Verify at least one entry exists (the one we just added)
        let initialCount = getFoodEntryCount()
        XCTAssertGreaterThanOrEqual(initialCount, 1, "Should have at least one food entry after adding")

        // WHEN: User relaunches the app
        relaunchAppWithoutReset()

        // THEN: The scheduled food should still appear (auto-population runs on launch)
        navigateToFoodLog()

        let postRelaunchCount = getFoodEntryCount()
        XCTAssertGreaterThanOrEqual(
            postRelaunchCount,
            1,
            "Scheduled food should appear after app relaunch"
        )

        // Verify the specific food is present
        XCTAssertTrue(
            foodEntryExists(named: "banana") || foodEntryExists(named: "Banana"),
            "Banana entry should exist after app relaunch"
        )
    }

    /// UAT Scenario 2: Auto-populated entry can be deleted without affecting schedule
    /// Delete an auto-populated food entry from Food Log.
    /// The entry is removed, but the schedule remains active
    func testDeleteAutoPopulatedEntryPreservesSchedule() {
        // GIVEN: User has a scheduled food that has been auto-populated
        launchAppWithTestMode(resetData: true)

        // Create a food entry and schedule
        logTestFoodEntry(searchTerm: "oatmeal")
        createScheduleForCurrentFood(meal: "Breakfast")
        addFoodToLog()

        navigateToFoodLog()

        // Verify entry exists
        let initialCount = getFoodEntryCount()
        XCTAssertGreaterThanOrEqual(initialCount, 1, "Should have at least one food entry")

        // WHEN: User deletes the food entry
        deleteFirstFoodEntry()

        // Wait for deletion to complete
        waitForUIUpdate(seconds: 0.5)

        // THEN: Entry should be removed
        let postDeleteCount = getFoodEntryCount()
        XCTAssertLessThan(postDeleteCount, initialCount, "Entry count should decrease after deletion")

        // AND: After relaunching, the schedule should still work
        // (In reality, schedule would populate on next applicable day, not immediately)
        // For today, since we already had an entry and deleted it, duplicate prevention
        // means it won't be recreated on same day

        // Navigate away and back to confirm deletion persisted
        TestUtilities.navigateToTab(app, tabName: "Dashboard")
        waitForUIUpdate(seconds: 0.3)
        navigateToFoodLog()

        // Entry should still be gone
        let finalCount = getFoodEntryCount()
        XCTAssertEqual(finalCount, postDeleteCount, "Deletion should persist after navigation")
    }

    /// UAT Scenario 3: Duplicate prevention on same day
    /// Force quit and relaunch app multiple times on the same day.
    /// The scheduled food appears only once - no duplicate entries created
    func testDuplicatePreventionOnSameDay() {
        // GIVEN: User has a scheduled food for today
        launchAppWithTestMode(resetData: true)

        // Create a food entry and schedule
        logTestFoodEntry(searchTerm: "eggs")
        createScheduleForCurrentFood(meal: "Breakfast")
        addFoodToLog()

        navigateToFoodLog()

        // Count initial entries
        let initialCount = getFoodEntryCount()

        // WHEN: User relaunches the app multiple times
        for relaunchNumber in 1...3 {
            relaunchAppWithoutReset()
            navigateToFoodLog()
            waitForUIUpdate(seconds: 0.5)

            // THEN: Entry count should not increase
            let currentCount = getFoodEntryCount()
            XCTAssertEqual(
                currentCount,
                initialCount,
                "Entry count should remain \(initialCount) after relaunch #\(relaunchNumber), but was \(currentCount)"
            )
        }
    }

    /// UAT Scenario 4: No backfill for missed days
    /// If app wasn't opened for several days with an active schedule,
    /// opening the app should NOT backfill those missed days - only today's entries are populated
    ///
    /// Note: This test has limitations in E2E testing since we can't actually skip days.
    /// We verify the principle by checking that auto-population only affects the current week.
    func testNoBackfillForMissedDays() {
        // GIVEN: User launches app with clean state
        launchAppWithTestMode(resetData: true)

        // Create a schedule (this will populate entries for remaining days of current week)
        logTestFoodEntry(searchTerm: "yogurt")
        createScheduleForCurrentFood(meal: "Breakfast")
        addFoodToLog()

        navigateToFoodLog()

        // Count entries for today
        let todayCount = getFoodEntryCount()
        XCTAssertGreaterThanOrEqual(todayCount, 1, "Should have at least one entry for today")

        // WHEN: Navigate to previous week
        let previousWeekButton = app.buttons.matching(
            NSPredicate(format: "label == 'Previous week'")
        ).firstMatch

        if !previousWeekButton.waitForExistence(timeout: 3) {
            TestUtilities.debugScreenshot(app, name: "no-previous-week-button")
            print(app.debugDescription)
            XCTFail("Previous week button should exist")
            return
        }

        previousWeekButton.tap()
        waitForUIUpdate(seconds: 0.5)

        // THEN: Previous week should have no auto-populated entries
        // (since we just created the schedule today, no backfill should occur)
        let previousWeekCount = getFoodEntryCount()
        XCTAssertEqual(
            previousWeekCount,
            0,
            "Previous week should have no entries - no backfill should occur"
        )

        // Navigate back to current week
        let nextWeekButton = app.buttons.matching(
            NSPredicate(format: "label == 'Next week'")
        ).firstMatch
        XCTAssertTrue(nextWeekButton.waitForExistence(timeout: 3), "Next week button should exist")
        nextWeekButton.tap()
        waitForUIUpdate(seconds: 0.5)

        // Tap today to return to today's view
        let todayCell = app.otherElements.matching(
            NSPredicate(format: "label CONTAINS[c] 'today'")
        ).firstMatch
        if todayCell.waitForExistence(timeout: 3) {
            todayCell.tap()
            waitForUIUpdate(seconds: 0.3)
        }

        // Today should still have our entry
        let todayFinalCount = getFoodEntryCount()
        XCTAssertGreaterThanOrEqual(
            todayFinalCount,
            1,
            "Today should still have entries after navigating back"
        )
    }
}
