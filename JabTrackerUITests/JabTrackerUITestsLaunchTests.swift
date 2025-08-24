import XCTest

final class JabTrackerUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot
        // In the screenshot, the entire app's initial launch state is captured
        
        // Verify app launched successfully
        XCTAssertTrue(app.tabBars.element.waitForExistence(timeout: 10), "App should launch with tab bar visible")
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}