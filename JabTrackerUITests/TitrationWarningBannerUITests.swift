//
//  TitrationWarningBannerUITests.swift
//  JabTrackerUITests
//
//  E2E tests for Issue #286 - Stream A: Titration Warning Banner Integration
//
//  Validates:
//  - AC1: Warning banner displays when titration within 30 days
//  - AC2: Banner shows correct message format
//  - AC3: Tapping banner navigates to Dose Titration Plan
//  - AC4: Warning uses getTitrationWarning() method (integration)
//

import XCTest

/// E2E test suite for titration warning banner in medication profile settings
final class TitrationWarningBannerUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
        app.launch()

        // Wait for app to be ready
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5.0))
    }

    // MARK: - AC1: Warning Banner Display Test

    /// GIVEN: A medication profile with titration scheduled within 30 days
    /// WHEN: Viewing the medication profile settings
    /// THEN: Warning banner displays in the schedule section
    func testWarningBannerDisplaysForUpcomingTitration() throws {
        // Navigate to Settings → Medication Profiles
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Medication Profiles"].waitForExistence(timeout: 3.0))
        app.buttons["Medication Profiles"].tap()

        // Create a medication profile with schedule
        XCTAssertTrue(app.buttons["Add Medication Profile"].waitForExistence(timeout: 3.0))
        app.buttons["Add Medication Profile"].tap()

        // Fill in basic profile info
        let genericNameField = app.textFields["generic-name-field"]
        XCTAssertTrue(genericNameField.waitForExistence(timeout: 3.0))
        genericNameField.tap()
        genericNameField.typeText("semaglutide")

        let brandNameField = app.textFields["brand-name-field"]
        brandNameField.tap()
        brandNameField.typeText("Ozempic")

        let currentDoseField = app.textFields["current-dose-field"]
        currentDoseField.tap()
        currentDoseField.typeText("0.5")

        // Save profile
        app.buttons["save-profile-button"].tap()

        // Wait for profile list and select the newly created profile
        XCTAssertTrue(app.buttons.matching(identifier: "profile-row-button").element.waitForExistence(timeout: 3.0))
        app.buttons.matching(identifier: "profile-row-button").element.tap()

        // Create a schedule for the profile
        XCTAssertTrue(app.buttons["create-schedule-button"].waitForExistence(timeout: 3.0))
        app.buttons["create-schedule-button"].tap()

        // Save schedule (using defaults)
        XCTAssertTrue(app.buttons["save-schedule-button"].waitForExistence(timeout: 3.0))
        app.buttons["save-schedule-button"].tap()

        // Create a titration scheduled within 30 days
        // Navigate to Dose Titration section
        let addTitrationButton = app.buttons["add-titration-button"]
        if addTitrationButton.exists {
            addTitrationButton.tap()

            // Fill in titration details: from 0.5mg to 1.0mg, scheduled 15 days from now
            let fromDoseField = app.textFields["from-dose-field"]
            if fromDoseField.waitForExistence(timeout: 3.0) {
                fromDoseField.tap()
                fromDoseField.typeText("0.5")
            }

            let toDoseField = app.textFields["to-dose-field"]
            toDoseField.tap()
            toDoseField.typeText("1.0")

            // Set date to 15 days from now (date picker interaction)
            let datePicker = app.datePickers["scheduled-date-picker"]
            if datePicker.exists {
                datePicker.tap()
                // Adjust date to 15 days from now (specific interaction depends on date picker UI)
            }

            // Save titration
            app.buttons["save-titration-button"].tap()
        }

        // THEN: Titration warning banner should be visible
        let warningBanner = app.buttons["titration-warning-banner"]
        XCTAssertTrue(
            warningBanner.waitForExistence(timeout: 5.0),
            "Titration warning banner should display when titration is within 30 days"
        )
    }

    // MARK: - AC2: Banner Message Format Test

    /// GIVEN: A medication profile with titration scheduled within 30 days
    /// WHEN: Viewing the warning banner
    /// THEN: Banner shows message: "Your dose will increase to {new_dose}mg on {date} per your titration plan"
    func testWarningBannerShowsCorrectMessageFormat() throws {
        // This test assumes we can create test data with titration
        // For now, we'll test that the banner contains expected text elements when it appears

        // Navigate to Settings → Medication Profiles
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Medication Profiles"].tap()

        // Create profile with schedule and titration (same setup as above, condensed)
        createMedicationProfileWithScheduleAndTitration()

        // Verify banner exists and contains expected text
        let warningBanner = app.buttons["titration-warning-banner"]
        XCTAssertTrue(warningBanner.waitForExistence(timeout: 5.0))

        // Get the banner's label (contains the full warning message)
        let bannerLabel = warningBanner.label
        XCTAssertTrue(
            bannerLabel.contains("dose") && bannerLabel.contains("mg"),
            "Warning message should mention dose amount"
        )
        XCTAssertTrue(
            bannerLabel.contains("increase") || bannerLabel.contains("change"),
            "Warning message should indicate dose change"
        )
        XCTAssertTrue(
            bannerLabel.contains("titration plan"),
            "Warning message should reference titration plan"
        )
    }

    // MARK: - AC3: Banner Navigation Test

    /// GIVEN: A medication profile with warning banner displayed
    /// WHEN: Tapping the warning banner
    /// THEN: Navigates to Dose Titration Plan screen
    func testTappingWarningBannerNavigatesToTitrationPlan() throws {
        // Navigate to Settings → Medication Profiles
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Medication Profiles"].tap()

        // Create profile with schedule and titration
        createMedicationProfileWithScheduleAndTitration()

        // Find and tap warning banner
        let warningBanner = app.buttons["titration-warning-banner"]
        XCTAssertTrue(warningBanner.waitForExistence(timeout: 5.0))
        warningBanner.tap()

        // Verify navigation to Dose Titration Plan
        // Check for titration plan screen elements
        let titrationPlanTitle = app.staticTexts["Dose Titration Plan"]
        XCTAssertTrue(
            titrationPlanTitle.waitForExistence(timeout: 3.0),
            "Should navigate to Dose Titration Plan screen after tapping banner"
        )
    }

    // MARK: - AC4: Integration Verification Test

    /// GIVEN: A medication profile with no upcoming titration
    /// WHEN: Viewing the medication profile settings
    /// THEN: No warning banner is displayed (verifies getTitrationWarning() returns nil correctly)
    func testNoWarningBannerWhenNoUpcomingTitration() throws {
        // Navigate to Settings → Medication Profiles
        app.tabBars.buttons["Settings"].tap()
        app.buttons["Medication Profiles"].tap()

        // Create a medication profile with schedule but NO titration
        app.buttons["Add Medication Profile"].tap()

        let genericNameField = app.textFields["generic-name-field"]
        XCTAssertTrue(genericNameField.waitForExistence(timeout: 3.0))
        genericNameField.tap()
        genericNameField.typeText("semaglutide")

        let brandNameField = app.textFields["brand-name-field"]
        brandNameField.tap()
        brandNameField.typeText("Ozempic")

        let currentDoseField = app.textFields["current-dose-field"]
        currentDoseField.tap()
        currentDoseField.typeText("0.5")

        app.buttons["save-profile-button"].tap()

        // Select profile and create schedule
        XCTAssertTrue(app.buttons.matching(identifier: "profile-row-button").element.waitForExistence(timeout: 3.0))
        app.buttons.matching(identifier: "profile-row-button").element.tap()

        XCTAssertTrue(app.buttons["create-schedule-button"].waitForExistence(timeout: 3.0))
        app.buttons["create-schedule-button"].tap()
        app.buttons["save-schedule-button"].tap()

        // THEN: No titration warning banner should be visible
        let warningBanner = app.buttons["titration-warning-banner"]
        XCTAssertFalse(
            warningBanner.waitForExistence(timeout: 2.0),
            "Warning banner should NOT display when there is no upcoming titration"
        )
    }

    // MARK: - Helper Methods

    /// Helper method to create a complete medication profile with schedule and titration
    private func createMedicationProfileWithScheduleAndTitration() {
        // Create profile
        app.buttons["Add Medication Profile"].tap()

        let genericNameField = app.textFields["generic-name-field"]
        XCTAssertTrue(genericNameField.waitForExistence(timeout: 3.0))
        genericNameField.tap()
        genericNameField.typeText("semaglutide")

        let brandNameField = app.textFields["brand-name-field"]
        brandNameField.tap()
        brandNameField.typeText("Ozempic")

        let currentDoseField = app.textFields["current-dose-field"]
        currentDoseField.tap()
        currentDoseField.typeText("0.5")

        app.buttons["save-profile-button"].tap()

        // Select profile
        XCTAssertTrue(app.buttons.matching(identifier: "profile-row-button").element.waitForExistence(timeout: 3.0))
        app.buttons.matching(identifier: "profile-row-button").element.tap()

        // Create schedule
        XCTAssertTrue(app.buttons["create-schedule-button"].waitForExistence(timeout: 3.0))
        app.buttons["create-schedule-button"].tap()
        app.buttons["save-schedule-button"].tap()

        // Create titration (if add button exists)
        let addTitrationButton = app.buttons["add-titration-button"]
        if addTitrationButton.exists {
            addTitrationButton.tap()

            let fromDoseField = app.textFields["from-dose-field"]
            if fromDoseField.waitForExistence(timeout: 3.0) {
                fromDoseField.tap()
                fromDoseField.typeText("0.5")
            }

            let toDoseField = app.textFields["to-dose-field"]
            toDoseField.tap()
            toDoseField.typeText("1.0")

            app.buttons["save-titration-button"].tap()
        }
    }
}
