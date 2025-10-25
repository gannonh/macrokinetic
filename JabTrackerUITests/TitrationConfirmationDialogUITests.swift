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
        app.launchArguments = ["--ui-testing", "--bypass-onboarding", "--test-titration-data"]
        app.launch()
    }

    // MARK: - ACCEPTANCE CRITERION: Dialog appears when tapping quick dose with TODAY titration

    func testTitrationDialogAppearsOnQuickDoseButtonTap() throws {
        // TEST DATA: createTestTitrations() creates TODAY titration (1.0mg → 2.0mg)
        // EXPECTATION: Tapping "+" tab should show titration dialog, not quick dose sheet

        // Wait for test data seeding to complete by checking for dashboard elements
        // The concentration card only appears when medication profiles and doses are loaded
        let concentrationCard = app.otherElements.matching(identifier: "concentration-card-semaglutide").firstMatch
        XCTAssertTrue(
            concentrationCard.waitForExistence(timeout: 10),
            "Dashboard should load with seeded medication data before testing titration dialog"
        )

        // Navigate to home tab (ensure we're on known starting point)
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 3), "Tab bar should exist")

        let homeTab = tabBar.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
            usleep(500_000)  // 0.5s for tab switch
        }

        // Tap "+" tab to trigger dose entry flow
        let addTab = tabBar.buttons["Add"]
        XCTAssertTrue(addTab.waitForExistence(timeout: 2), "Add tab should exist")
        addTab.tap()
        usleep(1_000_000)  // 1s for dialog presentation

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

        let fromDoseAmount = app.staticTexts["2.0 mg"]
        XCTAssertTrue(fromDoseAmount.exists, "Current dose amount should be displayed")

        let toDoseLabel = app.staticTexts["New"]
        XCTAssertTrue(toDoseLabel.exists, "New dose label should be displayed")

        let toDoseAmount = app.staticTexts["3.0 mg"]
        XCTAssertTrue(toDoseAmount.exists, "New dose amount should be displayed")

        let scheduledDate = app.staticTexts["Scheduled for Oct 25, 2025"]
        XCTAssertTrue(scheduledDate.exists, "Scheduled date should be displayed")

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
}
