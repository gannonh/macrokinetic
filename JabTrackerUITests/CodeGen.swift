import XCTest

final class CodeGenTests: XCTestCase {
  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false

    self.app = XCUIApplication()
    self.app.launchArguments = ["--ui-testing", "--reset-app-data"]
    self.app.launch()

    // Wait for app to be ready
    XCTAssertTrue(self.app.tabBars.firstMatch.waitForExistence(timeout: 5.0))
  }

  @MainActor
  func testCodeGen() throws {
    // record here

  }
}
