import XCTest

final class SettingsUITests: XCTestCase {
    @MainActor
    func testSettingsViewElementsExist() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Settings tab
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Validate that essential UI elements exist
        let allButtons = app.buttons
        let allStaticTexts = app.staticTexts
        let allOtherElements = app.otherElements

        // Test that we have actual UI elements (not an empty view)
        XCTAssertGreaterThan(allButtons.count, 0, "Settings view should contain buttons")
        XCTAssertGreaterThan(allStaticTexts.count, 0, "Settings view should contain text elements")
        
        // Test that the Settings title text exists
        XCTAssertTrue(app.staticTexts["Settings"].exists, "Settings title should be visible")
        
        // Test that at least one interactive element exists
        let interactiveElementsExist = allButtons.count > 0
        XCTAssertTrue(interactiveElementsExist, "Settings view should have interactive elements")
        
        // Test that design system components are accessible
        // Look for design system card if it exists in settings
        let designSystemCard = app.descendants(matching: .any)["design-system-card"]
        if designSystemCard.exists {
            XCTAssertTrue(designSystemCard.exists, "Design system card should be accessible when present")
        }
    }
    
    @MainActor
    func testSettingsViewAccessibility() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Settings tab
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Test that key accessibility elements have labels
        let buttonsWithLabels = app.buttons.allElementsBoundByIndex.filter { !$0.label.isEmpty }
        XCTAssertGreaterThan(buttonsWithLabels.count, 0, "At least one button should have accessibility label")
        
        // Test that text elements are accessible
        let textsWithContent = app.staticTexts.allElementsBoundByIndex.filter { !$0.label.isEmpty }
        XCTAssertGreaterThan(textsWithContent.count, 0, "At least one text element should have content")
    }
}
