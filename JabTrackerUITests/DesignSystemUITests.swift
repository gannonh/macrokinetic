import XCTest

final class DesignSystemUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDesignSystemComponents() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Settings tab to test design system components
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Scroll down to ensure design system components are visible
        app.swipeUp()

        // First, check if the large title exists (this should be easier to find)
        let largeTitle = app.staticTexts["design-system-large-title"]
        XCTAssertTrue(largeTitle.waitForExistence(timeout: 5), "Large title should exist")

        // Look for the design card using descendants matching (deterministic approach)
        let designCard = app.descendants(matching: .any)["design-system-card"]
        XCTAssertTrue(designCard.waitForExistence(timeout: 5), "Design system card should exist")

        // Finally, verify primary button exists with proper styling
        // (search by label since accessibility inheritance affects identifiers)
        let primaryButton = app.buttons["Primary Button"]
        XCTAssertTrue(primaryButton.waitForExistence(timeout: 5), "Primary button should exist")
        XCTAssertTrue(primaryButton.isEnabled, "Primary button should be enabled")

        // Verify secondary button exists
        let secondaryButton = app.buttons["Secondary Button"]
        XCTAssertTrue(secondaryButton.exists, "Secondary button should exist")
        XCTAssertTrue(secondaryButton.isEnabled, "Secondary button should be enabled")

        // Verify card component exists (already declared above)
        XCTAssertTrue(designCard.exists, "Design system card should exist")

        // Test primary button interaction
        primaryButton.tap()

        // Verify button remains functional after tap
        XCTAssertTrue(primaryButton.exists, "Primary button should still exist after tap")

        // Test secondary button interaction
        secondaryButton.tap()

        // Verify button remains functional after tap
        XCTAssertTrue(secondaryButton.exists, "Secondary button should still exist after tap")
    }

    @MainActor
    func testDesignSystemAccessibility() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Settings tab
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Scroll down to ensure design system components are visible
        app.swipeUp()

        // Test VoiceOver accessibility
        let primaryButton = app.buttons["Primary Button"]
        XCTAssertTrue(primaryButton.waitForExistence(timeout: 5), "Primary button should exist")

        // Verify accessibility properties
        XCTAssertFalse(primaryButton.label.isEmpty, "Primary button should have accessibility label")
        XCTAssertTrue(primaryButton.isHittable, "Primary button should be hittable for accessibility")

        let secondaryButton = app.buttons["Secondary Button"]
        XCTAssertTrue(secondaryButton.exists, "Secondary button should exist")
        XCTAssertFalse(secondaryButton.label.isEmpty, "Secondary button should have accessibility label")
        XCTAssertTrue(secondaryButton.isHittable, "Secondary button should be hittable for accessibility")

        // Test card accessibility using descendants matching (deterministic approach)
        let designCard = app.descendants(matching: .any)["design-system-card"]
        XCTAssertTrue(designCard.exists, "Design system card should exist")
        // Note: Card itself doesn't need to be hittable since interactive elements (buttons) are inside it
    }

    @MainActor
    func testTypographyRendering() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Settings tab
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Scroll down to ensure typography elements are visible
        app.swipeUp()

        // Verify typography elements exist with proper styling
        let largeTitle = app.staticTexts["design-system-large-title"]
        XCTAssertTrue(largeTitle.waitForExistence(timeout: 5), "Large title should exist")

        let headline = app.staticTexts["Design System Demo"]
        XCTAssertTrue(headline.exists, "Headline should exist")

        let bodyText = app.staticTexts["Typography and Colors"]
        XCTAssertTrue(bodyText.exists, "Body text should exist")

        let caption = app.staticTexts["Sample caption text"]
        XCTAssertTrue(caption.exists, "Caption should exist")

        // Verify text content is readable
        XCTAssertFalse(largeTitle.label.isEmpty, "Large title should have text content")
        XCTAssertFalse(headline.label.isEmpty, "Headline should have text content")
        XCTAssertFalse(bodyText.label.isEmpty, "Body text should have text content")
        XCTAssertFalse(caption.label.isEmpty, "Caption should have text content")
    }
}
