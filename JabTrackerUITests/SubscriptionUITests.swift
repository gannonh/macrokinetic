import StoreKitTest
import XCTest

final class SubscriptionUITests: XCTestCase {
  var testSession: SKTestSession?

  override func setUpWithError() throws {
    continueAfterFailure = false
    let thisFile = URL(fileURLWithPath: #file)
    let repoRoot = thisFile.deletingLastPathComponent().deletingLastPathComponent()
    let configURL = repoRoot.appendingPathComponent("JabTrackerStoreKit.storekit")

    print("🛒 StoreKitTest init -> expecting config at: \(configURL.path)")
    guard FileManager.default.fileExists(atPath: configURL.path) else {
      XCTFail("❌ StoreKit configuration missing at: \(configURL.path)")
      return
    }
    let session = try SKTestSession(contentsOf: configURL)
    session.disableDialogs = false  // verify purchase UI
    session.clearTransactions()
    self.testSession = session
    print("✅ StoreKitTest session ready (disableDialogs=\(session.disableDialogs))")
  }

  override func tearDown() {
    self.testSession = nil
    super.tearDown()
  }

  @MainActor
  func testSubscriptionRestoreFlow() throws {
    // ACCEPTANCE CRITERIA: User can restore previous purchases
    let app = TestUtilities.launchAppWithConfiguration(
      testMode: true,
      resetData: true,
      additionalArguments: ["--force-onboarding"])

    // Navigate to subscription screen
    self.completeOnboardingToSubscriptionScreen(app)

    // If the simulated Apple ID sign-in alert is shown on first entry, restore will be
    // blocked until it's accepted. Dismiss it if present, and also register an
    // interruption monitor to catch any mid-flow appearances.
    self.dismissSignInSimulationIfPresent(app)
    let signInMonitor = self.addUIInterruptionMonitor(
      withDescription: "Simulated Apple ID sign-in"
    ) { alert in
      if alert.staticTexts["Sign in with Apple ID"].exists {
        if alert.buttons["OK"].exists {
          alert.buttons["OK"].tap()
          return true
        }
        if alert.buttons["Continue"].exists {
          alert.buttons["Continue"].tap()
          return true
        }
        if alert.buttons.firstMatch.exists {
          alert.buttons.firstMatch.tap()
          return true
        }
      }
      return false
    }
    defer { self.removeUIInterruptionMonitor(signInMonitor) }
    // Nudge the app so the interruption monitor can fire if the alert is on-screen
    app.tap()

    // ACCEPTANCE CRITERIA: Restore purchases button is available
    let restoreButton = app.buttons["restore-purchases-button"]
    XCTAssertTrue(
      restoreButton.waitForExistence(timeout: 3),
      "Should show restore purchases button")
    XCTAssertTrue(
      restoreButton.isEnabled,
      "Restore button should be enabled")

    // Tap restore purchases
    restoreButton.tap()

    // ACCEPTANCE CRITERIA: Restore process provides user feedback
    let restoreAlert = app.alerts["Restore Purchases"]
    XCTAssertTrue(
      restoreAlert.waitForExistence(timeout: 6),
      "Should show restore purchases result alert (title: Restore Purchases)")

    // Dismiss alert and continue
    if restoreAlert.buttons["OK"].exists {
      restoreAlert.buttons["OK"].tap()
    }
  }

  @MainActor
  func testSubscriptionStatusDisplay() throws {
    // ACCEPTANCE CRITERIA: Subscription status is displayed correctly in Settings
    let app = TestUtilities.launchAppWithTestMode()

    // Navigate to Settings tab
    app.tabBars.buttons["Settings"].tap()

    // ACCEPTANCE CRITERIA: Subscription status section exists
    XCTAssertTrue(
      app.staticTexts["Subscription"].waitForExistence(timeout: 3),
      "Should show subscription section in settings")

    // ACCEPTANCE CRITERIA: Current subscription status is displayed
    let subscriptionStatus = app.staticTexts["subscription-status"]
    XCTAssertTrue(
      subscriptionStatus.waitForExistence(timeout: 3),
      "Should display current subscription status")

    // Status should be one of: Trial Active, Premium Active, or Not Subscribed
    let statusText = subscriptionStatus.label
    let validStatuses = ["Trial Active", "Premium Active", "Not Subscribed"]
    XCTAssertTrue(
      validStatuses.contains(statusText),
      "Subscription status should be one of: \(validStatuses.joined(separator: ", "))")
  }

  @MainActor
  func testTrialCountdownAccuracyAfterPurchase() throws {
    XCTAssertEqual(
      self.testSession?.disableDialogs, false,
      "StoreKit dialogs must be enabled for deterministic purchase UI")
    let app = TestUtilities.launchAppWithConfiguration(
      testMode: true,
      resetData: true,
      additionalArguments: ["--force-onboarding"])
    self.completeOnboardingToSubscriptionScreen(app)
    self.dismissSignInSimulationIfPresent(app)
    self.performPurchaseFlow(app: app)
    self.verifyTrialOrPremiumInSettings(app: app)
  }

  @MainActor
  func testEnhancedSubscriptionPricingUI() throws {
    // ACCEPTANCE CRITERIA: Enhanced subscription pricing UI displays all required elements
    let app = TestUtilities.launchAppWithConfiguration(
      testMode: true,
      resetData: true,
      additionalArguments: ["--force-onboarding"])

    // Navigate to subscription screen
    self.completeOnboardingToSubscriptionScreen(app)

    // ACCEPTANCE CRITERIA: Trial period shows "4-week" not "2-week"
    let trialText = app.staticTexts["4-week free trial"]
    XCTAssertTrue(
      trialText.waitForExistence(timeout: 3),
      "Should display '4-week free trial' text")

    // ACCEPTANCE CRITERIA: Both monthly and annual pricing options are displayed
    let monthlyCard = app.buttons["monthly-pricing-card"]
    XCTAssertTrue(
      monthlyCard.waitForExistence(timeout: 3),
      "Should show monthly pricing card")

    let annualCard = app.buttons["annual-pricing-card"]
    XCTAssertTrue(
      annualCard.waitForExistence(timeout: 3),
      "Should show annual pricing card")

    // ACCEPTANCE CRITERIA: Monthly pricing displays correctly
    let monthlyPrice = app.staticTexts["$4.99/month"]
    XCTAssertTrue(
      monthlyPrice.exists,
      "Should display monthly price as $4.99/month")

    // ACCEPTANCE CRITERIA: Annual pricing displays with savings
    let annualPrice = app.staticTexts["$39.99/year"]
    XCTAssertTrue(
      annualPrice.exists,
      "Should display annual price as $39.99/year")

    let savingsText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Save'"))
    XCTAssertTrue(
      savingsText.firstMatch.exists,
      "Should display savings information for annual plan")

    // ACCEPTANCE CRITERIA: "Most Popular" badge appears on annual plan
    let popularBadge = app.staticTexts["Most Popular"]
    XCTAssertTrue(
      popularBadge.exists,
      "Should show 'Most Popular' badge on annual plan")

    // ACCEPTANCE CRITERIA: Terms of Service and Privacy Policy links are present
    let termsLink = app.buttons["terms-of-service-link"]
    XCTAssertTrue(
      termsLink.exists,
      "Should show Terms of Service link")

    let privacyLink = app.buttons["privacy-policy-link"]
    XCTAssertTrue(
      privacyLink.exists,
      "Should show Privacy Policy link")

    // ACCEPTANCE CRITERIA: Purchase buttons work for both subscription types
    // First test annual button (selected by default)
    let annualPurchaseButton = app.buttons["purchase-annual-button"]
    XCTAssertTrue(
      annualPurchaseButton.exists,
      "Should show annual purchase button when annual plan selected")
    XCTAssertTrue(
      annualPurchaseButton.isEnabled,
      "Annual purchase button should be enabled")

    // Select monthly plan to test monthly button
    monthlyCard.tap()

    let monthlyPurchaseButton = app.buttons["purchase-monthly-button"]
    XCTAssertTrue(
      monthlyPurchaseButton.waitForExistence(timeout: 2),
      "Should show monthly purchase button when monthly plan selected")
    XCTAssertTrue(
      monthlyPurchaseButton.isEnabled,
      "Monthly purchase button should be enabled")
  }

  @MainActor
  func testSubscriptionManagementInSettings() throws {
    // ACCEPTANCE CRITERIA: Settings includes subscription management guidance
    let app = TestUtilities.launchAppWithTestMode()

    // Navigate to Settings tab
    app.tabBars.buttons["Settings"].tap()

    // ACCEPTANCE CRITERIA: Subscription management section exists
    let managementSection = app.staticTexts["Manage Subscription"]
    XCTAssertTrue(
      managementSection.waitForExistence(timeout: 3),
      "Should show 'Manage Subscription' section")

    // ACCEPTANCE CRITERIA: Explanatory text about App Store subscription management
    let explanationText = app.staticTexts.matching(
      NSPredicate(format: "label CONTAINS 'Apple App Store'"))
    XCTAssertTrue(
      explanationText.firstMatch.waitForExistence(timeout: 3),
      "Should show explanation about managing subscription via Apple App Store")

    // ACCEPTANCE CRITERIA: Link to manage subscription is functional
    let manageLink = app.buttons["manage-subscription-link"]
    XCTAssertTrue(
      manageLink.exists,
      "Should show manage subscription link")
    XCTAssertTrue(
      manageLink.isEnabled,
      "Manage subscription link should be enabled")
  }

  // Helpers moved to SubscriptionUITests+Helpers.swift
}
