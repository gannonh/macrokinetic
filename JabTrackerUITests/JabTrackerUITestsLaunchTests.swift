import XCTest

final class JabTrackerUITestsLaunchTests: XCTestCase {
  override static var runsForEachTargetApplicationUIConfiguration: Bool {
    true
  }

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testLaunch() throws {
    let app = TestUtilities.launchAppWithTestMode()

    // Insert steps here to perform after app launch but before taking a screenshot
    // In the screenshot, the entire app's initial launch state is captured

    // Verify app launched successfully
    XCTAssertTrue(
      app.tabBars.element.waitForExistence(timeout: 10), "App should launch with tab bar visible")

    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Launch Screen"
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  @MainActor
  func testAppLaunchAndTabNavigation() throws {
    let app = TestUtilities.launchAppWithTestMode()

    // Verify tab bar exists
    let tabBar = app.tabBars.element
    XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Tab bar should exist")

    // Test Home tab (should be selected by default)
    let homeTab = tabBar.buttons["Home"]
    XCTAssertTrue(homeTab.exists, "Home tab should exist")
    XCTAssertTrue(homeTab.isSelected, "Home tab should be selected by default")
    XCTAssertTrue(
      app /*@START_MENU_TOKEN@*/.staticTexts[
        "Add medication profiles"
      ] /*[[".otherElements.staticTexts[\"Add medication profiles\"]",".staticTexts[\"Add medication profiles\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        .exists, "Add Dose title should exist")

    //

    // Test Add Dose tab navigation
    let addTab = tabBar.buttons["Add"]
    XCTAssertTrue(addTab.exists, "Add tab should exist")
    addTab.tap()

    XCTAssertTrue(
      app /*@START_MENU_TOKEN@*/.staticTexts[
        "Quick Add Dose"
      ] /*[[".navigationBars",".staticTexts.firstMatch",".staticTexts[\"Quick Add Dose\"]"],[[[-1,2],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        .exists, "Add Dose title should exist")
    app.buttons["quick-dose-cancel-button"].tap()

    // Test History tab navigation
    let historyTab = tabBar.buttons["History"]
    XCTAssertTrue(historyTab.exists, "History tab should exist")
    historyTab.tap()

    XCTAssertTrue(historyTab.isSelected, "History tab should be selected after tap")
    XCTAssertTrue(
      app /*@START_MENU_TOKEN@*/.staticTexts[
        "No doses logged yet"
      ] /*[[".otherElements.staticTexts[\"No doses logged yet\"]",".staticTexts[\"No doses logged yet\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        .exists, "History title should exist")

    // Test Analytics tab navigation
    let analyticsTab = tabBar.buttons["Analytics"]
    XCTAssertTrue(analyticsTab.exists, "Analytics tab should exist")
    analyticsTab.tap()

    XCTAssertTrue(analyticsTab.isSelected, "Analytics tab should be selected after tap")
    XCTAssertTrue(app.staticTexts["Analytics"].exists, "Analytics title should exist")

    // Test Settings tab navigation
    let settingsTab = tabBar.buttons["Settings"]
    XCTAssertTrue(settingsTab.exists, "Settings tab should exist")
    settingsTab.tap()

    XCTAssertTrue(settingsTab.isSelected, "Settings tab should be selected after tap")
    XCTAssertTrue(
      app /*@START_MENU_TOKEN@*/.staticTexts[
        "medication-management-header"
      ] /*[[".otherElements",".staticTexts[\"Medication Management\"]",".staticTexts[\"medication-management-header\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/
        .exists, "Settings title should exist")

    // Navigate back to Home tab
    homeTab.tap()
    XCTAssertTrue(homeTab.isSelected, "Home tab should be selected after returning")
  }
}
