import XCTest

/// Minimal E2E tests for medication profile settings integration
/// Core functionality has been moved to dedicated test files for better organization
final class MedicationProfileSettingsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        self.app = XCUIApplication()
        self.app.launchArguments = ["--ui-testing", "--reset-app-data"]
        self.app.launch()

        XCTAssertTrue(self.app.tabBars.firstMatch.waitForExistence(timeout: 5.0))
    }

    /// Integration test: Settings navigation to medication profiles
    func testMedicationProfilesNavigation() throws {
        TestUtilities.navigateToSettings(self.app)

        let medicationProfilesButton = self.app.buttons["Medication Profiles"]
        XCTAssertTrue(
            medicationProfilesButton.waitForExistence(timeout: 3.0),
            "Medication Profiles button should exist in Settings")
        medicationProfilesButton.tap()

        let addProfileButton = self.app.buttons["Add Medication Profile"]
        XCTAssertTrue(
            addProfileButton.waitForExistence(timeout: 3.0),
            "Add button should be accessible in medication profiles")
    }

    /// Integration test: Empty state display
    func testEmptyStateDisplay() throws {
        TestUtilities.navigateToSettings(self.app)
        self.app.buttons["Medication Profiles"].tap()

        let emptyStateLabel = self.app.staticTexts["No medication profiles yet"]
        XCTAssertTrue(
            emptyStateLabel.waitForExistence(timeout: 3.0),
            "Empty state should be shown when no profiles exist")
    }
}
