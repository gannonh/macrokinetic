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
        
        // Verify primary button exists with proper styling
        let primaryButton = app.buttons["design-system-primary-button"]
        XCTAssertTrue(primaryButton.waitForExistence(timeout: 5), "Primary button should exist")
        XCTAssertTrue(primaryButton.isEnabled, "Primary button should be enabled")
        
        // Verify secondary button exists
        let secondaryButton = app.buttons["design-system-secondary-button"]
        XCTAssertTrue(secondaryButton.exists, "Secondary button should exist")
        XCTAssertTrue(secondaryButton.isEnabled, "Secondary button should be enabled")
        
        // Verify card component exists
        let designCard = app.otherElements["design-system-card"]
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
        
        // Test VoiceOver accessibility
        let primaryButton = app.buttons["design-system-primary-button"]
        XCTAssertTrue(primaryButton.waitForExistence(timeout: 5), "Primary button should exist")
        
        // Verify accessibility properties
        XCTAssertFalse(primaryButton.label.isEmpty, "Primary button should have accessibility label")
        XCTAssertTrue(primaryButton.isHittable, "Primary button should be hittable for accessibility")
        
        let secondaryButton = app.buttons["design-system-secondary-button"]
        XCTAssertTrue(secondaryButton.exists, "Secondary button should exist")
        XCTAssertFalse(secondaryButton.label.isEmpty, "Secondary button should have accessibility label")
        XCTAssertTrue(secondaryButton.isHittable, "Secondary button should be hittable for accessibility")
        
        // Test card accessibility
        let designCard = app.otherElements["design-system-card"]
        XCTAssertTrue(designCard.exists, "Design system card should exist")
        XCTAssertTrue(designCard.isHittable, "Design card should be hittable for accessibility")
    }
    
    @MainActor
    func testTypographyRendering() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Settings tab
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()
        
        // Verify typography elements exist with proper styling
        let largeTitle = app.staticTexts["design-system-large-title"]
        XCTAssertTrue(largeTitle.waitForExistence(timeout: 5), "Large title should exist")
        
        let headline = app.staticTexts["design-system-headline"]
        XCTAssertTrue(headline.exists, "Headline should exist")
        
        let bodyText = app.staticTexts["design-system-body"]
        XCTAssertTrue(bodyText.exists, "Body text should exist")
        
        let caption = app.staticTexts["design-system-caption"]
        XCTAssertTrue(caption.exists, "Caption should exist")
        
        // Verify text content is readable
        XCTAssertFalse(largeTitle.label.isEmpty, "Large title should have text content")
        XCTAssertFalse(headline.label.isEmpty, "Headline should have text content")
        XCTAssertFalse(bodyText.label.isEmpty, "Body text should have text content")
        XCTAssertFalse(caption.label.isEmpty, "Caption should have text content")
    }
}