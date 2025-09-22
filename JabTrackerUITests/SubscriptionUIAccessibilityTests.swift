import StoreKitTest
import XCTest

/// Tests for accessibility and user interaction edge cases in subscription UI
final class SubscriptionUIAccessibilityTests: SubscriptionUIBaseTests {
  // MARK: - Accessibility and Interaction

  @MainActor
  func testVoiceOverNavigationThroughPricingCards() throws {
    // EDGE CASE: Test accessibility navigation through subscription elements
    let app = TestUtilities.launchAppWithConfiguration(
      testMode: true,
      resetData: true,
      additionalArguments: ["--force-onboarding"])

    self.completeOnboardingToSubscriptionScreen(app)

    // Test that key elements have accessibility identifiers
    let monthlyCard = app.buttons["monthly-pricing-card"]
    let annualCard = app.buttons["annual-pricing-card"]
    let purchaseButton = app.buttons["purchase-annual-button"]
    let restoreButton = app.buttons["restore-purchases-button"]

    XCTAssertTrue(
      monthlyCard.exists,
      "Monthly pricing card should be accessible")
    XCTAssertTrue(
      annualCard.exists,
      "Annual pricing card should be accessible")
    XCTAssertTrue(
      purchaseButton.exists,
      "Purchase button should be accessible")
    XCTAssertTrue(
      restoreButton.exists,
      "Restore button should be accessible")

    // Test that pricing text is accessible
    let monthlyPrice = app.staticTexts["$4.99/month"]
    let annualPrice = app.staticTexts["$39.99/year"]
    let trialText = app.staticTexts["4-week free trial"]

    XCTAssertTrue(
      monthlyPrice.exists,
      "Monthly price should be accessible to screen readers")
    XCTAssertTrue(
      annualPrice.exists,
      "Annual price should be accessible to screen readers")
    XCTAssertTrue(
      trialText.exists,
      "Trial period text should be accessible to screen readers")
  }
}
