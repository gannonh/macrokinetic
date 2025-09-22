import StoreKitTest
import XCTest

/// Tests for restore purchase edge cases and error handling
final class SubscriptionUIRestorePurchaseTests: SubscriptionUIBaseTests {
  // MARK: - Restore Purchase Edge Cases

  @MainActor
  func testRestoreWithNoPreviousPurchases() throws {
    // EDGE CASE: Test restore when user has no previous purchases
    let app = TestUtilities.launchAppWithConfiguration(
      testMode: true,
      resetData: true,
      additionalArguments: ["--force-onboarding"])

    self.completeOnboardingToSubscriptionScreen(app)
    self.dismissSignInSimulationIfPresent(app)

    // Clear any existing transactions to simulate no previous purchases
    self.testSession?.clearTransactions()

    let restoreButton = app.buttons["restore-purchases-button"]
    XCTAssertTrue(
      restoreButton.waitForExistence(timeout: 3),
      "Restore purchases button should be available")

    restoreButton.tap()

    // Should show alert indicating no purchases to restore
    let restoreAlert = app.alerts["Restore Purchases"]
    XCTAssertTrue(
      restoreAlert.waitForExistence(timeout: 5),
      "Should show restore purchases alert")

    // Dismiss alert
    if restoreAlert.buttons["OK"].exists {
      restoreAlert.buttons["OK"].tap()
    }

    // Should remain on subscription screen
    XCTAssertTrue(
      app.staticTexts["JabTracker Premium"].exists,
      "Should remain on subscription screen after restore with no purchases")
  }

  @MainActor
  func testMultipleRestoreAttempts() throws {
    // EDGE CASE: Test multiple restore attempts in succession
    let app = TestUtilities.launchAppWithConfiguration(
      testMode: true,
      resetData: true,
      additionalArguments: ["--force-onboarding"])

    self.completeOnboardingToSubscriptionScreen(app)
    self.dismissSignInSimulationIfPresent(app)

    let restoreButton = app.buttons["restore-purchases-button"]
    XCTAssertTrue(restoreButton.waitForExistence(timeout: 3))

    // Attempt multiple restores rapidly
    for attempt in 1...3 {
      print("🔄 Restore attempt \(attempt)")

      if !restoreButton.isEnabled {
        // Wait for restore button to become enabled again
        let enabled = XCTNSPredicateExpectation(
          predicate: NSPredicate(format: "isEnabled == true"),
          object: restoreButton)
        XCTAssertEqual(
          XCTWaiter().wait(for: [enabled], timeout: 3), .completed,
          "Restore button should become enabled between attempts")
      }

      restoreButton.tap()

      let restoreAlert = app.alerts["Restore Purchases"]
      if restoreAlert.waitForExistence(timeout: 3) {
        restoreAlert.buttons["OK"].tap()
      }

      // Brief pause between attempts
      Thread.sleep(forTimeInterval: 0.5)
    }

    // App should remain stable after multiple restore attempts
    XCTAssertTrue(
      app.staticTexts["JabTracker Premium"].exists,
      "App should remain stable after multiple restore attempts")
  }
}
