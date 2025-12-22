import XCTest

/// General UI test recording file for ad-hoc test recording
///
/// To record a test:
/// 1. Place cursor inside an empty test method
/// 2. Click the red record button at bottom of editor
/// 3. Interact with the app in the simulator
/// 4. Xcode will generate test code automatically
/// 5. Click the record button again to stop recording
///
/// This file is for quick exploratory testing and recording UI interactions.
/// Once recorded, you can refactor the test into a proper test file.
final class UITestRecordings: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Cleanup after each test
    }

    /// Launch app with UI testing flags
    private func launchApp() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-app-data", "--skip-onboarding", "--disable-cloudkit"]
        app.launch()
    }

    /// General purpose test recording method
    ///
    /// Use this method to record any UI flow you want to capture.
    /// Click inside this method and press the record button.
    func testRecordUIFlow() throws {
        launchApp()
        // Record test here

    }

}
