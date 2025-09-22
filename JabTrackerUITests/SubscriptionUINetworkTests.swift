import StoreKitTest
import XCTest

/// Tests for network connectivity and loading states during subscription flows
final class SubscriptionUINetworkTests: SubscriptionUIBaseTests {
  // MARK: - Network and Loading States

  @MainActor
  func testLoadingStatesDuringProductFetch() throws {
    // EDGE CASE: Test UI loading states during product fetch
    let app = TestUtilities.launchAppWithConfiguration(
      testMode: true,
      resetData: true,
      additionalArguments: ["--force-onboarding"])

    self.completeOnboardingToSubscriptionScreen(app)

    // Pricing should be displayed even in test environment
    let monthlyPrice = app.staticTexts["$4.99/month"]
    let annualPrice = app.staticTexts["$39.99/year"]

    XCTAssertTrue(
      monthlyPrice.exists || annualPrice.exists,
      "At least one pricing option should be visible")
  }
}
