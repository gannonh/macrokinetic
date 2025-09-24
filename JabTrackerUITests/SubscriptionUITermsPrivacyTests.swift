import StoreKitTest
import XCTest

/// Tests for Terms of Service and Privacy Policy link interactions
final class SubscriptionUITermsPrivacyTests: SubscriptionUIBaseTests {
    // MARK: - Terms and Privacy Links

    @MainActor
    func testTermsAndPrivacyLinksInteraction() throws {
        // EDGE CASE: Test Terms of Service and Privacy Policy links
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])

        self.completeOnboardingToSubscriptionScreen(app)

        let termsLink = app.buttons["terms-of-service-link"]
        let privacyLink = app.buttons["privacy-policy-link"]

        XCTAssertTrue(
            termsLink.exists && termsLink.isEnabled,
            "Terms of Service link should be available and enabled")
        XCTAssertTrue(
            privacyLink.exists && privacyLink.isEnabled,
            "Privacy Policy link should be available and enabled")

        // Test that links don't crash the app when tapped
        // Note: In test environment, these might not actually open URLs
        termsLink.tap()

        // App should remain stable
        XCTAssertTrue(
            app.staticTexts["JabTracker Premium"].exists,
            "App should remain stable after Terms link interaction")

        privacyLink.tap()

        // App should remain stable
        XCTAssertTrue(
            app.staticTexts["JabTracker Premium"].exists,
            "App should remain stable after Privacy link interaction")
    }
}
