import StoreKitTest
import XCTest

/// Tests for subscription plan switching edge cases and UI interactions
final class SubscriptionUIPlanSwitchingTests: SubscriptionUIBaseTests {
    // MARK: - Plan Switching Edge Cases

    @MainActor
    func testRapidPlanSwitching() throws {
        // EDGE CASE: Test rapid switching between monthly/annual plans
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])

        self.completeOnboardingToSubscriptionScreen(app)

        let monthlyCard = app.buttons["monthly-pricing-card"]
        let annualCard = app.buttons["annual-pricing-card"]

        XCTAssertTrue(monthlyCard.waitForExistence(timeout: 3),
                      "Monthly pricing card should exist")
        XCTAssertTrue(annualCard.exists,
                      "Annual pricing card should exist")

        // Test rapid switching
        for _ in 0 ..< 3 {
            monthlyCard.tap()
            Thread.sleep(forTimeInterval: 0.1)

            // Verify monthly purchase button appears
            let monthlyPurchaseButton = app.buttons["purchase-monthly-button"]
            XCTAssertTrue(monthlyPurchaseButton.waitForExistence(timeout: 1),
                          "Monthly purchase button should appear when monthly plan selected")

            annualCard.tap()
            Thread.sleep(forTimeInterval: 0.1)

            // Verify annual purchase button appears
            let annualPurchaseButton = app.buttons["purchase-annual-button"]
            XCTAssertTrue(annualPurchaseButton.waitForExistence(timeout: 1),
                          "Annual purchase button should appear when annual plan selected")
        }
    }

    @MainActor
    func testMostPopularBadgeVisibility() throws {
        // EDGE CASE: Verify "Most Popular" badge only appears on annual plan
        let app = TestUtilities.launchAppWithConfiguration(
            testMode: true,
            resetData: true,
            additionalArguments: ["--force-onboarding"])

        self.completeOnboardingToSubscriptionScreen(app)

        // Most Popular badge should be visible by default (annual selected)
        let popularBadge = app.staticTexts["Most Popular"]
        XCTAssertTrue(popularBadge.exists,
                      "Most Popular badge should be visible on annual plan")

        // Switch to monthly and verify badge is still associated with annual card
        let monthlyCard = app.buttons["monthly-pricing-card"]
        monthlyCard.tap()

        // Badge should still exist (it's part of the annual card, not selection-dependent)
        XCTAssertTrue(popularBadge.exists,
                      "Most Popular badge should remain visible even when monthly plan selected")
    }
}
