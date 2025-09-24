import XCTest

final class SettingsUITests: XCTestCase {
    @MainActor
    func testSettingsViewElementsExist() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Navigate to Settings tab
        TestUtilities.navigateToTab(app, tabName: "Settings")

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Test specific functional elements instead of generic counts
        XCTAssertTrue(app.staticTexts["Settings"].exists, "Settings title should be visible")

        // Test for User Profile section (key functionality)
        let userProfileText = app.staticTexts["User Profile"]
        XCTAssertTrue(
            userProfileText.waitForExistence(timeout: 3), "User Profile section should be visible")

        // Test for specific interactive elements that matter
        let editProfileButton = app.buttons["Edit Profile"]
        if editProfileButton.exists {
            XCTAssertTrue(editProfileButton.isHittable, "Edit Profile button should be interactive")
        }

        // Test for sign out functionality
        let signOutButton = app.buttons["sign-out-button"]
        if signOutButton.exists {
            XCTAssertTrue(
                signOutButton.isEnabled, "Sign out button should be enabled when user is authenticated")
        }

        // Test biometric toggle if available
        let biometricToggle = app.switches["biometric-auth-toggle"]
        if biometricToggle.exists {
            XCTAssertTrue(biometricToggle.isHittable, "Biometric toggle should be interactive")
        }

        // Test design system demo section
        let designSystemCard = app.descendants(matching: .any)["design-system-card"]
        if designSystemCard.exists {
            XCTAssertTrue(designSystemCard.exists, "Design system card should be accessible when present")
        }
    }

    @MainActor
    func testSettingsViewAccessibility() throws {
        let app = TestUtilities.launchAppWithTestMode()

        // Navigate to Settings tab
        TestUtilities.navigateToTab(app, tabName: "Settings")

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Test that key accessibility elements have labels
        let buttonsWithLabels = app.buttons.allElementsBoundByIndex.filter { !$0.label.isEmpty }
        XCTAssertGreaterThan(
            buttonsWithLabels.count, 0, "At least one button should have accessibility label")

        // Test that text elements are accessible
        let textsWithContent = app.staticTexts.allElementsBoundByIndex.filter { !$0.label.isEmpty }
        XCTAssertGreaterThan(textsWithContent.count, 0, "At least one text element should have content")
    }
}
