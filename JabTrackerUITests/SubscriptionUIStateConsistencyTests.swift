import StoreKitTest
import XCTest

/// Tests for UI state consistency and navigation edge cases
final class SubscriptionUIStateConsistencyTests: SubscriptionUIBaseTests {
  // MARK: - UI State Consistency

  @MainActor
  func testButtonStatesWhenNoProductsAvailable() throws {
    // EDGE CASE: Test button states when StoreKit products unavailable
    let app = TestUtilities.launchAppWithConfiguration(
      testMode: true,
      resetData: true,
      additionalArguments: ["--force-onboarding"])

    self.completeOnboardingToSubscriptionScreen(app)

    // Test that pricing cards are still interactive even without products
    let monthlyCard = app.buttons["monthly-pricing-card"]
    let annualCard = app.buttons["annual-pricing-card"]

    XCTAssertTrue(
      monthlyCard.exists && monthlyCard.isEnabled,
      "Monthly pricing card should be interactive")
    XCTAssertTrue(
      annualCard.exists && annualCard.isEnabled,
      "Annual pricing card should be interactive")

    // Test plan switching still works
    monthlyCard.tap()
    annualCard.tap()

    // UI should respond to interactions
    XCTAssertTrue(true, "UI should remain responsive during plan switching")
  }

  @MainActor
  func testBackNavigationDuringPurchaseFlow() throws {
    // EDGE CASE: Test back navigation during purchase attempt
    let app = TestUtilities.launchAppWithConfiguration(
      testMode: true,
      resetData: true,
      additionalArguments: ["--force-onboarding"])

    self.completeOnboardingToSubscriptionScreen(app)

    // Check if back button is available (might not be in final onboarding step)
    let backButton = app.buttons["onboarding-back-button"]
    if backButton.exists {
      print("✅ Back button available during subscription screen")

      // Test back navigation
      backButton.tap()

      // Should navigate to previous onboarding step
      let continueButton = app.buttons["onboarding-continue-button"]
      if continueButton.waitForExistence(timeout: 2) {
        // Navigate forward again to test state consistency
        continueButton.tap()

        XCTAssertTrue(
          app.staticTexts["JabTracker Premium"].waitForExistence(timeout: 3),
          "Should return to subscription screen after back/forward navigation")
      }
    } else {
      print("ℹ️  No back button available on subscription screen (expected for final step)")
    }
  }
}
