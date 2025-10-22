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

        // Verify profile is hidden from active list
        XCTAssertFalse(profileCell.waitForExistence(timeout: 3.0))
        let emptyStateLabel = app.staticTexts["No medication profiles yet"]
        XCTAssertTrue(emptyStateLabel.waitForExistence(timeout: 3.0))

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

        // Confirm permanent deletion
        let confirmDialog = app.alerts["Delete Medication Profile?"]
        XCTAssertTrue(confirmDialog.waitForExistence(timeout: 3.0))
        let deletePermanentlyButton = confirmDialog.buttons["Delete Permanently"]
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
        let emptyAnalyticsMessage = app.staticTexts["No data available"]
        XCTAssertTrue(
            emptyAnalyticsMessage.waitForExistence(timeout: 5.0) || !chart.exists,
            "Analytics should be empty after permanent delete removes all doses")
    }
}
