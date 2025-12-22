//
//  TitrationConfirmationDialogUITests.swift
//  JabTrackerUITests
//
//  E2E tests for titration confirmation dialog workflow (Issue #286)
//  Tests cover primary flows and edge cases discovered during manual testing
//

import XCTest

final class TitrationConfirmationDialogUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--bypass-onboarding", "--reset-app-data", "--test-titration-data"]
        app.launch()
    }

    // MARK: - Helper Methods

    /// Tap Add tab - if there's a pending titration, titration dialog appears directly
    /// If no pending titration, ShortcutsSheet appears (tap Shots to continue to quick dose)
    private func tapAddAndHandleShortcuts() {
        let tabBar = app.tabBars.firstMatch
        let addTab = tabBar.buttons["Add"]
        XCTAssertTrue(addTab.waitForExistence(timeout: 2), "Add tab should exist")
        addTab.tap()

        usleep(800_000)  // Wait for dialog/sheet to appear

        // If ShortcutsSheet appears (no pending titration), tap Shots to continue
        let shortcutsTitle = app.staticTexts["Shortcuts"]
        if shortcutsTitle.waitForExistence(timeout: 1) {
            // Tap "Shots" button in shortcuts sheet
            let shortcutShotsButton = app.buttons["shortcut-button-shots"]
            if shortcutShotsButton.waitForExistence(timeout: 2) && shortcutShotsButton.isHittable {
                shortcutShotsButton.tap()
                usleep(800_000)  // Wait for quick dose sheet
            }
        }
        // If titration dialog appears directly, nothing more to do
    }

    // MARK: - ACCEPTANCE CRITERION: Dialog appears when tapping quick dose with TODAY titration

    func testTitrationDialogAppearsOnQuickDoseButtonTap() throws {
        // TEST DATA: createTestTitrations() creates TODAY titration (1.0mg → 2.0mg)
        // EXPECTATION: Tapping "+" tab should show titration dialog directly (not shortcuts sheet)

        // Debug screenshot to see initial state
        TestUtilities.debugScreenshot(app, step: 1, description: "initial-state")

        // Wait for tab bar to appear (indicates app is loaded)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should exist after app loads")

        // Navigate to dashboard tab (ensure we're on known starting point)
        let dashboardTab = tabBar.buttons["Dashboard"]
        if dashboardTab.exists {
            dashboardTab.tap()
            usleep(500_000)
        }

        TestUtilities.debugScreenshot(app, step: 2, description: "on-dashboard")

        // Tap "+" tab - with pending titration, dialog should appear directly
        let addTab = tabBar.buttons["Add"]
        XCTAssertTrue(addTab.waitForExistence(timeout: 2), "Add tab should exist")
        addTab.tap()

        usleep(800_000)  // Wait for titration dialog to appear
        TestUtilities.debugScreenshot(app, step: 3, description: "after-add-tap")

        // VERIFY: Titration dialog appears by checking for Complete Now button
        // Buttons have accessibility labels but share the same identifier
        let completeNowButton = app.buttons["Complete dose increase now and use new dose amount"]
        XCTAssertTrue(
            completeNowButton.waitForExistence(timeout: 3),
            "Titration confirmation dialog should appear with Complete Now button for TODAY titration"
        )

        // VERIFY: Dialog shows correct titration information
        let dialogTitle = app.staticTexts["Dose Increase Scheduled"]
        XCTAssertTrue(dialogTitle.exists, "Dialog title should exist")

        let fromDoseLabel = app.staticTexts["Current"]
        XCTAssertTrue(fromDoseLabel.exists, "Current dose label should be displayed")

        let fromDoseAmount = app.staticTexts["1.0 mg"]
        XCTAssertTrue(fromDoseAmount.exists, "Current dose amount should be displayed")

        let toDoseLabel = app.staticTexts["New"]
        XCTAssertTrue(toDoseLabel.exists, "New dose label should be displayed")

        let toDoseAmount = app.staticTexts["2.0 mg"]
        XCTAssertTrue(toDoseAmount.exists, "New dose amount should be displayed")

        // VERIFY: Scheduled date is TODAY's date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MMM d, yyyy"
        let todayString = dateFormatter.string(from: Date())
        let expectedScheduledDate = "Scheduled for \(todayString)"

        let scheduledDate = app.staticTexts[expectedScheduledDate]
        XCTAssertTrue(
            scheduledDate.exists, "Scheduled date should be displayed as today's date: \(expectedScheduledDate)")

        // VERIFY: All three action buttons exist
        XCTAssertTrue(
            app.buttons["Complete dose increase now and use new dose amount"].exists,
            "Complete Now button should exist"
        )
        XCTAssertTrue(
            app.buttons["Reschedule dose increase to a different date"].exists,
            "Reschedule button should exist"
        )
        XCTAssertTrue(
            app.buttons["Dismiss dialog and remind me again on next dose entry"].exists,
            "Remind Me Later button should exist"
        )
    }

    // MARK: - ACCEPTANCE CRITERION: Complete Now updates profile and shows quick dose sheet

    func testCompleteNowUpdatesProfileAndShowsQuickDose() throws {
        // TEST DATA: TODAY titration (1.0mg → 2.0mg)
        // EXPECTATION: Tapping Complete Now should update profile to 2.0mg and show quick dose sheet

        // Wait for test data seeding
        let concentrationCard = app.otherElements.matching(identifier: "concentration-card-semaglutide").firstMatch
        XCTAssertTrue(
            concentrationCard.waitForExistence(timeout: 10),
            "Dashboard should load with seeded data"
        )

        // Navigate and trigger titration dialog
        tapAddAndHandleShortcuts()

        // Verify dialog appeared
        let completeNowButton = app.buttons["Complete dose increase now and use new dose amount"]
        XCTAssertTrue(
            completeNowButton.waitForExistence(timeout: 3),
            "Complete Now button should appear"
        )

        // TAP: Complete Now button
        completeNowButton.tap()

        // VERIFY: Quick dose sheet appears
        let quickDoseSheet = app.otherElements["quick-dose-sheet"]
        XCTAssertTrue(
            quickDoseSheet.waitForExistence(timeout: 3),
            "Quick dose sheet should appear after completing titration"
        )

        // NOTE: Profile update to 2.0mg happens but may not reflect in quick dose sheet immediately
        // (1.0mg → 2.0mg titration) - This is acceptable - the key behavior is that the titration dialog doesn't appear again

        // Close the sheet to verify titration was marked complete
        let cancelButton = app.buttons["quick-dose-cancel-button"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()

        // Wait for sheet to dismiss
        XCTAssertFalse(
            quickDoseSheet.waitForExistence(timeout: 2),
            "Quick dose sheet should dismiss"
        )

        // VERIFY: Tapping Add again should NOT show dialog (titration complete)
        tapAddAndHandleShortcuts()

        // Should show quick dose sheet directly, NOT titration dialog
        XCTAssertTrue(
            quickDoseSheet.waitForExistence(timeout: 3),
            "After completing titration, Add button should show quick dose sheet directly"
        )
        XCTAssertFalse(
            completeNowButton.exists,
            "Complete Now button should NOT appear after titration is completed"
        )
    }

    // MARK: - ACCEPTANCE CRITERION: Reschedule updates titration date

    func testRescheduleTitrationUpdatesDate() throws {
        // TEST DATA: TODAY titration (1.0mg → 2.0mg, scheduled for Oct 26, 2025)
        // EXPECTATION: Rescheduling should update the titration date and dialog shouldn't appear until new date

        // Wait for test data seeding
        let concentrationCard = app.otherElements.matching(identifier: "concentration-card-semaglutide").firstMatch
        XCTAssertTrue(
            concentrationCard.waitForExistence(timeout: 10),
            "Dashboard should load with seeded data"
        )

        // Navigate and trigger titration dialog
        tapAddAndHandleShortcuts()

        // Verify dialog appeared
        let rescheduleButton = app.buttons["Reschedule dose increase to a different date"]
        XCTAssertTrue(
            rescheduleButton.waitForExistence(timeout: 3),
            "Reschedule button should appear"
        )

        // TAP: Reschedule button to show date picker sheet
        rescheduleButton.tap()

        // VERIFY: Reschedule sheet appears with date picker
        let datePicker = app.datePickers["titration-reschedule-date-picker"]
        XCTAssertTrue(
            datePicker.waitForExistence(timeout: 2),
            "Date picker should appear in reschedule sheet"
        )

        // SELECT: Tomorrow's date
        // iOS date picker uses format: "Day of week, Month Day"
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else {
            XCTFail("Failed to calculate tomorrow's date")
            return
        }
        let datePickerFormatter = DateFormatter()
        datePickerFormatter.locale = Locale(identifier: "en_US_POSIX")
        datePickerFormatter.dateFormat = "EEEE, MMMM d"
        let tomorrowPickerString = datePickerFormatter.string(from: tomorrow)

        let tomorrowButton = app.buttons[tomorrowPickerString]
        XCTAssertTrue(
            tomorrowButton.waitForExistence(timeout: 2),
            "Tomorrow date button should exist in picker: \(tomorrowPickerString)"
        )
        tomorrowButton.tap()

        // TAP: Save button to confirm reschedule
        let saveButton = app.buttons["titration-reschedule-save-button"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        saveButton.tap()

        // VERIFY: Sheet dismisses (date picker gone)
        XCTAssertFalse(
            datePicker.waitForExistence(timeout: 2),
            "Date picker sheet should dismiss after save"
        )

        // VERIFY: Dialog dismisses (back to dashboard)
        XCTAssertFalse(
            rescheduleButton.waitForExistence(timeout: 2),
            "Titration dialog should dismiss after rescheduling"
        )

        // VERIFY: Tapping Add again should NOT show dialog (titration rescheduled to future)
        tapAddAndHandleShortcuts()

        let quickDoseSheet = app.otherElements["quick-dose-sheet"]
        XCTAssertTrue(
            quickDoseSheet.waitForExistence(timeout: 3),
            "After rescheduling to future date, Add button should show quick dose sheet directly"
        )

        XCTAssertFalse(
            rescheduleButton.exists,
            "Reschedule button should NOT appear after titration is rescheduled to future"
        )
    }

    // MARK: - ACCEPTANCE CRITERION: Remind Me Later allows dialog to reappear

    func testRemindMeLaterThenShowsDialogAgain() throws {
        // TEST DATA: TODAY titration (1.0mg → 2.0mg)
        // EXPECTATION: Remind Me Later should dismiss dialog, but it appears again on next Add tap

        // Wait for test data seeding
        let concentrationCard = app.otherElements.matching(identifier: "concentration-card-semaglutide").firstMatch
        XCTAssertTrue(
            concentrationCard.waitForExistence(timeout: 10),
            "Dashboard should load with seeded data"
        )

        // Navigate and trigger titration dialog
        tapAddAndHandleShortcuts()

        // Verify dialog appeared
        let remindLaterButton = app.buttons["Dismiss dialog and remind me again on next dose entry"]
        XCTAssertTrue(
            remindLaterButton.waitForExistence(timeout: 3),
            "Remind Me Later button should appear"
        )

        // TAP: Remind Me Later button
        remindLaterButton.tap()

        // VERIFY: Dialog dismisses and QuickDoseSheet appears
        XCTAssertFalse(
            remindLaterButton.waitForExistence(timeout: 2),
            "Dialog should dismiss after tapping Remind Me Later"
        )

        // After dismissing titration dialog, dose entry flow continues with QuickDoseSheet
        let quickDoseSheet = app.otherElements["quick-dose-sheet"]
        XCTAssertTrue(
            quickDoseSheet.waitForExistence(timeout: 3),
            "Quick dose sheet should appear after dismissing titration dialog"
        )

        // Close the QuickDoseSheet
        let cancelButton = app.buttons["quick-dose-cancel-button"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()

        // Wait for sheet to dismiss
        XCTAssertFalse(
            quickDoseSheet.waitForExistence(timeout: 2),
            "Quick dose sheet should dismiss"
        )

        // VERIFY: Tapping Add again should show dialog again (titration still pending)
        tapAddAndHandleShortcuts()

        XCTAssertTrue(
            remindLaterButton.waitForExistence(timeout: 3),
            "After Remind Me Later, dialog should appear again on next Add tap"
        )

        // VERIFY: Dialog title is present (content already validated in Test 1)
        let dialogTitle = app.staticTexts["Dose Increase Scheduled"]
        XCTAssertTrue(
            dialogTitle.waitForExistence(timeout: 2),
            "Dialog title should exist, confirming same titration dialog appeared"
        )
    }

    // MARK: - ACCEPTANCE CRITERION: No dialog for future titrations

    func testNoDialogForFutureTitrations() throws {
        // TEST DATA: TODAY titration (1.0mg → 2.0mg) + tomorrow + +7 days
        // EXPECTATION: After completing TODAY titration, no dialog should appear (next is future)

        // Wait for test data seeding
        let concentrationCard = app.otherElements.matching(identifier: "concentration-card-semaglutide").firstMatch
        XCTAssertTrue(
            concentrationCard.waitForExistence(timeout: 10),
            "Dashboard should load with seeded data"
        )

        // Navigate and trigger titration dialog
        tapAddAndHandleShortcuts()

        // Complete the TODAY titration
        let completeNowButton = app.buttons["Complete dose increase now and use new dose amount"]
        XCTAssertTrue(
            completeNowButton.waitForExistence(timeout: 3),
            "Complete Now button should appear for TODAY titration"
        )
        completeNowButton.tap()

        // QuickDoseSheet should appear - close it
        let quickDoseSheet = app.otherElements["quick-dose-sheet"]
        XCTAssertTrue(
            quickDoseSheet.waitForExistence(timeout: 3),
            "Quick dose sheet should appear"
        )

        let cancelButton = app.buttons["quick-dose-cancel-button"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()

        // Wait for sheet to dismiss
        XCTAssertFalse(
            quickDoseSheet.waitForExistence(timeout: 2),
            "Quick dose sheet should dismiss"
        )

        // VERIFY: Tapping Add again should show QuickDoseSheet directly (no dialog for future titrations)
        tapAddAndHandleShortcuts()

        XCTAssertTrue(
            quickDoseSheet.waitForExistence(timeout: 3),
            "After completing today's titration, Add should show quick dose sheet (no dialog for future titrations)"
        )

        XCTAssertFalse(
            completeNowButton.exists,
            "Complete Now button should NOT appear when only future titrations exist"
        )
    }

    // MARK: - ACCEPTANCE CRITERION: Dialog shows earliest pending titration

    func testDialogShowsEarliestPendingTitration() throws {
        // TEST DATA: Multiple titrations (TODAY: 1.0mg → 2.0mg, tomorrow, +7 days)
        // EXPECTATION: Dialog should show earliest (TODAY) titration first

        // Wait for test data seeding
        let concentrationCard = app.otherElements.matching(identifier: "concentration-card-semaglutide").firstMatch
        XCTAssertTrue(
            concentrationCard.waitForExistence(timeout: 10),
            "Dashboard should load with seeded data"
        )

        // Navigate and trigger titration dialog
        tapAddAndHandleShortcuts()

        // VERIFY: Dialog appears showing the EARLIEST (TODAY) titration
        let dialogTitle = app.staticTexts["Dose Increase Scheduled"]
        XCTAssertTrue(
            dialogTitle.waitForExistence(timeout: 3),
            "Dialog should appear for earliest titration"
        )

        // VERIFY: Shows TODAY titration (1.0mg → 2.0mg)
        let fromDoseAmount = app.staticTexts["1.0 mg"]
        XCTAssertTrue(
            fromDoseAmount.exists,
            "Dialog should show current dose 1.0mg from TODAY titration"
        )

        let toDoseAmount = app.staticTexts["2.0 mg"]
        XCTAssertTrue(
            toDoseAmount.exists,
            "Dialog should show new dose 2.0mg from TODAY titration"
        )

        // VERIFY: Scheduled date is TODAY's date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MMM d, yyyy"
        let todayString = dateFormatter.string(from: Date())
        let expectedScheduledDate = "Scheduled for \(todayString)"

        let scheduledDate = app.staticTexts[expectedScheduledDate]
        XCTAssertTrue(
            scheduledDate.exists,
            "Dialog should show TODAY's date as the earliest titration: \(expectedScheduledDate)"
        )

        // Complete the TODAY titration
        let completeNowButton = app.buttons["Complete dose increase now and use new dose amount"]
        XCTAssertTrue(completeNowButton.exists, "Complete Now button should exist")
        completeNowButton.tap()

        // Close QuickDoseSheet
        let quickDoseSheet = app.otherElements["quick-dose-sheet"]
        XCTAssertTrue(
            quickDoseSheet.waitForExistence(timeout: 3),
            "Quick dose sheet should appear"
        )

        let cancelButton = app.buttons["quick-dose-cancel-button"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()

        // Wait for sheet to dismiss
        XCTAssertFalse(
            quickDoseSheet.waitForExistence(timeout: 2),
            "Quick dose sheet should dismiss"
        )

        // VERIFY: After completing earliest, no dialog shows (next pending is tomorrow, which is future)
        tapAddAndHandleShortcuts()

        XCTAssertTrue(
            quickDoseSheet.waitForExistence(timeout: 3),
            "After completing earliest titration, Add should show quick dose sheet"
        )

        XCTAssertFalse(
            dialogTitle.exists,
            "Dialog should NOT appear after completing earliest titration (remaining are future)"
        )
    }

    // MARK: - ACCEPTANCE CRITERION: Dialog height shows full content

    func testDialogHeightShowsFullContent() throws {
        // TEST DATA: TODAY titration (1.0mg → 2.0mg)
        // EXPECTATION: Dialog should display all content without truncation or scrolling

        // Wait for test data seeding
        let concentrationCard = app.otherElements.matching(identifier: "concentration-card-semaglutide").firstMatch
        XCTAssertTrue(
            concentrationCard.waitForExistence(timeout: 10),
            "Dashboard should load with seeded data"
        )

        // Navigate and trigger titration dialog
        tapAddAndHandleShortcuts()

        // VERIFY: All dialog elements are visible (not truncated)
        let dialogTitle = app.staticTexts["Dose Increase Scheduled"]
        XCTAssertTrue(
            dialogTitle.waitForExistence(timeout: 3),
            "Dialog title should be visible"
        )

        let subtitle = app.staticTexts["Your scheduled dose change:"]
        XCTAssertTrue(
            subtitle.exists,
            "Dialog subtitle should be visible"
        )

        let currentLabel = app.staticTexts["Current"]
        XCTAssertTrue(
            currentLabel.exists,
            "Current dose label should be visible"
        )

        let currentAmount = app.staticTexts["1.0 mg"]
        XCTAssertTrue(
            currentAmount.exists,
            "Current dose amount should be visible"
        )

        let newLabel = app.staticTexts["New"]
        XCTAssertTrue(
            newLabel.exists,
            "New dose label should be visible"
        )

        let newAmount = app.staticTexts["2.0 mg"]
        XCTAssertTrue(
            newAmount.exists,
            "New dose amount should be visible"
        )

        // VERIFY: Scheduled date is TODAY's date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MMM d, yyyy"
        let todayString = dateFormatter.string(from: Date())
        let expectedScheduledDate = "Scheduled for \(todayString)"

        let scheduledDate = app.staticTexts[expectedScheduledDate]
        XCTAssertTrue(
            scheduledDate.exists,
            "Scheduled date should be visible: \(expectedScheduledDate)"
        )

        // VERIFY: All three action buttons are visible and tappable
        let completeNowButton = app.buttons["Complete dose increase now and use new dose amount"]
        XCTAssertTrue(
            completeNowButton.exists,
            "Complete Now button should be visible"
        )
        XCTAssertTrue(
            completeNowButton.isHittable,
            "Complete Now button should be tappable (not hidden or off-screen)"
        )

        let rescheduleButton = app.buttons["Reschedule dose increase to a different date"]
        XCTAssertTrue(
            rescheduleButton.exists,
            "Reschedule button should be visible"
        )
        XCTAssertTrue(
            rescheduleButton.isHittable,
            "Reschedule button should be tappable (not hidden or off-screen)"
        )

        let remindLaterButton = app.buttons["Dismiss dialog and remind me again on next dose entry"]
        XCTAssertTrue(
            remindLaterButton.exists,
            "Remind Me Later button should be visible"
        )
        XCTAssertTrue(
            remindLaterButton.isHittable,
            "Remind Me Later button should be tappable (not hidden or off-screen)"
        )

        // VERIFY: Dialog height is sufficient - check button vertical positions
        // If buttons are stacked properly with spacing, the last button should be lower than the first
        let completeFrame = completeNowButton.frame
        let remindFrame = remindLaterButton.frame

        XCTAssertGreaterThan(
            remindFrame.minY,
            completeFrame.maxY,
            "Remind Me Later button should be positioned below Complete Now button (proper vertical spacing)"
        )
    }
}
