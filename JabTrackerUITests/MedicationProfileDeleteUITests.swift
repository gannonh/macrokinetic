import XCTest

/// E2E tests for medication profile deletion (disable vs permanent delete)
final class MedicationProfileDeleteUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDisableMedicationProfile() throws {
        // Setup: Launch app with 90 days of seeded test data
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "90"
        app.launchEnvironment["TEST_DATA_MEDICATION"] = "semaglutide"
        app.launchEnvironment["TEST_DATA_BRAND"] = "Ozempic"
        app.launchEnvironment["TEST_DATA_DOSE"] = "1.0"  // Use 1.0mg to match actual seeded data
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5.0))

        // Verify historical doses exist
        app.tabBars.buttons["History"].tap()

        let historyList = app.collectionViews["dose-history-list"]
        XCTAssertTrue(historyList.waitForExistence(timeout: 5.0))
        let initialDoseCount = historyList.cells.count
        print("📊 Initial dose count: \(initialDoseCount)")
        XCTAssertTrue(initialDoseCount > 0, "Should have dose history (90 days)")

        // Navigate to medication profiles
        app.tabBars.buttons["Settings"].tap()
        let medicationProfilesButton = app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: 3.0))
        medicationProfilesButton.tap()

        // Disable the profile (1.0mg dose)
        let profileCell = app.buttons.matching(
            identifier: "medication-profile-semaglutide-ozempic-1.00mg"
        ).firstMatch
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))

        profileCell.swipeLeft()
        let disableButton = app.buttons["disable-medication-profile"]
        XCTAssertTrue(disableButton.waitForExistence(timeout: 3.0))
        disableButton.tap()

        // Verify profile still appears in list (grayed out with Disabled badge)
        XCTAssertTrue(
            profileCell.waitForExistence(timeout: 3.0),
            "Disabled profile should still appear in list")
        let disabledBadge = app.staticTexts["Disabled"]
        XCTAssertTrue(
            disabledBadge.waitForExistence(timeout: 3.0),
            "Profile should show 'Disabled' badge")

        // Verify disabled profile has Enable and Delete swipe actions (not Disable and Delete)
        profileCell.swipeLeft()
        let enableButton = app.buttons["enable-medication-profile"]
        XCTAssertTrue(
            enableButton.waitForExistence(timeout: 3.0),
            "Disabled profile should have 'Enable' swipe action")

        // Swipe right to close swipe actions
        profileCell.swipeRight()

        // Verify historical doses are PRESERVED
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(historyList.waitForExistence(timeout: 3.0))
        let finalDoseCount = historyList.cells.count
        print("📊 Final dose count: \(finalDoseCount)")
        XCTAssertEqual(
            finalDoseCount,
            initialDoseCount,
            "Historical doses should be preserved after disable")

        // Verify analytics data still exists (doses preserved)
        app.tabBars.buttons["Analytics"].tap()
        let chart = app.otherElements["concentration-timeline-chart"].firstMatch
        XCTAssertTrue(
            chart.waitForExistence(timeout: 10.0),
            "Analytics chart should still exist (historical doses preserved)")
    }

    func testPermanentDeleteRemovesAllData() throws {
        // Setup: Launch app with 90 days of seeded test data
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "90"
        app.launchEnvironment["TEST_DATA_MEDICATION"] = "semaglutide"
        app.launchEnvironment["TEST_DATA_BRAND"] = "Ozempic"
        app.launchEnvironment["TEST_DATA_DOSE"] = "1.0"  // Use 1.0mg to match actual seeded data
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5.0))

        // Verify historical data exists in History tab
        app.tabBars.buttons["History"].tap()

        let historyList = app.collectionViews["dose-history-list"]
        XCTAssertTrue(historyList.waitForExistence(timeout: 5.0))
        let initialDoseCount = historyList.cells.count
        print("📊 Dose count in history: \(initialDoseCount)")
        XCTAssertTrue(initialDoseCount > 0, "Should have dose history (90 days)")

        // Verify analytics data exists
        app.tabBars.buttons["Analytics"].tap()
        let chart = app.otherElements["concentration-timeline-chart"].firstMatch
        XCTAssertTrue(chart.waitForExistence(timeout: 10.0), "Chart should exist with historical data")

        // Navigate to medication profiles
        app.tabBars.buttons["Settings"].tap()
        let medicationProfilesButton = app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: 3.0))
        medicationProfilesButton.tap()

        // Permanently delete the profile (1.0mg dose)
        let profileCell = app.buttons.matching(
            identifier: "medication-profile-semaglutide-ozempic-1.00mg"
        ).firstMatch
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))

        profileCell.swipeLeft()
        let deleteButton = app.buttons["delete-medication-profile"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3.0))
        deleteButton.tap()

        // Confirm permanent deletion using accessibility identifier
        let deletePermanentlyButton = app.buttons["delete-permanently-button"]
        XCTAssertTrue(deletePermanentlyButton.waitForExistence(timeout: 3.0))
        deletePermanentlyButton.tap()

        // Verify profile is removed from list
        XCTAssertFalse(profileCell.waitForExistence(timeout: 3.0))
        let emptyStateLabel = app.staticTexts["No medication profiles yet"]
        XCTAssertTrue(emptyStateLabel.waitForExistence(timeout: 3.0))

        // Verify ALL historical doses are deleted (cascade delete)
        app.tabBars.buttons["History"].tap()
        let emptyHistoryMessage = app.staticTexts["No doses logged yet"]
        XCTAssertTrue(
            emptyHistoryMessage.waitForExistence(timeout: 3.0),
            "History should be empty after permanent delete (cascade delete removes all doses)")

        // Verify analytics data is also gone
        app.tabBars.buttons["Analytics"].tap()
        // Chart should not exist or show empty state
        let emptyAnalyticsMessage = app.staticTexts["No Analytics Data"]
        XCTAssertTrue(
            emptyAnalyticsMessage.waitForExistence(timeout: 5.0) || !chart.exists,
            "Analytics should be empty after permanent delete removes all doses")
    }

    func testCancelDeleteConfirmation() throws {
        // Setup: Launch app with 90 days of seeded test data
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "90"
        app.launchEnvironment["TEST_DATA_MEDICATION"] = "semaglutide"
        app.launchEnvironment["TEST_DATA_BRAND"] = "Ozempic"
        app.launchEnvironment["TEST_DATA_DOSE"] = "1.0"
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5.0))

        // Navigate to medication profiles
        app.tabBars.buttons["Settings"].tap()
        let medicationProfilesButton = app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: 3.0))
        medicationProfilesButton.tap()

        // Start delete action
        let profileCell = app.buttons.matching(
            identifier: "medication-profile-semaglutide-ozempic-1.00mg"
        ).firstMatch
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))

        profileCell.swipeLeft()
        let deleteButton = app.buttons["delete-medication-profile"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3.0))
        deleteButton.tap()

        // Wait for confirmation dialog buttons to appear (use specific identifiers)
        let disableInsteadButton = app.buttons["disable-instead-button"]
        XCTAssertTrue(
            disableInsteadButton.waitForExistence(timeout: 3.0),
            "Should have 'Disable Instead' button")

        let deletePermanentlyButton = app.buttons["delete-permanently-button"]
        XCTAssertTrue(deletePermanentlyButton.exists, "Should have 'Delete Permanently' button")

        let cancelButton = app.buttons["cancel-delete-button"]
        XCTAssertTrue(cancelButton.exists, "Should have 'Cancel' button")

        // Click Cancel
        cancelButton.tap()

        // Verify profile still exists and is still active (no Disabled badge)
        XCTAssertTrue(
            profileCell.waitForExistence(timeout: 3.0),
            "Profile should still exist after cancel")

        let disabledBadge = app.staticTexts["Disabled"]
        XCTAssertFalse(
            disabledBadge.waitForExistence(timeout: 1.0),
            "Profile should NOT show 'Disabled' badge after cancel")

        // Verify profile has Disable and Delete swipe actions (not Enable)
        profileCell.swipeLeft()
        let disableButton = app.buttons["disable-medication-profile"]
        XCTAssertTrue(
            disableButton.waitForExistence(timeout: 3.0),
            "Active profile should have 'Disable' swipe action")
    }

    func testDisabledProfileCannotBeUsedForDoseLogging() throws {
        // Setup: Launch app with test data
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "7"
        app.launchEnvironment["TEST_DATA_MEDICATION"] = "semaglutide"
        app.launchEnvironment["TEST_DATA_BRAND"] = "Ozempic"
        app.launchEnvironment["TEST_DATA_DOSE"] = "1.0"
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5.0))

        // Disable the medication profile
        app.tabBars.buttons["Settings"].tap()
        let medicationProfilesButton = app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: 3.0))
        medicationProfilesButton.tap()

        let profileCell = app.buttons.matching(
            identifier: "medication-profile-semaglutide-ozempic-1.00mg"
        ).firstMatch
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))

        profileCell.swipeLeft()
        let disableButton = app.buttons["disable-medication-profile"]
        XCTAssertTrue(disableButton.waitForExistence(timeout: 3.0))
        disableButton.tap()

        // Verify profile is disabled
        let disabledBadge = app.staticTexts["Disabled"]
        XCTAssertTrue(disabledBadge.waitForExistence(timeout: 3.0))

        // Try to log a dose via Quick Add
        app.tabBars.buttons["Add"].tap()

        // Use debug utilities to find the medication picker
        TestUtilities.debugElements(in: app, containing: "medication")

        // Quick dose sheet should show "No medication profiles found" error
        // because disabled profiles are filtered out
        let errorMessage = app.staticTexts["No medication profiles found. Please create a medication profile first."]
        XCTAssertTrue(
            errorMessage.waitForExistence(timeout: 5.0),
            "Should show error when no active profiles available for dose logging")
    }
    func testReEnablingProfileCreatesSchedule() throws {
        // Setup: Launch app with test data
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
        app.launchEnvironment["TEST_DATA_SEED"] = "true"
        app.launchEnvironment["TEST_DATA_DAYS"] = "7"
        app.launchEnvironment["TEST_DATA_MEDICATION"] = "semaglutide"
        app.launchEnvironment["TEST_DATA_BRAND"] = "Ozempic"
        app.launchEnvironment["TEST_DATA_DOSE"] = "1.0"
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5.0))

        // Disable the profile
        app.tabBars.buttons["Settings"].tap()
        let medicationProfilesButton = app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: 3.0))
        medicationProfilesButton.tap()

        let profileCell = app.buttons.matching(
            identifier: "medication-profile-semaglutide-ozempic-1.00mg"
        ).firstMatch
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))

        profileCell.swipeLeft()
        app.buttons["disable-medication-profile"].tap()

        // Verify disabled
        XCTAssertTrue(app.staticTexts["Disabled"].waitForExistence(timeout: 3.0))

        // Re-enable the profile
        profileCell.swipeLeft()
        let enableButton = app.buttons["enable-medication-profile"]
        XCTAssertTrue(enableButton.waitForExistence(timeout: 3.0))
        enableButton.tap()

        // Verify no longer disabled
        XCTAssertFalse(app.staticTexts["Disabled"].waitForExistence(timeout: 2.0))

        // Verify schedule was created by checking for schedule UI elements
        profileCell.tap()

        // Wait for profile detail view to load
        usleep(500_000)  // 500ms

        // Verify edit schedule button exists (schedule is active and editable)
        // Note: Using edit-schedule-button as the primary indicator of schedule existence
        // (consistent with other schedule UI tests)
        let editScheduleButton = app.buttons["edit-schedule-button"]
        XCTAssertTrue(
            editScheduleButton.waitForExistence(timeout: 5.0),
            "Edit schedule button should appear after re-enabling profile")
    }

    func testNewProfileCreatesSchedule() throws {
        // Setup: Launch app with NO test data
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5.0))

        // Create a new medication profile
        app.tabBars.buttons["Settings"].tap()
        let medicationProfilesButton = app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: 3.0))
        medicationProfilesButton.tap()

        let addButton = app.buttons["Add Medication Profile"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3.0))
        addButton.tap()

        // Select medication
        let medicationPicker = app.buttons["medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 3.0))
        medicationPicker.tap()

        let semaglutideOption = app.buttons["medication-semaglutide"]
        XCTAssertTrue(semaglutideOption.waitForExistence(timeout: 3.0))
        semaglutideOption.tap()

        // Save profile
        let saveButton = app.buttons["save-medication-profile"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3.0))
        saveButton.tap()

        // Verify profile created
        let profileCell = app.buttons.matching(
            identifier: "medication-profile-semaglutide-ozempic-0.25mg"
        ).firstMatch
        XCTAssertTrue(profileCell.waitForExistence(timeout: 3.0))

        // Tap profile to view details
        profileCell.tap()

        // Wait for profile detail view to load
        usleep(500_000)  // 500ms

        // Verify edit schedule button exists (schedule is active and editable)
        // Note: Using edit-schedule-button as the primary indicator of schedule existence
        // (consistent with other schedule UI tests)
        let editScheduleButton = app.buttons["edit-schedule-button"]
        XCTAssertTrue(
            editScheduleButton.waitForExistence(timeout: 5.0),
            "Edit schedule button should appear after creating new profile")
    }

    func testAnalyticsEmptyStateForNewProfile() throws {
        // Setup: Launch app with NO test data
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data"]
        app.launch()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5.0))

        // Create a new medication profile (no doses logged yet)
        app.tabBars.buttons["Settings"].tap()
        let medicationProfilesButton = app.buttons["Medication Profiles"]
        XCTAssertTrue(medicationProfilesButton.waitForExistence(timeout: 3.0))
        medicationProfilesButton.tap()

        let addButton = app.buttons["Add Medication Profile"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3.0))
        addButton.tap()

        let medicationPicker = app.buttons["medication-picker"]
        XCTAssertTrue(medicationPicker.waitForExistence(timeout: 3.0))
        medicationPicker.tap()

        let semaglutideOption = app.buttons["medication-semaglutide"]
        XCTAssertTrue(semaglutideOption.waitForExistence(timeout: 3.0))
        semaglutideOption.tap()

        let saveButton = app.buttons["save-medication-profile"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3.0))
        saveButton.tap()

        // Go to Analytics tab
        app.tabBars.buttons["Analytics"].tap()

        // Should show "No Analytics Data" message (not infinite loading spinner)
        let emptyStateMessage = app.staticTexts["No Analytics Data"]
        XCTAssertTrue(
            emptyStateMessage.waitForExistence(timeout: 10.0),
            "Should show empty state message for new profile with no doses")

        // Should NOT show loading spinner indefinitely
        let loadingSpinner = app.staticTexts["Generating Concentration Chart..."]
        XCTAssertFalse(
            loadingSpinner.exists,
            "Should NOT show loading spinner for profile with no doses")
    }
}
