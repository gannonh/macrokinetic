import XCTest

final class DebugUITests: XCTestCase {
    @MainActor
    func testSettingsViewElements() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Settings tab
        let tabBar = app.tabBars.element
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()

        // Wait for Settings view to load
        let settingsTitle = app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "Settings navigation should exist")

        // Print all buttons in the view
        print("=== ALL BUTTONS ===")
        let allButtons = app.buttons
        for index in 0 ..< allButtons.count {
            let button = allButtons.element(boundBy: index)
            if button.exists {
                print("Button \(index): identifier='\(button.identifier)', label='\(button.label)'")
            }
        }

        // Print all static texts
        print("=== ALL STATIC TEXTS ===")
        let allStaticTexts = app.staticTexts
        for index in 0 ..< allStaticTexts.count {
            let text = allStaticTexts.element(boundBy: index)
            if text.exists {
                print("Text \(index): identifier='\(text.identifier)', label='\(text.label)'")
            }
        }

        // Print all other elements
        print("=== ALL OTHER ELEMENTS ===")
        let allOthers = app.otherElements
        for index in 0 ..< allOthers.count {
            let other = allOthers.element(boundBy: index)
            if other.exists {
                print("Other \(index): identifier='\(other.identifier)', label='\(other.label)'")
            }
        }

        // Force pass this test - it's just for debugging
        XCTAssertTrue(true)
    }
}
